////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#import "OFMultiplayer.h"
#import "OFMultiplayerService+Private.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"
#import "OFPaginatedSeries.h"
#import "OFSettings.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFProvider.h"
#import "OFHttpRequest.h"
#import "OFHttpRequestObserver.h"
#import "OFMultiplayerNotificationData.h"
#import "OFNotification.h"
#import "OFMultiplayerInputResponse.h"
#import "OFOptionSerializer.h"
////////////////////////////////////////////////
// Webnet Includes

#import "webnet/webnet.h"
#import "webnet/stream.h"
#import "webnet/base64.h"
#import "webnet/cstr.h"
#import "webnet/ofmp.h"

#import "OFMultiplayerGame.h"
#import "OFMPAnomaly.h"

////////////////////////////////////////////////
// Webnet Defines

// Specify an URL that returns a server URL to be used
// for multiplayer communications.
#define WEBNET_BUFFER_DATA_SIZE       65536
#define WEBNET_PROCESS_TIMER_LENGTH   (1 / 10.0f)   // in seconds
#define WEBNET_LOGIN_TIMER_LENGTH     3.0f          // in seconds

#ifdef _DEBUG
// Uncomment to enable output in debug mode.
#define OFMP_DEBUG_OUTPUT
#endif

#ifdef OFMP_DEBUG_OUTPUT
#define ofmp_dprintf printf
#else
static __inline void ofmp_dprintf(const char* f, ...) {}
#endif

////////////////////////////////////////////////
// Webnet Function Defs
namespace {
    void clearRequests();
    void cleanupGameSlot(OFMultiplayerGame* lobbySlot);
    void readGameSlotFromStream(OFMultiplayerGame *lobbySlot, wn_stream_t* stream);
    void forceLogout();
    OFMultiplayerGame* getActiveSlot();
    OFMultiplayerGame* getActiveSlotMatchingId(u64 gameId);
    void consumeMove(OFMultiplayerMove* move);
    void addMoveToQueueIn(OFMultiplayerMove* move);
    void randomSeed(u32 seed);
    
    wn_stream_t* openOutputBufferStream();
    wn_stream_t* openInputBufferStream(const void* data, u32 size);
    wn_stream_t* openRequest();
    wn_stream_t* openResponse(const void* data, u32 size);
    
    wn_webnet_request_status_t loginResponse(const unsigned char* data, u32 size);
    wn_webnet_request_status_t getGamesResponse(const unsigned char* data, u32 size);
    wn_webnet_request_status_t sendMovesResponse(const unsigned char* data, u32 size);
    wn_webnet_request_status_t getMovesResponse(const unsigned char* data, u32 size);
    wn_webnet_request_status_t anomalyResponse(const unsigned char* data, u32 size);
}
////////////////////////////////////////////////
// Internal classes
/*
    An anomoly is anything outside the usual move system.   These may be sent by any player, they will be checked by the server.
    RESIGN player, next player - new move type, a player can resign themselves if they wish as a normal move, or you can force it
        RESIGN will only be accepted as an anomoly if the player is either closed or timed out
    END TURN player, next player - adds this type of move if the player is closed or timed out
    FINISH (rank list) - register an ending to the game
 
    All anomolies are considered top priority.  If an anomoly is added, but already in progress, then it will not be added again.
    RESIGNED players are considered to be closed as far as the player state is concerned.
 
 */

@interface OFMPAnomalyProcessor : NSObject
{
@private
    NSMutableDictionary* unprocessed;
    NSMutableDictionary* inProcess;
    NSMutableDictionary* finished;
    BOOL dataSent;
    NSUInteger serial;
}
@property (nonatomic, retain) NSMutableDictionary* unprocessed;
@property (nonatomic, retain) NSMutableDictionary* inProcess;
@property (nonatomic, retain) NSMutableDictionary* finished;
@property (nonatomic) BOOL dataSent;
@property (readonly, nonatomic) NSUInteger waitingCount;

-(void) addAnomaly:(OFMPAnomaly*) anomaly;
-(void) reset;

@end

@implementation OFMPAnomalyProcessor
@synthesize unprocessed;
@synthesize inProcess;
@synthesize finished;
@synthesize dataSent;
-(NSUInteger)waitingCount { return [unprocessed count]; }
-(id) init {
    self = [super init];
    if(self) {
        self.unprocessed = [NSMutableDictionary dictionaryWithCapacity:4];
        self.inProcess = [NSMutableDictionary dictionaryWithCapacity:4];
        self.finished = [NSMutableDictionary dictionaryWithCapacity:4];
        self.dataSent = NO;
    }
    return self;
}
-(void) addAnomaly:(OFMPAnomaly*) anomaly {
    [self.unprocessed setObject:anomaly forKey:[NSNumber numberWithInt:serial++]];
}

-(void) reset {
    //TODO:if anything in flight, what happens?
    [unprocessed removeAllObjects];
    [inProcess removeAllObjects];
    [finished removeAllObjects];
    dataSent = NO;
}

-(void) dealloc {
    self.unprocessed = nil;
    self.inProcess = nil;
    self.finished = nil;
    [super dealloc];
}

@end



@interface OFMPOutgoingMoveQueue : NSObject
{
    NSMutableDictionary* moves;
    NSUInteger maxSize;
    NSUInteger processedSerial;  //the player-specific move number that will be the next move
    BOOL movesSent;
    NSUInteger processFailureCount;
}

@property (nonatomic, retain) NSMutableDictionary* moves;
@property (nonatomic) NSUInteger maxSize;
@property (nonatomic) NSUInteger processedSerial;
@property (nonatomic) BOOL movesSent;
@property (nonatomic, readonly) NSUInteger spaceLeft;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic) NSUInteger processFailureCount;
-(id)initWithCapacity:(NSUInteger) size;
-(void)reset;
-(NSUInteger)clearMovesBeforeSerial:(NSUInteger) serial;
-(void)addMove:(OFMultiplayerMove*) move;
@end

@implementation OFMPOutgoingMoveQueue
@synthesize moves,maxSize, movesSent, processedSerial;
@synthesize processFailureCount;
-(id)initWithCapacity:(NSUInteger) size {
    self = [super init];
    if(self) {
        self.moves = [NSMutableDictionary dictionaryWithCapacity:size];
        self.maxSize = size;
        [self reset];
    }
    return self;
}
-(NSUInteger) spaceLeft {
    return maxSize - [moves count];
}
-(NSUInteger) count {
    return [self.moves count];
}
-(void)reset {
    [self.moves removeAllObjects];
    self.movesSent = NO;
    self.processedSerial = 0;
    self.processFailureCount = 0;
}
-(void)dealloc {
    self.moves = nil;
    [super dealloc];
}
-(void)addMove:(OFMultiplayerMove*) move {
    NSAssert(self.spaceLeft, @"Trying to enter into a full outgoing queue!");
    NSAssert(![self.moves objectForKey:[NSNumber numberWithUnsignedInt:move.movePlayerSerial]], @"Move already queued!");
    OFLog(@"Adding move for serial# %d", move.movePlayerSerial);
    [self.moves setObject:move forKey:[NSNumber numberWithUnsignedInt:move.movePlayerSerial]];
}
-(NSUInteger)clearMovesBeforeSerial:(NSUInteger) serial {
    NSUInteger movesRemoved = 0;
    NSArray* keys = [self.moves allKeys];
    for(NSNumber* key in keys) {
        if([key unsignedIntValue] < serial) {
            [self.moves removeObjectForKey:key];
            ++movesRemoved;
        }
    }
    return movesRemoved;
}
@end


@interface OFMPIncomingMoveQueue : NSObject
{
    BOOL gettingMoves;
    NSUInteger maxSize;
    NSUInteger nextMoveToLoad;
    NSUInteger finalMove;
    NSMutableArray* moves;
    
}
@property (nonatomic) BOOL gettingMoves;
@property (nonatomic, retain) NSMutableArray* moves;
@property (nonatomic) NSUInteger maxSize;
@property (nonatomic) NSUInteger nextMoveToLoad;
@property (nonatomic) NSUInteger finalMove;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSUInteger spaceLeft;
-(id)initWithCapacity:(NSUInteger) size;
-(void) reset;

@end
@implementation OFMPIncomingMoveQueue 
@synthesize gettingMoves,maxSize, moves, nextMoveToLoad, finalMove;
-(NSUInteger)count {
    return [self.moves count];
}
-(NSUInteger)spaceLeft {
    return self.maxSize - self.count;
}
-(id)initWithCapacity:(NSUInteger) size {
    self = [super init];
    if(self) {
        self.moves = [NSMutableArray arrayWithCapacity:size];
        self.maxSize = size;
        self.gettingMoves = NO;
        self.nextMoveToLoad = 0;
        self.finalMove = 65535;
    }
    return self;
}
-(void)dealloc {
    self.moves = nil;
    [super dealloc];
}
-(void)reset {
    [self.moves removeAllObjects];
    self.gettingMoves = NO;
    self.nextMoveToLoad = 0;
    self.finalMove = 65535;
}
@end


