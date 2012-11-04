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

#import "OFMPSerializer.h"
#import "stream.h"

@implementation OFMPSerializer
@synthesize data;

-(id) initWithData:(NSMutableData*) _data {
    if((self = [super init])) {
        data = _data;
        pos = 0;
        crc32 = 0;
    }
    return self;
}

-(void) dealloc {
    data = nil;
    [super dealloc];
}

+(OFMPSerializer*) serializerWithData:(NSData*) data {
    return [[[self alloc] initWithData:data] autorelease];
}

+(OFMPSerializer*) serializerWithSize:(NSUInteger) size {
    return [self serializerWithData:[NSMutableData dataWithLength:size]];
}
+(OFMPSerializer*) serializerFromBytes:(const void*) bytes size:(NSUInteger) size {
    return [self serializerWithData:[NSMutableData dataWithBytes:bytes length:size]];
}


#define implementSizedRead(T, capT)\
-(T) read##capT {\
    NSAssert(pos + sizeof(T) < [data length], @"Read past input buffer");\
    T buffer;\
    [data getBytes:&buffer range:NSMakeRange(pos, sizeof(T))];\
    pos += sizeof(T);\
    return buffer;\
}
                                
implementSizedRead(u16, U16)
implementSizedRead(u32, U32)
implementSizedRead(u8, U8)
implementSizedRead(u64, U64)

-(NSString*) readStr {
    u16 size = [self readU16];
    if(!size) return nil;
    NSAssert(pos + size < [data length], @"Read past input buffer");\
    NSString* str = [[[NSString alloc] initWithBytes:(const char*)[data bytes] + pos length:size encoding:NSUTF8StringEncoding] autorelease];
    pos += size;
    return str;
}

#define implementSizedWrite(T, capT)\
-(void) write##capT:(T) value {\
    NSAssert(pos + sizeof(T) < [data length], @"Write past end of buffer");\
    [data replaceBytesInRange:NSMakeRange(pos, sizeof(T)) withBytes:&value];\
    crc32 = wn_stream_crc32_check(&value, sizeof(T), crc32);\
    pos += sizeof(T);\
}
//TODO: add crc32 checking

implementSizedWrite(u64, U64)
implementSizedWrite(u32, U32)
implementSizedWrite(u16, U16)
implementSizedWrite(u8, U8)

-(void) writeStr:(NSString*) value {
    //string length is NOT the UTF8 length!
    const char* asUTF8 = value.UTF8String;
    NSUInteger size = strlen(asUTF8);    
    
    NSAssert(pos + 2 + size < [data length], @"Write past end of buffer");
    NSAssert(size < 65536, @"Strings are limited to 16 bits (65535)");
    [self writeU16:size];
    [data replaceBytesInRange:NSMakeRange(pos, size) withBytes:asUTF8];
    pos += size;
}

-(BOOL) testCRC32 {
    //TODO: implement
    return YES;
}

-(void) writeCRC32 {
    [self writeU32:crc32];
}

+(void) tests {
    const char* stringBytes = "THIS IS A TEST STRING\xf0\x9d\x84\x9e"; //that's a UTF8 G-clef at the end, \u1d11e and thus not in the BMP (lower 16 bit Unicode region)
    NSString* inStr = [NSString stringWithCString:stringBytes encoding:NSUTF8StringEncoding];
    u32 in32 = 0xababcdcd;
    u32 in8 = 0x55;
    u32 in16 = 0x3456;
    u64 in64 = 0x123456789abcdefLL;
    
    OFMPSerializer* test1 = [self serializerWithSize:100];
    [test1 writeU32:in32];
    [test1 writeU8:in8];
    [test1 writeU16:in16];
    [test1 writeU64:in64];
    [test1 writeStr:inStr];
    [test1 writeCRC32];
    
    OFMPSerializer* test2 = [self serializerFromBytes:test1.data.bytes size:test1.data.length];
    NSAssert([test2 readU32] == in32, @"Test fail");
    NSAssert([test2 readU8] == in8, @"Test fail");
    NSAssert([test2 readU16] == in16, @"Test fail");
    NSAssert([test2 readU64] == in64, @"Test fail");
    NSString *readStr = [test2 readStr];
    
    NSAssert([readStr isEqualToString:inStr], @"Test fails");
}
@end
