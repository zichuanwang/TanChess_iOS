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

#include "webnet_sys.h"

////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////

#include <stdarg.h>
#include <stdio.h>

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

#ifdef _DEBUG
void wn_assert_core(s32 b, const char* f, ...) {
  if(!b) {
    volatile s32 wait;

    va_list ap;
    va_start(ap, f);
    vprintf(f, ap);
    va_end(ap);

#ifdef WIN32
    assert(false);
#endif

    wait = 0;   // continue from here to execute more code
    
    if(!wait) {
      abort();
    }
  }
}
#endif