@interface OFMultiplayerMove () 
    @property (nonatomic, readwrite) unsigned int number; //the order of the move in the entire game
    @property (nonatomic, readwrite) unsigned int nextPlayer; //the next player if this is an end turn move
    @property (nonatomic, readwrite) unsigned int movePlayer; //the player who made this move
    @property (nonatomic, readwrite) unsigned int movePlayerSerial; //the order of this player's moves
    @property (nonatomic, readwrite) unsigned int moveReason; //the reason for an EndTurn or Resign
    @property (nonatomic, readwrite) OFMPMoveCode code; //the OFMPMoveCode
    @property (nonatomic, readwrite, retain) NSData* data; //a data block for DATA and DATA_ECHO types
    @property (nonatomic, readwrite, retain) NSArray* finishRanks; 
@end
////////////////////////////////////////////////
// Webnet Variables

namespace {
    NSObject<OFMultiplayerDelegate> *mDelegate;
    
    wn_stream_t mBufferStream;
    void* mBufferData;
    
    NSTimer* mProcessTimer;
    NSTimeInterval mProcessLastTime;
    
    float mLoginTimer;
    bool mLoginInProcess;
    u32 mLoginToken;
    
    u8 mUpdateRateGetGames;
    u8 mUpdateRateGetMoves;
    float mGetGamesTimer;
    float mGetMovesTimer;
    OFDelegate mViewingGamesOnSuccess;
    
    bool mViewingGames;
    int mLaunchingGameSlot = -1;   //this indicates that a Push Notification started the process
    NSDictionary *mLaunchingGameOptions = nil;
    u8 mGameCount;
    s32 mActiveGameSlot;
    bool mActiveGameMovesRestored;
    bool mActiveGameGetGamesSent;
    u8 mActiveGameCurrentPlayer;
    NSString* mActiveGamePushMessage;
    
    OFMPOutgoingMoveQueue* mOutgoingMoveQueue;
    OFMPIncomingMoveQueue* mIncomingMoveQueue;
    OFMPAnomalyProcessor* mAnomalyProcessor;
    
    NSInteger mHighestMoveProcessed; //in a given set of moves, the highest value that was actually done
        
    NSArray* mSlotArray;
    u32 mSlotArraySize;
    
    u32 mRandomValueVar;
    
    NSMutableArray* mChallenges;
    BOOL mChallengesAutoAssign = YES;
    
    NSString* masterUrlOverride = nil;
    NSString* applicationIdOverride = nil;
    
    OFOptionSerializer* createGameSerializer = nil;
    OFOptionSerializer* findGameSerializer = nil;
    OFOptionSerializer* findOrCreateGameSerializer = nil;
    OFOptionSerializer* gameResponseSerializer = nil;
    OFOptionSerializer* sendMovesSerializer = nil;
    OFOptionSerializer* loginSerializer = nil;
    OFOptionSerializer* getMovesSerializer = nil;
} //anon namespace



////////////////////////////////////////////////
// OpenFeint OFMultiplayerService Interface
OPENFEINT_DEFINE_SERVICE_INSTANCE(OFMultiplayerService)
@interface OFMultiplayerGame ()
@property (nonatomic, readwrite) unsigned char minPlayers;
@property (nonatomic, readwrite) unsigned char maxPlayers;

@property (nonatomic, readwrite) unsigned long long gameId;
@property (nonatomic, readwrite) unsigned int rseed;
@property (nonatomic, readwrite) unsigned int startDateInSec;
@property (nonatomic, readwrite, retain) NSString* gameDefinitionId;
@property (nonatomic, readwrite) unsigned int turnTime;
@property (nonatomic, readwrite) unsigned int elapsedTime;
@property (nonatomic, readwrite) unsigned int moveCount;
@property (nonatomic, readwrite) unsigned char playerCount;
@property (nonatomic, readwrite) unsigned char currentPlayer;
@property (nonatomic, readwrite) unsigned char player;
@property (nonatomic, readwrite) unsigned char playerChallengeState;
@property (nonatomic, readwrite) unsigned char gameSlot;


@property (nonatomic, readwrite) OFMultiplayer::enumSlotCloseState slotCloseState;
@property (nonatomic, readwrite) OFMultiplayer::enumGameState state;
@property (nonatomic, readwrite, retain) NSMutableArray* playerOFUserIds;
@property (nonatomic, readwrite, retain) NSMutableArray* playerRanks;
@property (nonatomic, readwrite, retain) NSMutableArray* playerSlotCloseStates;
@property (nonatomic, readwrite, retain) NSMutableArray* playerSlotElapsedTime;

@property (nonatomic, readwrite) OFMultiplayer::enumClientGameSlotState clientGameSlotState;
@property (nonatomic, readwrite) char currentPlayerClosed;
@property (nonatomic, readwrite) BOOL acceptChallenge;
@property (nonatomic, readwrite) BOOL waitingForRematch;

@property (nonatomic, readwrite, retain) NSDictionary* previousValues;
@property (nonatomic, readwrite, retain) NSDictionary* options;
@end

@interface OFMultiplayerService ()
+ (void) createSerializers;
+ (void) internalProcess;

+ (void) internalDestroyMoveQueue;
+ (void) internalResetMoveQueue;

+ (void) internalGetGames;
+ (void) internalSendAnomalies;

+ (void) internalSendMoves;
+ (void) internalGetMoves;
+ (bool) internalHasCurrentPlayerLeftGame;
@end


@implementation OFMultiplayerService

OPENFEINT_DEFINE_SERVICE(OFMultiplayerService)

#pragma mark Boilerplate Service Methods

- (id)init
{
	self = [super init];
    
    if(masterUrlOverride) {
        [OFMPNet createWithMasterURL:masterUrlOverride];
    }
    else {
        [OFMPNet createWithMasterURL:OFSettings::Instance()->getMultiplayerServerUrl()];
    }
    
    mDelegate = nil;
    
    mBufferData = malloc(WEBNET_BUFFER_DATA_SIZE);
    wn_assert(mBufferData, "Could not create buffer.");
    
    mProcessLastTime = [NSDate timeIntervalSinceReferenceDate];
    
    mLoginTimer = 0.0f;
    mLoginInProcess = false;
    mLoginToken = 0;
    
    mUpdateRateGetGames = OFMP_DEFAULT_UPDATE_RATE_GET_GAMES;
    mUpdateRateGetMoves = OFMP_DEFAULT_UPDATE_RATE_GET_MOVES;
    mGetGamesTimer = 0.0f;
    mGetMovesTimer = 0.0f;
    mViewingGamesOnSuccess = OFDelegate();
    
    mViewingGames = false;
    mGameCount = 0;
    mActiveGameSlot = -1;
    mActiveGameMovesRestored = false;
    mActiveGameGetGamesSent = false;
    mActiveGamePushMessage = 0;
    
    mOutgoingMoveQueue = nil;
    mIncomingMoveQueue = nil;
    mAnomalyProcessor = nil;
    	
	mSlotArraySize = 0;
	mSlotArray = nil;
	
	[OFMultiplayerService internalCreateMoveQueueWithOutgoingSize:16 withIncomingSize:256];
	[OFMultiplayerService internalSetSlotArraySize:1];
    mAnomalyProcessor = [OFMPAnomalyProcessor new];
    
    mChallenges = [[NSMutableArray alloc] initWithCapacity:1];
    [OFMultiplayerService createSerializers];
    
	return self;
}

+(void) internalSetSlotArraySize:(unsigned int) size {
	
	mSlotArraySize = size;
	if(mSlotArray) {
		[mSlotArray release];
		mSlotArray = nil;
	}
    
	NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:size];
	for(unsigned int i=0; i<size; ++i)
	{
		OFMultiplayerGame* slot = [[[OFMultiplayerGame alloc] init] autorelease];
		slot.gameSlot = i;
		[tempArray addObject: slot];
	}
	mSlotArray = [[NSArray alloc]initWithArray:tempArray];
}

+ (void) internalSetMasterUrlOverride:(NSString*) url {
    masterUrlOverride = [url retain];
}

+ (void) internalSetApplicationIdOverride:(NSString*) appId {
    applicationIdOverride = [appId retain];
}

