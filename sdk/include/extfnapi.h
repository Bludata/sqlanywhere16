// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _EXTFNAPI_H_INCLUDED
#define _EXTFNAPI_H_INCLUDED

#include "extfncmn.h"

// ************************************************************************
// 	IDENTIFICATION
// ************************************************************************

// A library that wishes to use the interfaces defined in this file
// must contain the EXTFN_USE_NEW_API entry point and its return value
// must be EXTFN_V2_API. The following definition of EXFN_API_VERSION is
// included for backwards compatibility

#define EXTFN_API_VERSION	2

// ************************************************************************

typedef struct an_extfn_api {
    // arg_handle = a handle to arguments provided by the server
    // arg_num    = argument number 0..N, 0=return value
    // data       = pointer to arg data
    
    // Calling get_value on an OUT argument will simply return the data type
    // of the argument, and will return data as NULL.

    // Must call get_value before get_piece.

    short (SQL_CALLBACK *get_value)(
				    void *          arg_handle,
				    a_sql_uint32    arg_num,
				    an_extfn_value *value
				    );
    short (SQL_CALLBACK *get_piece)(
				    void *          arg_handle,
				    a_sql_uint32    arg_num,
				    an_extfn_value *value,
				    a_sql_uint32    offset
				    );

    // To return a null value, set "data" to NULL in an_extfn_value.
    // The total_len field is ignored on calls to set_value, the data supplied
    // becomes the value of the argument if append is FALSE; otherwise the
    // data is appended to the current value of the argument. It is expected
    // that set_value will be called with append=FALSE for an argument before
    // being called with append=TRUE for the same argument.
    // The append field is ignored for fixed length data types (i.e., all 
    // numeric data types)

    short (SQL_CALLBACK *set_value)(
				    void *          arg_handle,
				    a_sql_uint32    arg_num,
				    an_extfn_value *value,
				    short	    append
				    );
    // The external function should call the following
    // if it expects the server to pass on any interrupts.
    // The cancel_handle will be passed back into the
    // DLL by the server on the extfn_cancel call below 
    void (SQL_CALLBACK *set_cancel)(
				    void *	arg_handle,
				    void *	cancel_handle
				    );
} an_extfn_api;

// The following definition and structures are to be used for getting
// server side connection handles and returning result sets for
// an external procedure, but only if the procedure is being executed in
// an external environment using either the c_esql or c_odbc language
// specification

#define EXTFN_CONNECTION_HANDLE_ARG_NUM	    (a_sql_uint32)(~0)
#define EXTFN_RESULT_SET_ARG_NUM	    (a_sql_uint32)(~0)

// the following definitions are to be used with the set_value callback
// to signal whether a result set is being described, or if a new result
// set row has been started, or if a result set row is being appended to,
// or if the current result set row is complete and ready to be flushed

#define EXTFN_RESULT_SET_DESCRIBE	    -1
#define EXTFN_RESULT_SET_NEW_ROW	    0
#define EXTFN_RESULT_SET_APPEND_ROW	    1
#define EXTFN_RESULT_SET_FLUSH_ROW	    2
#define EXTFN_RESULT_SET_NEW_ROW_FLUSH	    3 // set a new row and flush it in
					      // the same call

typedef struct an_extfn_result_set_column_info {
    char *				column_name;
    a_sql_data_type			column_type;
    // the following is for char(n), varchar(n) and binary(n) declarations
    // set to 0 for all other types
    a_sql_uint32			column_width;
    // column index starts from 1
    a_sql_uint32			column_index;
    // set the following field to 0 if the column is non-nullable
    // and set the field to 1 if the column is nullable
    short int				column_can_be_null;
} an_extfn_result_set_column_info;

typedef struct an_extfn_result_set_column_data {
    // as before, column index starts from 1
    a_sql_uint32			column_index;
    void *				column_data;
    a_sql_uint32			data_length;
    short				append;
} an_extfn_result_set_column_data;

typedef struct an_extfn_result_set_info {
    a_sql_uint32			number_of_columns;
    // the arrays below are zero based even though the column index
    // starts from 1
    an_extfn_result_set_column_info	*column_infos;
    an_extfn_result_set_column_data	*column_data_values;
} an_extfn_result_set_info;


#if defined( __cplusplus )
   }
#endif


// prototype for external function should be
//
// extern "C" void (SQL_CALLBACK *function_name)( an_extfn_api *api, void *arg_handle );

 
// If the following entry point exists in the DLL *and* returns >0, the new
// interface defined in this file is used. Otherwise, the old interface
// defined in dllapi.h is assumed. The return value is expected to be the
// version number defined in this file (EXTFN_API_VERSION) 
//
// #define EXTFN_USE_NEW_API "extfn_use_new_api"
// typedef a_sql_uint32 (_entry an_extnfn_new_api_pointer *) ( );

//
// The following function can be (optionally) implemented by the
// DLL to support cancelling of executing external functions in
// the same manner as cancelling of normal SQL statements.
//
// #define EXTFN_CANCEL "extfn_cancel"
// typedef void (_entry an_extfn_cancel) ( void *cancel_handle );

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif /* _EXTFNAPI_H_INCLUDED */
