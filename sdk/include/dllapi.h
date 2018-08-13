// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _DLLAPI_H_INCLUDED
#define _DLLAPI_H_INCLUDED

#include "sqlca.h"

#if defined( __cplusplus )
    #define _crtn   "C"
#else
    #define _crtn
#endif

#define _callback_pref

#ifndef _WIN32_WCE_EMULATION
#ifdef UNDER_CE
#define __stdcall __cdecl	// Note this doesn't match the desktop definition
#endif
#endif

#if !defined( _entry )
    #if defined( _WIN32 )
	#define _entry		            __stdcall
	#define _callback_local	            __stdcall
	#if defined( __WATCOMC__ )
            #define _callback	            __export __stdcall
	    #define _ext_fn_entry           __export __stdcall
	#elif defined( _MSC_VER ) || defined( __BORLANDC__ )
            #define _callback               __stdcall
            #undef _callback_pref
            #define _callback_pref          __declspec( dllexport )
	    #define _ext_fn_entry           __declspec( dllexport )
	#endif
    #else
	#define _entry   
	#define _callback
	#define _callback_local
	#define _ext_fn_entry
    #endif
#endif

// These types are used so that tools routines can call back to the main
// routine with messages that should be displayed in the appropriate user
// interface (eg. Windows, stdout or other GUI).

#if defined( __cplusplus )
    extern "C" {
	typedef short _callback_pref (_callback MSG_ROUTINE)( const char * str );
	typedef short _callback_pref (_callback STATUS_ROUTINE)( a_sql_uint32 code, void * data, a_sql_uint32 length );
	typedef short                (_callback_local MSG_LOCAL_ROUTINE)( const char * str );
	typedef short _callback_pref (_callback MSG_QUEUE_ROUTINE)( a_sql_uint32 );
	typedef short _callback_pref (_callback SET_WINDOW_TITLE_ROUTINE)( const char * str );
	typedef short _callback_pref (_callback SET_TRAY_MESSAGE_ROUTINE)( const char * str );
	typedef short _callback_pref (_callback SET_PROGRESS_ROUTINE)( a_sql_uint32 index, a_sql_uint32 max );
	typedef short _callback_pref (_callback USAGE_ROUTINE)( const char * str );
	typedef short _callback_pref (_callback SPLASH_ROUTINE)( const char * title, const char * body );
    }
#elif defined( THINK_C ) || defined( __MWERKS__ )
    typedef _callback short	    (MSG_ROUTINE)( const char * str );
    typedef _callback short	    (STATUS_ROUTINE)( a_sql_uint32 code, void * data, a_sql_uint32 length );
    typedef _callback_local short   (MSG_LOCAL_ROUTINE)( const char * str );
    typedef _callback short	    (MSG_QUEUE_ROUTINE)( a_sql_uint32 );
    typedef _callback short	    (SET_WINDOW_TITLE_ROUTINE)( const char * );
    typedef _callback short	    (SET_TRAY_MESSAGE_ROUTINE)( const char * );
    typedef _callback short 	    (SET_PROGRESS_ROUTINE)( a_sql_uint32, a_sql_uint32 );
    typedef _callback short	    (USAGE_ROUTINE)( const char * str );
    typedef _callback short	    (SPLASH_ROUTINE)( const char * title, const char *body );
#else
    typedef short _callback_pref (_callback MSG_ROUTINE)( const char * str );
    typedef short		 (_callback STATUS_ROUTINE)( a_sql_uint32 code, void * data, a_sql_uint32 length );
    typedef short                (_callback_local MSG_LOCAL_ROUTINE)( const char * str );
    typedef short		 (_callback MSG_QUEUE_ROUTINE)( a_sql_uint32 );
    typedef short		 (_callback SET_WINDOW_TITLE_ROUTINE)( const char * );
    typedef short		 (_callback SET_TRAY_MESSAGE_ROUTINE)( const char * );
    typedef short 		 (_callback SET_PROGRESS_ROUTINE)( a_sql_uint32, a_sql_uint32 );
    typedef short		 (_callback USAGE_ROUTINE)( const char * str );
    typedef short		 (_callback SPLASH_ROUTINE)( const char * title, const char * body );
#endif

// Common MSG_QUEUE_ROUTINE return values
#define MSGQ_SHUTDOWN_REQUESTED		0
#define MSGQ_SLEEP_THROUGH		1
#define MSGQ_SYNC_REQUESTED		2

typedef void (*FATAL_RTN)( int ret_code );
typedef MSG_ROUTINE *		    MSG_CALLBACK;
typedef STATUS_ROUTINE *	    STATUS_CALLBACK;
typedef MSG_QUEUE_ROUTINE *	    MSG_QUEUE_CALLBACK;
typedef SET_WINDOW_TITLE_ROUTINE *  SET_WINDOW_TITLE_CALLBACK;
typedef SET_TRAY_MESSAGE_ROUTINE *  SET_TRAY_MESSAGE_CALLBACK;
typedef SET_PROGRESS_ROUTINE *      SET_PROGRESS_CALLBACK;
typedef USAGE_ROUTINE *		    USAGE_CALLBACK;
typedef SPLASH_ROUTINE *	    SPLASH_CALLBACK;

// These typedefs define the return types supported by external function calls.

typedef a_sql_int32	ext_fn_rv_integer;
typedef short		ext_fn_rv_smallint;
typedef a_sql_uint32	ext_fn_rv_real;

// These macros should be used to return values from an external function
// for a particular type.  The float macro is necessary because the return
// value must be forced into the same place an uint32 would return
// rather than being returned in a floating-point register.

#define return_ext_fn_integer(x)    return x
#define return_ext_fn_smallint(x)   return x
#define return_ext_fn_real(x)				\
	    {						\
		auto float fp_result = x;		\
		return *((a_sql_uint32 *) &fp_result);	\
	    }

#endif
