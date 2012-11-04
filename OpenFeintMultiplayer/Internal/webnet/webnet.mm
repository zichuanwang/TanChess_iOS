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

#import "webnet.h"
#import <UIKit/UIKit.h>

#include <stdio.h>
#include "base64.h"
#include "stream.h"
#include "ofmp.h"
#import "OFMultiplayer.h"
#import "OFMultiplayerService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFSettings.h"

@class OFMPNetRequest;
namespace {
    OFMPNet* sOFMPNetInstance = nil;
}
@interface OFMPNet()

@property (nonatomic, retain) NSMutableSet *pendingRequests; //pending the creation of the master URL
@property (nonatomic, retain) NSMutableSet *activeRequests;
@property (nonatomic, retain) OFMPNetMasterURLLoader* loader;
@property (nonatomic, retain) NSString* masterUrl;
@property (nonatomic, retain) NSURL* serverUrl;    
-(void) removeRequest:(OFMPNetRequest*) req;
@end

@interface OFMPNetRequest : NSObject
{
@private
    BOOL cancelled;
    NSUInteger code;
    NSUInteger retryCount;
    NSMutableData* receivedData;
    wn_webnet_request_cb_t callback;
    NSMutableURLRequest* request;
}
@property (nonatomic) BOOL cancelled;
@property (nonatomic) NSUInteger code;
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic) wn_webnet_request_cb_t callback;
@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) NSMutableURLRequest* request;

-(id) initWithBytes:(void*) bytes size:(NSUInteger) size callback:(wn_webnet_request_cb_t) callback;
-(BOOL) startConnection;
-(void) cancel;
-(void) doCallbackWithSuccess:(BOOL) success;

@end

@interface OFMPNetMasterURLLoader : NSObject
{
@private
    NSMutableData* receivedData;
    NSUInteger code;
    NSUInteger retryCount;
}
@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic) NSUInteger code;
@property (nonatomic) NSUInteger retryCount;

-(BOOL) startConnection;
@end

@implementation OFMPNetMasterURLLoader
@synthesize receivedData, code, retryCount;

-(id)init {
    if((self = [super init])) {
        self.retryCount = 0;
        if(![self startConnection]) {
            [self autorelease];
            return nil;
        }
    }
    return self;
}

-(void)dealloc {
    self.receivedData = nil;
    self.code = nil;
    self.retryCount = nil;
    [super dealloc];
}

