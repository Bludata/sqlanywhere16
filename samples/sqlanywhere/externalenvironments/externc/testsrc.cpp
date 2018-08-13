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

// Sample code for C_ESQL and C_ODBC external environments

#include "testsrc.h"

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


#if defined( WIN32 )
    #define int64	__int64
    #defing uint64	unsigned __int64
#else
    #define int64	long long
    #define uint64	unsigned long long
#endif

// Proper
static unsigned char	t = 0;
static short		s = 0;
static unsigned short	us = 0;
static int		i = 0;
static unsigned int	ui = 0;
static int64		big = 0;
static uint64		ubig = 0;
static float		f = 0;
static double		d = 0;


_UINT32_ENTRY extfn_use_new_api( void )
/*************************************/
{
    return( EXTFN_API_VERSION );
}


_VOID_ENTRY SetDataTypes( an_extfn_api *api, void *arg_handle )
/*************************************************************/
{
    an_extfn_value	arg;

    // Takes a set of input arguments and sets the static variables
    // Parameters:
    //     1) tinyint
    //     2) smallint
    //     3) unsigned smallint
    //     4) int
    //     5) unsigned int
    //     6) bigint
    //     7) unsigned bigint
    //     8) float
    //     9) double
    if( api->get_value( arg_handle, 1, &arg ) && arg.data != NULL ) {
	t = *(unsigned char *) arg.data;
    }
    if( api->get_value( arg_handle, 2, &arg ) && arg.data != NULL ) {
	s = *(short *) arg.data;
    }
    if( api->get_value( arg_handle, 3, &arg ) && arg.data != NULL ) {
	us = *(unsigned short *) arg.data;
    }
    if( api->get_value( arg_handle, 4, &arg ) && arg.data != NULL ) {
	i = *(int *) arg.data;
    }
    if( api->get_value( arg_handle, 5, &arg ) && arg.data != NULL ) {
	ui = *(unsigned int *) arg.data;
    }
    if( api->get_value( arg_handle, 6, &arg ) && arg.data != NULL ) {
	big = *(int64 *) arg.data;
    }
    if( api->get_value( arg_handle, 7, &arg ) && arg.data != NULL ) {
	ubig = *(uint64 *) arg.data;
    }
    if( api->get_value( arg_handle, 8, &arg ) && arg.data != NULL ) {
	f = *(float *) arg.data;
    }
    if( api->get_value( arg_handle, 9, &arg ) && arg.data != NULL ) {
	d = *(double *) arg.data;
    }
}

_VOID_ENTRY FetchTiny( an_extfn_api *api, void *arg_handle )
/**********************************************************/
{
    an_extfn_value  retval;

    // returns the tinyint value set above
    retval.type = DT_TINYINT;
    retval.data = (void *)&t;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned char);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchSmallint( an_extfn_api *api, void *arg_handle )
/**************************************************************/
{
    an_extfn_value  retval;

    // returns the smallint value set above
    retval.type = DT_SMALLINT;
    retval.data = (void *)&s;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(short);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchUSmallint( an_extfn_api *api, void *arg_handle )
/***************************************************************/
{
    an_extfn_value  retval;

    // returns the unsigned smallint value set above
    retval.type = DT_UNSSMALLINT;
    retval.data = (void *)&us;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned short);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchInt( an_extfn_api *api, void *arg_handle )
/*********************************************************/
{
    an_extfn_value  retval;

    // returns the int value set above
    retval.type = DT_INT;
    retval.data = (void *)&i;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(int);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchUInt( an_extfn_api *api, void *arg_handle )
/**********************************************************/
{
    an_extfn_value  retval;

    // returns the unsigned int value set above
    retval.type = DT_UNSINT;
    retval.data = (void *)&ui;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned int);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchBigInt( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    an_extfn_value  retval;

    // returns the unsigned bigint value set above
    retval.type = DT_BIGINT;
    retval.data = (void *)&big;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(int64);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchUBigInt( an_extfn_api *api, void *arg_handle )
/*************************************************************/
{
    an_extfn_value  retval;

    // returns the unsigned bigint value set above
    retval.type = DT_UNSBIGINT;
    retval.data = (void *)&ubig;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(uint64);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchFloat( an_extfn_api *api, void *arg_handle )
/***********************************************************/
{
    an_extfn_value  retval;

    // returns the float value set above
    retval.type = DT_FLOAT;
    retval.data = (void *)&f;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(float);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchDouble( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    an_extfn_value  retval;

    // returns the double value set above
    retval.type = DT_DOUBLE;
    retval.data = (void *)&d;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(double);
    api->set_value( arg_handle, 0, &retval, 0);
}

_VOID_ENTRY FetchString( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    an_extfn_value  retval;
    an_extfn_value  arg;

    char *	    str1 = NULL;
    char *	    str2 = NULL;

    // takes 2 strigs as input and returns the concatenation of the two strings

    // assume strings are small enough to come in on a single chunk
    if( api->get_value( arg_handle, 1, &arg ) && arg.data != NULL ) {
	str1 = (char *)calloc( arg.len.total_len + 1, 1 );
	memcpy( str1, arg.data, arg.len.total_len );
    }

    if( api->get_value( arg_handle, 2, &arg ) && arg.data != NULL ) {
	str2 = (char *)calloc( arg.len.total_len + 1, 1 );
	memcpy( str2, arg.data, arg.len.total_len );
    }

    size_t len = (str1 == NULL ? 4 : strlen(str1));
    len += (str2 == NULL ? 4 : strlen(str2));
    ++len;

    char * result_str = (char *)calloc( len, 1 );
    if( str1 == NULL ) {
	strcpy( result_str, "NULL " );
    } else {
	strcpy( result_str, str1 );
	free( str1 );
    }
    if( str2 == NULL ) {
	strcat( result_str, "NULL " );
    } else {
	strcat( result_str, str2 );
	free( str2 );
    }

    // return the concatenated string in a single chunk
    retval.type = DT_FIXCHAR;
    retval.data = (void *)result_str;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)len;
    api->set_value( arg_handle, 0, &retval, 0);

    free( result_str );
}

_VOID_ENTRY FetchOuts( an_extfn_api *api, void *arg_handle )
/**********************************************************/
{
    an_extfn_value  retval;

    // returns each of the static variables in out parameters
    retval.type = DT_TINYINT;
    retval.data = (void *)&t;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned char);
    api->set_value( arg_handle, 1, &retval, 0);

    retval.type = DT_SMALLINT;
    retval.data = (void *)&s;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(short);
    api->set_value( arg_handle, 2, &retval, 0);

    retval.type = DT_UNSSMALLINT;
    retval.data = (void *)&us;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned short);
    api->set_value( arg_handle, 3, &retval, 0);

    retval.type = DT_INT;
    retval.data = (void *)&i;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(int);
    api->set_value( arg_handle, 4, &retval, 0);

    retval.type = DT_UNSINT;
    retval.data = (void *)&ui;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(unsigned int);
    api->set_value( arg_handle, 5, &retval, 0);

    retval.type = DT_BIGINT;
    retval.data = (void *)&big;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(int64);
    api->set_value( arg_handle, 6, &retval, 0);

    retval.type = DT_UNSBIGINT;
    retval.data = (void *)&ubig;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(uint64);
    api->set_value( arg_handle, 7, &retval, 0);

    retval.type = DT_FLOAT;
    retval.data = (void *)&f;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(float);
    api->set_value( arg_handle, 8, &retval, 0);

    retval.type = DT_DOUBLE;
    retval.data = (void *)&d;
    retval.piece_len = retval.len.total_len = (a_sql_uint32)sizeof(double);
    api->set_value( arg_handle, 9, &retval, 0);

    // convert all of the static variables into one long string and
    // return the string in multiple chunks
    char buffer[4096];
    sprintf( buffer, "t%d;s%d;us%d;ui%u;big%I64d", t, s, us, ui, big );
    size_t len = strlen( buffer );
    size_t split_len = len / 4; // send the value in four pieces

    // first chunk (append set to 0)
    retval.type = DT_LONGVARCHAR;
    retval.data = (void *)buffer;
    retval.piece_len = (a_sql_uint32)split_len;
    retval.len.total_len = (a_sql_uint32)len;
    api->set_value( arg_handle, 10, &retval, 0);

    // second chunk (append set to 1)
    retval.type = DT_LONGVARCHAR;
    retval.data = (void *)(buffer + split_len);
    retval.piece_len = (a_sql_uint32)split_len;
    retval.len.total_len = (a_sql_uint32)len;
    api->set_value( arg_handle, 10, &retval, 1);

    // third chunk (append set to 1)
    retval.type = DT_LONGVARCHAR;
    retval.data = (void *)(buffer + (split_len * 2));
    retval.piece_len = (a_sql_uint32)split_len;
    retval.len.total_len = (a_sql_uint32)len;
    api->set_value( arg_handle, 10, &retval, 1);

    // last chunk (append set to 1)
    retval.type = DT_LONGVARCHAR;
    retval.data = (void *)(buffer + (split_len * 3));
    retval.piece_len = (a_sql_uint32)(len - (split_len * 3));
    retval.len.total_len = (a_sql_uint32)len;
    api->set_value( arg_handle, 10, &retval, 1);
}

