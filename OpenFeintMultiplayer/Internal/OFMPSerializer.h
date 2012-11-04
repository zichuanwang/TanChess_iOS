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
#import "webnet_sys.h"
//handles conversion of data to and from the network
@interface OFMPSerializer : NSObject {
    NSMutableData* data;
    NSUInteger pos;    
    NSUInteger crc32;
}

@property (nonatomic, retain) NSMutableData* data;
+(OFMPSerializer*) serializerWithSize:(NSUInteger) size;
+(OFMPSerializer*) serializerFromBytes:(const void*) bytes size:(NSUInteger) size;



-(u64) readU64;
-(u32) readU32;
-(u16) readU16;
-(u8) readU8;
-(NSString*) readStr;
-(BOOL) testCRC32;

-(void) writeU64:(u64) value;
-(void) writeU32:(u32) value;
-(void) writeU16:(u16) value;
-(void) writeU8:(u8) value;
-(void) writeStr:(NSString*) value;
-(void) writeCRC32;

+(void) tests;
@end
