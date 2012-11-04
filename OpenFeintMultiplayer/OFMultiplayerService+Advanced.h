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
/**
    Multiplayer functionality that isn't required by all games.  
    - Configuration options - queue sizes, custom server, sharing games across apps
    - Randomizer - allows adding chance but with perfect reproducibility
    - Multislot Lobby functionality - allows a player to be in several games at the same time
    - Multiplayer challenges - informs the user of challenges that don't fit in the available games
 */

///Multiplayer service methods for special use
@interface OFMultiplayerService (Advanced)

///    If you want to change the queue size you must call this before you start processing Defaults to 16 outgoing and 256 incoming
+ (void) createMoveQueueWithOutgoingSize:(unsigned int)outgoingSize withIncomingSize:(unsigned int)incomingSize;

///Determine if a player is logged into the server
+ (bool) isLoggedIn;

///Retrieve a random number, note this must be executed the same on all clients
+ (unsigned int) randomValue;
///Retrieve a random number in the specified range, including endpoints
+ (int) randomRange:(int)low high:(int)high;

///Send the end of your turn with a specific next player, allowing non cyclic player order
+ (void) sendEndTurnToNextPlayer:(unsigned int)nextPlayer;
///Tells you the number of moves that can be sent
+ (unsigned int) getSendableMoveCount;

///For custom server setup.  only use this if told to by the OpenFeint team
+(void)setMasterUrlOverride:(NSString*) url;

/**
 *  This allows different applications to play against each other.  For example, you could have a paid and free version of the
 *  same game.    The application Id string can be found by calling applicationId in OpenFeint+UserOptions.h.   Find the application Id
 *  of, for example, the paid version and use that value with this call in the free version.  You should set this immediately after 
 *  initializing OpenFeint.
 */
///Specify the application Id to use for multiplayer use
+(void)setApplicationIdOverride:(NSString*) appId;

#pragma mark Lobby functionality
/*! \name Multislot Lobby 
    Allows the player to participate in several games at the same time.
 */
/* @{*/

/**
 * If you wish to use mulitslot lobby, this must be called before startProcessing.  If you do not call this, the system will
 * default to 1 slot, which basically means to not use multislot lobby.
 */
///Set number of lobby slots desired, default 1
+ (void) setSlotArraySize:(unsigned int) size;
///Tells you how many slots do not have a game
+ (unsigned int) getNonEmptyGameSlotCount;
///Tells how many slots do have a game
+ (unsigned int) getActiveGameSlot;
///Returns total number of slots
+ (unsigned int) getSlotCount;
///Returns the OFMultiplayerGame associated with that slot number
+ (OFMultiplayerGame *) getSlot: (unsigned int) slotNumber;
///tells the networking layer to switch to this game and start sending moves
+(void) enterGame:(OFMultiplayerGame*)game;
/* @}*/
#pragma mark Challenges
/*! \name Challenges 
    Methods to handle incoming challenges when no slots are available
*/
/* @{*/
 /*
 Challenges can be auto-assigned to slots, or returned in a seperate list
  If you use auto-assign, then challenges are added to slots as space permits

  If there isn't enough space or you don't use autoassign, then the challenges are returned in
  a separate list.   Sending an accept for these challenges has the effect of assigning them to a slot
  If no slot is available, the accept will be ignored.
  */
///DO NOT USE.   Intended for future work
+(void) setChallengeAutoAssign:(bool)doAutoAssign;  //for now, do not use this option
/**
    It is possible that people have challenged you when you do not have available slots for that game.
 You must somehow clear those slots before the challenge can be accepted
 */
///Number of challenges that are outstanding
+(int) getNumberOfChallenges;
/**
    This should only be used for information purposes (such as finding the challenger)  Lobby functions
 such as enterGame, acceptChallenge, etc. will not work until the challenge has been assigned a slot.
 */
 
///Get the OFMultiplayerGame associated with a challenge
+(OFMultiplayerGame*) getChallengeAtIndex:(unsigned int) index;
/* @}*/

@end