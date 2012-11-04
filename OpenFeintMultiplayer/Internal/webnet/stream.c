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
// Function Defs
////////////////////////////////////////////////////////////////////////////////

static void wn_stream_mfile_close(wn_stream_t* io);
static bool wn_stream_mfile_eof(wn_stream_t* io);

static s8 wn_stream_mfile_is8(wn_stream_t* io);
static s16 wn_stream_mfile_is16(wn_stream_t* io);
static s32 wn_stream_mfile_is32(wn_stream_t* io);
static s64 wn_stream_mfile_is64(wn_stream_t* io);
static u8 wn_stream_mfile_iu8(wn_stream_t* io);
static u16 wn_stream_mfile_iu16(wn_stream_t* io);
static u32 wn_stream_mfile_iu32(wn_stream_t* io);
static u64 wn_stream_mfile_iu64(wn_stream_t* io);
static float wn_stream_mfile_ifloat(wn_stream_t* io);
static void wn_stream_mfile_ibytes(wn_stream_t* io, void* b, u32 size);
static bool wn_stream_mfile_ib(wn_stream_t* io);
static const u8* wn_stream_mfile_iutf8(wn_stream_t* io);
static const char* wn_stream_mfile_istr(wn_stream_t* io);
static u32 wn_stream_mfile_istrn(wn_stream_t* io, char* s, u32 n);

static void wn_stream_mfile_os8(wn_stream_t* io, s8 v);
static void wn_stream_mfile_os16(wn_stream_t* io, s16 v);
static void wn_stream_mfile_os32(wn_stream_t* io, s32 v);
static void wn_stream_mfile_os64(wn_stream_t* io, s64 v);
static void wn_stream_mfile_ou8(wn_stream_t* io, u8 v);
static void wn_stream_mfile_ou16(wn_stream_t* io, u16 v);
static void wn_stream_mfile_ou32(wn_stream_t* io, u32 v);
static void wn_stream_mfile_ou64(wn_stream_t* io, u64 v);
static void wn_stream_mfile_ofloat(wn_stream_t* io, float f);
static void wn_stream_mfile_obytes(wn_stream_t* io, const void* b, u32 size);
static void wn_stream_mfile_ob(wn_stream_t* io, bool b);
static void wn_stream_mfile_outf8(wn_stream_t* io, const u8* utf8);
static void wn_stream_mfile_ostr(wn_stream_t* io, const char* str);

static void mfile_read(void* p, u32 size, u32 count, wn_stream_t* io);
static void mfile_write(const void* p, u32 size, u32 count, wn_stream_t* io);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

bool wn_stream_mfile_open(wn_stream_t* io, const void* p, u32 size, wn_stream_mode_t mode, bool crc32_check) {
  memset(io, 0, sizeof(wn_stream_t));

  io->crc32_check = crc32_check;
  io->crc32_fail = true;
  io->crc32 = 0;

  io->mode = mode;
  io->pos = 0;
  io->size = size;

  io->data = (void*) p;

  if(mode == PFSM_READ) {
    io->is8 = wn_stream_mfile_is8;
    io->is16 = wn_stream_mfile_is16;
    io->is32 = wn_stream_mfile_is32;
    io->is64 = wn_stream_mfile_is64;
    io->iu8 = wn_stream_mfile_iu8;
    io->iu16 = wn_stream_mfile_iu16;
    io->iu32 = wn_stream_mfile_iu32;
    io->iu64 = wn_stream_mfile_iu64;
    io->ifloat = wn_stream_mfile_ifloat;
    io->ibytes = wn_stream_mfile_ibytes;
    io->ib = wn_stream_mfile_ib;
    io->iutf8 = wn_stream_mfile_iutf8;
    io->istr = wn_stream_mfile_istr;
    io->istrn = wn_stream_mfile_istrn;
    io->close = wn_stream_mfile_close;
    io->eof = wn_stream_mfile_eof;
  }
  else if(mode == PFSM_WRITE) {
    io->os8 = wn_stream_mfile_os8;
    io->os16 = wn_stream_mfile_os16;
    io->os32 = wn_stream_mfile_os32;
    io->os64 = wn_stream_mfile_os64;
    io->ou8 = wn_stream_mfile_ou8;
    io->ou16 = wn_stream_mfile_ou16;
    io->ou32 = wn_stream_mfile_ou32;
    io->ou64 = wn_stream_mfile_ou64;
    io->ofloat = wn_stream_mfile_ofloat;
    io->obytes = wn_stream_mfile_obytes;
    io->ob = wn_stream_mfile_ob;
    io->outf8 = wn_stream_mfile_outf8;
    io->ostr = wn_stream_mfile_ostr;
    io->close = wn_stream_mfile_close;
    io->eof = wn_stream_mfile_eof;
  }
  
  return true;
}

void wn_stream_mfile_close(wn_stream_t* io) {
  if(io->mode == PFSM_READ) {
    if(io->crc32_check) {
      u32 crc32;
      io->crc32_check = false;
      crc32 = wn_stream_mfile_iu32(io);
      io->crc32_check = true;
      io->crc32 = io->crc32 ^ 0xFFFFFFFF;
      io->crc32_fail = crc32 != io->crc32;
    }
  }
  else if(io->mode == PFSM_WRITE) {
    if(io->crc32_check) {
      io->crc32 = io->crc32 ^ 0xFFFFFFFF;
      wn_stream_mfile_ou32(io, io->crc32);
    }
  }
}

bool wn_stream_mfile_eof(wn_stream_t* io) {
  return io->pos == io->size;
}

s8 wn_stream_mfile_is8(wn_stream_t* io) {
  s8 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

s16 wn_stream_mfile_is16(wn_stream_t* io) {
  s16 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

s32 wn_stream_mfile_is32(wn_stream_t* io) {
  s32 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

s64 wn_stream_mfile_is64(wn_stream_t* io) {
  s64 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

u8 wn_stream_mfile_iu8(wn_stream_t* io) {
  u8 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

u16 wn_stream_mfile_iu16(wn_stream_t* io) {
  u16 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

u32 wn_stream_mfile_iu32(wn_stream_t* io) {
  u32 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

u64 wn_stream_mfile_iu64(wn_stream_t* io) {
  u64 result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

float wn_stream_mfile_ifloat(wn_stream_t* io) {
  float result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

void wn_stream_mfile_ibytes(wn_stream_t* io, void* b, u32 size) {
  mfile_read(b, 1, size, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(b, size, io->crc32);
}

bool wn_stream_mfile_ib(wn_stream_t* io) {
  bool result;
  mfile_read(&result, sizeof(result), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&result, sizeof(result), io->crc32);
  return result;
}

const u8* wn_stream_mfile_iutf8(wn_stream_t* io) {
  u32 size = wn_stream_iu32(io);
  if(size) {
    u8* utf8 = (u8*) malloc(size + 1);
    wn_stream_ibytes(io, utf8, size);
    utf8[size] = 0;
    return utf8;
  }
  return NULL;
}

const char* wn_stream_mfile_istr(wn_stream_t* io) {
  u16 len = wn_stream_iu16(io);
  if(len) {
    char* str = (char*) malloc(len + 1);
    wn_stream_ibytes(io, str, len);
    str[len] = 0;

    return str;
  }
  return NULL;
}

u32 wn_stream_mfile_istrn(wn_stream_t* io, char* s, u32 n) {
  u16 len = wn_stream_iu16(io);
  if(n) {
    len = min(len, n);

    wn_stream_ibytes(io, s, len);

    if(len < n)
      s[len] = 0;

    return len;
  }
  else {
    return 0;
  }
}

void wn_stream_mfile_os8(wn_stream_t* io, s8 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_os16(wn_stream_t* io, s16 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_os32(wn_stream_t* io, s32 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_os64(wn_stream_t* io, s64 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_ou8(wn_stream_t* io, u8 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_ou16(wn_stream_t* io, u16 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_ou32(wn_stream_t* io, u32 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_ou64(wn_stream_t* io, u64 v) {
  mfile_write(&v, sizeof(v), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&v, sizeof(v), io->crc32);
}

void wn_stream_mfile_ofloat(wn_stream_t* io, float f) {
  mfile_write(&f, sizeof(f), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&f, sizeof(f), io->crc32);
}

void wn_stream_mfile_obytes(wn_stream_t* io, const void* b, u32 size) {
  mfile_write(b, 1, size, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(b, size, io->crc32);
}

void wn_stream_mfile_ob(wn_stream_t* io, bool b) {
  mfile_write(&b, sizeof(b), 1, io);
  if(io->crc32_check)
    io->crc32 = wn_stream_crc32_check(&b, sizeof(b), io->crc32);
}

void wn_stream_mfile_outf8(wn_stream_t* io, const u8* utf8) {
  wn_assert(false, "Unsupported call to wn_stream_file_iutf8.");
}

void wn_stream_mfile_ostr(wn_stream_t* io, const char* str) {
  if(str) {
    u32 len = strlen(str);

    wn_assert(len < 0x10000, "String to long, %d characters", len);
    
    wn_stream_ou16(io, len);
    wn_stream_obytes(io, str, len);
  }
  else {
    wn_stream_ou16(io, 0);
  }
}

void mfile_read(void* p, u32 size, u32 count, wn_stream_t* io) {
  u8* s = ((u8*) io->data) + io->pos;
  u8* d = (u8*) p;
  u32 amount = size * count;

  wn_assert(io->mode == PFSM_READ, "Stream must be in READ mode.");
  
  while(amount-- && io->pos < io->size) {
    *d++ = *s++;
    io->pos++;
  }
}

void mfile_write(const void* p, u32 size, u32 count, wn_stream_t* io) {
  u8* s = (u8*) p;
  u8* d = ((u8*) io->data) + io->pos;
  u32 amount = size * count;

  wn_assert(io->mode == PFSM_WRITE, "Stream must be in WRITE mode.");
  
  while(amount-- && io->pos < io->size) {
    *d++ = *s++;
    io->pos++;
  }
}

void wn_stream_close(wn_stream_t* io) {
  io->close(io);
}

bool wn_stream_eof(wn_stream_t* io) {
  return io->eof(io);
}

s8 wn_stream_is8(wn_stream_t* io) {
  return io->is8(io);
}

s16 wn_stream_is16(wn_stream_t* io) {
  return io->is16(io);
}

s32 wn_stream_is32(wn_stream_t* io) {
  return io->is32(io);
}

s64 wn_stream_is64(wn_stream_t* io) {
  return io->is64(io);
}

u8 wn_stream_iu8(wn_stream_t* io) {
  return io->iu8(io);
}

u16 wn_stream_iu16(wn_stream_t* io) {
  return io->iu16(io);
}

u32 wn_stream_iu32(wn_stream_t* io) {
  return io->iu32(io);
}

u64 wn_stream_iu64(wn_stream_t* io) {
  return io->iu64(io);
}

float wn_stream_ifloat(wn_stream_t* io) {
  return io->ifloat(io);
}

void wn_stream_ibytes(wn_stream_t* io, void* b, u32 size) {
  io->ibytes(io, b, size);
}

bool wn_stream_ib(wn_stream_t* io) {
  return io->ib(io);
}

const u8* wn_stream_iutf8(wn_stream_t* io) {
  return io->iutf8(io);
}

const char* wn_stream_istr(wn_stream_t* io) {
  return io->istr(io);
}

u32 wn_stream_istrn(wn_stream_t* io, char* s, u32 n) {
  return io->istrn(io, s, n);
}

void wn_stream_os8(wn_stream_t* io, s8 v) {
  io->os8(io, v);
}

void wn_stream_os16(wn_stream_t* io, s16 v) {
  io->os16(io, v);
}

void wn_stream_os32(wn_stream_t* io, s32 v) {
  io->os32(io, v);
}

void wn_stream_os64(wn_stream_t* io, s64 v) {
  io->os64(io, v);
}

void wn_stream_ou8(wn_stream_t* io, u8 v) {
  io->ou8(io, v);
}

void wn_stream_ou16(wn_stream_t* io, u16 v) {
  io->ou16(io, v);
}

void wn_stream_ou32(wn_stream_t* io, u32 v) {
  io->ou32(io, v);
}

void wn_stream_ou64(wn_stream_t* io, u64 v) {
  io->ou64(io, v);
}

void wn_stream_ofloat(wn_stream_t* io, float f) {
  io->ofloat(io, f);
}

void wn_stream_obytes(wn_stream_t* io, const void* b, u32 size) {
  io->obytes(io, b, size);
}

void wn_stream_ob(wn_stream_t* io, bool b) {
  io->ob(io, b);
}

void wn_stream_outf8(wn_stream_t* io, const u8* utf8) {
  io->outf8(io, utf8);
}

void wn_stream_ostr(wn_stream_t* io, const char* str) {
  io->ostr(io, str);
}

bool wn_stream_crc32_failed(wn_stream_t* io) {
  return io->crc32_fail;
}