+ (void) createSerializers {
    createGameSerializer = [OFOptionSerializer new];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_CONFIG atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_TURN_TIME atByte:0 atBit:1 ofType:OFOptionSerializerTypes::U32];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS atByte:0 atBit:2 ofType:OFOptionSerializerTypes::U8];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS atByte:0 atBit:3 ofType:OFOptionSerializerTypes::U8];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_CHALLENGE_OF_IDS atByte:0 atBit:4 ofType:OFOptionSerializerTypes::CharStringArray];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN atByte:0 atBit:6 ofType:OFOptionSerializerTypes::Flag];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_FIRST_PLAYER atByte:1 atBit:0 ofType:OFOptionSerializerTypes::U8];
    
    findGameSerializer = [OFOptionSerializer new];
    [findGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_TURN_TIME_FIND_FILTER atByte:0 atBit:5 ofType:OFOptionSerializerTypes::U32Array];
    
    findOrCreateGameSerializer = [OFOptionSerializer new];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_CONFIG atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_TURN_TIME atByte:0 atBit:1 ofType:OFOptionSerializerTypes::U32];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS atByte:0 atBit:2 ofType:OFOptionSerializerTypes::U8];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS atByte:0 atBit:3 ofType:OFOptionSerializerTypes::U8];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_TURN_TIME_FIND_FILTER atByte:0 atBit:5 ofType:OFOptionSerializerTypes::U32Array];
    [findOrCreateGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN atByte:0 atBit:6 ofType:OFOptionSerializerTypes::Flag];
    [createGameSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_FIRST_PLAYER atByte:1 atBit:0 ofType:OFOptionSerializerTypes::U8];

    gameResponseSerializer = [OFOptionSerializer new];
    [gameResponseSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_CONFIG atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
    [gameResponseSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_CHALLENGER_OF_ID atByte:0 atBit:4 ofType:OFOptionSerializerTypes::CharString];
    [gameResponseSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN atByte:0 atBit:6 ofType:OFOptionSerializerTypes::Flag];
    [gameResponseSerializer addOptionKey:@"presence" atByte:0 atBit:5 ofType:OFOptionSerializerTypes::Flag];
    [gameResponseSerializer addOptionKey:OFMultiplayer::LOBBY_OPTION_FIRST_PLAYER atByte:1 atBit:0 ofType:OFOptionSerializerTypes::U8];
    
    sendMovesSerializer = [OFOptionSerializer new];
    [sendMovesSerializer addOptionKey:@"message" atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
    
    getMovesSerializer = [OFOptionSerializer new];
    [getMovesSerializer addOptionKey:@"presence" atByte:0 atBit:0 ofType:OFOptionSerializerTypes::Flag];
    
    loginSerializer = [OFOptionSerializer new];
    [loginSerializer addOptionKey:@"version" atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
}

- (void)dealloc
{
    if(mSlotArray)
    {
        [mSlotArray release];
        mSlotArray = nil;
    }
    if(mChallenges)
    {
        [mChallenges release];
    }
    mDelegate = nil;
    
    [mLaunchingGameOptions release];
    mLaunchingGameOptions = nil;
    
	if(mProcessTimer) {
        mGetGamesTimer = 0;
        mGetMovesTimer = 0;
        [OFMultiplayerService internalProcess];
    }
    
    [OFMultiplayerService internalDestroyMoveQueue];
    forceLogout();
    [OFMPNet destroy];
    
    if(mActiveGamePushMessage) {
        OFSafeRelease(mActiveGamePushMessage);
    }
    OFSafeRelease(masterUrlOverride);
    OFSafeRelease(applicationIdOverride);
    OFSafeRelease(createGameSerializer);
    OFSafeRelease(findGameSerializer);
    OFSafeRelease(findOrCreateGameSerializer);
    OFSafeRelease(gameResponseSerializer);
    OFSafeRelease(sendMovesSerializer);
    OFSafeRelease(getMovesSerializer);
    OFSafeRelease(loginSerializer);
    [super dealloc];
}

- (void)populateKnownResources:(OFResourceNameMap*)namedResources
{
//	namedResources->addResource([OFMPGameDefinition getResourceName], [OFMPGameDefinition class]);
}

#pragma mark Webnet Interface Functions

+ (void) internalSetDelegate:(id<OFMultiplayerDelegate>)delegate {
    mDelegate = delegate;
}

+ (void) internalUnsetDelegate:(id<OFMultiplayerDelegate>)delegate {
    if(mDelegate != delegate) {
        OFLog(@"Warning:  delegate being removed %@ is not the current delegate %@", delegate, mDelegate);
    }
    mDelegate = nil;
}
                                

+ (void) internalCreateMoveQueueWithOutgoingSize:(unsigned int)outgoingSize withIncomingSize:(unsigned int)incomingSize {
    [OFMultiplayerService internalDestroyMoveQueue];
    
    mOutgoingMoveQueue = [[OFMPOutgoingMoveQueue alloc] initWithCapacity:outgoingSize];
    mIncomingMoveQueue = [[OFMPIncomingMoveQueue alloc] initWithCapacity:incomingSize];
    
    [OFMultiplayerService internalResetMoveQueue];
}

+ (void) internalDestroyMoveQueue {
    [OFMultiplayerService internalResetMoveQueue];
    
    OFSafeRelease(mOutgoingMoveQueue);
    OFSafeRelease(mIncomingMoveQueue);
    OFSafeRelease(mAnomalyProcessor);
}

+ (void) internalResetMoveQueue {    
    [mOutgoingMoveQueue reset];
    [mIncomingMoveQueue reset];
}

+ (void) internalProcess {
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval deltaTime = currentTime - mProcessLastTime;
    mProcessLastTime = currentTime;

#ifndef _DISTRIBUTION        
    static NSTimeInterval nagWarningDelta = 0;
    nagWarningDelta += deltaTime;
    if(nagWarningDelta > 60) {
        OFLog(@"WARNING: OpenFeint Multiplayer using sandbox server, #define _DISTRIBUTION before submitting to Apple");
        nagWarningDelta = 0;
    }
#endif    
    
    if(!mLoginToken) {
        if(!mLoginInProcess) {
            if(mLoginTimer > deltaTime) {
                mLoginTimer -= deltaTime;
            }
            else {
                NSString* userId = [OpenFeint lastLoggedInUserId];
                if(userId) {
                    NSString* appId = [OpenFeint clientApplicationId];
                    if(appId) {
                        NSString* accessToken = [[OpenFeint provider] getAccessToken];
                        if(accessToken) {
                            mLoginTimer = WEBNET_LOGIN_TIMER_LENGTH;
                            mLoginInProcess = true;
                            [OFMultiplayerService internalLogin:appId withOFUserId:userId withAccessToken:accessToken];
                        }
                    }
                }
            }
        }
    }
    else {
        //view games if there was a launch game or if viewing games and the timer has expired
        bool viewGames = mLaunchingGameSlot != -1;
        if(mViewingGames) {
            if(mGetGamesTimer > deltaTime) {
                mGetGamesTimer -= deltaTime;
            }
            else {
                viewGames = YES;
            }
        }
        if(viewGames) {
            mGetGamesTimer = mUpdateRateGetGames;
            [OFMultiplayerService internalGetGames];
        }
        
        if(mActiveGameSlot != -1) {
            if(mGetMovesTimer > deltaTime) {
                mGetMovesTimer -= deltaTime;
            }
            else {
                mGetMovesTimer = mUpdateRateGetMoves;
                [OFMultiplayerService internalGetMoves];
            }
            if(mAnomalyProcessor.waitingCount) {
                [OFMultiplayerService internalSendAnomalies];
            }
            else if(mOutgoingMoveQueue.count && !mOutgoingMoveQueue.movesSent)
                [OFMultiplayerService internalSendMoves];
        }
    }
}

+ (void) internalStartProcessing {
    OFAssert(mIncomingMoveQueue && mOutgoingMoveQueue, "Move queue is not initialized.");
    
    [OFMultiplayerService internalStopProcessing];
    mProcessTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)WEBNET_PROCESS_TIMER_LENGTH target:self selector:@selector(internalProcess) userInfo:nil repeats:TRUE];
}

+ (void) internalStopProcessing {
    if(mProcessTimer) {
        [mProcessTimer invalidate];
        mProcessTimer = nil;
    }
}

+ (void) internalSignalNetworkFailure:(NSUInteger) reason {
    if([mDelegate respondsToSelector:@selector(networkFailureWithReason:)])
        [mDelegate networkFailureWithReason:reason];
}


+ (bool) internalIsLoggedIn {
    return mLoginToken != 0;
}

+ (bool) internalIsViewingGames {
    return mViewingGames;
}

+ (bool) internalIsItMyTurn {
    //TODO: we really need to create a different "slot" for the active game, thereby avoiding confusion between the current
    //and server game states
    OFMultiplayerGame* active = getActiveSlot();
    if(active.state != OFMultiplayer::GS_PLAYING) return false;
    if([active.options objectForKey:OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN]) 
        return true;
    else 
        return mActiveGameCurrentPlayer == active.player;
}

+ (bool) internalHasCurrentPlayerLeftGame {
	OFMultiplayerGame* active = getActiveSlot();
	if(active != nil) {		
        //TODO: handle RESIGN
        return active.currentPlayerClosed;
//		return (mActiveGameAdvanceTurnSendState) ? false : active.currentPlayerClosed;
	}
	else {
		return false;
	}
}

+ (unsigned int) internalGetNonEmptyGameSlotCount {
    return mGameCount;
}

+ (int) internalGetActiveGameSlot {
    return mActiveGameSlot;
}


+ (unsigned int) internalGetSendableMoveCount {
	OFMultiplayerGame* slot = getActiveSlot();
	if(slot != nil) {
        //TODO: handle anomalies
		if(!mActiveGameMovesRestored
		   || mIncomingMoveQueue.count
		   || slot.state == OFMultiplayer::GS_FINISHED) {
			return 0;
		}
		else {
			if([self internalIsItMyTurn])
                return mOutgoingMoveQueue.spaceLeft;
		}
	}
	return 0;
}

+(NSUInteger) internalMovesToBeSent {
    return mOutgoingMoveQueue.count + mAnomalyProcessor.waitingCount;
}

+ (void) internalStartViewingGames {
    if(!mViewingGames) {
        mGetGamesTimer = 0.0f;
        mViewingGames = true;
    }
}

+ (void) internalStopViewingGames {
    if(mViewingGames) {
        mViewingGames = false;  }
}

+(void) internalEnterGame:(OFMultiplayerGame*)game {
	if(game.gameId) {
		clearRequests();
		mActiveGameSlot = game.gameSlot;
		mActiveGameMovesRestored = game.moveCount == 0;
		mActiveGameCurrentPlayer = game.currentPlayer;        
		mGetMovesTimer = 0.0f;
		
		[OFMultiplayerService internalResetMoveQueue];
		
		randomSeed(game.rseed);
	}
	
}

+ (void) internalLeaveGame {
    mActiveGameSlot = -1;
    [OFMultiplayerService internalResetMoveQueue];
    clearRequests();
}

