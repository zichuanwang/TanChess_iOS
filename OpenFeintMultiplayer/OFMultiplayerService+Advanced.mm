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
#import "OFMultiplayer.h"
#import "OFMultiplayerService.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFMultiplayerService+private.h"
#import "OFMultiplayerGame.h"

@implementation OFMultiplayerService (Advanced)

#pragma mark Webnet Interface Functions
+ (void) createMoveQueueWithOutgoingSize:(unsigned int)outgoingSize withIncomingSize:(unsigned int)incomingSize {
    [OFMultiplayerService internalCreateMoveQueueWithOutgoingSize:outgoingSize withIncomingSize:incomingSize];
}

+(void) setSlotArraySize: (unsigned int) size {
	[OFMultiplayerService internalSetSlotArraySize:size];
}

+ (bool) isLoggedIn {
    return [OFMultiplayerService internalIsLoggedIn];
}

+ (unsigned int) getNonEmptyGameSlotCount {
    return [OFMultiplayerService internalGetNonEmptyGameSlotCount];
}

+ (unsigned int) getActiveGameSlot {
    return [OFMultiplayerService internalGetActiveGameSlot];
}


+ (unsigned int) getSendableMoveCount {
    return [OFMultiplayerService internalGetSendableMoveCount]; 
}


+ (void) sendEndTurnToNextPlayer:(unsigned char)nextPlayer {  
    [OFMultiplayerService internalSendMove:nil
                                  withCode:OFMP_MC_END_TURN
                            withNextPlayer:nextPlayer];
}

+(void)setMasterUrlOverride:(NSString*) url {
    [OFMultiplayerService internalSetMasterUrlOverride:url];
}

+(void)setApplicationIdOverride:(NSString*) appId {
    [OFMultiplayerService internalSetApplicationIdOverride:appId];
}

+ (OFMultiplayerMove*) getNextMove {
    return [OFMultiplayerService internalGetNextMove];
}

+ (unsigned int) randomValue {
    return [OFMultiplayerService internalRandomValue];
}

+ (int) randomRange:(int)low high:(int)high {
    return [OFMultiplayerService internalRandomRange:low high:high];
}

+(unsigned int) getSlotCount {
	return [self internalGetSlotCount];
}

+(OFMultiplayerGame*) getSlot: (unsigned int) slotNumber {
	return [[self internalGetSlotArray] objectAtIndex:slotNumber];
}

+(void) enterGame:(OFMultiplayerGame*)game {
	[OFMultiplayerService internalEnterGame: game];
}

#pragma mark Challenges
//This returns the number of challenges that have not been assigned slots.
//This means that either setChallengeAutoAssign is false or there aren't enough slots
//to handle all the outstanding challenges.   If you are auto-filling, then they will be
//moved to slots when one becomes available.
+(int) getNumberOfChallenges
{
    return [OFMultiplayerService internalGetNumberOfChallenges];
}

//get the game corresponding to an unslotted challenge
//this should be used for information purpose only, as the game will not be able to start
//until it is assigned a slot
+(OFMultiplayerGame*) getChallengeAtIndex:(unsigned int) index
{
    return [OFMultiplayerService internalGetChallengeAtIndex:index];
}
//Defaults to YES.  If this is set, then when you receive a challenge, a slot will automatically
//be chosen in your lobby.    If not, then outstanding challenges can be found using the above functions.
//this is intended for future functionality, and should not be set at this time
+(void) setChallengeAutoAssign:(bool)doAutoAssign
{
    [OFMultiplayerService internalSetChallengeAutoAssign:doAutoAssign];
}


@end