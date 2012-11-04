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

#include "cstr.h"

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

const char* wn_cstr_clone(const char* str, u32 size) {
  char* result;

  if(!str)
    return NULL;

  if(size == 0)
    size = strlen(str) + 1;

  result = (char*) malloc(size);
  strncpy(result, str, size);
  result[size] = 0;

  return result;
}

void wn_cstr_copy(char* dest, const char* str, u32 size) {
  if(!dest || size == 0)
    return;

  if(!str) {
    dest[0] = 0;
    return;
  }

  strncpy(dest, str, size - 1);
}

void wn_cstr_free(const char* str) {
  if(str)
    free((void*) str);
}