+ (void) internalFinishGameWithPlayerRanks:(NSArray*)playerRanks {
	OFMultiplayerGame* slot = getActiveSlot();
	if(slot != nil) {
        //use the anomaly processor
        OFMPAnomaly*anomaly = [[OFMPAnomaly new] autorelease];
        anomaly.action = Anomaly::ACTION_FINISH_GAME;
        anomaly.finishStates = playerRanks;
        [mAnomalyProcessor addAnomaly:anomaly];
    }
}

+ (void) internalLogin:(NSString*)ofAppId withOFUserId:(NSString*)ofUserId withAccessToken:(NSString*)accessToken {
    
    wn_stream_t* io = openRequest();
    
    wn_stream_ou8(io, OFMP_RQ_LOGIN);
    if(applicationIdOverride)  
        wn_stream_ostr(io, [applicationIdOverride UTF8String]);  
    else 
        wn_stream_ostr(io, [ofAppId UTF8String]);  //this is the Multiplayer Id, which may or may not be the same as...
    wn_stream_ostr(io, [ofAppId UTF8String]);  //the actual application Id
    wn_stream_ostr(io, [ofUserId UTF8String]);
    wn_stream_ostr(io, [accessToken UTF8String]);
    NSDictionary* options = [NSDictionary dictionaryWithObject:OFSettings::Instance()->getClientBundleVersion() forKey:@"version"];
    [loginSerializer writeOptions:options toStream:io];
    
    wn_stream_close(io);
    [OFMPNet requestWithBytes:mBufferData size:io->pos callback:loginResponse];
    ofmp_dprintf("Sent request for: OFMP_RQ_LOGIN\n");
}

+ (void) internalLogout {
    forceLogout();
}

+ (void) internalGetGames {
    if(!mActiveGameGetGamesSent) {
        wn_stream_t* io = openRequest();
        u8 gameSlotRequestCount = 0;
        
        NSEnumerator *enumerator = [[OFMultiplayerService internalGetSlotArray] objectEnumerator];
        OFMultiplayerGame* slot;
        while((slot = [enumerator nextObject])) {
            if(slot.clientGameSlotState) gameSlotRequestCount++;
        }
        
        wn_stream_ou8(io, OFMP_RQ_GET_GAMES);
        wn_stream_ou32(io, mLoginToken);
        wn_stream_ou8(io, mChallengesAutoAssign ? mSlotArraySize : 0);
        wn_stream_ou8(io, gameSlotRequestCount);           
        [gameResponseSerializer writeBitFieldToStream:io];
        
        // Write the info for each game slot request.
        for(u32 i = 0; i < mSlotArraySize; i++) {
            OFMultiplayerGame* slot = [self getSlot:i];
            switch(slot.clientGameSlotState) {
                case OFMultiplayer::CGSS_CREATING_GAME:
                    wn_stream_ou8(io, OFMP_SLOT_CREATE_GAME);
                    wn_stream_ou8(io, i);
                    wn_stream_ostr(io, [slot.gameDefinitionId UTF8String]);
                    assert(slot.gameDefinitionId);  //this was getting reset by accident during getGamesMove, leaving this here in case it comes back
                    [createGameSerializer writeOptions:slot.options toStream:io];
                    break;
                    
                case OFMultiplayer::CGSS_FINDING_GAME:
                    wn_stream_ou8(io, OFMP_SLOT_FIND_GAME);
                    wn_stream_ou8(io, i);
                    wn_stream_ostr(io, [slot.gameDefinitionId UTF8String]);
                    [findGameSerializer writeOptions:slot.options toStream:io];
                    break;
                    
                case OFMultiplayer::CGSS_FINDING_OR_CREATING_GAME:
                    wn_stream_ou8(io, OFMP_SLOT_FIND_OR_CREATE_GAME);
                    wn_stream_ou8(io, i);
                    wn_stream_ostr(io, [slot.gameDefinitionId UTF8String]);
                    [findOrCreateGameSerializer writeOptions:slot.options toStream:io];
                    break;
                    
                case OFMultiplayer::CGSS_CANCELLING_GAME:
                    wn_stream_ou8(io, OFMP_SLOT_CANCEL_GAME);
                    wn_stream_ou8(io, i);
                    break;
                    
                case OFMultiplayer::CGSS_CLOSING_GAME:
                    wn_stream_ou8(io, OFMP_SLOT_CLOSE_GAME);
                    wn_stream_ou8(io, i);
                    break;
                    
                case OFMultiplayer::CGSS_REQUESTING_REMATCH:
                    wn_stream_ou8(io, OFMP_SLOT_REQUEST_REMATCH);
                    wn_stream_ou8(io, i);
                    slot.waitingForRematch = true;
                    break;
                    
                case OFMultiplayer::CGSS_SENDING_CHALLENGE_RESPONSE:
                    wn_stream_ou8(io, OFMP_SLOT_SEND_CHALLENGE_RESPONSE);
                    wn_stream_ou8(io, i);
                    wn_stream_ob(io, slot.acceptChallenge);
                    break;
                    
                default:
                    break;
            }
            
            if(slot.clientGameSlotState != OFMultiplayer::CGSS_FINDING_GAME)
                slot.clientGameSlotState = OFMultiplayer::CGSS_NONE;
        }
        
        wn_stream_close(io);
        [OFMPNet requestWithBytes:mBufferData size:io->pos callback:getGamesResponse];
        mActiveGameGetGamesSent = true;
        
        ofmp_dprintf("Sent request for: OFMP_RQ_GET_GAMES\n");
    }
}


+(void) internalSetLobbyType:(OFMultiplayer::enumClientGameSlotState)clientSlotState 
          withGameDefinition:(OFMPGameDefinitionId*)gameDefinitionId
                 withOptions:(NSDictionary *)options 
                     forGame:(OFMultiplayerGame *)game
{
    if(!game.gameId) {
        cleanupGameSlot(game);
        game.options = [NSMutableDictionary dictionaryWithDictionary:options];
        game.gameDefinitionId = gameDefinitionId;
        game.clientGameSlotState = clientSlotState;
    }
}



+ (void) internalSendChallengeResponseForGame:(OFMultiplayerGame*)game withAccept:(bool)accept {
	if(game.gameId && game.playerChallengeState == OFMP_CS_WAIT_FOR_APPROVAL) {
		game.clientGameSlotState = OFMultiplayer::CGSS_SENDING_CHALLENGE_RESPONSE;
		game.acceptChallenge = accept;
	}
    
}

+ (bool) internalSendMove:(NSData*)data
                 withCode:(OFMPMoveCode)code
           withNextPlayer:(unsigned int)nextPlayer {
    
      if(mOutgoingMoveQueue.spaceLeft) {
        OFMultiplayerGame* slot = getActiveSlot();
        if(slot && [OFMultiplayerService isItMyTurn]) {
            OFMultiplayerMove* move = [[[OFMultiplayerMove alloc] init] autorelease];
            
            move.number = 65535;  //NOTE: this value will be changed by the server
            move.code = code;
            move.data = [[[NSData alloc] initWithData:data] autorelease];
            move.nextPlayer = nextPlayer;
            move.movePlayer = slot.player;  
            move.movePlayerSerial = mOutgoingMoveQueue.processedSerial++;  
            move.moveReason = OFMultiplayer::ANOMALY_REASON_SELF;
                        
            [mOutgoingMoveQueue addMove:move];
            
            switch(code) {
                case OFMP_MC_RESIGN:
                case OFMP_MC_END_TURN:
                    mActiveGameCurrentPlayer = nextPlayer;
                    break;
                default:
                    break;
            }
            
            return true;
        }
    }
    
    return false;
}

+ (void) internalAddAnomaly:(OFMPAnomaly*) anomaly {
    OFMultiplayerGame*slot =  getActiveSlot();
    if(slot) {
        anomaly.nextPlayer = [slot getNextPlayerNumber];
        [mAnomalyProcessor addAnomaly:anomaly];
    }
}

+ (bool) internalSendMove:(NSData*)data
                 withCode:(OFMPMoveCode)code
     withPushNotification:(NSString*)pushNotification
           withNextPlayer:(unsigned int)nextPlayer {
    mActiveGamePushMessage = [pushNotification retain];
    return [OFMultiplayerService internalSendMove:data withCode:code withNextPlayer:nextPlayer];
}

+(bool) internalSendFinishGameTurnWithPlayerRanks:(NSArray *)playerRanks {
    if(mOutgoingMoveQueue.spaceLeft) {
        OFMultiplayerGame* slot = getActiveSlot();
        if(slot && [OFMultiplayerService isItMyTurn]) {
            OFMultiplayerMove* move = [[[OFMultiplayerMove alloc] init] autorelease];
            
            move.number = 65535;  //NOTE: this value will be changed by the server
            move.code = OFMP_MC_FINISH_GAME;
            move.finishRanks = playerRanks;
            move.movePlayerSerial = mOutgoingMoveQueue.processedSerial++;  
            [mOutgoingMoveQueue addMove:move];
            return true;
        }
    }
    return false;
}

