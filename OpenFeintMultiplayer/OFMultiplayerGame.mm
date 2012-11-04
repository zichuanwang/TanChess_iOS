////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright 2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#import "OFMultiplayer.h"
#import "OFMultiplayerGame.h"
#import "OFMultiplayerService.h"

const NSString* OFMultiplayer::LOBBY_OPTION_CONFIG = @"config";
const NSString* OFMultiplayer::LOBBY_OPTION_CHALLENGER_OF_ID = @"challengerOFUserId";
const NSString* OFMultiplayer::LOBBY_OPTION_CHALLENGE_OF_IDS = @"challengeOFUserIds";
const NSString* OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS = @"minPlayers";
const NSString* OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS = @"maxPlayers";
const NSString* OFMultiplayer::LOBBY_OPTION_TURN_TIME = @"turnTime";
const NSString* OFMultiplayer::LOBBY_OPTION_TURN_TIME_FIND_FILTER = @"turnTimeFilter";
const NSString* OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN = @"simultaneous";
const NSString* OFMultiplayer::LOBBY_OPTION_FIRST_PLAYER = @"firstPlayer";

///private interface - for some reason Doxygen wants a line here
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

@implementation OFMultiplayerGame

@synthesize gameId,
rseed,
startDateInSec,
gameDefinitionId,
turnTime,
elapsedTime,
moveCount,
playerCount,
currentPlayer,
player,
playerChallengeState,
gameSlot,
slotCloseState,
state,
playerOFUserIds,
playerRanks,
playerSlotCloseStates,
playerSlotElapsedTime,

clientGameSlotState,
currentPlayerClosed,
acceptChallenge,
waitingForRematch,

previousValues;

#pragma mark Options and accessors
@synthesize options;
@dynamic minPlayers;
@dynamic maxPlayers;
@dynamic challengerOFUserId;

-(unsigned char) maxPlayers {
    NSNumber*value = [self.options objectForKey:OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS];
    return value ? [value charValue] : maxPlayers;
}

-(void) setMaxPlayers:(unsigned char) max {
    maxPlayers = max;
}

-(unsigned char) minPlayers {
    NSNumber*value = [self.options objectForKey:OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS];
    return value ? [value charValue] : minPlayers;
}

-(void) setMinPlayers:(unsigned char) min {
    minPlayers = min;
}

-(NSString*) challengerOFUserId {
    return [self.options objectForKey:OFMultiplayer::LOBBY_OPTION_CHALLENGER_OF_ID];
}

#pragma mark Original interface
-(BOOL) isActive {
	return self.gameId != 0;	
}
-(BOOL) isStarted {
	return self.gameId && self.state > OFMultiplayer::GS_WAITING_TO_START;
}

-(BOOL) isFinished {
	return self.gameId && self.state == OFMultiplayer::GS_FINISHED;
}

-(BOOL) hasCurrentPlayerLeftGame {
    //TODO: handle RESIGNS
    return self.currentPlayerClosed;
//	return [OFMultiplayerService internalIsAdvancingTurn] ? false : self.currentPlayerClosed;
}

-(BOOL) hasBeenChallenged {
	return self.gameId && self.state == OFMultiplayer::GS_WAITING_TO_START && self.challengerOFUserId && self.player;
}

-(BOOL) hasRequestedRematch {
	return self.gameId && self.slotCloseState == OFMultiplayer::SCS_REMATCH;
}

-(unsigned int) getRankWithPlayerNumber:(unsigned int)playerNumber {
	if(self.gameId && self.playerRanks)
	{
		if(playerNumber < [self.playerRanks count]) {
			NSNumber* rank = [ self.playerRanks objectAtIndex:playerNumber];
			if(rank) 
				return [rank unsignedIntValue];
		}
	}
	return 0;
}


-(NSString*) getOFUserIdWithPlayerNumber:(unsigned int)playerNumber {
	if(self.gameId && self.playerOFUserIds)
		if(playerNumber < [self.playerOFUserIds count]) {
			NSString* ofUserId = [self.playerOFUserIds objectAtIndex:playerNumber];
			if(ofUserId && [ofUserId length])
				return ofUserId;
		}
	return nil;
}

-(void)requestRematch {
	if(self.gameId)
		self.clientGameSlotState = OFMultiplayer::CGSS_REQUESTING_REMATCH;
}

