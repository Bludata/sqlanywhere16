// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _MLREPLAYAPI_HPP_INCLUDED
#define _MLREPLAYAPI_HPP_INCLUDED

#if defined( _WIN32 )
    #define _MLREPLAY_CDECL	__cdecl
    #define _MLREPLAY_STDCALL	__stdcall

    #if defined( __WATCOMC__ )
	#define _MLREPLAY_EXPORT	__export
    #elif defined( _MSC_VER ) || defined( __BORLANDC__ )
	#define _MLREPLAY_EXPORT	__declspec( dllexport )
    #else
	#define _MLREPLAY_EXPORT
    #endif
#else
    #define _MLREPLAY_EXPORT
    #define _MLREPLAY_CDECL
    #define _MLREPLAY_STDCALL
#endif

#endif
