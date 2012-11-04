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

#include "base64.h"

////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////

#include <unistd.h>

////////////////////////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////////////////////////

const s8* wn_base64_table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
static s8 wn_base64_table_rev[128];

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

void wn_base64_init() {
  u32 i;

  memset(wn_base64_table_rev, 0, sizeof(wn_base64_table_rev));

  for(i = 0; i < 65; i++)
    wn_base64_table_rev[(int)(wn_base64_table[i])] = i;
}

u32 wn_base64_encode(u8* data, u32 size, u32 max_size) {
  s32 i, j;
  u32 use_size = (size % 3) != 0 ? 3 : 0;
  u32 result = 0;
  
  use_size += (size / 3) * 3;
  if(use_size > max_size)
    return 0;

  for(i = use_size; i >= 3; i -= 3) {
    u8 p[4];
    s32 id3 = i / 3;
    s32 index = id3 << 2;

    for(j = 0; j < 4; j++)
      p[j] = 64;
    
    if(index <= max_size) {
      u32 t_start = id3 * 3 - 3;
      u8* t = data + t_start;
      u8* d = data + (index - 4);

      p[0] = (t[0] & 0xFC) >> 2;
      p[1] = ((t[0] & 0x03) << 4);
      if(t_start + 1 < size) {
        p[1] |= ((t[1] & 0xF0) >> 4);
        p[2] = ((t[1] & 0x0F) << 2);
        if(t_start + 2 < size) {
          p[2] |= ((t[2] & 0xC0) >> 6);
          p[3] = t[2] & 0x3F;
        }
      }
      
      for(j = 0; j < 4; j++) {
        wn_assert(p[j] <= 64, "Invalid Base64 data: %d\n", p[j]);
        *d++ = p[j];
      }
    }
    else {
      return 0;
    }
  }
  
  result = (use_size / 3) << 2;
  for(i = 0; i < result; i++) {
    u8 c;
    wn_assert(data[i] <= 64, "Invalid Base64 data: %d\n", data[i]);
    c = wn_base64_table[data[i]];
    wn_assert(c == '=' || c == '+' || c == '/'
      || (c >= '0' && c <= '9')
      || (c >= 'a' && c <= 'z')
      || (c >= 'A' && c <= 'Z')
      , "Invalid Base64 data: %d\n", c);
    data[i] = c;
  }

#if 0
  printf("base 64 data encoded, %d bytes\n", result);
  for(i = 0; i < result; i++)
    printf("%c", data[i]);
  printf("\nend data\n\n");
#endif
  
  return result;
}

u32 wn_base64_decode(u8* data, u32 size, u32 max_size) {
  s32 i, j;
  u32 use_size = (size & 3) != 0 ? 4 : 0;
  u8* d = data;
  u32 result = 0;
  
  use_size += (size >> 2) << 2;
  if(use_size > max_size)
    return 0;

  for(i = 0; i < use_size; i += 4) {
    u8 p[3];
    u8 t[4];
    u8 bytes_found = 0;
    
    for(j = 0; j < 4; j++) {
      u8 c = data[i + j];
      
      if(c == '=') {
        t[j] = 0;
        if(!bytes_found) {
          bytes_found = j - 1;
        }
      }
      else {
        t[j] = wn_base64_table_rev[c];
      }
    }
    
    if(!bytes_found)
      bytes_found = 3;
      
    result += bytes_found;

    p[0] = (t[0] << 2) | ((t[1] & 0x30) >> 4);
    if(bytes_found > 1) {
      p[1] = ((t[1] & 0x0F) << 4) | ((t[2] & 0x3C) >> 2);
      if(bytes_found > 2) {
        p[2] = ((t[2] & 0x03) << 6) | (t[3] & 0x3F);
      }
      else {
        p[2] = 0;
      }
    }
    else {
      p[1] = 0;
    }
    
    for(j = 0; j < 3; j++)
      *d++ = p[j];
  }

#if 0
  dprintf("base 64 data decoded, %d bytes\n", result);
  for(i = 0; i < result; i++)
    dprintf("%d,", data[i]);
  dprintf("\nend data\n\n");
#endif
  
  return result;
}

u32 wn_base64_encode_size(u32 size, u32 max_size) {
  u32 use_size = (size % 3) != 0 ? 3 : 0;
  use_size += (size / 3) * 3;
  use_size = (use_size / 3) << 2;
  if(max_size == 0)
    max_size = use_size;
  return min(use_size, max_size);
}

u32 wn_base64_decode_size(u32 size, u32 max_size) {
  u32 use_size = (size & 3) != 0 ? 4 : 0;
  use_size += (size >> 2) << 2;
  use_size = (use_size << 2) / 3;
  if(max_size == 0)
    max_size = use_size;
  return min(use_size, max_size);
}