-(unsigned int)getPlayerNumberAfterPlayerNumber:(unsigned int)playerNumber {
	return self.playerCount ? (playerNumber + 1) % self.playerCount : 0;
}

-(unsigned int)getNextPlayerNumber {
	return [self getPlayerNumberAfterPlayerNumber:[OFMultiplayerService internalGetActiveGameCurrentPlayer]];
}

-(unsigned int)getTurnTime {
	return (self.gameId && self.state == OFMultiplayer::GS_PLAYING) ? self.turnTime : 0;
}

-(unsigned int)getElapsedTime {
	return (self.gameId && self.state == OFMultiplayer::GS_PLAYING) ? self.elapsedTime : 0;
}

-(BOOL)isTurnPlayerOutOfTime {
	return (self.gameId && self.state == OFMultiplayer::GS_PLAYING) ? self.turnTime > self.elapsedTime : false;
}

-(BOOL)isItMyTurn {
    if (self.state != OFMultiplayer::GS_PLAYING) return false;
    return self.currentPlayer == self.player || [self.options objectForKey:OFMultiplayer::LOBBY_OPTION_SIMULTANEOUS_TURN];
}

-(void) cancelGame {
	if(self.gameId)
		self.clientGameSlotState = OFMultiplayer::CGSS_CANCELLING_GAME;
    else if(self.clientGameSlotState == OFMultiplayer::CGSS_FINDING_GAME)
        self.clientGameSlotState = OFMultiplayer::CGSS_NONE;
}

-(void) closeGame {
	if(self.gameId)
		self.clientGameSlotState = OFMultiplayer::CGSS_CLOSING_GAME;
}

- (void) sendMove:(NSData*)data {
	[OFMultiplayerService internalSendMove:data
								  withCode:OFMP_MC_DATA
							withNextPlayer:0];
	
}

- (void) sendMoveWithDelay:(NSData*)data {
	[OFMultiplayerService internalSendMove:data
								  withCode:OFMP_MC_DATA_ECHO
							withNextPlayer:0];
	
}

- (void) sendEndTurn {
	[OFMultiplayerService internalSendMove:nil
								  withCode:OFMP_MC_END_TURN
							withNextPlayer: [self getNextPlayerNumber]];
	
}

- (void) resign {
	[OFMultiplayerService internalSendMove:nil
								  withCode:OFMP_MC_RESIGN
							withNextPlayer: [self getNextPlayerNumber]];
	
}


-(void) sendEndTurnWithPushNotification:(NSString*)pushNotification {
	[OFMultiplayerService internalSendMove:nil
								  withCode:OFMP_MC_END_TURN
                      withPushNotification: pushNotification
							withNextPlayer: [self getNextPlayerNumber]];
    
}

-(void) sendFinishGameWithPlayerRanks:(NSArray *)ranks {
    [OFMultiplayerService internalSendFinishGameTurnWithPlayerRanks:ranks];
}

-(void) dealloc {
	[playerOFUserIds release];
	[playerRanks release];
	[playerSlotCloseStates release];	
    [playerSlotElapsedTime release];
    [options release];
	
	[super dealloc];
}


-(void) createGame:(NSString *)aGameDefinitionId
       withOptions:(NSDictionary*)lobbyOptions {
    [OFMultiplayerService internalSetLobbyType:OFMultiplayer::CGSS_CREATING_GAME 
                            withGameDefinition:aGameDefinitionId 
                                   withOptions:lobbyOptions 
                                       forGame:self];
}

-(void) findGame:(NSString *)aGameDefinitionId
     withOptions:(NSDictionary*)lobbyOptions {
    [OFMultiplayerService internalSetLobbyType:OFMultiplayer::CGSS_FINDING_GAME 
                            withGameDefinition:aGameDefinitionId 
                                   withOptions:lobbyOptions 
                                       forGame:self];
}

-(void) findOrCreateGame:(NSString *)aGameDefinitionId 
             withOptions:(NSDictionary*)lobbyOptions {
    [OFMultiplayerService internalSetLobbyType:OFMultiplayer::CGSS_FINDING_OR_CREATING_GAME 
                            withGameDefinition:aGameDefinitionId 
                                   withOptions:lobbyOptions 
                                       forGame:self];
}

- (void) sendChallengeResponseWithAccept:(bool)accept {
	[OFMultiplayerService internalSendChallengeResponseForGame:self withAccept:accept];
}


@end
