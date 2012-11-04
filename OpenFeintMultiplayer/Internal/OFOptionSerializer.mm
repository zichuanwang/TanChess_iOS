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

#import "OFOptionSerializer.h"
#import "stream.h"
#import "cstr.h"

@interface OFOptionSerializerOption : NSObject {
@private
NSUInteger byte;
NSUInteger bit;
NSString* key;
NSUInteger type;
}
-(NSComparisonResult)sortMethod:(OFOptionSerializerOption*) rhs;

@property (nonatomic) NSUInteger byte;
@property (nonatomic) NSUInteger bit;
@property (nonatomic) NSUInteger type;
@property (nonatomic, retain) NSString* key;


@end


@implementation OFOptionSerializerOption
@synthesize bit, byte, key, type;
-(NSComparisonResult)sortMethod:(OFOptionSerializerOption*) rhs {
    if(self.byte != rhs.byte) 
        return self.byte < rhs.byte ? NSOrderedAscending : NSOrderedDescending;    
    else 
        return self.bit < rhs.bit ? NSOrderedAscending : NSOrderedDescending;
}
@end

@interface OFOptionSerializer ()
@property (nonatomic, retain) NSMutableDictionary* options;
-(OFOptionSerializerOption*) getOptionWithByte:(NSUInteger) byte andBit:(NSUInteger) bit;
@end

const static unsigned char maxLength = 4;

