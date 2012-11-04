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

#ifndef _OFMP_CONFIG_H
#define _OFMP_CONFIG_H

////////////////////////////////////////////////////////////////////////////////
// Defines
////////////////////////////////////////////////////////////////////////////////

#define OFMP_COMM_VERSION 3
#define OFMP_API_VERSION @"1.1"

//#define OFMP_MOVE_MAX_PER_REQUEST 256
//#define OFMP_MOVE_MAX_SIZE 64

//#define OFMP_SESSION_MAX_TIME_IN_SECONDS 600
//#define OFMP_SESSION_SHOULD_EXPIRE FALSE

#define OFMP_DEFAULT_UPDATE_RATE_GET_GAMES 5
#define OFMP_DEFAULT_UPDATE_RATE_GET_MOVES 10

////////////////////////////////////////////////////////////////////////////////
// Enums
////////////////////////////////////////////////////////////////////////////////

// Request codes
typedef enum {
  OFMP_RQ_LOGIN = 1,
  OFMP_RQ_GET_GAMES_LEGACY = 2,
  OFMP_RQ_GET_MOVES_LEGACY = 3,
  OFMP_RQ_SEND_MOVE_LEGACY = 4,
//  OFMP_RQ_FINISH_GAME = 5,
//  OFMP_RQ_ADVANCE_TURN = 6,
  OFMP_RQ_LOGOUT = 7,
  OFMP_RQ_GET_GAMES = 8,
  OFMP_RQ_SEND_MOVE = 10,  
  OFMP_RQ_GET_MOVES = 11,
  OFMP_RQ_SEND_ANOMALIES = 12,
} ofmp_request_t;

// Slot action codes
typedef enum {
  OFMP_SLOT_NONE = 0,
  OFMP_SLOT_CREATE_GAME = 1,
  OFMP_SLOT_FIND_GAME = 2,
  OFMP_SLOT_FIND_OR_CREATE_GAME = 3,
  OFMP_SLOT_CLOSE_GAME = 4,
  OFMP_SLOT_REQUEST_REMATCH = 5,
  OFMP_SLOT_CANCEL_GAME = 6,
  OFMP_SLOT_SEND_CHALLENGE_RESPONSE = 7,
} ofmp_slot_action_t;

// Response codes
typedef enum {
  OFMP_RS_OK = 0,
  OFMP_RS_GENERAL_ERROR = 1,
  OFMP_RS_SERVER_OFFLINE = 2,
  OFMP_RS_VERSION_OUT_OF_DATE = 3,
  OFMP_RS_SESSION_EXPIRED = 4,
  OFMP_RS_DATA_ERROR = 5,
  OFMP_RS_INVALID_PLAYER_TURN = 6,
  OFMP_RS_SERVER_RETURNED_NULL = 255,
} ofmp_response_t;

// Challenge states
typedef enum {
  OFMP_CS_NONE = 0,
  OFMP_CS_WAIT_FOR_APPROVAL = 1,
} ofmp_challenge_state_t;

#endif  // _OFMP_CONFIG_H