+ (void) internalSendMoves {
	OFMultiplayerGame* slot = getActiveSlot();
    if(slot) {
        wn_stream_t* io = openRequest();
        
        wn_stream_ou8(io, OFMP_RQ_SEND_MOVE);
        wn_stream_ou32(io, mLoginToken);
        wn_stream_ou64(io, slot.gameId);
        wn_stream_ou8(io, mOutgoingMoveQueue.count);
        NSMutableDictionary* options = [NSMutableDictionary dictionaryWithCapacity:2];
        if(mActiveGamePushMessage) {
            [options setObject:mActiveGamePushMessage forKey:@"message"];
        }
        [sendMovesSerializer writeOptions:options toStream:io];

        NSArray *keyArray = [[mOutgoingMoveQueue.moves allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(NSNumber* key in keyArray) {
            OFMultiplayerMove* move = [mOutgoingMoveQueue.moves objectForKey:key];
            
            wn_stream_ou8(io, move.code);
            wn_stream_ou16(io, move.movePlayerSerial);
            
            switch(move.code) {
                case OFMP_MC_DATA: 
                case OFMP_MC_DATA_ECHO:
                {
                    u32 dataSize = [move.data length];
                    wn_stream_ou16(io, dataSize);
                    if(dataSize)
                        wn_stream_obytes(io, [move.data bytes], dataSize);
                    break;
                }
                case OFMP_MC_RESIGN:
                case OFMP_MC_END_TURN:
                    wn_stream_ou8(io, move.movePlayer);
                    wn_stream_ou8(io, move.nextPlayer);
                    wn_stream_ou8(io, move.moveReason);
                    break;
                case OFMP_MC_FINISH_GAME:
                    wn_stream_ou8(io, [move.finishRanks count]);
                    for(NSNumber* rank in move.finishRanks) 
                        wn_stream_ou8(io,[rank unsignedCharValue]);
                    break;
            }
        }
        
        wn_stream_close(io);
        [OFMPNet requestWithBytes:mBufferData size:io->pos callback:sendMovesResponse];
        mOutgoingMoveQueue.movesSent = YES;
        OFSafeRelease(mActiveGamePushMessage);
        
        ofmp_dprintf("Sent request for: OFMP_RQ_SEND_MOVES (%d moves, slot = %d)\n", mOutgoingMoveQueue.count, mActiveGameSlot);
    }
}

+ (void) internalSendAnomalies {
	OFMultiplayerGame* slot = getActiveSlot();
    if(slot) {
        wn_stream_t* io = openRequest();
        
        wn_stream_ou8(io, OFMP_RQ_SEND_ANOMALIES);
        wn_stream_ou32(io, mLoginToken);
        wn_stream_ou64(io, slot.gameId);
        wn_stream_ou8(io, mAnomalyProcessor.waitingCount);
        wn_stream_ou8(io, 0);  //reserved for future options
        for (NSNumber*index in mAnomalyProcessor.unprocessed) {
            OFMPAnomaly* anomaly = [mAnomalyProcessor.unprocessed objectForKey:index];
            wn_stream_ou16(io, [index unsignedShortValue]);
            wn_stream_ou8(io, anomaly.action);
            switch(anomaly.action) {
                case Anomaly::ACTION_RESIGN:
                case Anomaly::ACTION_END_TURN:
                    wn_stream_ou8(io, anomaly.player);
                    wn_stream_ou8(io, anomaly.nextPlayer);
                    wn_stream_ou8(io, anomaly.reason);
                    break;
                case Anomaly::ACTION_FINISH_GAME:
                    wn_stream_ou8(io, [anomaly.finishStates count]);
                    for(unsigned int i=0; i<[anomaly.finishStates count]; ++i) {
                        wn_stream_ou8(io, [[anomaly.finishStates objectAtIndex:i] unsignedCharValue]);
                    }
                    break;
            }
            [mAnomalyProcessor.inProcess setObject:anomaly forKey:index];
        }
        [mAnomalyProcessor.unprocessed removeAllObjects];
        
        wn_stream_close(io);
        [OFMPNet requestWithBytes:mBufferData size:io->pos callback:anomalyResponse];
        mAnomalyProcessor.dataSent = TRUE;
        
        ofmp_dprintf("Sent request for: OFMP_RQ_SEND_ANOMALIES\n");
    }    
}

+ (void) internalGetMoves {
    // Don't bother getting moves until all queued outgoing moves have been sent first.
    if(!mOutgoingMoveQueue.count && !mIncomingMoveQueue.gettingMoves) {
        OFMultiplayerGame* slot = getActiveSlot();
        
        if(slot) {
            wn_stream_t* io = openRequest();
            
            wn_stream_ou8(io, OFMP_RQ_GET_MOVES);
            wn_stream_ou32(io, mLoginToken);
            wn_stream_ou64(io, slot.gameId);
            wn_stream_ou16(io, mIncomingMoveQueue.nextMoveToLoad);
            wn_stream_ou16(io, mIncomingMoveQueue.spaceLeft);
            wn_stream_ou16(io, mOutgoingMoveQueue.processedSerial);
            [getMovesSerializer writeBitFieldToStream:io];
            
            wn_stream_close(io);
            [OFMPNet requestWithBytes:mBufferData size:io->pos callback:getMovesResponse];

            mIncomingMoveQueue.gettingMoves = YES;
            
            ofmp_dprintf("Sent request for: OFMP_RQ_GET_MOVES (starting from #%d, serial %d)\n", mIncomingMoveQueue.nextMoveToLoad, mOutgoingMoveQueue.processedSerial);
        }
    }
}

+ (OFMultiplayerMove*) internalGetNextMove {
    if(mIncomingMoveQueue.count) {
        OFMultiplayerGame* slot = getActiveSlot();
        if(slot) {
            OFMultiplayerMove* move = [mIncomingMoveQueue.moves objectAtIndex:0];
            [move retain];  //make sure the object survives long enough for the client to receive it
            [move autorelease];
            [mIncomingMoveQueue.moves removeObjectAtIndex:0];
            
            ofmp_dprintf("Extracting move #%d\n", move.number);
            
            consumeMove(move);  //update the internal state (current player, whether the final move is loaded, etc)
            return move;
        }
    }
    
    return nil;
}

+ (unsigned int) internalRandomValue {
    mRandomValueVar = mRandomValueVar * 214013L + 2531011L;
    return mRandomValueVar;
}

+ (int) internalRandomRange:(int)low high:(int)high {
    int result;
    
    if(high == low)
        result = high;
    else {
        unsigned int range;
        if(high < low) {
            int temp = high;
            high = low;
            low = temp;
        }
        range = high - low;
        result = ((int) ([self internalRandomValue] % (range + 1))) + low;
    }
    
    return result;
}

+(NSArray*) internalGetSlotArray {
	return mSlotArray;
}

+(unsigned int) internalGetSlotCount {
	return mSlotArraySize;
}

+(unsigned int) internalGetActiveGameCurrentPlayer {
	return mActiveGameCurrentPlayer;
}


+(int) internalGetNumberOfChallenges {
    return [mChallenges count];
}
+(OFMultiplayerGame*) internalGetChallengeAtIndex:(unsigned int) index {
    
    return [mChallenges objectAtIndex:index];
}
+(void) internalSetChallengeAutoAssign:(bool)doAutoAssign {
    mChallengesAutoAssign = doAutoAssign;
}

+(void) handleInputResponseFromPushNotification:(NSDictionary*) notificationData {
    SEL selector = @selector(gameRequestedFromPushRequest:withOptions:);
    //perhaps a bit paranoid, but it's possible the delegate switches between notification and response
    if([mDelegate respondsToSelector:selector]) {
        int slot = [[notificationData objectForKey:@"slot"] intValue];
        [mDelegate gameRequestedFromPushRequest:[mSlotArray objectAtIndex:slot] 
                                    withOptions:notificationData];
    }

}

+(void) internalProcessPushNotification:(NSDictionary *)notificationData fromLaunch:(BOOL) wasLaunched {    
    if(wasLaunched)
    {
        //look for the matching game id
        //this will have to force a load at boot time so we can get the game to view
        mLaunchingGameSlot = [[notificationData objectForKey:@"slot"] intValue];
        mLaunchingGameOptions = [[NSDictionary dictionaryWithDictionary:notificationData] retain];
    }
    else
    {
        //this means we got the message "in-flight", so just give a notification
        //this might be enhanced so that it doesn't show if you are currently viewing the game in question
        OFMultiplayerNotificationData *notification = [OFMultiplayerNotificationData dataWithPushNotification:notificationData];
        [[OFNotification sharedInstance] showBackgroundNotice:notification andStatus:nil];
    }
}

+(BOOL)notificationIsMultiplayer:(NSDictionary*)params {
    NSString *notificationType = [params objectForKey:@"notification_type"];
    if(notificationType && [notificationType isEqualToString:@"mp"])
    {
        return YES;
    }
    return NO;    
}

@end

#pragma mark Webnet Interface Functions (Private)
namespace {
    void clearRequests() {
        mOutgoingMoveQueue.movesSent = NO;
        mIncomingMoveQueue.gettingMoves = NO;
        //TODO: replace this functionality
        [OFMPNet cancelRequestsForCallback:getMovesResponse];
        [OFMPNet cancelRequestsForCallback:sendMovesResponse];
    }
    
    void cleanupGameSlot(OFMultiplayerGame *lobbySlot) {
        lobbySlot.gameDefinitionId = nil;
        lobbySlot.gameId = 0;
        if(lobbySlot.clientGameSlotState != OFMultiplayer::CGSS_SENDING_CHALLENGE_RESPONSE)
            lobbySlot.acceptChallenge = FALSE;
        lobbySlot.clientGameSlotState = OFMultiplayer::CGSS_NONE;
        lobbySlot.rseed = 0;
        lobbySlot.turnTime = 0;
        lobbySlot.elapsedTime = 0;
        lobbySlot.moveCount = 0;
        lobbySlot.playerCount = 0;
        lobbySlot.currentPlayer = 0;
        lobbySlot.player = 0;
        lobbySlot.playerChallengeState = 0;
        lobbySlot.slotCloseState = OFMultiplayer::SCS_AVAILABLE;
        lobbySlot.state = OFMultiplayer::GS_UNKNOWN;
        lobbySlot.currentPlayerClosed = FALSE;
        lobbySlot.options = nil;
        
        OFSafeRelease(lobbySlot.playerOFUserIds);
        OFSafeRelease(lobbySlot.playerRanks);
        OFSafeRelease(lobbySlot.playerSlotCloseStates);
        OFSafeRelease(lobbySlot.playerSlotElapsedTime);
    }
    
    void readGameSlotFromStream(OFMultiplayerGame *slot, wn_stream_t* io) {
        cleanupGameSlot(slot);
        slot.gameId = wn_stream_iu64(io);
        slot.rseed = wn_stream_iu32(io);
        slot.startDateInSec = wn_stream_iu32(io);
        slot.gameDefinitionId = [NSString stringWithCString:wn_stream_istr(io) encoding:NSUTF8StringEncoding];
        slot.turnTime = wn_stream_iu32(io);
        slot.elapsedTime = wn_stream_iu32(io);
        slot.moveCount = wn_stream_iu32(io);
        slot.minPlayers = wn_stream_iu8(io);
        slot.maxPlayers = wn_stream_iu8(io);
        slot.playerCount = wn_stream_iu8(io);
        slot.currentPlayer = wn_stream_iu8(io);
        slot.player = wn_stream_iu8(io);
        slot.playerChallengeState = wn_stream_iu8(io);
        slot.slotCloseState = (OFMultiplayer::enumSlotCloseState) wn_stream_iu8(io);
        slot.state = (OFMultiplayer::enumGameState) wn_stream_iu8(io);
                
        slot.playerOFUserIds = [[NSMutableArray alloc] initWithCapacity: slot.maxPlayers];
        slot.playerRanks = [[NSMutableArray alloc] initWithCapacity:slot.maxPlayers];
        slot.playerSlotCloseStates = [[NSMutableArray alloc] initWithCapacity:slot.maxPlayers];
        slot.playerSlotElapsedTime = [[NSMutableArray alloc] initWithCapacity:slot.maxPlayers];
        
        
        for(u32 i = 0; i < slot.maxPlayers; i++) {
            [slot.playerOFUserIds addObject:[[[NSString alloc] initWithString:@""]  autorelease]];
            [slot.playerRanks addObject:[[[NSNumber alloc] initWithUnsignedInt:0] autorelease]];
            [slot.playerSlotCloseStates addObject:[[[NSNumber alloc] initWithUnsignedInt:OFMultiplayer::SCS_AVAILABLE] autorelease]];
            [slot.playerSlotElapsedTime addObject:[[[NSNumber alloc] initWithUnsignedInt:0] autorelease]];
        }
        
        for(u32 i = 0; i < slot.playerCount; i++) {
            u8 player = wn_stream_iu8(io);
            const char* ofUserId = wn_stream_istr(io);
            u32 rank = wn_stream_iu32(io);
            OFMultiplayer::enumSlotCloseState slotCloseState = (OFMultiplayer::enumSlotCloseState) wn_stream_iu8(io);
            u32 elapsed = wn_stream_iu32(io);
            
            NSString* newString = [[NSString alloc] initWithUTF8String:ofUserId];
            NSNumber* newRank = [[NSNumber alloc] initWithUnsignedInt:rank];
            NSNumber* newSlotCloseState = [[NSNumber alloc] initWithUnsignedInt:slotCloseState];
            NSNumber* newElapsed = [[NSNumber alloc] initWithUnsignedInt:elapsed];
            
            [slot.playerOFUserIds replaceObjectAtIndex:player withObject:newString];
            [slot.playerRanks replaceObjectAtIndex:player withObject:newRank];
            [slot.playerSlotCloseStates replaceObjectAtIndex:player withObject:newSlotCloseState];
            [slot.playerSlotElapsedTime replaceObjectAtIndex:player withObject:newElapsed];
            
            OFLog(@">>>>>>>>>>>player %d elapsed %d", player, elapsed);
                                    
            [newString release];
            [newRank release];
            [newSlotCloseState release];
            [newElapsed release];                        
            
            wn_cstr_free(ofUserId);
        }
        slot.options = [gameResponseSerializer readOptionsFromStream:io];
    }
    
    void forceLogout() {
        mLoginToken = 0;
        mGameCount = 0;
        
        NSEnumerator* enumerator = [[OFMultiplayerService internalGetSlotArray] objectEnumerator];
        OFMultiplayerGame *slot;
        
        while((slot = [enumerator nextObject])) {
            cleanupGameSlot(slot);
        }
        clearRequests();
        
        if([mDelegate respondsToSelector:@selector(didLogoutFromMultiplayerServer)])
            [mDelegate didLogoutFromMultiplayerServer];
    }
    
    OFMultiplayerGame *getActiveSlot() {
        if(mActiveGameSlot < 0) {
            return nil;
        }
        else {
            OFMultiplayerGame *slot = [OFMultiplayerService getSlot:mActiveGameSlot];
            if(slot.gameId) {
                return slot;
            }
            else {
                mActiveGameSlot = -1;
                return nil;
            }
        }
    }
    
    OFMultiplayerGame *getActiveSlotMatchingId(u64 gameId) {
        OFMultiplayerGame* slot=getActiveSlot();
        return  (slot.gameId == gameId) ? slot : nil;
    }
    
    void consumeMove(OFMultiplayerMove* move) {
        if(!mActiveGameMovesRestored && move.number >= mIncomingMoveQueue.finalMove)
            mActiveGameMovesRestored = YES;
        
        switch(move.code) {
            case OFMP_MC_END_TURN:
                mActiveGameCurrentPlayer = move.nextPlayer;
                
                if([mDelegate respondsToSelector:@selector(gameDidAdvanceTurnToPlayerNumber:)])
                    [mDelegate gameDidAdvanceTurnToPlayerNumber:mActiveGameCurrentPlayer];
                
                break;
            default:
                break;
        }        
    }
    
    void addMoveToQueueIn(OFMultiplayerMove* move) {
        if(mIncomingMoveQueue.spaceLeft) {
            if([mDelegate respondsToSelector:@selector(gameMoveReceived:)])
                if([mDelegate gameMoveReceived:move]) {
                    //if using delegates, we need to keep track of this because the number it compares against isn't available yet
                    if (mHighestMoveProcessed < (NSInteger) move.number) {
                        mHighestMoveProcessed = move.number;
                    }
                    consumeMove(move);
                    return;
                }
            [mIncomingMoveQueue.moves addObject:move];
        }
    }
        
    void randomSeed(u32 seed) {
        mRandomValueVar = seed;
    }
    
    wn_stream_t* openOutputBufferStream() {
        wn_stream_t* io = &mBufferStream;
        wn_stream_mfile_open(io, mBufferData, WEBNET_BUFFER_DATA_SIZE, PFSM_WRITE, true);
        return io;
    }
    
    wn_stream_t* openInputBufferStream(const void* data, u32 size) {
        wn_stream_t* io = &mBufferStream;
        wn_stream_mfile_open(io, data, size, PFSM_READ, false);
        return io;
    }
    
    wn_stream_t* openRequest() {
        wn_stream_t* io = openOutputBufferStream();
        wn_stream_ou16(io, OFMP_COMM_VERSION);
        return io;
    }
    
    wn_stream_t* openResponse(const void* data, u32 size, ofmp_response_t& response) {
        if(size < 5) {  // response should be at least 1 byte + 4 byte checksum
            response = OFMP_RS_SERVER_RETURNED_NULL;
            return NULL;
        }
        else {
            wn_stream_t* io = openInputBufferStream(data, size);
            
            response = (ofmp_response_t) wn_stream_iu8(io);
            mUpdateRateGetGames = wn_stream_iu8(io);
            mUpdateRateGetMoves = wn_stream_iu8(io);
            
            if(response == OFMP_RS_OK) {
                return io;
            }
            else {
                ofmp_dprintf("Recieved bad response: %d\n", response);
                if(response == OFMP_RS_SERVER_OFFLINE) {
                    [mDelegate networkFailureWithReason:OFMultiplayer::NETWORK_FAILURE_SERVER_OFFLINE];
                }
                
                if(response == OFMP_RS_SESSION_EXPIRED) {
                    // Force the user to login again by invalidating the login token.
                    forceLogout();
                }
                
                return NULL;
            }
        }
    }
    
    
    
    void cleanUpGameSlotBeforeRead(OFMultiplayerGame*slot, bool doCleanup)
    {
        slot.previousValues = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:slot.gameId], @"gameId",
                               [NSNumber numberWithInt:slot.state], @"state",
                                slot.playerSlotCloseStates, @"closeStates",
                                nil];
                               
        OFMultiplayer::enumClientGameSlotState state = slot.clientGameSlotState;
        if(doCleanup && state != OFMultiplayer::CGSS_CREATING_GAME && state != OFMultiplayer::CGSS_FINDING_GAME 
           && state != OFMultiplayer::CGSS_FINDING_OR_CREATING_GAME && state != OFMultiplayer::CGSS_SENDING_CHALLENGE_RESPONSE) {
            cleanupGameSlot(slot);
            slot.clientGameSlotState = state;
        }
    }
    
    void fillGameSlot(OFMultiplayerGame*slot, wn_stream_t*io) {
        OFMultiplayer::enumClientGameSlotState state;
        state = slot.clientGameSlotState;
        
        readGameSlotFromStream(slot, io);
        
        if([[slot.previousValues objectForKey:@"gameId"] longLongValue] != (long long)slot.gameId) {
            if(slot.waitingForRematch) {
                if(mDelegate) {
                    if(slot.gameId && [slot isStarted]) {
                        if([mDelegate respondsToSelector:@selector(rematchAccepted:)])
                            [mDelegate rematchAccepted:slot];
                    }
                    else {
                        if([mDelegate respondsToSelector:@selector(rematchRejected:)])
                            [mDelegate rematchRejected:slot];
                    }
                }
                
                slot.waitingForRematch = false;
            }
            /*
             //this code will now fire during play, if we need this functionality then we must add a flag
             //of some sort so that getMovesResponse doesn't call this
             if(mActiveGameSlot == slot.gameSlot) {
             //TODO: game switched during play?   Can this really happen?
             [OFMultiplayerService internalLeaveGame];
             if(slot.gameId) {
             [OFMultiplayerService internalEnterGame:slot];
             }
             }*/
        }
        
        if(state == OFMultiplayer::CGSS_CANCELLING_GAME || state == OFMultiplayer::CGSS_CLOSING_GAME 
           || state == OFMultiplayer::CGSS_REQUESTING_REMATCH || state == OFMultiplayer::CGSS_SENDING_CHALLENGE_RESPONSE) {
            slot.clientGameSlotState = state;
        }
        
    }
    
    void callDelegatesForSlot(OFMultiplayerGame*slot) {
        if(mDelegate) {
            // Call delegates based on game slot changes.
            long long lastGameId = [[slot.previousValues objectForKey:@"gameId"] longLongValue];
            if(!slot.gameId && lastGameId) {
                if([mDelegate respondsToSelector:@selector(gameSlotDidBecomeEmpty:)])
                    [mDelegate gameSlotDidBecomeEmpty:slot];
            }
            else if(slot.gameId && !lastGameId) {
                if([mDelegate respondsToSelector:@selector(gameSlotDidBecomeActive:)])
                    [mDelegate gameSlotDidBecomeActive:slot];
            }
            
            if(slot.gameId) {
                int lastState = [[slot.previousValues objectForKey:@"state"] intValue];
                // Call delegates based on game state changes.
                if(lastState != OFMultiplayer::GS_PLAYING && slot.state == OFMultiplayer::GS_PLAYING) {
                    if([mDelegate respondsToSelector:@selector(gameDidStart:)])
                        [mDelegate gameDidStart:slot];
                }
                else if(lastState != OFMultiplayer::GS_FINISHED && slot.state == OFMultiplayer::GS_FINISHED) {
                    if([mDelegate respondsToSelector:@selector(gameDidFinish:)])
                        [mDelegate gameDidFinish:slot];
                }
                
                // Call delegates based on player slot close state changes.
                NSArray *lastPlayerSlotCloseStates = [slot.previousValues objectForKey:@"playerSlotCloseStates"];
                if(lastPlayerSlotCloseStates && slot.playerSlotCloseStates) {
                    for(u32 i = 0; i < slot.maxPlayers; i++) {
                        OFMultiplayer::enumSlotCloseState oldState = (OFMultiplayer::enumSlotCloseState) ([(NSNumber*)[lastPlayerSlotCloseStates objectAtIndex:i] unsignedIntValue]);
                        OFMultiplayer::enumSlotCloseState newState = (OFMultiplayer::enumSlotCloseState) ([(NSNumber*)[slot.playerSlotCloseStates objectAtIndex:i] unsignedIntValue]);
                        
                        if(oldState == OFMultiplayer::SCS_AVAILABLE && newState == OFMultiplayer::SCS_CLOSED) {
                            if([mDelegate respondsToSelector:@selector(playerLeftGame:)])
                                [mDelegate playerLeftGame:i];
                        }
                    }
                }
            }
        }
        
        slot.previousValues = nil;
        if(!slot.gameId && slot.waitingForRematch) {
            if([mDelegate respondsToSelector:@selector(rematchRejected:)])
                [mDelegate rematchRejected:slot];
        }
        
        slot.waitingForRematch = [slot hasRequestedRematch];
    }
    
    void readCurrentGameUpdates(OFMultiplayerGame*slot, wn_stream_t*io) {
        OFMultiplayer::enumGameState oldState = slot.state;
        //read in the ranks
        slot.state = (OFMultiplayer::enumGameState) wn_stream_iu8(io);
        if(slot.state == OFMultiplayer::GS_FINISHED) {
            unsigned char count=wn_stream_iu8(io);
            for(int i=0; i<count; ++i) {
                unsigned int rank = wn_stream_iu32(io);
                NSNumber* newRank = [[[NSNumber alloc] initWithUnsignedInt:rank] autorelease];
                [slot.playerRanks replaceObjectAtIndex:i withObject:newRank];		
            }
        }
        if(oldState != OFMultiplayer::GS_PLAYING && slot.state == OFMultiplayer::GS_PLAYING) {
            if([mDelegate respondsToSelector:@selector(gameDidStart:)])
                [mDelegate gameDidStart:slot];
        }
        else if(oldState != OFMultiplayer::GS_FINISHED && slot.state == OFMultiplayer::GS_FINISHED) {
            if([mDelegate respondsToSelector:@selector(gameDidFinish:)])
                [mDelegate gameDidFinish:slot];
        }
        
    }
}

