////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
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
#import "OFMultiplayerAddOn.h"

#import "OFMultiplayerService+Private.h"
#import "OpenFeint+AddOns.h"
#import "OFSettings.h"

@implementation OFMultiplayerAddOn

OPENFEINT_AUTOREGISTER_ADDON

+ (void)initializeAddOn:(NSDictionary*)settings
{
	[OFMultiplayerService initializeService];
//	[OFMPGameDefinitionService initializeService];
}

+ (void)shutdownAddOn
{
	[OFMultiplayerService shutdownService];
//	[OFMPGameDefinitionService shutdownService];
}

+ (BOOL)respondToPushNotification:(NSDictionary*)notificationInfo duringApplicationLaunch:(BOOL)duringApplicationLaunch
{
	BOOL willRespond = [OFMultiplayerService notificationIsMultiplayer:notificationInfo];
	
	if (willRespond)
	{
		[OFMultiplayerService internalProcessPushNotification:notificationInfo fromLaunch:duringApplicationLaunch];
	}
	
	return willRespond;
}

+ (void)defaultSettings:(OFSettings*)settings {
#ifdef _DISTRIBUTION
    settings->setDefault(@"multiplayer-server-url", @"http://mp.openfeint.com/");
#else    
    settings->setDefault(@"multiplayer-server-url", @"http://mp-sandbox.openfeint.com/");
    OFLog(@"***********************************************************************************");
    OFLog(@"WARNING: using the OpenFeint Multiplayer sandbox server.   This server should not be used for release.");
    OFLog(@"To switch to release server make sure to #define _DISTRIBUTION before submitting to Apple");
    OFLog(@"The sandbox server is prone to untested modifications and may cause games to be lost or crash");
    OFLog(@"***********************************************************************************");
#endif
}

+ (void)loadSettings:(OFSettings*)settings fromReader:(OFXmlReader&) reader {
    settings->loadSetting(reader, "multiplayer-server-url");
    settings->loadSetting(reader, "multiplayer-backdoor");
}


+ (void)userLoggedIn
{
	[OFMultiplayerService internalStartProcessing];
}

+ (void)userLoggedOut
{
	[OFMultiplayerService internalStopProcessing];
}

@end