-(BOOL) startConnection {    
    self.retryCount++;
    if(self.retryCount > 3) {
        OFLog(@"OFMPNet: Failed to find master URL Server");
        [OFMultiplayerService internalSignalNetworkFailure:OFMultiplayer::NETWORK_FAILURE_NO_MASTER];
        return NO;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sOFMPNetInstance.masterUrl]];
    [req setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"x-application-bundle"];
    [req setValue:OFMP_API_VERSION forHTTPHeaderField:@"x-application-version"];
    [req setValue:[OpenFeint clientApplicationId]  forHTTPHeaderField:@"x-application-ofid"];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if(conn) {
        [conn release];
        self.receivedData = [NSMutableData data];
        return YES;
    }
    OFLog(@"OFMPNet: Failed to create request for connection, will try again");
    [self performSelector:@selector(startConnection) withObject:nil afterDelay:3.0];
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    self.code = httpResponse.statusCode;
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data {
    [self.receivedData appendData:_data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self performSelector:@selector(startConnection) withObject:nil afterDelay:3.0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //set the serverUrl and begin any pending requests
    if(self.code == 200) {
        NSString* urlString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
        if([urlString rangeOfString:@"http" options:NSCaseInsensitiveSearch].location == NSNotFound) {
            [OFMultiplayerService internalSignalNetworkFailure:OFMultiplayer::NETWORK_FAILURE_BAD_API_VERSION_FOR_SERVER];
            return; //nothing can be done
        }
            
        sOFMPNetInstance.serverUrl = [NSURL URLWithString:urlString];
        [urlString release];
        sOFMPNetInstance.activeRequests = [NSMutableSet setWithSet:sOFMPNetInstance.pendingRequests];
        [sOFMPNetInstance.pendingRequests removeAllObjects];
        for(OFMPNetRequest *req in sOFMPNetInstance.activeRequests) {
            [req.request setURL:sOFMPNetInstance.serverUrl];
            [req startConnection];
        }
    }
    else {
        [self performSelector:@selector(startConnection) withObject:nil afterDelay:3.0];
    }
}


@end

@implementation OFMPNet
@synthesize pendingRequests, activeRequests, masterUrl, serverUrl, loader;
+(void)createWithMasterURL:(NSString*) _masterUrl {
    wn_base64_init();
    wn_stream_crc32_init();
    sOFMPNetInstance = [OFMPNet new];
    sOFMPNetInstance.masterUrl = _masterUrl;    
    sOFMPNetInstance.pendingRequests = [NSMutableSet setWithCapacity:5];
    sOFMPNetInstance.activeRequests = nil;
}
+(void) destroy {
    for(OFMPNetRequest* req in sOFMPNetInstance.activeRequests) {
        [req cancel];
    }
    [sOFMPNetInstance release];
    sOFMPNetInstance = nil;
}
+(BOOL)requestWithBytes:(void*) bytes size:(NSUInteger) size callback:(wn_webnet_request_cb_t) callback {
    OFMPNetRequest* request = [[OFMPNetRequest alloc ]initWithBytes: bytes size:size callback:callback];
    if(sOFMPNetInstance.serverUrl) {
        [sOFMPNetInstance.activeRequests addObject:request];
        [request startConnection];
    }
    else {
        [sOFMPNetInstance.pendingRequests addObject:request];
        sOFMPNetInstance.loader = [[[OFMPNetMasterURLLoader alloc] init] autorelease];
    }
    return YES;
}

+(void)cancelRequestsForCallback:(wn_webnet_request_cb_t) callback {
    NSSet *pendingCopy = [NSSet setWithSet:sOFMPNetInstance.pendingRequests];
    for(OFMPNetRequest *req in pendingCopy)        
        if(req.callback == callback) [sOFMPNetInstance.pendingRequests removeObject:req];
    for(OFMPNetRequest *req in sOFMPNetInstance.activeRequests)
        if(req.callback == callback) [req cancel];
}

-(void) removeRequest:(OFMPNetRequest*) req {
    [self.pendingRequests removeObject:req];
    [self.activeRequests removeObject:req];
}

-(void)dealloc {
    self.masterUrl = nil;
    self.serverUrl = nil;
    self.pendingRequests = nil;
    self.activeRequests = nil;
    self.loader = nil;
    [super dealloc];
}

@end

@implementation OFMPNetRequest
@synthesize cancelled, code, receivedData,callback, retryCount, request;
-(id)initWithBytes:(void*) bytes size:(NSUInteger) size callback:(wn_webnet_request_cb_t) _callback {
    if((self = [super init])) {
        self.cancelled = NO;
        self.callback = _callback;
        self.retryCount = 0;
        
        NSData* data = [NSData dataWithBytes:bytes length:size];
        NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:sOFMPNetInstance.serverUrl 
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:3.0];
        [req setHTTPBody:data];
        [req setHTTPMethod:@"POST"];
        [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        [req setValue:@"binary" forHTTPHeaderField:@"Content-Transfer-Encoding"];
        NSString *backdoor = OFSettings::Instance()->getSetting(@"multiplayer-backdoor");
        if(backdoor)
            [req setValue:backdoor  forHTTPHeaderField:@"x-lockout-override"];
        self.request = [req copy];
    }
    return self;
}

-(void)dealloc {
    self.receivedData = nil;
    self.request = nil;
    [super dealloc];
}


-(BOOL) startConnection {    
    self.retryCount++;
    if(self.retryCount > 3) {
        OFLog(@"OFMPNet: Multiple resend failures, server not responding?");
        [OFMultiplayerService internalSignalNetworkFailure:OFMultiplayer::NETWORK_FAILURE_RESENDING_FAILED];
        return NO;
    }
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    if(conn) {
        [conn release];
        self.receivedData = [NSMutableData data];
        return YES;
    }
    OFLog(@"OFMPNet: Failed to create request for connection, will try again");
    [self performSelector:@selector(startConnection) withObject:nil afterDelay:3.0];
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    self.code = httpResponse.statusCode;
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data {
    [self.receivedData appendData:_data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self doCallbackWithSuccess:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(self.cancelled) return;
    [self doCallbackWithSuccess:self.code == 200];
}

-(void)cancel {
    self.cancelled = YES;
}

-(void) doCallbackWithSuccess:(BOOL) success {
    if(success) {
        if(self.cancelled) {
            [sOFMPNetInstance removeRequest:self];
            return;
        }
        self.callback((const unsigned char*)[self.receivedData bytes], [self.receivedData length]);
    }
    else {
        if(self.callback(nil, 0) == PFWRS_RESEND)
            [self startConnection];
        else {
            [sOFMPNetInstance removeRequest:self];
        }
    }
}

@end
