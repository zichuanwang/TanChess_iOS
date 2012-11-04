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

//For future use:  right now, this value is simply a string.  This may be expanded to a resource Id in the future
//The strings used until then should start with a letter and not the prefix "OF" which is reserved.
typedef NSString OFMPGameDefinitionId;


/**
 *  @mainpage OpenFeint Turn-Based Multiplayer
 *          
 *  Copyright 2010 Aurora Feint, Inc.
 * 
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *  	http://www.apache.org/licenses/LICENSE-2.0
 *  	
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *      
 *
 *
 *      <h2> Sample Applications</h2>
 *    The OFMP distribution contains two samples showing different ways it can be used
 *      - Battleship - a functional game, shows simultaneous turns, configuration, and anomaly processing
 *      - MPSample - an older sample designed to show various advanced functions such as multi-slot lobbies,
 *                  push notifications, delay moves, and rematches.
 *    
 *    To use these, you will need to copy the App directory from a distribution of OpenFeint 2.6 or later.
 *    The application will need to get a key and secret by registering at http://api.openfeint.com. 
 *
 *
 *      <h2> New features</h2>
 *  Version 1.1.2 adds the following features since the last public release (1.1)
 *  - presence checking: playerSlotElapsedGame will return an array which tells the # of seconds since a given user 
 *      did any action which touched the server for this game.   This can be used to detect dropouts.
 *  - LOBBY_OPTION_FIRST_PLAYER: in a non-simultaneous game, you can now specify who moves first.  
 *
 *
 */


/**
Public definitions that are used by the OpenFeint Multiplayer system
This header must be included or imported before any other OFMultiplayer headers
 */
///A namespace for all public enumerations and lobby keys
namespace OFMultiplayer {
    
    ///The reason the server should accept an anomaly.  A parameter type for [OFMultiplayerService force___] methods
    enum {
        ANOMALY_REASON_SELF=0,///<you can always make an anomaly on yourself, note that this is not usually used
        ANOMALY_REASON_TIME_OUT=1,///<not yet implemented, but will allow you to force timeouts to change player
        ANOMALY_REASON_CLOSED=2 ///<the target player is closed, the server will verify before adding
    };    
    
    ///Slot close states can be queried via OFMultiplayerGame.slotCloseState to determine if a rematch is desired
    typedef enum {
        SCS_AVAILABLE = 0,///<this slot is not closed
        SCS_CLOSED = 1,///<this slot has been closed by the player
        SCS_REMATCH = 2,///<this slot was closed, but a rematch was requested
    } enumSlotCloseState;
    
    ///Game states can be queried via OFMultiplayerGame.state
    typedef enum {
        GS_UNKNOWN = 0,  ///<usually indicates no game
        GS_WAITING_TO_START = 1, ///<a gam has been created, but does not have sufficient players
        GS_PLAYING = 2, ///<game is in progree
        GS_FINISHED = 3, ///<game has ended,finish ranks may be available
    } enumGameState;

    ///The current lobby function for this slot, query using OFMultiplayerGame.clientGameSlotState
    typedef enum {
        CGSS_NONE = 0,  ///<slot is not in use
        CGSS_CREATING_GAME = 1, ///<slot contains a network game that has not started
        CGSS_FINDING_GAME = 2, ///<slot is searching for a game each network update
        CGSS_FINDING_OR_CREATING_GAME = 3, ///<slot will try to find a game, if not will create one
        CGSS_CANCELLING_GAME = 4, ///<slot will cancel the game, this is done before it starts and deletes the game
        CGSS_CLOSING_GAME = 5, ///<slot will close the game, removing this player from the list
        CGSS_REQUESTING_REMATCH = 6, ///<slot has a finished game and request for another game has been made
        CGSS_SENDING_CHALLENGE_RESPONSE = 7, ///<slot is a challenge and a response will be sent
    } enumClientGameSlotState;
    
    ///the return type for networkFailureWithReason
    typedef enum {
        NETWORK_FAILURE_NO_MASTER,  ///<indicates the Master URL is not valid
        NETWORK_FAILURE_RESENDING_FAILED,  ///<this is not currently used
        NETWORK_FAILURE_BAD_API_VERSION_FOR_SERVER,  ///<your API version is not recognized by the server
        NETWORK_FAILURE_SERVER_OFFLINE  ///<the server has been taken offline, possibly for updates
    } enumNetworkFailureReason;
    
    ///(NSString*) Holds the game configuration.  This string can be used for any purpose
    extern const NSString* LOBBY_OPTION_CONFIG;  
    ///(NSString*) For games that were created with challenged players, this will hold the OpenFeint ID of the challenger
    extern const NSString* LOBBY_OPTION_CHALLENGER_OF_ID;   
    ///(NSArray* of NSString*) OpenFeint Ids of players to challenge. They will receive the challenge in the first open slot
    extern const NSString* LOBBY_OPTION_CHALLENGE_OF_IDS;   
    ///player counts are not enabled at this time,so this should not be used yet
    extern const NSString* LOBBY_OPTION_MIN_PLAYERS;
    ///player counts are not enabled at this time,so this should not be used yet
    extern const NSString* LOBBY_OPTION_MAX_PLAYERS;
    ///(NSNumber with Int) Maximum turn time desired in seconds
    extern const NSString* LOBBY_OPTION_TURN_TIME;     
    ///(NSArray* of NSNumber* with Ints) When searching for games, only allow those with one of these turn times
    extern const NSString* LOBBY_OPTION_TURN_TIME_FIND_FILTER; 
    ///(Flag) If defined, the game will allow both players to move at once
    extern const NSString* LOBBY_OPTION_SIMULTANEOUS_TURN;  
    ///(NSNumber with Unsigned Char) The number of the first player, defaults to player zero.
    extern const NSString* LOBBY_OPTION_FIRST_PLAYER;
};
