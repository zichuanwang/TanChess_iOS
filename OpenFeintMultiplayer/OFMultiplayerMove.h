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
/*
    These are generally created by calling one of the send functions in OFMultiplayerGame
    
 */
typedef enum {
	OFMP_MC_DATA = 0,    //sendMove
    //1,2 are retired types
    OFMP_MC_DATA_ECHO = 3,  //sendMoveWithDelay - this is a move that should be processed on receiving, not sending
    OFMP_MC_RESIGN = 4, //player is dead, no more moves accepted
    OFMP_MC_END_TURN = 5,
    OFMP_MC_FINISH_GAME = 6, 
} OFMPMoveCode;

/**
    An OFMultiplayerMove encapsulates a specific change to the current game state.  When a game is entered using
 the [OFMultiplayerService enterGame] or [OFMultiplayer enterGame:] methods, the moves will all be returned in order
 from the server.   You must then process each of these moves until the system has signalled that all moves have
 been received.   Moves can contain arbitrary data, change the current player, cause a player to resign, or
 end the game.  
 
    Anomalies are special moves that may be entered by any player.  This is for handling cases like player
 dropout.  These are checked by the server if they are valid, and if so are created as moves made by a special player = 255
 
*/
///Represents a specific change to the game state
@interface OFMultiplayerMove : NSObject
{
@private
    unsigned int number;   
    unsigned int nextPlayer;  
    unsigned int movePlayer;
    unsigned int movePlayerSerial;  
    unsigned int moveReason;
    NSArray* finishRanks;
    OFMPMoveCode code;
    NSData* data;
}

///the serial of the move for all players combined
@property (nonatomic, readonly) unsigned int number; 
///the next player if this is an end turn move
@property (nonatomic, readonly) unsigned int nextPlayer; 
///the player who made this move, or the server player (255) for anomaly moves
@property (nonatomic, readonly) unsigned int movePlayer; 
///the serial of this move for this player only
@property (nonatomic, readonly) unsigned int movePlayerSerial; 
///for EndTurn and Resign anomaly moves, the reason it was entered
@property (nonatomic, readonly) unsigned int moveReason; 
///the OFMPMoveCode, basically the type of move
@property (nonatomic, readonly) OFMPMoveCode code; 
///a data block for DATA and DATA_ECHO types, up to 16k of data will be accepted
@property (nonatomic, readonly, retain) NSData* data; 
///only sensible for FINISH_GAME moves
@property (nonatomic, readonly, retain) NSArray* finishRanks; 

///True if a data move
@property (nonatomic, readonly) bool isStandard;  
///True if an end turn move
@property (nonatomic, readonly) bool isEndTurn;   
///True if a resign move
@property (nonatomic, readonly) bool isResign;   

@end