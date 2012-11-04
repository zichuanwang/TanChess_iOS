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

#pragma once

#import "OFService.h"
#import "OFMultiplayerMove.h"
#import "OFMultiplayerGame.h"
#import "OFMultiplayerDelegate.h"

@class OFMultiplayerGame;
@class OFMPAnomaly;
@interface OFMultiplayerService : OFService 

OPENFEINT_DECLARE_AS_SERVICE(OFMultiplayerService);
+ (void) internalSetDelegate:(id<OFMultiplayerDelegate>)delegate;
+ (void) internalUnsetDelegate:(id<OFMultiplayerDelegate>)delegate;

+ (void) internalCreateMoveQueueWithOutgoingSize:(unsigned int)outgoingSize withIncomingSize:(unsigned int)incomingSize;

+ (void) internalSetSlotArraySize:(unsigned int) size;
+ (void) internalSetMasterUrlOverride:(NSString*) url;
+ (void) internalSetApplicationIdOverride:(NSString*) url;

+ (void) internalStartProcessing;
+ (void) internalStopProcessing;
+ (void) internalSignalNetworkFailure:(NSUInteger) reason;

+ (bool) internalIsLoggedIn;
+ (bool) internalIsViewingGames;
+ (bool) internalIsItMyTurn;
+ (unsigned int) internalGetNonEmptyGameSlotCount;
+ (int) internalGetActiveGameSlot;
+ (unsigned int) internalGetSendableMoveCount;
+ (NSUInteger) internalMovesToBeSent;

+ (void) internalStartViewingGames;
+ (void) internalStopViewingGames;
+ (void) internalEnterGame:(OFMultiplayerGame*)game;
+ (void) internalLeaveGame;
+ (void) internalFinishGameWithPlayerRanks:(NSArray*)playerRanks;

+ (void) internalLogin:(NSString*)ofAppId withOFUserId:(NSString*)ofUserId withAccessToken:(NSString*)accessToken;
+ (void) internalLogout;

+(void)internalSetLobbyType:(OFMultiplayer::enumClientGameSlotState) clientSlotState
         withGameDefinition:(OFMPGameDefinitionId*)gameDefinitionId
                withOptions:(NSDictionary*) options
                    forGame:(OFMultiplayerGame*)game;

+ (void) internalSendChallengeResponseForGame: (OFMultiplayerGame*)game withAccept:(bool)accept;

+ (bool) internalSendMove:(NSData*)data
  withCode:(OFMPMoveCode)code
  withNextPlayer:(unsigned int)nextPlayer;

+ (bool) internalSendMove:(NSData*)data
                 withCode:(OFMPMoveCode)code
     withPushNotification:(NSString*)pushNotification
           withNextPlayer:(unsigned int)nextPlayer;

+(bool) internalSendFinishGameTurnWithPlayerRanks:(NSArray *)playerRanks;

+ (void) internalAddAnomaly:(OFMPAnomaly*) anomaly;

+ (OFMultiplayerMove*) internalGetNextMove;

+ (unsigned int) internalRandomValue;
+ (int) internalRandomRange:(int)low high:(int)high;

+(NSArray*) internalGetSlotArray;
+(unsigned int) internalGetSlotCount;

+(unsigned int) internalGetActiveGameCurrentPlayer;

+(int) internalGetNumberOfChallenges;
+(OFMultiplayerGame*) internalGetChallengeAtIndex:(unsigned int) index;
+(void) internalSetChallengeAutoAssign:(bool)doAutoAssign;

+(void) handleInputResponseFromPushNotification:(NSDictionary*) notificationData;
+(BOOL) notificationIsMultiplayer:(NSDictionary*)params;
+(void) internalProcessPushNotification:(NSDictionary *)notification fromLaunch:(BOOL) wasLaunched;
@end