@implementation OFOptionSerializer
@synthesize options;
-(id) init {
    self = [super init];
    if (self) {
        self.options = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}
-(void)addOptionKey:(NSString*)key atByte:(NSUInteger) byte atBit:(NSUInteger) bit ofType:(NSUInteger) type {
    OFOptionSerializerOption* newOption = [[OFOptionSerializerOption new] autorelease];
    newOption.key = key;
    newOption.byte = byte;
    newOption.bit = bit;
    newOption.type = type;
    [self.options setObject:newOption forKey:key];
}


-(NSDictionary*)readOptionsFromStream:(wn_stream_t*) stream {
    NSMutableDictionary* output = [NSMutableDictionary dictionaryWithCapacity:5];
    //need to check for each bit in turn, read in that value
    unsigned char inBytes[maxLength];
    char numBytes = 0;
    for(; numBytes < maxLength; ++numBytes) {
        inBytes[(int)numBytes] = wn_stream_iu8(stream);        
        if(!(inBytes[(int)numBytes] & 0x80)) {
            ++numBytes;
            break;
        }
    }
    for(int i=0;i<numBytes;++i) {
        for(int bit=0; bit<7; ++bit) {
            if(inBytes[i] & (1<<bit)) {
                OFOptionSerializerOption* description = [self getOptionWithByte:i andBit:bit];
                switch(description.type) {
                    case OFOptionSerializerTypes::CharString:
                    {
                        const char *cString = wn_stream_istr(stream);
                        if(cString) {  //we can in fact read and write null strings
                            [output setValue:[[[NSString alloc] initWithUTF8String:cString] autorelease] forKey:description.key];
                            wn_cstr_free(cString);
                        }
                    }
                        break;
                    case OFOptionSerializerTypes::U8:
                        [output setValue:[NSNumber numberWithUnsignedChar:wn_stream_iu8(stream)] forKey:description.key];
                        break;
                    case OFOptionSerializerTypes::U32:
                        [output setValue:[NSNumber numberWithUnsignedInt:wn_stream_iu32(stream)] forKey:description.key];
                        break;
                    case OFOptionSerializerTypes::CharStringArray:
                    {
                        char count = wn_stream_iu8(stream);
                        NSMutableArray* outArray = [NSMutableArray arrayWithCapacity:count];
                        for(int i=0; i<count; ++i) {
                            const char *cString = wn_stream_istr(stream);
                            NSAssert(cString, @"CharStringArrays cannot contain null values");
                            [outArray addObject:[[[NSString alloc] initWithUTF8String:cString] autorelease]];
                            wn_cstr_free(cString);
                            
                        }
                        [output setValue:[NSArray arrayWithArray:outArray] forKey:description.key];
                    }
                        break;
                    case OFOptionSerializerTypes::Flag:
                        [output setValue:@"" forKey:description.key];
                        break;
                    case OFOptionSerializerTypes::U32Array:
                    {
                        char count = wn_stream_iu8(stream);
                        NSMutableArray* outArray = [NSMutableArray arrayWithCapacity:count];
                        for(int i=0; i<count; ++i) {
                            [outArray addObject:[NSNumber numberWithUnsignedInt:wn_stream_iu32(stream)]];
                        }
                        [output setValue:[NSArray arrayWithArray:outArray] forKey:description.key];
                    }
                        break;
                    default:
                        NSAssert(0, @"Invalid option serializer type");
                        
                }
            }
        }
    }
    
    
    
    
    return output;
}
-(void)writeOptions:(NSDictionary*)dictionary toStream:(wn_stream_t *) stream {
    unsigned char outBytes[maxLength];  
    memset(outBytes, 0, maxLength);
    char highByte = 0;
    NSMutableArray*optionsToWrite = [NSMutableArray arrayWithCapacity:10];
    for(NSString* key in dictionary) {
        OFOptionSerializerOption* description = [self.options valueForKey:key];
        if(description) {
            [optionsToWrite addObject:description];
            outBytes[description.byte] |= 1<<description.bit;
            if(highByte < (int)description.byte) highByte = description.byte;
        }
        else {
            OFLog(@"Options reader was given unknown option %@", key);
        }
    }
    for(int i=0; i<highByte+1; ++i) {        
        if(highByte > i) {
            outBytes[i] |= 0x80;  //high bit == chaining bit
        }
        wn_stream_ou8(stream, outBytes[i]);
    }        
    
    [optionsToWrite sortUsingSelector:@selector(sortMethod:)];
    for(OFOptionSerializerOption* description in optionsToWrite) {
        id value = [dictionary objectForKey:description.key];
        switch(description.type) {
            case OFOptionSerializerTypes::CharString:
                wn_stream_ostr(stream, [value UTF8String]);
                break;
            case OFOptionSerializerTypes::U8:
                wn_stream_ou8(stream, [value unsignedCharValue]);
                break;
            case OFOptionSerializerTypes::U32:
                wn_stream_ou32(stream, [value unsignedIntValue]);
                break;
            case OFOptionSerializerTypes::CharStringArray:
                wn_stream_ou8(stream, [value count]);
                for(NSString*str in value) {
                    wn_stream_ostr(stream, [str UTF8String]);
                }
                break;
            case OFOptionSerializerTypes::Flag:
                break;
            case OFOptionSerializerTypes::U32Array:
                wn_stream_ou8(stream, [value count]);
                for(NSNumber*val in value) {
                    wn_stream_ou32(stream, [val unsignedIntValue]);
                }
                break;
            default:
                NSAssert(0, @"Unknown type of data for option serializer");
        }
    }
}

-(void)writeBitFieldToStream:(wn_stream_t*) stream {
    unsigned char outBytes[maxLength];  
    memset(outBytes, 0, maxLength);
    char highByte = 0;
    for(NSString* key in self.options) {
        OFOptionSerializerOption* description = [self.options valueForKey:key];
        outBytes[description.byte] |= 1<<description.bit;
        if(highByte < (int)description.byte) highByte = description.byte;
    }
    for(int i=0; i<highByte+1; ++i) {        
        if(highByte > i) {
            outBytes[i] |= 0x80;  //high bit == chaining bit
        }
        wn_stream_ou8(stream, outBytes[i]);
    }            
}


-(OFOptionSerializerOption*) getOptionWithByte:(NSUInteger) byte andBit:(NSUInteger) bit {
    for(NSString *key in self.options) {
        OFOptionSerializerOption* option = [self.options objectForKey:key];
        if(option.byte == byte && option.bit == bit) return option;
    }
    OFLog(@"Options reader does not understand byte %d bit %d", byte, bit);
    return nil;
}

-(void) dealloc {
    self.options = nil;
    [super dealloc];
}

/*
+(void) load {
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    OFLog(@"Running option reader tests");
    [OFOptionSerializer tests];
    [pool release];
}
*/

+(void)tests {
    //stream data
    wn_stream_t inStream;
    wn_stream_t outStream;
    wn_stream_t* istream = &inStream;
    wn_stream_t* ostream = &outStream;
    char streamData[100];
        
    //test option reader
    OFOptionSerializer* testReader = [[OFOptionSerializer new] autorelease];
    [testReader addOptionKey:@"string" atByte:0 atBit:0 ofType:OFOptionSerializerTypes::CharString];
    [testReader addOptionKey:@"uchar" atByte:0 atBit:1 ofType:OFOptionSerializerTypes::U8];
    [testReader addOptionKey:@"uint"  atByte:0 atBit:2 ofType:OFOptionSerializerTypes::U32];
    [testReader addOptionKey:@"uchar1" atByte:1 atBit:3 ofType:OFOptionSerializerTypes::U8];
    [testReader addOptionKey:@"uchar2" atByte:2 atBit:4 ofType:OFOptionSerializerTypes::U8];
    [testReader addOptionKey:@"uchar3" atByte:3 atBit:3 ofType:OFOptionSerializerTypes::U8];
    [testReader addOptionKey:@"ary" atByte:2 atBit:1 ofType:OFOptionSerializerTypes::CharStringArray];
    [testReader addOptionKey:@"ary2" atByte:2 atBit:6 ofType:OFOptionSerializerTypes::U32Array];
    [testReader addOptionKey:@"flag" atByte:1 atBit:1 ofType:OFOptionSerializerTypes::Flag];

    //test declarations
    NSMutableDictionary* outDict;
    NSDictionary* inDict;
    
    
    //test one
    outDict = [NSMutableDictionary dictionaryWithCapacity:4];    
    [outDict setObject:@"CHECKING" forKey:@"string"];
    [outDict setObject:[NSNumber numberWithUnsignedChar:34] forKey:@"uchar"];

    wn_stream_mfile_open(ostream, streamData, 100, PFSM_WRITE, true);
    [testReader writeOptions:outDict toStream:ostream];
    
    wn_stream_mfile_open(istream, streamData, 100, PFSM_READ, true);    
    inDict = [testReader readOptionsFromStream:istream];
    NSAssert([inDict isEqualToDictionary:outDict], @"Dictionaries didn't copy");

    //test2
    [outDict removeAllObjects];
    [outDict setObject:@"THIS IS A STRING" forKey:@"string"];
    [outDict setObject:[NSNumber numberWithUnsignedInt:666] forKey:@"uint"];
    [outDict setObject:[NSNumber numberWithUnsignedChar:57] forKey:@"uchar1"];
    [outDict setObject:[NSNumber numberWithUnsignedChar:2] forKey:@"uchar3"];

    wn_stream_mfile_open(ostream, streamData, 100, PFSM_WRITE, true);
    [testReader writeOptions:outDict toStream:ostream];
    
    wn_stream_mfile_open(istream, streamData, 100, PFSM_READ, true);    
    inDict = [testReader readOptionsFromStream:istream];
    NSAssert([inDict isEqualToDictionary:outDict], @"Test2: Dictionaries didn't copy");

    //test3
    [outDict removeAllObjects];
    [outDict setObject:[NSArray arrayWithObjects:@"A", @"B", @"C", nil] forKey:@"ary"];
    [outDict setObject:[NSNumber numberWithUnsignedInt:12] forKey:@"uint"];
    [outDict setObject:[NSNumber numberWithUnsignedChar:22] forKey:@"uchar3"];
    [outDict setObject:@"" forKey:@"flag"];
    
    wn_stream_mfile_open(ostream, streamData, 100, PFSM_WRITE, true);
    [testReader writeOptions:outDict toStream:ostream];
    
    wn_stream_mfile_open(istream, streamData, 100, PFSM_READ, true);    
    inDict = [testReader readOptionsFromStream:istream];
    NSAssert([inDict isEqualToDictionary:outDict], @"Test3: Dictionaries didn't copy");
    
    //test4
    [outDict removeAllObjects];
    [outDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:34], [NSNumber numberWithUnsignedInt:56], nil] forKey:@"ary2"];
    [outDict setObject:[NSNumber numberWithUnsignedChar:22] forKey:@"uchar2"];
    [outDict setObject:@"" forKey:@"flag"];
    
    wn_stream_mfile_open(ostream, streamData, 100, PFSM_WRITE, true);
    [testReader writeOptions:outDict toStream:ostream];
    
    wn_stream_mfile_open(istream, streamData, 100, PFSM_READ, true);    
    inDict = [testReader readOptionsFromStream:istream];
    NSAssert([inDict isEqualToDictionary:outDict], @"Test4: Dictionaries didn't copy");
    
}

@end
