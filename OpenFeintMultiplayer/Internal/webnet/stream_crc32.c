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

#include "stream.h"

////////////////////////////////////////////////////////////////////////////////
// Variables
////////////////////////////////////////////////////////////////////////////////

static const u32 wn_stream_crc32_polynomial = 0x04C11DB7;
static u32 wn_stream_crc32_table[256];

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

void wn_stream_crc32_init() {
  u32 i, j;
  u32 h = 1;

  wn_stream_crc32_table[0] = 0;
  for(i = 128; i; i >>= 1) {
    h = (h >> 1) ^ ((h & 1) ? wn_stream_crc32_polynomial : 0);
    for(j = 0; j < 256; j += 2 * i)
      wn_stream_crc32_table[i + j] = wn_stream_crc32_table[j] ^ h;
  }
}

u32 wn_stream_crc32_check(const void* p, u32 size, u32 crc32) {
  u8* b = (u8*) p;
  while(size--)
    crc32 = (crc32 >> 8) ^ wn_stream_crc32_table[(crc32 ^ *b++) & 0xFF];
  return crc32;
}
