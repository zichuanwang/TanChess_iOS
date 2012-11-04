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

#ifndef _WN_WEBNET_H
#define _WN_WEBNET_H

#include "webnet_sys.h"

#define WN_WEBNET_CHALLENGE_SLOT 255

typedef enum {
  PFWRS_ACCEPT=0,
  PFWRS_RESEND,
} wn_webnet_request_status_t;

typedef wn_webnet_request_status_t (*wn_webnet_request_cb_t)(const u8*, u32);
@class OFMPNetMasterURLLoader;
@interface OFMPNet : NSObject
{
@private
    NSMutableSet *pendingRequests; //pending the creation of the master URL
    NSMutableSet* activeRequests;
    OFMPNetMasterURLLoader* loader;
    NSString* masterUrl;
    NSURL* serverUrl;    
}

+(void)createWithMasterURL:(NSString*) masterUrl;
+(void)destroy;
+(BOOL)requestWithBytes:(void*) bytes size:(NSUInteger) size callback:(wn_webnet_request_cb_t) callback;
+(void)cancelRequestsForCallback:(wn_webnet_request_cb_t) callback;

@end

#endif  // _WN_WEBNET_H
