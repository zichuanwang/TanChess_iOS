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

#import "OFMultiplayerMove.h"
@interface OFMultiplayerMove () 
@property (nonatomic, readwrite) unsigned int number; //the order of the move in the entire game
@property (nonatomic, readwrite) unsigned int nextPlayer; //the next player if this is an end turn move
@property (nonatomic, readwrite) unsigned int movePlayer; //the player who made this move
@property (nonatomic, readwrite) unsigned int movePlayerSerial; //the order of this player's moves
@property (nonatomic, readwrite) unsigned int moveReason; //the reason for an end turn or resign
@property (nonatomic, readwrite) OFMPMoveCode code; //the OFMPMoveCode
@property (nonatomic, readwrite, retain) NSData* data; //a data block for DATA and DATA_ECHO types
@property (nonatomic, readwrite, retain) NSArray* finishRanks; 
@end

@implementation OFMultiplayerMove

@synthesize number;
@synthesize nextPlayer;
@synthesize code;
@synthesize data;
@synthesize movePlayer;
@synthesize movePlayerSerial;
@synthesize moveReason;
@synthesize finishRanks;

- (bool) isStandard {
    return code == OFMP_MC_DATA || code == OFMP_MC_DATA_ECHO;
}

- (bool) isEndTurn {
    return code == code == OFMP_MC_END_TURN;
}

-(bool) isResign {
    return code == OFMP_MC_RESIGN;
}

- (void) dealloc {
    [data release];
    [super dealloc];
}

@end