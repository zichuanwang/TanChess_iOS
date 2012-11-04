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

#ifndef _WN_STREAM_H
#define _WN_STREAM_H

////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////

#include "webnet_sys.h"

////////////////////////////////////////////////////////////////////////////////
// Enums
////////////////////////////////////////////////////////////////////////////////

typedef enum {
  PFSM_READ = 0,
  PFSM_WRITE,
} wn_stream_mode_t;

////////////////////////////////////////////////////////////////////////////////
// Structs
////////////////////////////////////////////////////////////////////////////////

typedef struct _wn_stream_t {
  void* data;

  wn_stream_mode_t mode;
  bool crc32_check;
  bool crc32_fail;
  u32 crc32;
  u32 pos;
  u32 size;

  void (*close)(struct _wn_stream_t*);
  bool (*eof)(struct _wn_stream_t*);

  s8 (*is8)(struct _wn_stream_t*);
  s16 (*is16)(struct _wn_stream_t*);
  s32 (*is32)(struct _wn_stream_t*);
  s64 (*is64)(struct _wn_stream_t*);
  u8 (*iu8)(struct _wn_stream_t*);
  u16 (*iu16)(struct _wn_stream_t*);
  u32 (*iu32)(struct _wn_stream_t*);
  u64 (*iu64)(struct _wn_stream_t*);
  float (*ifloat)(struct _wn_stream_t*);
  void (*ibytes)(struct _wn_stream_t*, void*, u32);
  bool (*ib)(struct _wn_stream_t*);
  const u8* (*iutf8)(struct _wn_stream_t*);
  const char* (*istr)(struct _wn_stream_t*);
  u32 (*istrn)(struct _wn_stream_t*, char*, u32);

  void (*os8)(struct _wn_stream_t*, s8);
  void (*os16)(struct _wn_stream_t*, s16);
  void (*os32)(struct _wn_stream_t*, s32);
  void (*os64)(struct _wn_stream_t*, s64);
  void (*ou8)(struct _wn_stream_t*, u8);
  void (*ou16)(struct _wn_stream_t*, u16);
  void (*ou32)(struct _wn_stream_t*, u32);
  void (*ou64)(struct _wn_stream_t*, u64);
  void (*ofloat)(struct _wn_stream_t*, float);
  void (*obytes)(struct _wn_stream_t*, const void*, u32);
  void (*ob)(struct _wn_stream_t*, bool);
  void (*outf8)(struct _wn_stream_t*, const u8*);
  void (*ostr)(struct _wn_stream_t*, const char*);
} wn_stream_t;

////////////////////////////////////////////////////////////////////////////////
// Function Defs
////////////////////////////////////////////////////////////////////////////////

WNAPI bool wn_stream_mfile_open(wn_stream_t* io, const void* p, u32 size, wn_stream_mode_t mode, bool crc32_check);

WNAPI void wn_stream_crc32_init();
WNAPI u32 wn_stream_crc32_check(const void* p, u32 size, u32 crc32);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

WNAPI void wn_stream_close(wn_stream_t* io);
WNAPI bool wn_stream_eof(wn_stream_t* io);
WNAPI s8 wn_stream_is8(wn_stream_t* io);
WNAPI s16 wn_stream_is16(wn_stream_t* io);
WNAPI s32 wn_stream_is32(wn_stream_t* io);
WNAPI s64 wn_stream_is64(wn_stream_t* io);
WNAPI u8 wn_stream_iu8(wn_stream_t* io);
WNAPI u16 wn_stream_iu16(wn_stream_t* io);
WNAPI u32 wn_stream_iu32(wn_stream_t* io);
WNAPI u64 wn_stream_iu64(wn_stream_t* io);
WNAPI float wn_stream_ifloat(wn_stream_t* io);
WNAPI void wn_stream_ibytes(wn_stream_t* io, void* b, u32 size);
WNAPI bool wn_stream_ib(wn_stream_t* io);
WNAPI const u8* wn_stream_iutf8(wn_stream_t* io);
WNAPI const char* wn_stream_istr(wn_stream_t* io);
WNAPI u32 wn_stream_istrn(wn_stream_t* io, char* s, u32 n);
WNAPI void wn_stream_os8(wn_stream_t* io, s8 v);
WNAPI void wn_stream_os16(wn_stream_t* io, s16 v);
WNAPI void wn_stream_os32(wn_stream_t* io, s32 v);
WNAPI void wn_stream_os64(wn_stream_t* io, s64 v);
WNAPI void wn_stream_ou8(wn_stream_t* io, u8 v);
WNAPI void wn_stream_ou16(wn_stream_t* io, u16 v);
WNAPI void wn_stream_ou32(wn_stream_t* io, u32 v);
WNAPI void wn_stream_ou64(wn_stream_t* io, u64 v);
WNAPI void wn_stream_ofloat(wn_stream_t* io, float f);
WNAPI void wn_stream_obytes(wn_stream_t* io, const void* b, u32 size);
WNAPI void wn_stream_ob(wn_stream_t* io, bool b);
WNAPI void wn_stream_outf8(wn_stream_t* io, const u8* utf8);
WNAPI void wn_stream_ostr(wn_stream_t* io, const char* str);
WNAPI bool wn_stream_crc32_failed(wn_stream_t* io);

#endif  // _WN_STREAM_H
