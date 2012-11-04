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

#ifndef _WN_WEBNET_SYS_H
#define _WN_WEBNET_SYS_H

#ifdef __cplusplus
#define WN_COMPILING_CPP
#endif

#ifdef WN_COMPILING_CPP
#define WNAPI extern "C"
#else
#define WNAPI
#endif

typedef char s8;
typedef short s16;
typedef int s32;
typedef long long s64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

#define HANDLE_NULL 0

#if !defined(COMPILING_CPP) && !defined(__OBJC__)

#import <stdlib.h>
#import <string.h>

typedef u8 bool;
#define false ((bool)0)
#define true ((bool)1)

#ifndef min
#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

#endif

#ifdef _DEBUG
WNAPI void wn_assert_core(s32 b, const char* f, ...);
#define wn_assert(b, f, ...) wn_assert_core((s32) (b), "\nASSERT: %s\nFUNC  : %s\nLINE  : %d\n" f "\n\n", __FILE__, __func__, __LINE__, ##__VA_ARGS__)
#else
#define wn_assert(b, f, ...) ((void) 0)
#endif

#endif  // _WN_WEBNET_SYS_H
