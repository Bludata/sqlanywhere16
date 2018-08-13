// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef EXTTXTCMN_H_INCLUDED
#define EXTTXTCMN_H_INCLUDED

#include "stdio.h"
#include "sqlhosttype.h"
#include "sqlcallback.h"

/******************************************************************/
/*  Define structure packing macro based on environment           */
/******************************************************************/
#if !defined( _SQL_PACK_STRUCTURES ) && ( defined( _SQL_OS_WINNT ) && !defined( UNDER_CE ) && !defined( _WIN64 ) ) \
||  defined( _SQL_OS_NETWARE )
    #define _SQL_PACK_STRUCTURES    1
#endif

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk4.h"
#endif

#if defined(__cplusplus)
extern "C" {
#endif

typedef unsigned char a_byte;

// Declare the forward declarations here
struct a_text_source;
struct a_word_source;

// Declare server context
typedef struct a_server_context {
    // Set the error in the engine
    void (SQL_CALLBACK *set_error)( a_server_context*			/*This*/
				   , a_sql_uint32			/*error code*/
				   , const char*			/*error string*/
				   , short				/*length of error string */
				  );

    // Check if the current operation has been cancelled
    // by the user.
    // Returns:
    //	TRUE - If the operation is cancelled by the user
    //	FALSE - If the oprtation is not cancelled by the user
    a_sql_uint32 (SQL_CALLBACK *get_is_cancelled)( a_server_context* /*This*/
				    );

    // Log messages into the server's message log
    void (SQL_CALLBACK *log_message)( a_server_context*			/*This*/
				    , const char*			/*message string*/
				    , short				/*message length*/
				    );

    // Engine's context
    void *_context;
} a_server_context, *p_server_context;

#if defined(__cplusplus)
}
#endif

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif // EXTTXTCMN_H_INCLUDED