namespace  {
    wn_webnet_request_status_t loginResponse(const unsigned char* data, u32 size) {
        ofmp_response_t response;
        wn_stream_t* io = openResponse(data, size, response);
        
        ofmp_dprintf("Recieved response for: OFMP_RQ_LOGIN\n");
        
        mLoginInProcess = false;
        
        if(!io) {
            ofmp_dprintf("Response is INVALID.\n");
            return PFWRS_ACCEPT;
        }
        else {
            [OFMultiplayerService internalResetMoveQueue];
            mLoginToken = wn_stream_iu32(io);
            wn_stream_close(io);
            
            ofmp_dprintf("User logged in successfully with token 0x%X\n", mLoginToken);
            
            if([mDelegate respondsToSelector:@selector(didLoginToMultiplayerServer)])
                [mDelegate didLoginToMultiplayerServer];
        }
        
        return PFWRS_ACCEPT;
    }
    
    wn_webnet_request_status_t getGamesResponse(const unsigned char* data, u32 size) {
        ofmp_response_t response;
        wn_stream_t* io = openResponse(data, size, response);
        
        ofmp_dprintf("Recieved response for: OFMP_RQ_GET_GAMES\n");
        
        mActiveGameGetGamesSent = false;
        
        if(!io) {
            ofmp_dprintf("Response is INVALID.\n");
            return PFWRS_ACCEPT;
        }
        else {
            u16 count = wn_stream_iu16(io);    
            mGameCount = count;
            [mChallenges removeAllObjects];
            ofmp_dprintf("There are currently %d games active.\n", mGameCount);
            
            for(u32 i = 0; i < mSlotArraySize; i++) {
                cleanUpGameSlotBeforeRead([mSlotArray objectAtIndex:i], TRUE);
            }
            
            for(u32 i = 0; i < count; i++) {
                u8 gameSlot = wn_stream_iu8(io);
                OFMultiplayerGame*game;
                if(gameSlot == WN_WEBNET_CHALLENGE_SLOT) 
                {
                    game = [[[OFMultiplayerGame alloc] init] autorelease];
                    game.gameSlot = WN_WEBNET_CHALLENGE_SLOT;
                    [mChallenges addObject:game];
                }
                else {
                    wn_assert(gameSlot < mSlotArraySize, "Invalid game slot.");
                    game = [mSlotArray objectAtIndex:gameSlot];
                }
                fillGameSlot(game,io);
            }
            
            for(u32 i = 0; i < mSlotArraySize; i++) {
                //This needs to do all the slots so it catches things like the other player cancelling
                callDelegatesForSlot([mSlotArray objectAtIndex:i]);
            }
            wn_stream_close(io);
        }    
        
        if(mLaunchingGameSlot != -1) {
            if([mDelegate respondsToSelector:@selector(gameLaunchedFromPushRequest:withOptions:)]) {
                OFMultiplayerGame *launchGame = [mSlotArray objectAtIndex:mLaunchingGameSlot];
                [mDelegate gameLaunchedFromPushRequest:launchGame withOptions:mLaunchingGameOptions];
            }
            [mLaunchingGameOptions release];
            mLaunchingGameOptions = nil;
            mLaunchingGameSlot = -1;
        }
        
        
        if([mDelegate respondsToSelector:@selector(networkDidUpdateLobby)])
            [mDelegate networkDidUpdateLobby];
        return PFWRS_ACCEPT;
    }
    
