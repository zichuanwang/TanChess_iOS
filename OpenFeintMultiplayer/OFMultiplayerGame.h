///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
/**
    This class is the main means of communication between the client's game state and the server.  
 The lobby functions all work by defining an object of class OFMultiplayerGame for each slot.  If not using
 multislot lobby, then there is a single OFMultiplayerGame object used.
 
    If a game says that it is valid for you to send moves, then you can update the server game state using
 send___ functions.
 */
///Represents a games connection to the network.

#import "OFMultiplayer.h"

@interface OFMultiplayerGame : NSObject {
@private    
	unsigned long long gameId;
	unsigned int rseed;
	unsigned int startDateInSec;
	NSString* gameDefinitionId;
	unsigned int turnTime;
	unsigned int elapsedTime;
	unsigned int moveCount;
	unsigned char playerCount;
	unsigned char currentPlayer;
	unsigned char player;
	unsigned char playerChallengeState;
	unsigned char gameSlot;
    unsigned char minPlayers;
    unsigned char maxPlayers;
	
    OFMultiplayer::enumSlotCloseState slotCloseState;
    OFMultiplayer::enumGameState state;
	NSMutableArray* playerOFUserIds;
	NSMutableArray* playerRanks;
	NSMutableArray* playerSlotCloseStates;
    NSMutableArray* playerSlotElapsedTime;
	
    OFMultiplayer::enumClientGameSlotState clientGameSlotState;
	char currentPlayerClosed;
	BOOL acceptChallenge;
	BOOL waitingForRematch;
	    
    NSMutableDictionary* options;	
    NSDictionary*previousValues;
}
#pragma mark Property declarations
///The current game's network Id
@property (nonatomic, readonly) unsigned long long gameId;
///A random seed generated at game start by the server, can be used as you wish
@property (nonatomic, readonly) unsigned int rseed;
///The game's starting date
@property (nonatomic, readonly) unsigned int startDateInSec;
///A string defined in the lobby functions, should start with a letter and not start with "OF"
@property (nonatomic, readonly, retain) NSString *gameDefinitionId;
///The maximum length of time that was configured.
@property (nonatomic, readonly) unsigned int turnTime;
///The amounf of time since the last player change, meaningless for simultaneous turn games
@property (nonatomic, readonly) unsigned int elapsedTime;
///The total number of moves made in this game
@property (nonatomic, readonly) unsigned int moveCount;
///The number of players in this game, including those who have closed
@property (nonatomic, readonly) unsigned char playerCount;
///The player who is currently active, meaningless for simultaneous turn games
@property (nonatomic, readonly) unsigned char currentPlayer;
///The player's personal number for this game
@property (nonatomic, readonly) unsigned char player;
///For answering challenges, this holds the current state
@property (nonatomic, readonly) unsigned char playerChallengeState;
///The lobby slot assoiciated with this game, or 0 if not using multislot lobby
@property (nonatomic, readonly) unsigned char gameSlot;

///At present, only two player games are allowed
@property (nonatomic, readonly) unsigned char minPlayers;
///Not in use, currently only two player games are valid.
@property (nonatomic, readonly) unsigned char maxPlayers;
///The OpenFeint ID of the person who issued the challenge.  You can use OFUserService to get more information
@property (nonatomic, readonly) NSString *challengerOFUserId;

///Used to keep track of rematch requests
@property (nonatomic, readonly) OFMultiplayer::enumSlotCloseState slotCloseState;
///The general state of a given game, waiting, active or finished
@property (nonatomic, readonly) OFMultiplayer::enumGameState state;
///A list of the OpenFeint Ids in the game, use OFUserService to get more info
@property (nonatomic, readonly, retain) NSMutableArray* playerOFUserIds;
///For a finished game, the rank given for each player
@property (nonatomic, readonly, retain) NSMutableArray* playerRanks;
///Tells whether a given player has left the game
@property (nonatomic, readonly, retain) NSMutableArray* playerSlotCloseStates;
///Tells how long in seconds it's been since this player did a getMove, sendMove or sendAnomaly, used for presence
@property (nonatomic, readonly, retain) NSMutableArray* playerSlotElapsedTime;

