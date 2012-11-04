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
#import "OFMultiplayerInputResponse.h"
#import "OFMultiplayerService+Private.h"


@implementation OFMultiplayerInputResponse
@synthesize notificationData;

-(id)initWithDictionary:(NSDictionary*)params {
    self = [super init];
    if(self) {
        self.notificationData = params;
    }
    return self;
}

-(void)dealloc {
    [notificationData release];
    [super dealloc];
}

+(OFNotificationInputResponse*) responseWithDictionary:(NSDictionary*)params {
    return [[OFMultiplayerInputResponse alloc] initWithDictionary:params];
}

-(void)respondToInput {
    [OFMultiplayerService handleInputResponseFromPushNotification:notificationData];
}
@end
