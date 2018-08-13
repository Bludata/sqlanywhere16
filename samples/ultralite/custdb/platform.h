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
#ifndef PLATFORM_H_INCLUDED
#define PLATFORM_H_INCLUDED

// Platform-specific cover functions for CustDB.

// First, figure out what platform we are building.
#ifdef __APPLE__
	#include <TargetConditionals.h>
	#define TARGET_OS_LINUX			0
#else
	#ifdef __linux__
		#define TARGET_OS_MAC		0
		#define TARGET_OS_IPHONE	0
		#define TARGET_OS_LINUX		1
		#define TARGET_OS_WIN32		0
	#else
		#define TARGET_OS_MAC		0
		#define TARGET_OS_IPHONE	0
		#define TARGET_OS_LINUX		0
		#define TARGET_OS_WIN32		1
	#endif
#endif

#if TARGET_OS_WIN32
	#include <windows.h>
	#include <stdlib.h>
	#include <string.h>
	#include <tchar.h>
	#ifndef TEXT
		#define TEXT(s)				_TEXT(s)
	#endif
	#define		my_strcpy			_tcscpy
	#define		my_strncpy			_tcsncpy
	#define		my_sprintf			_stprintf
#else
	#include <string.h>
	typedef		char				TCHAR;
	#define		TEXT(s)				s
	#define		my_strcpy			strcpy
	#define		my_strncpy			strncpy
	#define		my_sprintf			sprintf
#endif
#ifdef UNDER_CE
	#include <dbgapi.h>
	#define my_assert( x )			ASSERT( x )
#else
	#include <assert.h>
	#define my_assert( x )			assert( x )
#endif

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>

	#define CUSTDB_CPP // (always use the C++ API)

	inline bool my_okcancel_dialog( const char * ) {
		return true; // (N/A for iPhone)
	}
	inline void my_error_msg( const char * msg ) {
		NSLog( @"%s", msg );
	}

#elif TARGET_OS_LINUX || TARGET_OS_MAC
	#include <stdio.h>

	inline bool my_okcancel_dialog( const char * question ) {
		printf( "%s\n", question );
		printf( "1) OK [default]\n" );
		printf( "2) Cancel\n" );
		printf( "> " );
		int response;
		scanf( "%d", &response );
		return response != 2;
	}
	inline void my_error_msg( const char * msg ) {
		printf( "%s\n", msg );
	}

#elif TARGET_OS_WIN32 // Windows NT or Windows CE
	#include <stdio.h>

	inline bool my_okcancel_dialog( const TCHAR * question ) {
		int rc = MessageBox( NULL, question, TEXT("CustDB"), MB_ICONSTOP|MB_OKCANCEL );
		return rc == IDOK;
	}
	inline void my_error_msg( const TCHAR * msg ) {
		MessageBox( NULL, msg, TEXT("CustDB"), MB_ICONSTOP|MB_OK );
	}
	
#endif

#endif

// vim:ts=4:
