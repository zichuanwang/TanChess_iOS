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

#import "OFMultiplayerService+Private.h"
#import "OFMultiplayerDelegate.h"

@class OFMultiplayerGame;

/**
    The basic interface to the multiplayer networking system.
 */
///Represents the multiplayer networking system
@interface OFMultiplayerService (Public)

#pragma mark Basic functionality
/*
    Should be set to an object with protocol OFMultiplayerDelegate    
 */
///Must be called with the delegate before any multiplayer methods are called
+ (void) setDelegate:(id<OFMultiplayerDelegate>)delegate;
///Clear the delegate.  Call as part of shutdown
+ (void) unsetDelegate:(id<OFMultiplayerDelegate>)delegate;



///Call this to begin searching for games on the network
+ (void) startViewingGames;
/// Call this to stop searching for games on the network
+ (void) stopViewingGames;
///Tells you if you are currently viewing games
+ (bool) isViewingGames;

#pragma mark Active game processing
/*! @name Active game processing
    These affect the state of the currently playing game (from enterGame or enterGame:)
 @{
 */

/**
 * @brief Returns true when the current turn belongs to the player on this device.
 *
 * For simultaneous games, will return true as long as the current game is valid
 */
+ (bool) isItMyTurn;

/**
 * @brief True if the player can send moves.
 *
 * Returns true when moves can be sent.  If false, the game simulation should
 * not proceed with the move locally, and the game should possibly display a
 * loading icon until this method returns true.
 */
+ (bool) isReadyToSendMoves;

/**
 *@brief True if the system is sending moves.   Do not exit while this is true.
 *
 * Returns true if there are outgoing moves that have not yet been sent
 * If this is true, then you should not exit an existing game or those moves will be lost
 */
+(bool) isSendingMoves;

/**
 *@brief Enter into the game, not for use with multislot lobby
 *
 * tells the networking layer to switch to the game and start sending/receiving moves
 * If using the lobby functions, then use Advanced method enterGame: instead
 */
+(void) enterGame;

/**
 *@brief Exits sending/receiving moves for this game.
 *
 * tells the networking system to stop sending/receiving moves for this game
 * the player is still considered to be in the game, so this allows temporary exits
 
 */
+(void) leaveGame;
/**
 *@brief Force the ending of a player's turn
 *
 *   These functions handle the adding of "Anomalies".  These are requests for the server
 * to add moves to the game state.   The server will check if the reason is valid for that player.
 * The only currently working reason is ANOMALY_REASON_CLOSED
 */

+(void) forceEndTurnForPlayer:(NSUInteger) player reason:(NSUInteger) reason;
/**
 *@brief Force a player out of the game
 *
 *   These functions handle the adding of "Anomalies".  These are requests for the server
 * to add moves to the game state.   The server will check if the reason is valid for that player.
 * The only currently working reason is ANOMALY_REASON_CLOSED
 */
+(void) forceResignationForPlayer:(NSUInteger) player reason:(NSUInteger) reason;

/**
 *@brief End the game
 *
 * End the current game and assign ranks to players.  The array's indices map
 * to the player numbers starting from 0.  The values of the ranks are up to the
 * developer and should be unsigned integers wrapped in NSNumber objects.
 */
+ (void) finishGameWithPlayerRanks:(NSArray*)playerRanks;

/**
 *@brief Get the next downloaded move
 *
 * If the result is nil, then there were no moves  readily available.  Either the player has 
 * not yet made a move or the device still has yet to download moves.  Use either this or
 * the delegate method gameMoveReceived to read moves from the server.
 */
+ (OFMultiplayerMove*) getNextMove;
/*@}*/

/**
 *@brief OFMultiplayerGame when not using multislot lobby.
 *
 * If not using the lobby functions, this will refer to a single OFMultiplayerGame instance
 * If lobby functions are desired, then you need to use the Advanced method getSlot instead
 */
+(OFMultiplayerGame*) getGame;


@end