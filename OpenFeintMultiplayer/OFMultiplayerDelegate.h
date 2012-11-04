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

#pragma once

@class OFMultiplayerMove;
@class OFMultiplayerGame;
/**
    This delegate protocol is used for all communication with the multiplayer system.
 Specifically,it includes:
    Notifications of important lobby events, such as game start, player dropouts, etc.
    Push request notifications
    Networking failures    
 */
///The main protocol for communication with the multiplayer system
@protocol OFMultiplayerDelegate<NSObject>

@optional

/**
 * @brief Called when player was logged-in to multiplayer server.
 */
- (void) didLoginToMultiplayerServer;

/**
 * @brief Called when player was logged-out from multiplayer server.
 */
- (void) didLogoutFromMultiplayerServer;

/**
 * @brief Called when all players accepted the rematch and the new game starts.
 */
- (void) rematchAccepted:(OFMultiplayerGame*)game;

/**
 * @brief Called when some players have not requested a rematch.  
 
 * When this happens, the game is closed automatically for all players.
 */
- (void) rematchRejected:(OFMultiplayerGame*)game;

/**
 * @brief Called when a game slot became empty.
 */
- (void) gameSlotDidBecomeEmpty:(OFMultiplayerGame*)game;

/**
 * @brief Called when a game slot became active.
 */
- (void) gameSlotDidBecomeActive:(OFMultiplayerGame*)game;

/**
 * @brief Called when a game in a game slot started.  
 *
 * Will also be called when a game has already started and the game slot just refreshed from empty to active.
 */
- (void) gameDidStart:(OFMultiplayerGame*)game;

/**
 * @brief Called when a game in a game slot finished.  
 *
 * Will also be called when a game has already finished and the game slot just refreshed from empty to active.
 */
- (void) gameDidFinish:(OFMultiplayerGame*)game;

/**
 * @brief Called when the move currently consumed advanced the player turn.
 */
- (void) gameDidAdvanceTurnToPlayerNumber:(unsigned int)playerNumber;

/**
 * @brief Called when a move was received.  
 *
 * If applying this move to the local game
 * state, then return a YES to let the service know that the move was processed.
 * Use of this function is not encouraged.  Instead, use [OFMultiplayerService getNextMove], because that will
 * allow you to process moves at your own pace, rather than at loading time.
 */
- (BOOL) gameMoveReceived:(OFMultiplayerMove*)move;

/**
 * @brief Called when all outgoing moves have been sent and received and accepted by the server.
 */
- (void) allOutgoingGameMovesSent;

/**
 * @brief Called when the server rejects moves several times in a row
 * by the server.  
 *
 * Either the server cannot be reached or you are out of sync.
 */
- (void) outgoingMovesFailed:(NSUInteger) reponse;

/**
 * @brief Called when a player has left the game by calling the closeGame function.
 */
- (void) playerLeftGame:(unsigned int)playerNumber;

/**
 * @brief Called when the games are updated from the network
 *
 * Used when a non polling interface is desired
 */
- (void) networkDidUpdateLobby;

/**
 * @brief Called if the network receives several failures in a row.  
 *
 * This generally means you should inform the user that the multiplayer services are not available at this time.
 */
-(void) networkFailureWithReason:(NSUInteger) reason;

/**
 *@brief A push notification has launched the application
 *
 * When a push notification launches the game, the game id is read from that notification
 * If you wish the application to launch directly into the game, then execute your play logic here.
 */
-(void) gameLaunchedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options;

/**
 *@brief A push notification arrived while playing
 *
 * If a push notification arrives while playing, it creates a standard notification (which can be overridden in the OFNotificationDelegate)
 * If this standard notification is to respond to input, then define this method to receive that input
 */

-(void) gameRequestedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options;



@end
