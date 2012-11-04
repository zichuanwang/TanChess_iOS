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

#ifndef _WN_BASE64_H
#define _WN_BASE64_H

////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////

#include "webnet_sys.h"

////////////////////////////////////////////////////////////////////////////////
// Function Defs
////////////////////////////////////////////////////////////////////////////////

WNAPI void wn_base64_init();
WNAPI u32 wn_base64_encode(u8* data, u32 size, u32 max_size);
WNAPI u32 wn_base64_decode(u8* data, u32 size, u32 max_size);
WNAPI u32 wn_base64_encode_size(u32 size, u32 max_size);
WNAPI u32 wn_base64_decode_size(u32 size, u32 max_size);

#endif  // _WN_BASE64_H
