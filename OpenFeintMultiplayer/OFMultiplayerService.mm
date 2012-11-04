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
#import "OFMultiplayerService.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFMultiplayerService+private.h"
#import "OFMultiplayerGame.h"
#import "OFMPAnomaly.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFMultiplayerService);
@implementation OFMultiplayerService (Public)

OPENFEINT_DEFINE_SERVICE(OFMultiplayerService);

#pragma mark Webnet Interface Functions
+ (void) setDelegate:(id<OFMultiplayerDelegate>)delegate {
  [OFMultiplayerService internalSetDelegate:delegate];
}

+ (void) unsetDelegate:(id<OFMultiplayerDelegate>)delegate {
  [OFMultiplayerService internalUnsetDelegate:delegate];
}


+ (bool) isViewingGames {
	return [OFMultiplayerService internalIsViewingGames];
}

+ (void) startViewingGames {
	[OFMultiplayerService internalStartViewingGames];
}

+ (void) stopViewingGames {
	[OFMultiplayerService internalStopViewingGames];
}


+ (bool) isItMyTurn {
    return [OFMultiplayerService internalIsItMyTurn];
}

+ (bool) isReadyToSendMoves {
    return [OFMultiplayerService internalGetSendableMoveCount] > 0;
}

+(bool) isSendingMoves {
    return [OFMultiplayerService internalMovesToBeSent] > 0;
}

+(void) enterGame {
	[OFMultiplayerService internalEnterGame: [self getGame]];
};

+(void) leaveGame {
	[OFMultiplayerService internalLeaveGame];
}

+(void) forceEndTurnForPlayer:(NSUInteger) player reason:(NSUInteger) reason {
    OFMPAnomaly* anomaly = [[OFMPAnomaly new] autorelease];
    anomaly.action = Anomaly::ACTION_END_TURN;
    anomaly.reason = reason;
    anomaly.player = player;
    [OFMultiplayerService internalAddAnomaly:anomaly];
}
+(void) forceResignationForPlayer:(NSUInteger) player reason:(NSUInteger) reason {
    OFMPAnomaly* anomaly = [[OFMPAnomaly new] autorelease];
    anomaly.action = Anomaly::ACTION_RESIGN;
    anomaly.reason = reason;
    anomaly.player = player;
    [OFMultiplayerService internalAddAnomaly:anomaly];
}


+ (void) finishGameWithPlayerRanks:(NSArray*)playerRanks {
    [OFMultiplayerService internalFinishGameWithPlayerRanks:playerRanks];
}

+ (OFMultiplayerMove*) getNextMove {
    return [OFMultiplayerService internalGetNextMove];
}

+(OFMultiplayerGame*)getGame {
	return [[self internalGetSlotArray] objectAtIndex: 0];
}

@end