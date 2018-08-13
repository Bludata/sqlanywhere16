// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

// ************************************************************************
//	IMPORTANT: This file should not be used directly. Instead, one of 
//		   the files mentioned in the IDENTIFICATION section below
//		   should be used
// ************************************************************************

#ifndef _EXTFNCMN_H_INCLUDED
#define _EXTFNCMN_H_INCLUDED

#include "sqlos.h"
#include "sqlhosttype.h"
#include "sqlcallback.h"

#if defined( __cplusplus )
    #define _crtn   "C"
#else
    #define _crtn
#endif

#if defined( __cplusplus )
    extern "C" {
#endif

// ************************************************************************
// 	IDENTIFICATION
// ************************************************************************

// This section describes how a library identifies itself to the server

// If the following entry point exists in the library, the return value
// of the entry point determines which interface the library supports
// 
// If the entry point does not exist, its return value is assumed to be 0

//
// #define EXTFN_USE_NEW_API "extfn_use_new_api"
// typedef a_sql_uint32 (_entry an_extnfn_new_api_pointer *) ( );

// The return value of the  entry point must be one of the
// following values depending upon how the functions in the
// library are implemented

#define EXTFN_V0_API	0	// API defined in dllapi.h
#define EXTFN_V2_API	2	// API defined in extfnapi.h
#define EXTFN_V3_API	3	// API defined in extfnapiv3.h; not supported by SA
#define EXTFN_V4_API	4	// API defined in extfnapiv4.h; in development

// ************************************************************************


//
// The following function can be (optionally) implemented by the
// library to support cancelling of executing external functions in
// the same manner as cancelling of normal SQL statements.
//
// #define EXTFN_CANCEL "extfn_cancel"
// typedef void (_entry an_extfn_cancel) ( void *cancel_handle );

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk4.h"
#endif

typedef struct an_extfn_value {
    void *		data;
    a_sql_uint32	piece_len;
    union {
	a_sql_uint32	total_len;	// total length of field returned by get_value
	a_sql_uint32	remain_len;	// length remaining after calling get_piece
    } len;
    a_sql_data_type	type;
} an_extfn_value;


#endif /* _EXTFNCMN_H_INCLUDED */