///The overall state, including lobby functions
@property (nonatomic, readonly) OFMultiplayer::enumClientGameSlotState clientGameSlotState;
///True if the current player has left the game, in which case you'll need to create an Anomaly to continue
@property (nonatomic, readonly) char currentPlayerClosed;
///If you used sendChallengeResponseWithAccept, this holds the answer until the network can process it
@property (nonatomic, readonly) BOOL acceptChallenge;
///True if it is still waiting for players to accept a rematch
@property (nonatomic, readonly) BOOL waitingForRematch;

///Internal: do not use
@property (nonatomic, readonly, retain) NSDictionary* previousValues;
///A dictionary of all the options used when creating the game
@property (nonatomic, readonly, retain) NSDictionary* options;

#pragma mark Original Access Functions
/**
 * @brief Returns true when a game is active.  
 *
 *A game is defined active when the main
 * game slot is not empty.  In other words, a game is active when it is in the
 * waiting-to-start state, the playing state, and the finished state (but not yet
 * closed).
 */

-(BOOL) isActive;
/**
 * @brief Returns true when a game has started.  
 *
 * This method also returns true when
 * the game is in a finished state since the game has already started once.
 */

-(BOOL) isStarted;
/**
 * @brief Returns true when the game has finished and player ranks were assigned.
 */

-(BOOL) isFinished;
/**
 *@brief Cancel a game before it starts
 * 
 * When a player creates a game and is waiting for players to join, the game
 * may be cancelled as long as the game has not started.  The game automatically
 * starts when there are enough players.
 */
-(void) cancelGame;
/**
 *@brief Remove yourself from a game
 *
 * Make the current player on this device close the game and leave.  This
 * results in the removal of the player's presence and other players in the game
 * must decide to either declare victory, eliminate this player, or forcefully
 * advance the turn.
 */
-(void) closeGame;
/**
 * @brief True if the game is stalled because the turn player has left.
 *
 * At this time, the game should declare a winner by making a call to finishGameWithPlayerRanks
 * or forcefully advance the turn.
 */
-(BOOL) hasCurrentPlayerLeftGame;
/**
 *@brief True if this game is from a direct challenge.
 *
 * Send a response by calling sendChallengeRepsonse with a true value to accept or
 * false value to reject.
 */
-(BOOL) hasBeenChallenged;
/**
 *@brief True if a player has requested a rematch
 *
 * If the player is waiting too long for a response, the player is free to leave the 
 * game with the closeGame function.
 */
-(BOOL) hasRequestedRematch;
/**
 *@brief Return the rank of the player with the player number.  
 *
 * Returns 0 if the game has not yet finished or the rank was never specified.
 */
-(unsigned int)getRankWithPlayerNumber:(unsigned int)playerNumber;
/**
 * @brief Return the next OpenFeint user id with player number starting from 0.
 */
-(NSString*) getOFUserIdWithPlayerNumber:(unsigned int)playerNumber;
/**
 *@brief Request a rematch with the same players and configuration options
 *
 * Make the current player on this device request a rematch after the current
 * game has finished.  If not all players request a rematch, then the game will
 * be removed instead.
 */
-(void) requestRematch;

/**
 *@brief Send a move to the server.
 * 
 * Only the player on the current player's turn can send moves unless the game is simultaneous turn.
 * Make sure that the move could be sent by calling isReadyToSendMoves and observing
 * a boolean result of true.  If the result is false, then the move should not be
 * sent or else it will be lost and the game simulation will be out-of-sync.
 */
- (void) sendMove:(NSData*)data;

