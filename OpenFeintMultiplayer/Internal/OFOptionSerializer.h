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

#import <Foundation/Foundation.h>
#import "stream.h"

namespace OFOptionSerializerTypes {
    enum {
        CharString,
        U8,
        U32,
        CharStringArray,
        Flag,
        U32Array,
    };
}

@interface OFOptionSerializer : NSObject {
@private 
    NSMutableDictionary *options;    
}
-(void)addOptionKey:(NSString*)key atByte:(NSUInteger) byte atBit:(NSUInteger) bit ofType:(NSUInteger) type;
-(NSDictionary*)readOptionsFromStream:(wn_stream_t*) stream;
-(void)writeOptions:(NSDictionary*)dictionary toStream:(wn_stream_t *) stream;
-(void)writeBitFieldToStream:(wn_stream_t*) stream;  //writes all the bits that this reader can understand

+(void) tests;

@end
