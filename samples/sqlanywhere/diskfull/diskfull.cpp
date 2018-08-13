// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// *********************************************************************

#include "sqlos.h"

#if defined( WIN32 ) || defined( WIN64 )
    #include <windows.h>
#endif
#include <stdio.h>
#include <stdlib.h>

#if defined( WIN32 ) || defined( WIN64 )
    #define _UINT32_ENTRY	unsigned int FAR __stdcall
#else
    #define _UINT32_ENTRY	unsigned int 
#endif

#if !defined( _unused )
#define _unused( i )	( (i) = (i) )
#endif


#if defined( WIN32 ) || defined( WIN64 )

int __stdcall LibMain(
    HANDLE inst,
    ULONG reasoncalled,
    LPVOID reserved )
/*********************/
{
    _unused( inst );
    _unused( reasoncalled );
    _unused( reserved );
    return( 1 );
}

#endif


// *********************************************************************

//
// Set the COMMAND string to be an arbitrary command to execute upon a 
// disk-full condition.
//
#if defined( UNIX ) 
    #define COMMAND	"sh ~/diskfull.sh"
#else
    #define COMMAND	"c:\\diskfull.bat"
#endif
#define COMMAND_LEN	( sizeof( COMMAND ) )

#define INTEGER_MAX	10
#ifndef PATH_MAX
    #define PATH_MAX	1024
#endif

#if defined( UNIX )
// requires C linkage
extern "C" _UINT32_ENTRY xp_out_of_disk( const char*, int );
#endif

_UINT32_ENTRY xp_out_of_disk( const char* db_file_name, int error_code )
/**********************************************************************/
{
    char buffer[ COMMAND_LEN + 1 + PATH_MAX + 1 + INTEGER_MAX + 1 ]; 

    // Build and execute the command string.  Use at most PATH_MAX
    // characters of db_file_name.
    sprintf( buffer, COMMAND " %.1024s %d", db_file_name, error_code );
    return system( buffer );
}
