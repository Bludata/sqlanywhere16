// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of
// any kind.
// 
// You may use, reproduce, modify and distribute this sample code without
// limitation, on the condition that you retain the foregoing copyright 
// notice and disclaimer as to the original code.  
// 
// *******************************************************************

#if !defined( __TESTSRC_H )
#define __TESTSRC_H

#if defined( WIN32 )
#include <windows.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "extfnapi.h"

#if defined( WIN32 )
    #define _UINT32_ENTRY	extern "C" a_sql_uint32 FAR __stdcall
    #define _VOID_ENTRY		extern "C" void FAR __stdcall
#else
    #define _UINT32_ENTRY	extern "C" a_sql_uint32
    #define _VOID_ENTRY		extern "C" void
#endif

#endif // __TESTSRC_H