    wn_webnet_request_status_t sendMovesResponse(const unsigned char* data, u32 size) {
        ofmp_response_t response;
        wn_stream_t* io = openResponse(data, size, response);
        
        ofmp_dprintf("Recieved response for: OFMP_RQ_SEND_MOVE\n");
        
        mOutgoingMoveQueue.movesSent = NO;
        
        NSUInteger removedMoves = 0;
        if(!io) {
            ofmp_dprintf("Response is INVALID.\n");
//            return PFWRS_ACCEPT;
        }
        else {
            OFMultiplayerGame* slot = getActiveSlotMatchingId(wn_stream_iu64(io));
            if(slot) {
                u16 moveCount;
                u16 newSerial;
                
                moveCount = wn_stream_iu16(io);
                newSerial = wn_stream_iu16(io);
                readCurrentGameUpdates(slot, io);
                removedMoves = [mOutgoingMoveQueue clearMovesBeforeSerial:newSerial]; 
                OFLog(@"Response removed %d moves (up to %d)", removedMoves, newSerial);
                wn_stream_close(io);
                
                if(![mOutgoingMoveQueue.moves count]) {
                    if([mDelegate respondsToSelector:@selector(allOutgoingGameMovesSent)])
                        [mDelegate allOutgoingGameMovesSent];
                }
            }
        }
        
        if(response == OFMP_RS_OK) mOutgoingMoveQueue.processFailureCount = 0;
        else {
            if(++mOutgoingMoveQueue.processFailureCount >= 3) {
                if([mDelegate respondsToSelector:@selector(outgoingMovesFailed:)])
                    [mDelegate outgoingMovesFailed:response];
                
            }
        }
        
        return PFWRS_ACCEPT;
    }
    