/**
 *@brief Send a move that is always echoed back from the server
 *
 *  All requirements for regular send move must be met
 *  The delay means that this move is not to be processed until it returns from the server.  This will allow you
 *  to inject moves into the stream that will be processed by all players at the same point.   Otherwise, you
 *  need to insure that your moves are safe to move out of order.   
 *
 *  For this reason, the effects of this move should not be applied to the game state until it is returned.
 */
- (void) sendMoveWithDelay:(NSData*)data;

/**
 *@brief end your turn
 *
 * Send the end-turn command.  This is completed on the current player's turn and
 * cannot be successfully completed on another player's turn.  If the game is simultaneous, then
 * any player can send this with the effect of causing the turn timer to reset.
 */
- (void) sendEndTurn;
/**
    @brief Similar to sendEndTurn except you can enter text for any push notifications generated.
 */
- (void) sendEndTurnWithPushNotification:(NSString*)pushNotificationMessage;


/**
 * @brief Sends a move that ends the game, setting the ranks according to the input array and updating player stats
 *
 *  If the game has already ended, this will have no effect
 */
- (void) sendFinishGameWithPlayerRanks:(NSArray*)ranks;

/**
 * @brief Sends a resign command.   
 *
 * If this command is accepted, no further moves will be accepted by the server
 * Essentially, it means you are out of the game.
 */
-(void) resign;
/**
    @brief A helper function which gets the next player assuming you are using numerical order
 */
-(unsigned int) getPlayerNumberAfterPlayerNumber:(unsigned int)playerNumber;
/**
    @brief Returns the next player, assuming regular turn order
 */
-(unsigned int) getNextPlayerNumber;
/**
    @deprecated Returns the time allowed for a move. Should use turnTime property instead
 */
-(unsigned int) getTurnTime DEPRECATED_ATTRIBUTE;
/**
 @deprecated Returns the elapsed time for this turn. Should use elapsedTime property instead
 */
-(unsigned int) getElapsedTime DEPRECATED_ATTRIBUTE;
/**
 @brief Returns True if the elapsed time exceeds the turn time.
 */
-(BOOL) isTurnPlayerOutOfTime;
/**
 @brief Returns True if you are allowed to make moves.
 */
-(BOOL) isItMyTurn;

#pragma mark Lobby Functions
/*! @name Lobby Functions
    These enable the creation of new games and joining on games on the network
 @{
 */
/**
    @brief create a new game
 
    The lobby functions all take in a dictionary of options, the keys were defined as above.
 An example of creating a 3 player, simultaneous game with a config of "AA", would look like
    [game createGame:@"GAMEDEFID" withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                              @"AA", LOBBY_OPTION_CONFIG,
                                                [NSNumber numberWithInt:3], LOBBY_OPTION_MIN_PLAYERS,
                                                [NSNumber numberWithInt:3], LOBBY_OPTION_MIN_PLAYERS,
                                                NSNull, LOBBY_OPTION_SIMULTANEOUS_TURN]];
 
 */
-(void) createGame:(NSString *)aGameDefinitionId
       withOptions:(NSDictionary*)lobbyOptions;
/**
 @brief search for an existing game
 
    See createGame for a description of the options parameter.
    The slot will continue to search for any game which matches the criteria until you cancel or it
 finds a valid game.
    
 */
-(void) findGame:(NSString *)aGameDefinitionId
     withOptions:(NSDictionary*)lobbyOptions;

/**
 @brief search for an existing game, if not found then create a new one
 
 See createGame for a description of the options parameter.
 The next network update will try to match the given find options.  If nothing matches, then a game
 will be created and will immediately be available for others to find.
 
 */
-(void) findOrCreateGame:(NSString *)aGameDefinitionId 
             withOptions:(NSDictionary*)lobbyOptions;



/**
 *@brief Respond to a challenge.
 *
 * A true value means the challenge is accepted and the game will begin if all players have
 * accepted.  To see if this player has been challenged, call the function
 * hasBeenChallenged.  A response must be given in order to continue playing
 * or to find new games.
 */

- (void) sendChallengeResponseWithAccept:(bool)accept;
/*@}*/

@end
