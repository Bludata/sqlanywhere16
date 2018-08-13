// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer 
// as to the original code.  
// 
// *******************************************************************

#include "sqlos.h"

#if defined( WIN32 )
    #include <windows.h>
#endif

#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "extfnapi.h"

#if !defined( _unused )
#define _unused( i )	( (i) = (i) )
#endif

#if !defined( TRUE )
#define TRUE 1
#endif
#if !defined( FALSE )
#define FALSE 0
#endif

#if defined( WIN32 )
    #define _UINT32_ENTRY	unsigned int FAR __stdcall
    #define _VOID_ENTRY		void FAR __stdcall
#else
    #define _UINT32_ENTRY	unsigned int 
    #define _VOID_ENTRY		void 
#endif

#if defined( WIN32 )
    #define int64	__int64
    #define uint64	unsigned __int64
#else
    #define int64	long long
    #define uint64	unsigned long long
#endif


#if defined( WIN32 )

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


// ***************************************************************************

#if defined( UNIX )
// requires C linkage
extern "C" _UINT32_ENTRY	extfn_use_new_api( void );
extern "C" _VOID_ENTRY 		xp_all_types( an_extfn_api *api, void *arg_handle );
extern "C" _VOID_ENTRY 		xp_replicate( an_extfn_api *api, void *arg_handle );
extern "C" _VOID_ENTRY		xp_strip_punctuation_and_spaces( an_extfn_api *api, void *arg_handle );
extern "C" _VOID_ENTRY		xp_get_word( an_extfn_api *api, void *arg_handle );
#endif


_UINT32_ENTRY extfn_use_new_api( void )
/*************************************/
{
    return( EXTFN_API_VERSION );
}


// Utility functions:

static short set_null(
    an_extfn_api *	api,
    void *		arg_handle,
    a_sql_uint32	arg_num,
    a_sql_data_type	datatype )
/*********************************/
// Utility function for returning a null value.
{
    an_extfn_value	outval;

    outval.type = datatype;
    outval.data = NULL;
    outval.piece_len = outval.len.total_len = 0;
    return( api->set_value( arg_handle, arg_num, &outval, 0 ) );
}

static char * get_string(
    an_extfn_api *	api,
    void *		arg_handle,
    a_sql_uint32	arg_num,
    an_extfn_value *	arg,
    unsigned *		total_len )
/*********************************/
// Allocate and copy a string argument.
// Returns NULL if:
//  - the argument was null
//  - memory could not be allocated
//  - the argument could not be accessed
// Note: caller is responsible for freeing the string.
{
    char *		instr;
    unsigned		offset;

    if( !api->get_value( arg_handle, arg_num, arg ) || arg->data == NULL ) {
	return( NULL );
    }
    *total_len = arg->len.total_len;
    instr = (char *) malloc( (*total_len) + 1 );
    if( instr == NULL ) {
	return( NULL );
    }
    memcpy( instr, arg->data, arg->piece_len );
    offset = arg->piece_len;
    for( ; offset < *total_len; offset += arg->piece_len ) {
	if( !api->get_piece( arg_handle, arg_num, arg, offset ) || arg->data == NULL ) {
	    free( instr );
	    return( NULL );
	}
	memcpy( instr+offset, arg->data, arg->piece_len );
    }
    instr[*total_len] = '\0';
    return( instr );
}



_VOID_ENTRY xp_all_types( an_extfn_api *api, void *arg_handle )
/*************************************************************/
// This function shows how parameters of various types are passed.
// It returns a string showing the input values.
//
// Parameters:
//  1) integer
//  2) tinyint
//  3) smallint
//  4) bigint
//  5) char(30)
//  6) double
//  7) long varchar
// Result:
//  long varchar
// Comments:
//  - Size of result is limited so it can be easily viewed in DBISQL.
{
    an_extfn_value	arg;
    char *		result;
    an_extfn_value	retval;
    char		buff[30];

    result = (char *) malloc( 2000 );
    strcpy( result, "The parameters were: " );

    strcat( result, " 1) " );
    if( !api->get_value( arg_handle, 1, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	int		intval = *(int *) arg.data;
	sprintf( buff, "%d", intval );
	strcat( result, buff );
    }
    
    strcat( result, ", 2) " );
    if( !api->get_value( arg_handle, 2, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	unsigned char	tinyintval = *(unsigned char *) arg.data;
	sprintf( buff, "%hhu", tinyintval );
	strcat( result, buff );
    }
    
    strcat( result, ", 3) " );
    if( !api->get_value( arg_handle, 3, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	short		smallintval = *(short *) arg.data;
	sprintf( buff, "%hd", smallintval );
	strcat( result, buff );
    }
    
    strcat( result, ", 4) " );
    if( !api->get_value( arg_handle, 4, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	int64		bigintval = *(int64 *) arg.data;
	double		dbl = (double) bigintval;
	sprintf( buff, "%21.0f", dbl );
	strcat( result, buff );
    }
    
    strcat( result, ", 5) " );
    if( !api->get_value( arg_handle, 5, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	char *		instr = (char *)arg.data;
	strcat( result, "'" );
	strcat( result, instr );
	strcat( result, "'" );
    }
    
    strcat( result, ", 6) " );
    if( !api->get_value( arg_handle, 6, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	double		dblval = *(double *) arg.data;
	sprintf( buff, "%30.10g", dblval );
	strcat( result, buff );
    }
    
    strcat( result, ", 7) " );
    if( !api->get_value( arg_handle, 7, &arg ) || arg.data == NULL ) {
	strcat( result, "NULL" );
    } else {
	unsigned	expected = arg.len.total_len;
	unsigned	piece_len = arg.piece_len;
	char *		instr = (char *)arg.data;
	char		first = *instr;
	char *		last;
	char *		chk;
	unsigned	matches = TRUE;

	// Check if entire string is duplicate of first character
	if( piece_len == expected ) {
	    last = instr + expected - 1;
	    for( chk = instr; chk <= last; ++chk ) {
		if( *chk != first ) {
		    matches = FALSE;
		    break;
		}
	    }
	} else {
	    for( ; piece_len < expected; ) {
		instr = (char *) arg.data;
		last = instr + arg.piece_len - 1;
		for( chk = instr; chk <= last; ++chk ) {
		    if( *chk != first ) {
			matches = FALSE;
			break;
		    }
		}
		if( !api->get_piece( arg_handle, 7, &arg, piece_len ) || arg.data == NULL ) {
		    break;
		}
		piece_len += arg.piece_len;
	    }
	}
	if( piece_len != expected ) {
	    strcat( result, "*** length did not match expected ***" );
	} else {
	    sprintf( buff, "%u", piece_len );
	    strcat( result, "string length was " );
	    strcat( result, buff );
	    if( matches ) {
		strcat( result, "; all characters match" );
	    } else {
		strcat( result, "; characters are not all the same" );
	    } 
	}
    }
    
    retval.type = DT_LONGVARCHAR;
    retval.data = result;
    retval.piece_len = retval.len.total_len = (a_sql_uint32) strlen( result );
    api->set_value( arg_handle, 0, &retval, 0 );
    free( result );
}

_VOID_ENTRY xp_replicate( an_extfn_api *api, void *arg_handle )
/*************************************************************/
// Make copies of a string.
//
// Parameters:
//  1) integer (number of copies to make)
//  2) long varchar (source string)
//  3) long varchar (result, output)
// Comments:
//  - The "arg" local variable is re-used when accessing each of the arguments.
//    All of the information for one argument is obtained before moving to the
//    next.
//  - Memory for the (possibly long) source string is allocated and freed.
//    The output string is several times the size of the input string, but
//    we do not need to allocate space for it.
{
    an_extfn_value	arg;
    an_extfn_value	outval;
    unsigned		num_copies;
    unsigned		source_len;
    char *		chunk;
    short		appending = FALSE;

    if( !api->get_value( arg_handle, 1, &arg ) || arg.data == NULL ) {
	set_null( api, arg_handle, 3, DT_LONGVARCHAR );
	return;
    }
    num_copies = *(int *) arg.data;
    chunk = get_string( api, arg_handle, 2, &arg, &source_len );
    if( chunk == NULL ) {
	set_null( api, arg_handle, 3, DT_LONGVARCHAR );
	return;
    }
    outval.type = DT_LONGVARCHAR;
    outval.data = chunk;
    outval.len.total_len = source_len * num_copies;
    outval.piece_len = source_len;
    for( ; num_copies > 0; --num_copies, appending = TRUE ) {
	api->set_value( arg_handle, 3, &outval, appending );
    }
    free( chunk );
}

_VOID_ENTRY xp_strip_punctuation_and_spaces( an_extfn_api *api, void *arg_handle )
/********************************************************************************/
// Strip punctuation and spaces.
//
// Parameters:
// 1) long varchar (input string containing spaces and punctuation)
// Result:
//  long varchar (input string with spaces and punctuation removed)
// Comments:
//  - If the input string is NULL, the function returns immediately without
//    setting the result value. This causes the result to be set to NULL.
{
    char *		instr;
    char *		outstr;
    an_extfn_value	arg;
    char *		src;
    char *		result;
    an_extfn_value	retval;
    unsigned		source_len;

    src = get_string( api, arg_handle, 1, &arg, &source_len );
    if( src == NULL ) return;

    // Result length will be <= source length.
    result = (char *) malloc( source_len + 1 );
    if( result == NULL ) return;
    
    for( instr = src, outstr = result; *instr != '\0'; ++instr ) {
	if( !isalnum( *instr ) ) continue;
	*outstr = *instr;
	++outstr;
    }
    *outstr = '\0';
    
    retval.type = DT_LONGVARCHAR;
    retval.data = result;
    retval.piece_len = retval.len.total_len = (a_sql_uint32) strlen( result );
    api->set_value( arg_handle, 0, &retval, 0 );
    free( src );
    free( result );
}

_VOID_ENTRY xp_get_word( an_extfn_api *api, void *arg_handle )
/************************************************************/
// Get the n'th word of a sentence.
//
// Parameters:
//  1) long varchar (input sentence)
//  2) int (word number)
// Result:
//  char()
// Comments:
//  - Assumes a word will be <= 255 characters.
{
    char *		instr;
    char *		outstr;
    int			wordnum;
    an_extfn_value	arg;
    an_extfn_value	arg2;
    char *		src;
    char		result[256];
    an_extfn_value	retval;
    unsigned		source_len;

    src = get_string( api, arg_handle, 1, &arg, &source_len );
    if( src == NULL ) return;

    if( !api->get_value( arg_handle, 2, &arg2 ) || arg2.data == NULL ) {
	return; // NULL
    }
    wordnum = *((int *)arg2.data);
    if( wordnum < 1 ) {
	return; // NULL
    }
    
    for( instr = src;; ) {
	// Skip to start of next word
	while( *instr != '\0' && !isalnum( *instr ) ) ++instr;
	if( *instr == '\0' ) {
	    return; // NULL
	}
	outstr = &result[0];
	for( ; *instr != '\0' && isalnum( *instr ); ++instr ) {
	    *outstr = *instr;
	    ++outstr;
	    if( (unsigned) (outstr - result) >= (sizeof(result) - 1) ) break;
	}
	if( --wordnum == 0 ) break;
    }
    *outstr = '\0';

    free( src );
    
    retval.type = DT_FIXCHAR;
    retval.data = &result;
    retval.piece_len = retval.len.total_len = (a_sql_uint32) strlen( result );
    api->set_value( arg_handle, 0, &retval, 0 );		    
}