    wn_webnet_request_status_t getMovesResponse(const unsigned char* data, u32 size) {
        ofmp_response_t response;
        wn_stream_t* io = openResponse(data, size, response);
        
        ofmp_dprintf("Recieved response for: OFMP_RQ_GET_MOVES\n");
        
        mIncomingMoveQueue.gettingMoves = NO;
        //TODO: need to handle RESIGN?
//        if(mActiveGameAdvanceTurnSendState == OFMP_ATSS_COMPLETE)
//            mActiveGameAdvanceTurnSendState = OFMP_ATSS_NONE;
        
        //TODO: remove endturn anomalies from the finished
        
        if(!io) {
            ofmp_dprintf("Response is INVALID.\n");
            return PFWRS_ACCEPT;
        }
        else {
            OFMultiplayerGame* slot = getActiveSlotMatchingId(wn_stream_iu64(io));
            if(slot) {
                mHighestMoveProcessed = -1;
                NSArray *oldCloseStates = [NSArray arrayWithArray:slot.playerSlotCloseStates];
                u16 count = wn_stream_iu16(io);
                
                ofmp_dprintf("Received %d move(s) elapsed time is %d.\n", count, slot.elapsedTime);
                NSUInteger newProcessedSerial = mOutgoingMoveQueue.processedSerial;
                
                for(u32 i = 0; i < count; i++) {
                    u16 number;
                    OFMPMoveCode code;
                    u8 player;
                    u16 playerSerial;
                    
                    player = wn_stream_iu8(io);
                    playerSerial = wn_stream_iu16(io);
                    number = wn_stream_iu16(io);
                    code = (OFMPMoveCode) wn_stream_iu8(io);
                    if(player == slot.player && playerSerial >= newProcessedSerial) newProcessedSerial = playerSerial + 1; 
                    
                    ofmp_dprintf("Received move #%d, code %d player %d serial %d.\n", number, code, player, playerSerial);
                    
                    if([mIncomingMoveQueue spaceLeft]) {
                        //                    if([OFMultiplayerService internalIsMoveNumberReadyForQueue:number]) {
                        OFMultiplayerMove* move = [[OFMultiplayerMove alloc] init];
                        
                        move.code = code;
                        move.number = number;
                        move.movePlayer = player;
                        move.movePlayerSerial = playerSerial;
                        
                        switch(code) {
                            case OFMP_MC_DATA: 
                            case OFMP_MC_DATA_ECHO: 
                            {
                                u16 dataSize = wn_stream_iu16(io);
                                void* data = malloc(dataSize);
                                wn_stream_ibytes(io, data, dataSize);
                                move.data = [[[NSData alloc] initWithBytes:data length:dataSize] autorelease];
                                free(data);
                                break;
                            }
                                
                            case OFMP_MC_RESIGN:
                            case OFMP_MC_END_TURN:
                                move.movePlayer = wn_stream_iu8(io); //resigns can be added by the server player, too
                                move.nextPlayer = wn_stream_iu8(io);
                                move.moveReason = wn_stream_iu8(io);
                                break;
                            case OFMP_MC_FINISH_GAME:
                            {
                                int count = wn_stream_iu8(io);
                                NSMutableArray* ranks = [NSMutableArray arrayWithCapacity:count];
                                for(int rank=0;rank<count; ++rank) {
                                    NSUInteger rankValue = wn_stream_iu8(io);
                                    [ranks addObject:[NSNumber numberWithUnsignedChar:rankValue]];
                                }
                                move.finishRanks = [NSArray arrayWithArray:ranks];
                            }
                                break;
                        }
                        if(player == slot.player && playerSerial < mOutgoingMoveQueue.processedSerial && move.code != OFMP_MC_DATA_ECHO) {
                            //this is a move that was added by us between the getMoves request and response
                            //ignore it
                            OFLog(@"Captured spurious echoed move %d (serial %d) processedSerial %d", move.number, move.movePlayerSerial, mOutgoingMoveQueue.processedSerial);
                        }
                        else {
                            addMoveToQueueIn(move);
                        }
                        if(mIncomingMoveQueue.nextMoveToLoad <= move.number) mIncomingMoveQueue.nextMoveToLoad = move.number + 1;
                        [move release];
                    }
                    else {
                        OFLog(@"ERROR: reading in moves that we don't have space to queue?");
                        wn_stream_close(io);
                        mOutgoingMoveQueue.processedSerial = newProcessedSerial;
                        return PFWRS_ACCEPT;      
                    }
                }
                mOutgoingMoveQueue.processedSerial = newProcessedSerial;
                slot.elapsedTime = wn_stream_iu32(io);
                NSUInteger finalMove = wn_stream_iu16(io);
                if(finalMove < mIncomingMoveQueue.finalMove) mIncomingMoveQueue.finalMove = finalMove;
                ofmp_dprintf("Final move to send is %d (based on %d)\n", mIncomingMoveQueue.finalMove, finalMove);
                
                //if using the delegate, you need to track the highest value and check here since the moves are consumed
                //before the finalMove can be determined. 
                if(!mActiveGameMovesRestored && mHighestMoveProcessed >= (NSInteger) finalMove) {
                    mActiveGameMovesRestored = YES;
                }
                mHighestMoveProcessed = -1;

                unsigned char closedPlayers = wn_stream_iu8(io);
                if(closedPlayers > slot.playerSlotCloseStates.count) {
                    OFLog(@"Bad close states read  count(%d) data %@", closedPlayers, [NSData dataWithBytes:data length:size]);
                    NSData* ns_data  = [NSData dataWithBytes:data length:size];
                    NSString* userDocumentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];        
                    NSString* path = [userDocumentsPath stringByAppendingPathComponent:@"crashdata.txt"];
                    [ns_data writeToFile:path atomically:YES];
                }
                
                
                for(unsigned int i=0; i<closedPlayers; ++i) {
                    OFMultiplayer::enumSlotCloseState state = (OFMultiplayer::enumSlotCloseState) wn_stream_iu8(io);
                    //TODO: if the closedPlayers has more people due to drop-ins....
                    [slot.playerSlotCloseStates replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedInt:state]];
                    if([[oldCloseStates objectAtIndex:i] unsignedIntValue] == OFMultiplayer::SCS_AVAILABLE && state == OFMultiplayer::SCS_CLOSED) {
                        if([mDelegate respondsToSelector:@selector(playerLeftGame:)])
                            [mDelegate playerLeftGame:i];
                    }
                    
                    [slot.playerSlotElapsedTime replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedInt:wn_stream_iu32(io)]];
                    OFLog(@">>>>>>>>>>player %d time %d", i, [[slot.playerSlotElapsedTime objectAtIndex:i] unsignedIntValue]);
                }
                readCurrentGameUpdates(slot, io);
                wn_stream_close(io);
            }
        }
        
        return PFWRS_ACCEPT;
    }
    
    
    wn_webnet_request_status_t anomalyResponse(const unsigned char* data, u32 size) {
        ofmp_response_t response;
        wn_stream_t* io = openResponse(data, size, response);
        
        ofmp_dprintf("Recieved response for: OFMP_RQ_ANOMALY\n");
        
        if(!io) {
            ofmp_dprintf("Response is INVALID.\n");
            return PFWRS_ACCEPT;
        }
        else {
            OFMultiplayerGame* slot = getActiveSlotMatchingId(wn_stream_iu64(io));
            if(slot) {
                NSUInteger count = wn_stream_iu8(io);
                for(unsigned int i=0; i<count; ++i) {
                    NSNumber* index = [NSNumber numberWithUnsignedChar:wn_stream_iu8(io)];
                    OFMPAnomaly* anomaly = [mAnomalyProcessor.inProcess objectForKey:index];
                    [mAnomalyProcessor.finished setObject:anomaly forKey:index];
                    [mAnomalyProcessor.inProcess removeObjectForKey:index];
                }
                wn_stream_close(io);
            }
        }
        
        return PFWRS_ACCEPT;
    }
}

