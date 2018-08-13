/*-----------------------------------------------------------------------------+
 * Copyright 2013 SAP AG or an SAP affiliate company.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *                                                                                
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * While not a requirement of the license, if you do modify this file, we
 * would appreciate hearing about it. Please email sqlany_interfaces@sybase.com
 *-----------------------------------------------------------------------------+
 */

#if defined( WINNT ) && !POINTERS_ARE_64BITS
#define _USE_32BIT_TIME_T 1
#endif

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <assert.h>
#include <stddef.h>
#include <string.h>


#include "php.h"
#include "php_ini.h"
#include "php_sqlanywhere.h"
#include "php_sqlany_ver.h"
#include "php_globals.h"
#include "ext/standard/info.h"

#if HAVE_SQLANYWHERE 

#include "sqlany_dbg.h"

#define _SACAPI_VERSION 2
#include "sacapi.h"
#include "sacapidll.h"

ZEND_DECLARE_MODULE_GLOBALS(sqlanywhere)

#if defined( WIN32 )
   #define DBCAPI_PREFIX   ""
   #define DBCAPI_SUFFIX   ".dll"

   #if defined( ZTS )
       #define DBCAPI_ZTS	   ""
   #else
       #define DBCAPI_ZTS	   ""
   #endif

   #define DLL_PATH	"PATH"
#else

   #define DBCAPI_PREFIX   "lib"
   #define DBCAPI_SUFFIX   ".so"

   #if defined( _REENTRANT )
       #define DBCAPI_ZTS	   "_r"
   #else
       #define DBCAPI_ZTS	   ""
   #endif

   #define DLL_PATH	"LD_LIBRARY_PATH"
#endif

#ifndef Z_ADDREF_P
#define Z_ADDREF_P(x)	(((x)->refcount)++)
#define Z_DELREF_P(x)	(((x)->refcount)--)
#define Z_SET_REFCOUNT_P(x,v)   ((x)->refcount = v)
#endif


#define DBCAPI_NAME DBCAPI_PREFIX "dbcapi" DBCAPI_ZTS DBCAPI_SUFFIX

//#define DBCAPI_NOT_FOUND_ERROR "Could not load " DBCAPI_NAME ". Please ensure that " DBCAPI_NAME " can be found in your " DLL_PATH " environment variable."
#define DBCAPI_NOT_FOUND_ERROR "The SQLAnywhere client libraries could not be loaded. Please ensure that " DBCAPI_NAME " can be found in your " DLL_PATH " environment variable."

ZEND_BEGIN_ARG_INFO(third_arg_force_by_ref_only, 0)
  ZEND_ARG_PASS_INFO(0)
  ZEND_ARG_PASS_INFO(0)
  ZEND_ARG_PASS_INFO(1)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(third_arg_force_by_ref_and_rest, 1)
  ZEND_ARG_PASS_INFO(0)
  ZEND_ARG_PASS_INFO(0)
 ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(second_arg_force_by_ref_and_rest, 1)
  ZEND_ARG_PASS_INFO(0)
ZEND_END_ARG_INFO()

PHP_MINIT_FUNCTION(sqlanywhere);
PHP_MSHUTDOWN_FUNCTION(sqlanywhere);
PHP_RINIT_FUNCTION(sqlanywhere);
PHP_RSHUTDOWN_FUNCTION(sqlanywhere);
PHP_MINFO_FUNCTION(sqlanywhere);

PHP_FUNCTION(sasql_affected_rows);	
PHP_FUNCTION(sasql_close);	
PHP_FUNCTION(sasql_commit);	
PHP_FUNCTION(sasql_connect);	
/* sasql_disconnect */
PHP_FUNCTION(sasql_data_seek);	
PHP_FUNCTION(sasql_error);	
PHP_FUNCTION(sasql_errorcode);	
/* sasql_escape_string */
PHP_FUNCTION(sasql_fetch_array);	
PHP_FUNCTION(sasql_fetch_assoc);	
PHP_FUNCTION(sasql_fetch_field);	
PHP_FUNCTION(sasql_fetch_object);	
PHP_FUNCTION(sasql_fetch_row);	
PHP_FUNCTION(sasql_field_count);	
PHP_FUNCTION(sasql_field_seek);
PHP_FUNCTION(sasql_free_result);	
PHP_FUNCTION(sasql_get_client_info);	
PHP_FUNCTION(sasql_insert_id);	
PHP_FUNCTION(sasql_message);	
PHP_FUNCTION(sasql_next_result);
PHP_FUNCTION(sasql_num_fields);
PHP_FUNCTION(sasql_num_rows);	
PHP_FUNCTION(sasql_pconnect);	
PHP_FUNCTION(sasql_pconnect_from_sqlca);	
PHP_FUNCTION(sasql_prepare);
PHP_FUNCTION(sasql_query);	
PHP_FUNCTION(sasql_real_escape_string);
PHP_FUNCTION(sasql_real_query);	
PHP_FUNCTION(sasql_result_all);
PHP_FUNCTION(sasql_rollback);	
PHP_FUNCTION(sasql_set_option);	
PHP_FUNCTION(sasql_sqlstate);	
PHP_FUNCTION(sasql_stmt_affected_rows);
PHP_FUNCTION(sasql_stmt_bind_param);
PHP_FUNCTION(sasql_stmt_bind_param_ex);
PHP_FUNCTION(sasql_stmt_bind_result);
PHP_FUNCTION(sasql_stmt_close);
PHP_FUNCTION(sasql_stmt_data_seek);
PHP_FUNCTION(sasql_stmt_execute);
PHP_FUNCTION(sasql_stmt_errno);
PHP_FUNCTION(sasql_stmt_error);
PHP_FUNCTION(sasql_stmt_fetch);
PHP_FUNCTION(sasql_stmt_field_count);
PHP_FUNCTION(sasql_stmt_free_result);
PHP_FUNCTION(sasql_stmt_insert_id);
PHP_FUNCTION(sasql_stmt_next_result);
PHP_FUNCTION(sasql_stmt_num_rows);
PHP_FUNCTION(sasql_stmt_param_count);
PHP_FUNCTION(sasql_stmt_reset);
PHP_FUNCTION(sasql_stmt_result_metadata);
PHP_FUNCTION(sasql_stmt_send_long_data);
PHP_FUNCTION(sasql_stmt_store_result);
PHP_FUNCTION(sasql_stmt_sqlstate);
PHP_FUNCTION(sasql_store_result);
PHP_FUNCTION(sasql_use_result);



/* Deprecated function */
PHP_FUNCTION(sqlanywhere_query);	
PHP_FUNCTION(sqlanywhere_data_seek);	
PHP_FUNCTION(sqlanywhere_num_rows);	
PHP_FUNCTION(sqlanywhere_execute);	
PHP_FUNCTION(sqlanywhere_num_fields);	

/* 
 * Every user visible function must have an entry in sasql_functions[].
 */
zend_function_entry sqlanywhere_functions[] = {
    	/* connection functions */
	PHP_FE(sasql_connect,				NULL)
	PHP_FE(sasql_pconnect,				NULL)
	PHP_FE(sasql_pconnect_from_sqlca,		NULL)
	PHP_FE(sasql_close,				NULL)
	PHP_FE(sasql_query,				NULL)
	PHP_FE(sasql_real_query,			NULL)
	PHP_FE(sasql_store_result,			NULL)
	PHP_FE(sasql_use_result,			NULL)
	PHP_FE(sasql_next_result,			NULL)
	PHP_FE(sasql_set_option,			NULL)
	PHP_FE(sasql_affected_rows,			NULL)
	PHP_FE(sasql_commit,				NULL)
	PHP_FE(sasql_rollback,				NULL)
	PHP_FE(sasql_sqlstate,				NULL)

	/* result functions */
/*	PHP_FE(sasql_field_tell,			NULL) */
	PHP_FE(sasql_data_seek,				NULL)
	PHP_FE(sasql_fetch_array,			NULL)
	PHP_FE(sasql_fetch_assoc,			NULL)
/*	PHP_FE(sasql_fetch_field_direct,		NULL) */
	PHP_FE(sasql_fetch_field,			NULL)
	PHP_FE(sasql_fetch_object,			NULL)
	PHP_FE(sasql_fetch_row,				NULL)
	PHP_FE(sasql_field_seek,			NULL)
	PHP_FE(sasql_free_result,			NULL)
/*	PHP_FE(sasql_fetch_lengths,			NULL) */
	PHP_FE(sasql_num_rows,				NULL)
	PHP_FE(sasql_result_all,			NULL)

	/* connection functions */
	PHP_FE(sasql_error,				NULL)
	PHP_FE(sasql_errorcode,				NULL)
	PHP_FE(sasql_insert_id,				NULL)
	PHP_FE(sasql_message,				NULL)
	PHP_FE(sasql_prepare, 				NULL)
	PHP_FE(sasql_field_count,			NULL)
	PHP_FE(sasql_num_fields,			NULL)

	/* statement functions */
	PHP_FE(sasql_stmt_param_count,			NULL)
	PHP_FE(sasql_stmt_bind_param_ex,		third_arg_force_by_ref_only)
	PHP_FE(sasql_stmt_bind_param,			third_arg_force_by_ref_and_rest)
	PHP_FE(sasql_stmt_execute,			NULL)
	PHP_FE(sasql_stmt_close,			NULL)
	PHP_FE(sasql_stmt_result_metadata,		NULL)
	PHP_FE(sasql_stmt_affected_rows,		NULL)
	PHP_FE(sasql_stmt_num_rows,			NULL)
	PHP_FE(sasql_stmt_insert_id,			NULL)
	PHP_FE(sasql_stmt_bind_result,			second_arg_force_by_ref_and_rest)
	PHP_FE(sasql_stmt_send_long_data,		NULL)
	PHP_FE(sasql_stmt_store_result,			NULL)
	PHP_FE(sasql_stmt_free_result,			NULL)
	PHP_FE(sasql_stmt_reset,			NULL)
	PHP_FE(sasql_stmt_fetch,			NULL)
	PHP_FE(sasql_stmt_field_count,			NULL)
	PHP_FE(sasql_stmt_data_seek,			NULL)
	PHP_FE(sasql_stmt_next_result,                  NULL)
	PHP_FE(sasql_stmt_errno, 			NULL)
	PHP_FE(sasql_stmt_error, 			NULL)
	PHP_FE(sasql_stmt_sqlstate, 			NULL)

	/* misc functions */
	PHP_FE(sasql_real_escape_string, 		NULL)
	PHP_FE(sasql_get_client_info,			NULL)

	/* Deprecated functions */
	PHP_FE(sqlanywhere_query,			NULL)
	PHP_FE(sqlanywhere_num_rows,			NULL)
	PHP_FE(sqlanywhere_data_seek,			NULL)
	PHP_FE(sqlanywhere_execute,			NULL)

	/* Aliases */
	PHP_FALIAS(sqlanywhere_connect, 		sasql_connect,			NULL)
	PHP_FALIAS(sqlanywhere_pconnect, 		sasql_pconnect,			NULL)
	PHP_FALIAS(sqlanywhere_pconnect_from_sqlca, 	sasql_pconnect_from_sqlca,  	NULL)
	PHP_FALIAS(sqlanywhere_disconnect, 		sasql_close,			NULL)
	PHP_FALIAS(sqlanywhere_free_result, 		sasql_free_result,		NULL)
	PHP_FALIAS(sqlanywhere_fetch_field, 		sasql_fetch_field,		NULL)
	PHP_FALIAS(sqlanywhere_fetch_array, 		sasql_fetch_array,		NULL)
	PHP_FALIAS(sqlanywhere_fetch_object, 		sasql_fetch_object,		NULL)
	PHP_FALIAS(sqlanywhere_fetch_row, 		sasql_fetch_row,		NULL)
	PHP_FALIAS(sqlanywhere_commit, 			sasql_commit,			NULL)
	PHP_FALIAS(sqlanywhere_rollback, 		sasql_rollback,			NULL)
	PHP_FALIAS(sqlanywhere_set_option, 		sasql_set_option,		NULL)
	PHP_FALIAS(sqlanywhere_error, 			sasql_error,			NULL)
	PHP_FALIAS(sqlanywhere_errorcode, 		sasql_errorcode,		NULL)
	PHP_FALIAS(sqlanywhere_insert_id, 		sasql_insert_id,		NULL)
	PHP_FALIAS(sqlanywhere_identity, 		sasql_insert_id,		NULL)
	PHP_FALIAS(sqlanywhere_message, 		sasql_message,			NULL)
	PHP_FALIAS(sqlanywhere_result_all, 		sasql_result_all,		NULL)
	PHP_FALIAS(sqlanywhere_num_fields, 		sasql_num_fields,		NULL)
	PHP_FALIAS(sasql_disconnect, 			sasql_close,			NULL)

	PHP_FALIAS(sasql_escape_string, 		sasql_real_escape_string,	NULL)
	PHP_FALIAS(sasql_multi_query, 			sasql_real_query,		NULL)
	{NULL, NULL, NULL}	
};

zend_module_entry sqlanywhere_module_entry = {
    STANDARD_MODULE_HEADER,
    "sqlanywhere",
    sqlanywhere_functions,
    PHP_MINIT(sqlanywhere),
    PHP_MSHUTDOWN(sqlanywhere),
    PHP_RINIT(sqlanywhere),	/* Replace with NULL if there's nothing to do at request start */
    PHP_RSHUTDOWN(sqlanywhere),	/* Replace with NULL if there's nothing to do at request end */
    PHP_MINFO(sqlanywhere),
    PHP_SQLANYWHERE_VERSION,
    STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_SQLANYWHERE
ZEND_GET_MODULE(sqlanywhere)
#endif

static int le_result; 
static int le_conn; 
static int le_pconn;
static int le_stmt;
static SQLAnywhereInterface api;

#define sasql_HASH_STR	"sasql___"

/* types of fetch */
#define FETCH_ROW	(0x01)
#define FETCH_OBJ	(0x02)

#if PHP_MAJOR_VERSION >= 5 
#define ASA_UpdateInt	OnUpdateLong
  #if PHP_MINOR_VERSION < 4
    #define zend_rsrc_list_entry list_entry 
  #endif
#else
#define ASA_UpdateInt	OnUpdateInt
#endif

typedef struct sqlany_connection_t sqlany_connection_t;
typedef struct sqlany_result_t 	   sqlany_result_t;
typedef struct sqlany_stmt_t 	   sqlany_stmt_t;
typedef struct sqlany_stmt_param_t sqlany_stmt_param_t;
typedef struct php_stmt_param_t	   php_stmt_param_t;
typedef struct sqlany_result_row_t sqlany_result_row_t;
typedef struct sqlany_result_col_t sqlany_result_col_t;

struct sqlany_connection_t 
{
    int				id;
    a_sqlany_connection		*handle;
    int				auto_commit;
    int				verbose_errors;
    int				persistent;
    sqlany_result_t 		*result_list;
    sqlany_stmt_t		*stmt_list;
    a_sqlany_stmt		*last_stmt;
    int				ext_env_conn;
    char			error[SACAPI_ERROR_SIZE];
    int				errorcode;
    char			sqlstate[6];
    int				len;
};

struct sqlany_result_row_t
{
    int				row_id;
    a_sqlany_data_value		*values;
    sqlany_result_row_t		*next;
};

struct sqlany_result_t
{
    int				id;
    a_sqlany_stmt		*stmt_handle;
    sqlany_connection_t		*sqlany_conn;
    sqlany_result_t		*next;
    sqlany_stmt_t		*sqlany_stmt;

    sqlany_result_row_t		*curr_row;
    int				fetch_pos;
    int				num_rows;

    a_sqlany_column_info * 	column_info;
    int				num_cols;
    int				curr_col;
    int				result_cached;
};

struct sqlany_stmt_param_t
{
    a_sqlany_data_value		in;
    int				in_is_null;
    size_t			in_len;
    int				using_send_data;
    a_sqlany_data_value 	out;
    int				out_is_null;
    size_t			out_len;
};

struct php_stmt_param_t
{
    zval	*		in;
    zval	*		out;
};

struct sqlany_stmt_t
{
    int				id;
    a_sqlany_stmt		*handle;
    sqlany_stmt_t		*next;
    sqlany_connection_t		*sqlany_conn;
    sqlany_result_t		*sqlany_result;
    int				num_params;
    php_stmt_param_t		*php_params;
    sqlany_stmt_param_t		*sqlany_params;
    zval*			*php_result_vars;
    int				num_result_vars;
    char			error[SACAPI_ERROR_SIZE];
    int				errorcode;
    char			sqlstate[6];
    int				len;
};

static void SQLAnywhereConnect( INTERNAL_FUNCTION_PARAMETERS, int persistent );

/* {{{ PHP_INI */
PHP_INI_BEGIN()
    STD_PHP_INI_BOOLEAN(  "sqlanywhere.allow_persistent", "1", PHP_INI_SYSTEM, ASA_UpdateInt, 
	    allow_persistent, zend_sqlanywhere_globals, sqlanywhere_globals )
    STD_PHP_INI_ENTRY_EX( "sqlanywhere.max_persistent_connections", "-1", PHP_INI_SYSTEM, 
	    ASA_UpdateInt, max_pconns, zend_sqlanywhere_globals, sqlanywhere_globals, 
	    display_link_numbers )
    STD_PHP_INI_ENTRY_EX( "sqlanywhere.max_connections", "-1", PHP_INI_SYSTEM, ASA_UpdateInt, 
	    max_conns, zend_sqlanywhere_globals, sqlanywhere_globals, display_link_numbers )
    STD_PHP_INI_BOOLEAN(  "sqlanywhere.auto_commit", "1", PHP_INI_SYSTEM, ASA_UpdateInt, 
	    auto_commit, zend_sqlanywhere_globals, sqlanywhere_globals )
    STD_PHP_INI_BOOLEAN(  "sqlanywhere.verbose_errors", "1", PHP_INI_SYSTEM, ASA_UpdateInt, 
	    verbose_errors, zend_sqlanywhere_globals, sqlanywhere_globals )
PHP_INI_END()
/* }}} */

#if PHP_MAJOR_VERSION >= 5 
#undef ASA_UpdateInt
#endif

static 
void save_conn_error( sqlany_connection_t * sqlany_conn )
/********************************************************/
{
    sqlany_conn->errorcode = api.sqlany_error( sqlany_conn->handle, 
	    sqlany_conn->error, sizeof(sqlany_conn->error) );
    sqlany_conn->len = api.sqlany_sqlstate( sqlany_conn->handle, 
	    sqlany_conn->sqlstate, sizeof(sqlany_conn->sqlstate) - 1 );
}

static
void clear_conn_error( sqlany_connection_t * sqlany_conn )
/*********************************************************/
{
    sqlany_conn->errorcode = 0;
    memset( sqlany_conn->error, 0, sizeof(sqlany_conn->error) );
    strcpy( sqlany_conn->sqlstate, "00000" );
}

static
void save_stmt_error( sqlany_stmt_t * sqlany_stmt )
/**************************************************/
{
    sqlany_stmt->errorcode = api.sqlany_error( sqlany_stmt->sqlany_conn->handle,
	    sqlany_stmt->error, sizeof(sqlany_stmt->error) );
    sqlany_stmt->len = api.sqlany_sqlstate( sqlany_stmt->sqlany_conn->handle,
	    sqlany_stmt->sqlstate, sizeof(sqlany_stmt->sqlstate) - 1);
}

static
void clear_stmt_error( sqlany_stmt_t * sqlany_stmt )
/**************************************************/
{
    sqlany_stmt->errorcode = 0;
    memset( sqlany_stmt->error, 0, sizeof(sqlany_stmt->error) );
    strcpy( sqlany_stmt->sqlstate, "00000" );
}

static 
void free_cached_result( sqlany_result_t * sqlany_result )
/*********************************************************/
{
    int i;

    if( sqlany_result->column_info != NULL ) {
	for( i=0; i < sqlany_result->num_cols; i++ ) {
	    efree( sqlany_result->column_info[i].name );
	}
	efree( sqlany_result->column_info );
	sqlany_result->column_info = NULL;
    }

    while( sqlany_result->curr_row != NULL ) {
	sqlany_result_row_t * curr_row = sqlany_result->curr_row->next;

	if( curr_row->next == curr_row ) {
	    sqlany_result->curr_row = NULL;
	} else {
	    sqlany_result->curr_row->next = curr_row->next;
	}
	curr_row->next = NULL;
	
	for( i = 0; i < sqlany_result->num_cols; i++ ) {
	    efree( curr_row->values[i].buffer );
	    efree( curr_row->values[i].length );
	    efree( curr_row->values[i].is_null );
	}
	efree( curr_row->values );
	efree( curr_row );
	sqlany_result->num_rows--;
    }
    assert( sqlany_result->num_rows == 0 );
    assert( sqlany_result->curr_row == NULL );
}

static
int cache_result( sqlany_result_t * sqlany_result )
/**************************************************/
{
    sqlany_result_row_t * curr_row;
    int			  i;

    sqlany_result->num_rows = 0;
    sqlany_result->fetch_pos = 0;
    sqlany_result->num_cols = api.sqlany_num_cols( sqlany_result->stmt_handle );
    sqlany_result->column_info = (a_sqlany_column_info *)
	ecalloc( sqlany_result->num_cols, sizeof(a_sqlany_column_info));
    sqlany_result->result_cached = 1;

    // first cache column information
    for( i = 0; i < sqlany_result->num_cols; i++ ) {
	a_sqlany_column_info cinfo;

	api.sqlany_get_column_info( sqlany_result->stmt_handle, i, &cinfo );

	sqlany_result->column_info[i] = cinfo;
	sqlany_result->column_info[i].name = estrdup( cinfo.name );
    }

    // second cache row information
    while( api.sqlany_fetch_next( sqlany_result->stmt_handle ) ) {
	curr_row = ecalloc( 1, sizeof(sqlany_result_row_t) );
	curr_row->row_id = sqlany_result->num_rows;
	curr_row->values = ecalloc( sqlany_result->num_cols, sizeof(a_sqlany_data_value));

	for( i = 0; i < sqlany_result->num_cols; i++ ) {
	    a_sqlany_data_value	fetched_value;

	    api.sqlany_get_column( sqlany_result->stmt_handle, i, &fetched_value );

	    curr_row->values[i].type = fetched_value.type;
	    curr_row->values[i].is_null = (int *)emalloc( sizeof(int) );
	    *(curr_row->values[i].is_null) = *(fetched_value.is_null);
	    if( *(fetched_value.is_null) ) {
		curr_row->values[i].buffer = NULL;
		curr_row->values[i].length = NULL;
		continue;
	    }
	    switch( fetched_value.type ) {
		case A_BINARY:
		case A_STRING:
		    curr_row->values[i].buffer = (char *)emalloc( *(fetched_value.length) + 1 );
		    memcpy( curr_row->values[i].buffer, fetched_value.buffer, 
			    *(fetched_value.length) );
		    curr_row->values[i].buffer[*(fetched_value.length)] = '\0';
		    curr_row->values[i].length = (size_t*)emalloc( sizeof(size_t) );
		    *(curr_row->values[i].length) = *(fetched_value.length);
		    break;

		case A_DOUBLE:
		case A_VAL64:
		case A_UVAL64:
		    curr_row->values[i].buffer = emalloc( 8 );
		    memcpy( curr_row->values[i].buffer, fetched_value.buffer, 8 );
		    curr_row->values[i].length = (size_t*)emalloc( sizeof(size_t) );
		    *(curr_row->values[i].length) = sizeof(double);
		    break;

		case A_VAL32:
		case A_UVAL32:
		    curr_row->values[i].buffer = emalloc( 4 );
		    memcpy( curr_row->values[i].buffer, fetched_value.buffer, 4 );
		    curr_row->values[i].length = (size_t*)emalloc( sizeof(size_t) );
		    *(curr_row->values[i].length) = sizeof(int);
		    break;

		case A_VAL16:
		case A_UVAL16:
		    curr_row->values[i].buffer = emalloc( 2 );
		    memcpy( curr_row->values[i].buffer, fetched_value.buffer, 2 );
		    curr_row->values[i].length = (size_t*)emalloc( sizeof(size_t) );
		    *(curr_row->values[i].length) = 2;
		    break;

		case A_VAL8:
		case A_UVAL8:
		    curr_row->values[i].buffer = emalloc( 1 );
		    memcpy( curr_row->values[i].buffer, fetched_value.buffer, 1 );
		    curr_row->values[i].length = (size_t*)emalloc( sizeof(size_t) );
		    *(curr_row->values[i].length) = 1;
		    break;
		default:
		    break;
	    }
	}

	if( sqlany_result->curr_row == NULL ) {
	    curr_row->next = curr_row;
	} else {
	    curr_row->next = sqlany_result->curr_row->next;
	    sqlany_result->curr_row->next = curr_row;
	}
	sqlany_result->curr_row = curr_row;
	sqlany_result->num_rows++;
    }

    return api.sqlany_error( sqlany_result->sqlany_conn->handle, NULL, 0 );
}

static
int result_fetch_next( sqlany_result_t * sqlany_result, int is_connection )
/*************************************************************************/
{
    if( sqlany_result->result_cached ) {
	if( sqlany_result->fetch_pos >= sqlany_result->num_rows ) {
	    if( (is_connection && sqlany_result->sqlany_conn->errorcode == 0) ||
		 (!is_connection && sqlany_result->sqlany_stmt->errorcode == 0) ) {
		return 0;
	    } else {
		return -1;
	    }
	}
	sqlany_result->curr_row = sqlany_result->curr_row->next;
	sqlany_result->fetch_pos++;
    } else {
	if( !api.sqlany_fetch_next( sqlany_result->stmt_handle ) ) {
	    if( api.sqlany_error( sqlany_result->sqlany_conn->handle, NULL, 0 ) == 100 ) {
		if( is_connection ) {
		    clear_conn_error( sqlany_result->sqlany_conn );
		} else {
		    clear_stmt_error( sqlany_result->sqlany_stmt );
		}
		return 0;
	    } else {
		if( is_connection ) {
		    save_conn_error( sqlany_result->sqlany_conn );
		} else {
		    save_stmt_error( sqlany_result->sqlany_stmt );
		}
		return -1;
	    }
	}
	sqlany_result->fetch_pos++;
    }
    return 1;
}

static
int result_data_seek( sqlany_result_t * sqlany_result, int offset, int is_connection )
/*************************************************************************************/
{
    if( sqlany_result->result_cached ) {
	int row_id;
	if( offset < 0 ) {
	    offset += sqlany_result->num_rows;
	}
	if( offset < 0 || offset >= sqlany_result->num_rows ) {
	    return 0;
	}
	if( offset == 0 ) {
	    row_id = sqlany_result->num_rows - 1;
	} else {
	    row_id = offset - 1;
	}
	while( sqlany_result->curr_row->row_id != row_id ) {
	    sqlany_result->curr_row = sqlany_result->curr_row->next;
	}
	sqlany_result->fetch_pos = sqlany_result->curr_row->next->row_id;
	return 1;
    } else {
	int ok;
	if( offset <= 0 ) {
	    api.sqlany_fetch_absolute( sqlany_result->stmt_handle, offset );
	    ok = 1;
	} else {
	    ok = api.sqlany_fetch_absolute( sqlany_result->stmt_handle, offset );
	    if( !ok ) {
		if( is_connection ) {
		    save_conn_error( sqlany_result->sqlany_conn ); 
		} else {
		    save_stmt_error( sqlany_result->sqlany_stmt ); 
		}
	    }
	}
	return ok;
    }
}

int result_get_column_data( sqlany_result_t * sqlany_result, int col_num, a_sqlany_data_value * dvalue )
/*******************************************************************************************************/
{
    if( sqlany_result->curr_row != NULL ) {
	(*dvalue) = sqlany_result->curr_row->values[col_num];
    } else {
	api.sqlany_get_column( sqlany_result->stmt_handle, col_num, dvalue );
    }
    return 1;
}

int result_get_column_info( sqlany_result_t * sqlany_result, int col_num, a_sqlany_column_info * cinfo )
/*******************************************************************************************************/
{
    if( sqlany_result->column_info != NULL ) {
	(*cinfo) = sqlany_result->column_info[col_num];
    } else {
	api.sqlany_get_column_info( sqlany_result->stmt_handle, col_num, cinfo );
	save_conn_error( sqlany_result->sqlany_conn );
	if( sqlany_result->sqlany_conn->errorcode != 0 ) {
	    return 0;
	}
    }
    return 1;
}

static
void VerboseErrors( sqlany_connection_t * sqlany_conn TSRMLS_DC )
/***************************************************************/
{
    if( sqlany_conn->verbose_errors ) {
	php_error_docref( NULL TSRMLS_CC, E_WARNING, "SQLAnywhere: [%d] %s", 
		(int)sqlany_conn->errorcode, sqlany_conn->error );
    }
}


static 
ZEND_RSRC_DTOR_FUNC( sqlany_close_connection )
/*********************************************/
{
    sqlany_connection_t * sqlany_conn = (sqlany_connection_t *)rsrc->ptr;
    int 		  persistent = sqlany_conn->persistent;
    int			  id = sqlany_conn->id;

    if( !sqlany_conn->ext_env_conn ) {
	while( sqlany_conn->result_list != NULL ) {
	    zend_list_delete( sqlany_conn->result_list->id );
	}
	while( sqlany_conn->stmt_list != NULL ) {
	    zend_list_delete( sqlany_conn->stmt_list->id );
	}
	if( sqlany_conn->last_stmt != NULL ) {
	    api.sqlany_free_stmt( sqlany_conn->last_stmt );
	    sqlany_conn->last_stmt = NULL;
	}
	_debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_connection persist=%d id=%d ", 
		    persistent, id ) );
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_commit( sqlany_conn->handle );
	}
	api.sqlany_disconnect( sqlany_conn->handle );
	api.sqlany_free_connection( sqlany_conn->handle );
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_connection persist=%d id=%d done", 
		persistent, id ) );
    if( persistent ) {
	SAG(num_pconns)--;
	free( sqlany_conn );
    } else {
	efree( sqlany_conn );
    }
    SAG(num_conns)--;
}

static 
ZEND_RSRC_DTOR_FUNC( sqlany_close_result )
/******************************************/
{
    sqlany_result_t * sqlany_result = (sqlany_result_t *)rsrc->ptr;

    if( sqlany_result ) {
	sqlany_connection_t 	*sqlany_conn = sqlany_result->sqlany_conn;
	sqlany_result_t 	**curr;
	int			id;

	// We only need to auto commit if the result set is *not* cached and auto_commit is 'on'
	if( sqlany_result->curr_row == NULL && sqlany_conn->auto_commit ) {
	    api.sqlany_commit( sqlany_conn->handle );
	}

	for( curr = &(sqlany_conn->result_list); *curr != NULL ; curr = &(*curr)->next ) {
	    if( (*curr) == sqlany_result ) {
		(*curr) = (*curr)->next;
		break;
	    }
	}
	sqlany_result->sqlany_conn = NULL;

	free_cached_result( sqlany_result );

	if( sqlany_result->sqlany_stmt ) {
	    sqlany_result->sqlany_stmt->sqlany_result = NULL;
	    sqlany_result->sqlany_stmt = NULL;
	    sqlany_result->stmt_handle = NULL;
	} else if( sqlany_result->stmt_handle != NULL ) {
	    // if the result is referencing the current statement don't free it
	    // as the user might want to do a sasql_next_result()
	    if( sqlany_result->stmt_handle != sqlany_conn->last_stmt ) {
		api.sqlany_free_stmt( sqlany_result->stmt_handle );
	    }
	    sqlany_result->stmt_handle = NULL;
	}
	id = sqlany_result->id;
	_debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_result id=%d", id ) );
	efree( sqlany_result );
	_debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_result id=%d done", id ) );
    }
}

static 
ZEND_RSRC_DTOR_FUNC( sqlany_close_stmt )
/******************************************/
{
    sqlany_stmt_t * sqlany_stmt = (sqlany_stmt_t *)rsrc->ptr;

    if( sqlany_stmt ) {
	sqlany_connection_t 	*sqlany_conn = sqlany_stmt->sqlany_conn;
	sqlany_stmt_t 		**curr;

	for( curr = &(sqlany_conn->stmt_list); *curr != NULL ; curr = &(*curr)->next ) {
	    if( (*curr) == sqlany_stmt ) {
		(*curr) = (*curr)->next;
		break;
	    }
	}

	_debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_stmt id=%d", sqlany_stmt->id ) );

	if( sqlany_stmt->sqlany_params ) {
	    efree( sqlany_stmt->sqlany_params );
	    sqlany_stmt->sqlany_params = NULL;
	}

	if( sqlany_stmt->php_params ) {
	    int i;
	    for( i = 0; i < sqlany_stmt->num_params; i++ ) {
		if( sqlany_stmt->php_params[i].in ) {
		    Z_DELREF_P( sqlany_stmt->php_params[i].in );
		}
		if( sqlany_stmt->php_params[i].out ) {
		    Z_DELREF_P( sqlany_stmt->php_params[i].out );
		}
	    }
	    efree( sqlany_stmt->php_params );
	    sqlany_stmt->php_params = NULL;
	}

	if( sqlany_stmt->php_result_vars ) {
	    int i;
	    for( i = 0; i < sqlany_stmt->num_result_vars; i++ ) {
		if( sqlany_stmt->php_result_vars[i] != NULL ) {
		    Z_DELREF_P( sqlany_stmt->php_result_vars[i] );
		}
	    }
	    efree( sqlany_stmt->php_result_vars );
	    sqlany_stmt->php_result_vars = NULL;
	    sqlany_stmt->num_result_vars = 0;
	}

	if( sqlany_stmt->sqlany_result ) {
	    free_cached_result( sqlany_stmt->sqlany_result );
	    zend_list_delete( sqlany_stmt->sqlany_result->id );
	    sqlany_stmt->sqlany_result = NULL;
	}

	if( sqlany_stmt->handle != NULL ) {
	    api.sqlany_free_stmt( sqlany_stmt->handle );
	}
	_debug_enabled( SQLAnyDebug( _LOCATION_, "  sqlany_close_stmt id=%d done", 
		    sqlany_stmt->id ) );
	efree( sqlany_stmt );
    }
}

/* {{{ php_sqlany_init_globals 
*/
static 
void php_sqlany_init_globals( zend_sqlanywhere_globals * sqlany_globals TSRMLS_DC )
/*********************************************************************************/
{
    memset( sqlany_globals, 0, sizeof(*sqlany_globals));
    sqlany_globals->debug_trace = ( getenv( "SA_PHP_DEBUG" ) == NULL ? 0 : 1 );
}
/* }}} */

PHP_MINIT_FUNCTION(sqlanywhere)
/******************************/
{
#ifdef ZTS
    ts_allocate_id( &sqlanywhere_globals_id, sizeof(zend_sqlanywhere_globals), 
	    php_sqlany_init_globals, NULL);
#else
    php_sqlany_init_globals( &sqlanywhere_globals TSRMLS_CC );
#endif
    REGISTER_INI_ENTRIES();

    _debug_enabled( SQLAnyDebug( _LOCATION_, "BEGIN MINIT " ) );

    if( !sqlany_initialize_interface( &api, NULL ) ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, "Failed to load interface" ) );
	php_error_docref(NULL TSRMLS_CC, E_WARNING, DBCAPI_NOT_FOUND_ERROR );
    }
    le_conn  = zend_register_list_destructors_ex( sqlany_close_connection, 
	    NULL, 
	    "SQLAnywhere connection", module_number );

    le_pconn = zend_register_list_destructors_ex( NULL, 
	    sqlany_close_connection, 
	    "SQLAnywhere persistent connection ", module_number );

    le_result = zend_register_list_destructors_ex( sqlany_close_result, 
	    NULL, 
	    "SQLAnywhere result", module_number );

    le_stmt = zend_register_list_destructors_ex( sqlany_close_stmt, 
	    NULL, 
	    "SQLAnywhere statement", module_number );

    REGISTER_LONG_CONSTANT("SASQL_D_INPUT", 1, CONST_CS | CONST_PERSISTENT);
    REGISTER_LONG_CONSTANT("SASQL_D_OUTPUT", 2, CONST_CS | CONST_PERSISTENT);
    REGISTER_LONG_CONSTANT("SASQL_D_INPUT_OUTPUT", 3, CONST_CS | CONST_PERSISTENT);

    REGISTER_LONG_CONSTANT("SASQL_USE_RESULT", 0, CONST_CS | CONST_PERSISTENT);
    REGISTER_LONG_CONSTANT("SASQL_STORE_RESULT", 1, CONST_CS | CONST_PERSISTENT);

    REGISTER_LONG_CONSTANT("SASQL_NUM", 1, CONST_CS | CONST_PERSISTENT);
    REGISTER_LONG_CONSTANT("SASQL_ASSOC", 2, CONST_CS | CONST_PERSISTENT);
    REGISTER_LONG_CONSTANT("SASQL_BOTH", 3, CONST_CS | CONST_PERSISTENT);
    _debug_enabled( SQLAnyDebug( _LOCATION_, "FINI  MINIT " ) );
    return SUCCESS;
}

PHP_MSHUTDOWN_FUNCTION(sqlanywhere)
/**********************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, "BEGIN MSHUTDOWN " ) );
    UNREGISTER_INI_ENTRIES();
    if( !api.initialized ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, "FINI  MSHUTDOWN" ) );
	return SUCCESS;
    }
    if( SAG(sqlany_init_called) == 1 ) {
	if( SAG(context) ) {
	    api.sqlany_fini_ex( SAG(context) );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, "sqlany_fini_ex called" ) );
	} else {
	    api.sqlany_fini();
	    _debug_enabled( SQLAnyDebug( _LOCATION_, "sqlany_fini called" ) );
	}
	SAG(sqlany_init_called) = 0;
    }
    sqlany_finalize_interface( &api );
    _debug_enabled( SQLAnyDebug( _LOCATION_, "FINI MSHUTDOWN" ) );
    return SUCCESS;
}

/* Remove if there's nothing to do at request start */
PHP_RINIT_FUNCTION(sqlanywhere)
/******************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, "BEGIN RINIT" ) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, "api.initialized=%d", api.initialized) );
    if( api.initialized && SAG(sqlany_init_called) == 0 ) {
	if( api.sqlany_init_ex != NULL ) {
	    SAG(context) = api.sqlany_init_ex( "PHP", 2, NULL );
	    if( SAG(context) != NULL ) {
		SAG(sqlany_init_called) = 1;
	    }
	}
	if( SAG(sqlany_init_called) == 0 && !api.sqlany_init( "PHP", 1, NULL ) ) {
	    _debug_enabled( SQLAnyDebug( _LOCATION_, "Failed in sqlany_init() " ) );
	    return FAILURE;
	}
	SAG(sqlany_init_called) = 1;
	_debug_enabled( SQLAnyDebug( _LOCATION_, "sqlany_init() called successfully" ) );
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, "END RINIT" ) );
    return SUCCESS;
}

/* Remove if there's nothing to do at request end */
PHP_RSHUTDOWN_FUNCTION(sqlanywhere)
/**********************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, "BEGIN RSHUTDOWN" ) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, "END RSHUTDOWN" ) );
    return SUCCESS;
}

PHP_MINFO_FUNCTION(sqlanywhere)
/******************************/
{
    char maxp[32],maxl[32],client_version[32];

    if ( SAG(max_pconns) == -1 ) {
	snprintf(maxp, 31, "%ld/unlimited", SAG(num_pconns) );
    } else {
	snprintf(maxp, 31, "%ld/%ld", SAG(num_pconns), SAG(max_pconns));
    }
    maxp[31]=0;

    if ( SAG(max_conns) == -1) {
	snprintf(maxl, 31, "%ld/unlimited", SAG(num_conns) );
    } else {
	snprintf(maxl, 31, "%ld/%ld", SAG(num_conns), SAG(max_conns) );
    }
    maxl[31]=0;

    php_info_print_table_start();
    php_info_print_table_header(2, "SQLAnywhere support", "enabled");
    php_info_print_table_row(2, "Allow Persistent Connections", (SAG(allow_persistent)?"Yes":"No") );
    php_info_print_table_row(2, "Persistent Connections", maxp);
    php_info_print_table_row(2, "Total Connections", maxl);
    php_info_print_table_row(2, "PHP SQLAnywhere driver version", PHP_SQLANYWHERE_VERSION );
    if( api.initialized ) {
	int rc;
	if( SAG(context) ) {
	    rc = api.sqlany_client_version_ex( SAG(context), client_version, sizeof(client_version) );
	} else {
	    rc = api.sqlany_client_version( client_version, sizeof(client_version) );
	}
	if( !rc ) {
	    php_sprintf( client_version, "Uknown" );
	}
	php_info_print_table_row(2, "SQLAnywhere client version", client_version);
    } else {
	php_info_print_table_row(2, "SQLAnywhere client version", DBCAPI_NOT_FOUND_ERROR );
    }
    php_info_print_table_end();

    DISPLAY_INI_ENTRIES();
}

/* {{{ proto sasql_conn sasql_connect( string $conn_str ) 
   Open a SQLAnywhere server connection using arg as a connection string and returns a connection id */
PHP_FUNCTION(sasql_connect)
/**************************/
{
    SQLAnywhereConnect( INTERNAL_FUNCTION_PARAM_PASSTHRU, 0 );
}
/* }}} */

/* {{{ proto sasql_conn sasql_pconnect( string $conn_str )
   Open a persistant SQLAnywhere server connection using arg as a connection string and returns a connection id */
PHP_FUNCTION(sasql_pconnect)
/***************************/
{
    SQLAnywhereConnect( INTERNAL_FUNCTION_PARAM_PASSTHRU, 1 );
}
/* }}} */

static 
void SQLAnywhereConnect( INTERNAL_FUNCTION_PARAMETERS, int persistent )
/**********************************************************************/
{
    zval ** arg;
    sqlany_connection_t * sqlany_conn;
    char * hashed_details;
    int    hashed_details_length;

    if( !api.initialized ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, DBCAPI_NOT_FOUND_ERROR );
	RETURN_FALSE;
    }

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }

    convert_to_string_ex( arg );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect( '%s', persistance=%d )", 
		Z_STRVAL_PP(arg), persistent ) );

    hashed_details_length = strlen( sasql_HASH_STR ) + Z_STRLEN_PP(arg);
    hashed_details = (char *)emalloc( hashed_details_length + 1 );
    php_sprintf( hashed_details, "%s%s", sasql_HASH_STR, Z_STRVAL_PP(arg) );

    if( ! SAG(allow_persistent) ) {
	persistent = 0;
    }

try_again:
    /* always check the persistent list when no connection parms are given */
    if( persistent || 
	    hashed_details_length == strlen( sasql_HASH_STR ) + 1 ) {

	zend_rsrc_list_entry * le = NULL;

	/* try to find if we already have this link in our persistent list */
	if (zend_hash_find(&EG(persistent_list), hashed_details, hashed_details_length+1, 
		    (void **) &le)==FAILURE) {
	    /* we don't */
	    zend_rsrc_list_entry new_le;

	    if( SAG(max_conns) != -1 && 
		    SAG(num_conns) >= SAG(max_conns)) {
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"SQLAnywhere: Too many open connections (%ld)",SAG(num_conns));
		efree( hashed_details );
		_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
		RETURN_FALSE;
	    }
	    if( SAG(max_pconns) != -1 && 
		    SAG(num_pconns) >= SAG(max_pconns) ) {
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"SQLAnywherel:  Too many open persistent connections (%ld)", 
			SAG(num_pconns) );
		efree( hashed_details );
		_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
		RETURN_FALSE;
	    }

	    sqlany_conn = calloc( 1, sizeof(sqlany_connection_t) );
	    if( sqlany_conn == NULL ) {
		efree( hashed_details );
		RETURN_FALSE;
	    }
	    clear_conn_error( sqlany_conn );

	    if( SAG(context) ) {
		sqlany_conn->handle = api.sqlany_new_connection_ex( SAG(context) );
	    } else {
		sqlany_conn->handle = api.sqlany_new_connection();
	    }
	    if( sqlany_conn->handle == NULL ) {
		free( sqlany_conn );
		efree( hashed_details );
		RETURN_FALSE;
	    }

	    sqlany_conn->persistent = persistent;
	    sqlany_conn->auto_commit = SAG(auto_commit);
	    sqlany_conn->verbose_errors = SAG(verbose_errors);

	    if( !api.sqlany_connect( sqlany_conn->handle, Z_STRVAL_PP(arg) ) ) {
		save_conn_error( sqlany_conn );
		VerboseErrors( sqlany_conn TSRMLS_CC );
		SAG(error_code) = sqlany_conn->errorcode;
		memcpy( SAG(error), sqlany_conn->error, SACAPI_ERROR_SIZE );
		strcpy( SAG(sqlstate), sqlany_conn->sqlstate );
		api.sqlany_free_connection( sqlany_conn->handle );
		free( sqlany_conn );
		efree( hashed_details );
		_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE [%s]", 
			    SAG(error) ) );
		RETURN_FALSE;
	    }

	    new_le.type = le_pconn; 
	    new_le.ptr  = sqlany_conn;
	    if( zend_hash_update(&EG(persistent_list), hashed_details, 
			hashed_details_length+1, (void *) &new_le, 
			sizeof(zend_rsrc_list_entry),NULL)==FAILURE) {
		api.sqlany_disconnect( sqlany_conn->handle );
		api.sqlany_free_connection( sqlany_conn->handle );
		efree( hashed_details );
		free( sqlany_conn );
		_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
		RETURN_FALSE;
	    }
	    SAG(num_pconns)++;
	    SAG(num_conns)++;
	} else { /* we do */	
	    if( le->type != le_pconn ) {
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"SQLAnywhere:  Hashed persistent link is not a SQLAnywhere link!");
		_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
		RETURN_FALSE;
	    }

	    sqlany_conn = (sqlany_connection_t  *) le->ptr;

	    // test the connection 
	    if( !api.sqlany_execute_immediate( sqlany_conn->handle, "select 1 from dummy" ) ) {
		// connection is broken, destroy it and create a new one.
		zend_hash_del(&EG(persistent_list), hashed_details, hashed_details_length+1 );
		goto try_again;
	    }
	}
	sqlany_conn->id = zend_list_insert(sqlany_conn, le_pconn TSRMLS_CC);
    } else {
	/* ! persistent */
	zend_rsrc_list_entry * index_ptr, new_index_ptr;
	if (zend_hash_find(&EG(regular_list),hashed_details,hashed_details_length+1,
		    (void **) &index_ptr)==SUCCESS) {
	    int type;
	    long id;
	    void * ptr;

	    if( index_ptr->type != le_index_ptr ) {
		RETURN_FALSE;
	    }

	    id = (long)index_ptr->ptr;
	    ptr = (void *)zend_list_find( id, &type ); /* check if the link is still there */
	    if( ptr && (type == le_conn || type == le_pconn ) ) {
		efree( hashed_details );
		ZVAL_LONG( return_value, id );
		return;
	    } else {
		zend_hash_del( &EG(regular_list), hashed_details, hashed_details_length+1 );
	    }
	}
	if( SAG(max_conns) != -1 && 
		SAG(num_conns) >= SAG(max_conns) ) {
	    php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		    "SQLAnywhere: Too many open connections (%ld)",SAG(num_conns));
	    efree( hashed_details );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
	    RETURN_FALSE;
	}

	/* actually establish the connection */
	sqlany_conn = ecalloc( 1, sizeof(sqlany_connection_t));
	if( sqlany_conn == NULL ) {
	    efree( hashed_details );
	    RETURN_FALSE;
	}
	clear_conn_error( sqlany_conn );

	if( SAG(context) ) {
	    sqlany_conn->handle = api.sqlany_new_connection_ex( SAG(context) );
	} else {
	    sqlany_conn->handle = api.sqlany_new_connection();
	}
	if( sqlany_conn->handle == NULL ) {
	    efree( sqlany_conn );
	    efree( hashed_details );
	    RETURN_FALSE;
	}
	sqlany_conn->auto_commit = SAG(auto_commit);
	sqlany_conn->verbose_errors = SAG(verbose_errors);
	sqlany_conn->persistent = persistent;

	if( !api.sqlany_connect( sqlany_conn->handle, Z_STRVAL_PP(arg) ) ) {
	    save_conn_error( sqlany_conn );
	    VerboseErrors( sqlany_conn TSRMLS_CC );
	    SAG(error_code) = sqlany_conn->errorcode;
	    memcpy( SAG(error), sqlany_conn->error, SACAPI_ERROR_SIZE );
	    strcpy( SAG(sqlstate), sqlany_conn->sqlstate );
	    api.sqlany_free_connection( sqlany_conn->handle );
	    efree( sqlany_conn );
	    efree( hashed_details );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE[%s]", SAG(error) ) );
	    RETURN_FALSE;
	}
	sqlany_conn->id = zend_list_insert(sqlany_conn,le_conn TSRMLS_CC);

	new_index_ptr.ptr  = (void *) Z_LVAL_P( return_value );
	new_index_ptr.type = le_index_ptr;
	if (zend_hash_update(&EG(regular_list),hashed_details,hashed_details_length+1,
		    (void *) &new_index_ptr, sizeof(zend_rsrc_list_entry),NULL)==FAILURE) {
	    efree(hashed_details);
	    api.sqlany_disconnect( sqlany_conn->handle );
	    api.sqlany_free_connection( sqlany_conn->handle );
	    efree( sqlany_conn );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>FALSE" ) );
	    RETURN_FALSE;
	}
	SAG(num_conns)++;
    }

    efree(hashed_details);
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_connect=>%d", sqlany_conn->id ) );
    /* default to return return_value->value.lval */
    RETURN_RESOURCE( sqlany_conn->id );
}

/* {{{ proto sasql_conn sasql_pconnect_from_sqlca( void* sqlca)
   Create a persistent SQLAnywhere server connection using the given sqlca
   It can be accessed later by using sqlanywhere_pconnect( '' )
   Only one of thse may exist at a time.
   This should only be used by the SQLAnywhere PHP External Environment driver
*/
PHP_FUNCTION(sasql_pconnect_from_sqlca)
/**************************************/
{
    zval ** zv_sqlca;
    void *sqlca;
    sqlany_connection_t * sqlany_conn;
    char * hashed_details = sasql_HASH_STR;
    zend_rsrc_list_entry new_le;
    zend_rsrc_list_entry * le = NULL;

    if( !api.initialized ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, DBCAPI_NOT_FOUND_ERROR );
	RETURN_FALSE;
    }

    if( ( ZEND_NUM_ARGS() != 1 ) || 
        ( zend_get_parameters_array_ex( 1, &zv_sqlca ) != SUCCESS ) ) {
        WRONG_PARAM_COUNT;
    }

    /* we convert to long because we expect the zval struct to have type long
     * but the value should be stored in str.val (because it could be a 64-bit
     * pointer as opposed to a long int)
     */
    convert_to_long_ex( zv_sqlca );
    sqlca = (void*)Z_STRVAL_PP(zv_sqlca);

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_pconnect_from_sqlca( sqlca = %p )", 
		sqlca ) );

    /* try to find if we already have this link in our persistent list */
    if ( zend_hash_find( &EG(persistent_list), hashed_details,
                         strlen( hashed_details ) + 1, 
                         (void **) &le ) != FAILURE ) {
        /* we already have this connection, so we fail 
         * this seems to be better than silently returning the connection
         * that uses a different sqlca from what was passed in
         * which would cause confusion
         */
	_debug_enabled( SQLAnyDebug( _LOCATION_, 
		    " sqlanywhere_pconnect_from_sqlca return FALSE" ) );
        RETURN_FALSE;
    }

    /* actually create the connection */
    sqlany_conn = calloc( 1, sizeof(sqlany_connection_t));
    if( sqlany_conn == NULL ) {
        RETURN_FALSE;
    }
    if( SAG(context) ) {
	sqlany_conn->handle = api.sqlany_make_connection_ex( SAG(context), sqlca );
    } else {
	sqlany_conn->handle = api.sqlany_make_connection( sqlca );
    }
    if( sqlany_conn->handle == NULL ) {
        RETURN_FALSE;
    }

    sqlany_conn->persistent = 1;
    sqlany_conn->auto_commit = SAG(auto_commit);
    sqlany_conn->verbose_errors = SAG(verbose_errors);
    sqlany_conn->id = 0;
    sqlany_conn->result_list = NULL;
    sqlany_conn->ext_env_conn = 1;
    
    new_le.type = le_pconn;
    new_le.ptr  = sqlany_conn;
    if( zend_hash_update( &EG( persistent_list ), hashed_details, 
                          strlen( hashed_details ) + 1, (void *) &new_le, 
                          sizeof( zend_rsrc_list_entry ), NULL ) == FAILURE ) {
        /* we don't want to close the connection because it
         * belongs to someone else */
        api.sqlany_free_connection( sqlany_conn->handle );
        efree( sqlany_conn );
        RETURN_FALSE;
    }

    sqlany_conn->id = zend_list_insert(sqlany_conn, le_pconn TSRMLS_CC);

    SAG( num_pconns )++;
    SAG( num_conns )++;
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_pconnect_from_sqlca return %d", 
		sqlany_conn->id ) );
    RETURN_LONG( sqlany_conn->id );
}
/* }}} */

/* {{{ proto bool sasql_close( sasql_conn $conn )
   Closes a connection */
PHP_FUNCTION(sasql_close)
/*****************************/
{
    zval ** arg;
    sqlany_connection_t * sqlany_conn;
    zend_rsrc_list_entry * le;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg, -1, "SQLAnywhere connection", 
	    le_conn, le_pconn );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_discconnect( %d )", sqlany_conn->id ) );

    if ( zend_hash_find( &EG(persistent_list),  sasql_HASH_STR,
		strlen( sasql_HASH_STR ) + 1,
		(void **) &le ) != FAILURE  &&
	    (sqlany_connection_t *)(le->ptr) == sqlany_conn ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING,
		"Supplied argument 1 (%ld) refers to the default connection, which cannot be closed"
		, Z_LVAL_PP(arg) );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_close=>FALSE" ) );
	RETURN_FALSE;
    }

    zend_list_delete( Z_LVAL_PP(arg) );
    RETURN_TRUE;
}
/* }}} */

static
int sasql_real_query( sqlany_connection_t * sqlany_conn, char * query TSRMLS_DC )
/********************************************************************************/
{
    if( sqlany_conn->last_stmt != NULL ) {
	/* Before we open a new statement, make sure we close the previous default
	 * statement if and only if it's associated result set has been freed.
	 * When the result set gets closed and it's statement is not the default
	 * statement then the statement will be closed then. We need to keep the
	 * default statement around in case the user wants to call sasql_next_result()
	 * on the connection.
	 */
	sqlany_result_t * curr = sqlany_conn->result_list;
	int		  found = 0;
	while( curr != NULL ) {
	    if( curr->stmt_handle == sqlany_conn->last_stmt ) {
		found = 1;
		break;
	    }
	    curr = curr->next;
	}
	if( !found ) {
	    api.sqlany_free_stmt( sqlany_conn->last_stmt );
	}
    }
    sqlany_conn->last_stmt = api.sqlany_execute_direct( sqlany_conn->handle, query );
    save_conn_error( sqlany_conn );
    if( sqlany_conn->last_stmt == NULL ) {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " ssasql_real_query=>FALSE [%s]",
		    sqlany_conn->error ) );
	return 0;
    }

    if( api.sqlany_num_cols( sqlany_conn->last_stmt ) == 0 && 
	    sqlany_conn->auto_commit ) {
	api.sqlany_commit( sqlany_conn->handle );
    }
    return 1;
}

/* {{{ proto bool sasql_real_query( sasql_conn $conn, string $sql_str )
   Execute a query */
PHP_FUNCTION(sasql_real_query)
/****************************/
{
    zval ** args[2];
    sqlany_connection_t * sqlany_conn;

    switch( ZEND_NUM_ARGS() ) {
	case 2:
	    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    convert_to_string_ex( args[1] );
	    break;
	default:
	    WRONG_PARAM_COUNT;
	    break;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_real_query( conn=%d, sql=%s )", 
		sqlany_conn->id, Z_STRVAL_PP(args[1]) ) );

    if( sasql_real_query( sqlany_conn, Z_STRVAL_PP(args[1]) TSRMLS_CC ) ) {
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto mixed sasql_query(int conn, char * sql_str [, int $result_mode ] )
   Execute a query */
PHP_FUNCTION(sasql_query)
/************************/
{
    zval ** 		  args[3];
    sqlany_connection_t * sqlany_conn;
    sqlany_result_t * 	  sqlany_result;
    int			  store_result;
    int 		  rc;

    switch( ZEND_NUM_ARGS() ) {
	case 3:
	    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    convert_to_long_ex( args[2] );
	    convert_to_string_ex( args[1] );
	    store_result = Z_LVAL_PP(args[2]);
	    break;
	case 2:
	    args[2] = NULL;
	    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    store_result = 1;
	    convert_to_string_ex( args[1] );
	    break;
	default:
	    WRONG_PARAM_COUNT;
	    break;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query( conn=%d, sql=%s )", 
		sqlany_conn->id, Z_STRVAL_PP(args[1]) ) );


    if( !sasql_real_query( sqlany_conn, Z_STRVAL_PP(args[1]) TSRMLS_CC ) ) {
	RETURN_FALSE;
    }

    if( api.sqlany_num_cols( sqlany_conn->last_stmt ) == 0 ) {
	RETURN_TRUE;
    }

    // otherwise, create a result object
    sqlany_result = (sqlany_result_t *)ecalloc( 1, sizeof(sqlany_result_t) );
    sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
    sqlany_result->sqlany_conn = sqlany_conn;
    sqlany_result->stmt_handle = sqlany_conn->last_stmt;
    sqlany_result->num_cols = api.sqlany_num_cols( sqlany_result->stmt_handle );
    sqlany_result->num_rows = api.sqlany_num_rows( sqlany_result->stmt_handle );
    sqlany_result->next = sqlany_conn->result_list;
    sqlany_conn->result_list = sqlany_result;

    if( !store_result ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query=>%d use_result", 
		    sqlany_result->id ) );
	RETURN_RESOURCE( sqlany_result->id );
    } 

    rc = cache_result( sqlany_result );
    if( rc == 100 || rc == 0 ) {
	rc = 0;
	clear_conn_error( sqlany_conn );
    } else {
	save_conn_error( sqlany_conn );
    }
    if( rc >= 0 ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query:err=%d", rc ) );
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_commit( sqlany_conn->handle );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query:auto commit", sqlany_result->id ) );
	}
    } else {
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_rollback( sqlany_conn->handle );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query:auto commit", sqlany_result->id ) );
	}
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_query=>%d stored_result", sqlany_result->id ) );
    RETURN_RESOURCE( sqlany_result->id );
}
/* }}} */

/* {{{ proto mixed sasql_store_result( sasql_conn $conn )
   Execute a query */
PHP_FUNCTION(sasql_store_result)
/******************************/
{
    zval ** args[1];
    sqlany_connection_t * sqlany_conn;
    sqlany_result_t * 	  sqlany_result;
    int			  rc;

    switch( ZEND_NUM_ARGS() ) {
	case 1:
	    if( zend_get_parameters_array_ex( 1, args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    break;
	default:
	    WRONG_PARAM_COUNT;
	    break;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_store_result( conn=%d, sql=%s )", 
		sqlany_conn->id, Z_STRVAL_PP(args[1]) ) );

    if( sqlany_conn->last_stmt == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "No previous result to store" );
	RETURN_FALSE;
    }

    if( api.sqlany_num_cols( sqlany_conn->last_stmt ) == 0 ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "Previous query does not return a result" );
	RETURN_FALSE;
    }

    // otherwise, create a result object
    sqlany_result = (sqlany_result_t *)ecalloc( 1, sizeof(sqlany_result_t) );
    sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
    sqlany_result->sqlany_conn = sqlany_conn;
    sqlany_result->stmt_handle = sqlany_conn->last_stmt;
    sqlany_result->num_cols = api.sqlany_num_cols( sqlany_result->stmt_handle );
    sqlany_result->next = sqlany_conn->result_list;
    sqlany_conn->result_list = sqlany_result;

    rc = cache_result( sqlany_result );
    if( rc == 100 || rc == 0 ) {
	rc = 0;
	clear_conn_error( sqlany_conn );
    } else {
	save_conn_error( sqlany_conn );
    }

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_store_result:err=%d", rc ) );
    if( rc >= 0 ) {
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_commit( sqlany_conn->handle );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_store_result:auto commit", sqlany_result->id ) );
	}
    } else {
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_rollback( sqlany_conn->handle );
	    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_store_result:auto rolling back", sqlany_result->id ) );
	}
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_store_result=>%d", sqlany_result->id ) );
    RETURN_RESOURCE( sqlany_result->id );
}
/* }}} */

/* {{{ proto sasql_result sasql_use_result( sasql_conn $conn )
   */
PHP_FUNCTION(sasql_use_result)
/******************************/
{
    zval ** args[1];
    sqlany_connection_t * sqlany_conn;
    sqlany_result_t * 	  sqlany_result;

    switch( ZEND_NUM_ARGS() ) {
	case 1:
	    if( zend_get_parameters_array_ex( 1, args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    break;
	default:
	    WRONG_PARAM_COUNT;
	    break;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_use_result( conn=%d, sql=%s )", 
		sqlany_conn->id, Z_STRVAL_PP(args[1]) ) );

    if( sqlany_conn->last_stmt == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "No previous result to store" );
	RETURN_FALSE;
    }

    if( api.sqlany_num_cols( sqlany_conn->last_stmt ) == 0 ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "Previous query does not return a result" );
	RETURN_FALSE;
    }

    // otherwise, create a result object
    sqlany_result = (sqlany_result_t *)ecalloc( 1, sizeof(sqlany_result_t) );
    sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
    sqlany_result->sqlany_conn = sqlany_conn;
    sqlany_result->stmt_handle = sqlany_conn->last_stmt;
    sqlany_result->num_cols = api.sqlany_num_cols( sqlany_result->stmt_handle );
    sqlany_result->num_rows = api.sqlany_num_rows( sqlany_result->stmt_handle );
    sqlany_result->next = sqlany_conn->result_list;
    sqlany_conn->result_list = sqlany_result;

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_use_result=>%d", sqlany_result->id ) );
    RETURN_RESOURCE( sqlany_result->id );
}
/* }}} */

/* {{{ proto bool sasql_next_result( sasql_conn $conn )
   Retrieves the next result set */
PHP_FUNCTION(sasql_next_result)
/******************************/
{
    zval ** args[1];
    sqlany_connection_t * sqlany_conn;
    int     ok;

    switch( ZEND_NUM_ARGS() ) {
	case 1:
	    if( zend_get_parameters_array_ex( 1, args ) == FAILURE ) {
		WRONG_PARAM_COUNT;
	    }
	    break;
	default:
	    WRONG_PARAM_COUNT;
	    break;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_next_result( conn=%d, sql=%s )", 
		sqlany_conn->id, Z_STRVAL_PP(args[1]) ) );

    if( sqlany_conn->last_stmt == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "No previous result to store" );
	RETURN_FALSE;
    }

    ok = api.sqlany_get_next_result( sqlany_conn->last_stmt );
    if( api.sqlany_error( sqlany_conn->handle, NULL, 0 ) == 105 ) {
	clear_conn_error( sqlany_conn );
    } else {
	save_conn_error( sqlany_conn );
    }

    if( ok ) {
	sqlany_result_t * sqlany_result = (sqlany_result_t *)ecalloc( 1, sizeof(sqlany_result_t) ); 
	sqlany_result->num_cols = api.sqlany_num_cols( sqlany_conn->last_stmt );
	sqlany_result->num_rows = api.sqlany_num_rows( sqlany_conn->last_stmt );
	sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
	sqlany_result->sqlany_conn = sqlany_conn;
	sqlany_result->next = sqlany_conn->result_list;
	sqlany_result->sqlany_stmt = NULL;
	sqlany_result->stmt_handle = sqlany_conn->last_stmt;
	sqlany_conn->result_list = sqlany_result;
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_next_result=>TRUE" ) );
	RETURN_TRUE;
    } else {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_next_result=>FALSE" ) );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_free_result( sasql_result $result )
   Free result memory */
PHP_FUNCTION(sasql_free_result)
/******************************/
{
    zval ** arg1;
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }

    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, arg1, -1, "SQLAnywhere result", 
	    le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_free_result( %d )", sqlany_result->id ) );

    zend_list_delete( sqlany_result->id ); 
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_free_result=>SUCCESS" ) );
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto bool sasql_data_seek(int result, int row_num)
   Move internal row pointer */
PHP_FUNCTION(sasql_data_seek)
/****************************/
{
    zval ** args[2];
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 2) || (zend_get_parameters_array_ex(2,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    convert_to_long_ex( args[1] );
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, args[0], -1, 
	    "SQLAnywhere result", le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_data_seek( %d, %d )", 
		sqlany_result->id, Z_LVAL_PP( args[1] ) ) );

    if( !sqlany_result->result_cached ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"sasql_data_seek() cannot be used with a result object returned from sasql_use_result()" );
	RETURN_FALSE;
    }

    if( result_data_seek( sqlany_result, Z_LVAL_PP(args[1]), 1 ) ) {
	RETURN_TRUE;
    }
    RETURN_FALSE;
}
/* }}} */


/* {{{ proto int sasql_num_rows( sasql_result $result )
   Get number of rows in result, FALSE if the result was not stored! */
PHP_FUNCTION(sasql_num_rows)
/********************************/
{
    zval ** arg1;
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, arg1, -1, "SQLAnywhere result", 
	    le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_num_rows( %d )", sqlany_result->id ) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_num_rows=>%d", sqlany_result->num_rows ) );
    RETURN_LONG( sqlany_result->num_rows );
}
/* }}} */

/* {{{ proto int sasql_affected_rows( sasql_conn $conn )
   Get number of rows affected by the SQL statement. */
PHP_FUNCTION(sasql_affected_rows)
/********************************/
{
    zval ** arg1;
    sqlany_connection_t	* sqlany_conn;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_affected_rows( %d )", sqlany_conn->id ) );

    if( sqlany_conn->last_stmt != NULL ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_affected_rows=>%d", 
		    api.sqlany_affected_rows( sqlany_conn->last_stmt ) ) );
	RETURN_LONG( api.sqlany_affected_rows( sqlany_conn->last_stmt ) );
    } else {
	RETURN_LONG( 0 );
    }
}
/* }}} */

/* {{{ proto int sasql_field_count( sasql_conn $conn )
   Get number of columns from the last statement */
PHP_FUNCTION(sasql_field_count)
/********************************/
{
    zval ** arg1;
    sqlany_connection_t	* sqlany_conn;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_field_count( %d )", sqlany_conn->id ) );

    if( sqlany_conn->last_stmt != NULL ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_field_count=>%d", 
		    api.sqlany_affected_rows( sqlany_conn->last_stmt ) ) );
	RETURN_LONG( api.sqlany_num_cols( sqlany_conn->last_stmt ) );
    } else {
	RETURN_LONG( 0 );
    }
}
/* }}} */

/* {{{ proto bool sasql_field_seek(sasql result, int field_offset )
   Set result pointer to a specified field offset */
PHP_FUNCTION(sasql_field_seek)
/******************************/
{
    zval ** args[2];
    int col_num = 0;
    sqlany_result_t *sqlany_result;

    if(ZEND_NUM_ARGS() != 2 ) {
	WRONG_PARAM_COUNT;
    }
    if (zend_get_parameters_array_ex(2, args) != SUCCESS) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, args[0], -1, "SQLAnywhere result", le_result );
    convert_to_long_ex(args[1]);

    col_num = Z_LVAL_PP(args[1]);

    if( col_num < 0 || col_num >= sqlany_result->num_cols ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"SQLAnywhere: Bad column offset (%d) min = 0, max = %d", col_num, sqlany_result->num_cols -1 );
	RETURN_FALSE;
    }

    sqlany_result->curr_col = col_num;
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto int sasql_fetch_field(int result [, field_offset] ) 
   Get field information */
PHP_FUNCTION(sasql_fetch_field)
/******************************/
{
    zval **args[2];
    int col_num = 0;
    sqlany_result_t *sqlany_result;
    a_sqlany_column_info cinfo;

    switch (ZEND_NUM_ARGS()) {
	case 2:
	    if (zend_get_parameters_array_ex(2, args) != SUCCESS) {
		WRONG_PARAM_COUNT;
	    }
	    convert_to_long_ex(args[1]);
	    col_num = Z_LVAL_PP(args[1]) ;
	    break;

	case 1:
	    if (zend_get_parameters_array_ex(1, args) != SUCCESS) {
		WRONG_PARAM_COUNT;
	    }
	    break;

	default:
	    WRONG_PARAM_COUNT;
	    break;
    }
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, args[0], -1, "SQLAnywhere result", le_result );

    switch( ZEND_NUM_ARGS() ) {
	case 1:
	    col_num = sqlany_result->curr_col;
	    if( col_num >= sqlany_result->num_cols ) {
		RETURN_FALSE;
	    }
	    sqlany_result->curr_col++;
	    break;

	case 2:
	    if( col_num < 0 || col_num >= sqlany_result->num_cols ) {
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"SQLAnywhere: Bad column offset (%d) min = 0, max = %d", col_num, sqlany_result->num_cols -1 );
		RETURN_FALSE;
	    }
	    sqlany_result->curr_col = col_num + 1;
	    break;

	default:
	    WRONG_PARAM_COUNT;
	    break;
    }

    if( !result_get_column_info( sqlany_result, col_num, &cinfo ) ) {
	RETURN_FALSE;
    }

    if( object_init( return_value ) == FAILURE ) {
	RETURN_FALSE;
    }

    add_property_long( return_value, "id", col_num );
    add_property_string( return_value, "name", cinfo.name, 1 );
    switch( cinfo.type ) {
	case A_STRING:
	    add_property_long( return_value, "numeric", 0 );
	    add_property_string( return_value, "type", "string", 1 );
	    break;
	case A_BINARY:
	    add_property_long( return_value, "numeric", 0 );
	    add_property_string( return_value, "type", "blob", 1 );
	    break;
	case A_DOUBLE:
	    add_property_long( return_value, "numeric", 1 );
	    add_property_string( return_value, "type", "double", 1 );
	    break;
	case A_VAL64:
	case A_UVAL64:
	case A_VAL32:
	case A_UVAL32:
	case A_VAL16:
	case A_UVAL16:
	case A_VAL8:
	case A_UVAL8:
	    add_property_long( return_value, "numeric", 1 );
	    add_property_string( return_value, "type", "int", 1 );
	    break;
	default:
	    add_property_long( return_value, "numeric", 0 );
	    add_property_string( return_value, "type", "unknown", 1 );
    }
    switch( cinfo.native_type ) {
	case DT_NOTYPE:
	    add_property_string( return_value, "native_type", "DT_NOTYPE", 1 );
	    break;
	case DT_DATE:
	    add_property_string( return_value, "native_type", "DT_DATE", 1 );
	    break;
	case DT_TIME:
	    add_property_string( return_value, "native_type", "DT_TIME", 1 );
	    break;
	case DT_TIMESTAMP:
	    add_property_string( return_value, "native_type", "DT_TIMESTAMP", 1 );
	    break;
	case DT_VARCHAR:
	    add_property_string( return_value, "native_type", "DT_VARCHAR", 1 );
	    break;
	case DT_FIXCHAR:
	    add_property_string( return_value, "native_type", "DT_FIXCHAR", 1 );
	    break;
	case DT_LONGVARCHAR:
	    add_property_string( return_value, "native_type", "DT_LONGVARCHAR", 1 );
	    break;
	case DT_STRING:
	    add_property_string( return_value, "native_type", "DT_STRING", 1 );
	    break;
	case DT_DOUBLE:
	    add_property_string( return_value, "native_type", "DT_DOUBLE", 1 );
	    break;
	case DT_FLOAT:
	    add_property_string( return_value, "native_type", "DT_FLOAT", 1 );
	    break;
	case DT_DECIMAL:
	    add_property_string( return_value, "native_type", "DT_DECIMAL", 1 );
	    add_property_long( return_value, "precision", cinfo.precision );
	    add_property_long( return_value, "scale", cinfo.scale );
	    break;
	case DT_INT:
	    add_property_string( return_value, "native_type", "DT_INT", 1 );
	    break;
	case DT_SMALLINT:
	    add_property_string( return_value, "native_type", "DT_SMALLINT", 1 );
	    break;
	case DT_BINARY:
	    add_property_string( return_value, "native_type", "DT_BINARY", 1 );
	    break;
	case DT_LONGBINARY:
	    add_property_string( return_value, "native_type", "DT_LONGBINARY", 1 );
	    break;
	case DT_TINYINT:
	    add_property_string( return_value, "native_type", "DT_TINYINT", 1 );
	    break;
	case DT_BIGINT:
	    add_property_string( return_value, "native_type", "DT_BIGINT", 1 );
	    break;
	case DT_UNSINT:
	    add_property_string( return_value, "native_type", "DT_UNSINT", 1 );
	    break;
	case DT_UNSSMALLINT:
	    add_property_string( return_value, "native_type", "DT_UNSSMALLINT", 1 );
	    break;
	case DT_UNSBIGINT:
	    add_property_string( return_value, "native_type", "DT_UNSBIGINT", 1 );
	    break;
	case DT_BIT:
	    add_property_string( return_value, "native_type", "DT_BIT", 1 );
	    break;
	default:
	    add_property_string( return_value, "native_type", "unknown", 1 );
	    break;
    }
    /* FIXME: do something about the length and type fields, now they return numbers 
       corresponding to database data type which is not meaningfull in php scripts */
    add_property_long( return_value, "length", cinfo.max_size );
}
/* }}} */

static
void assign_from_sqlany_value( zval * tmp, a_sqlany_data_value * sqlany_value )
/****************************************************************************/
{
    char buffer[128];

    if( *(sqlany_value->is_null) ) {
	tmp->type = IS_NULL;
	return;
    }

    switch( sqlany_value->type ) {
	case A_STRING:
	case A_BINARY:
	    tmp->value.str.len = *(sqlany_value->length);
	    tmp->value.str.val = emalloc( tmp->value.str.len + 1 );
	    memcpy( tmp->value.str.val, sqlany_value->buffer, tmp->value.str.len );
	    tmp->value.str.val[tmp->value.str.len] = '\0';
	    tmp->type = IS_STRING;
	    break;

	case A_VAL64:
	    if( (*(sasql_int64 *)sqlany_value->buffer) >= -INT_MAX && 
		    (*(sasql_int64 *)sqlany_value->buffer) <= INT_MAX ) {
		tmp->value.lval = *(sasql_int64 *)sqlany_value->buffer;
		tmp->type = IS_LONG;
	    } else {
		php_sprintf( buffer, "%"SA_FMT64"d", *(sasql_int64*)sqlany_value->buffer );
		tmp->value.str.len = strlen( buffer );
		tmp->value.str.val = emalloc( tmp->value.str.len + 1 );
		memcpy( tmp->value.str.val, buffer, tmp->value.str.len );
		tmp->value.str.val[tmp->value.str.len] = '\0';
		tmp->type = IS_STRING;
	    }
	    break;

	case A_UVAL64:
	    if( (*(sasql_uint64 *)sqlany_value->buffer) <= INT_MAX ) {
		tmp->value.lval = *(sasql_uint64 *)sqlany_value->buffer;
		tmp->type = IS_LONG;
	    } else {
		php_sprintf( buffer, "%"SA_FMT64"u", *(sasql_uint64*)sqlany_value->buffer );
		tmp->value.str.len = strlen( buffer );
		tmp->value.str.val = emalloc( tmp->value.str.len + 1 );
		memcpy( tmp->value.str.val, buffer, tmp->value.str.len );
		tmp->value.str.val[tmp->value.str.len] = '\0';
		tmp->type = IS_STRING;
	    }
	    break;

	case A_DOUBLE:
	    tmp->value.dval = *(double *)sqlany_value->buffer;
	    tmp->type = IS_DOUBLE;
	    break;

	case A_VAL32:
	    tmp->value.lval = *(int *)sqlany_value->buffer;
	    tmp->type = IS_LONG;
	    break;
	case A_UVAL32:
	    if( (*(unsigned int*)sqlany_value->buffer) <= INT_MAX ) {
		tmp->value.lval = *(unsigned int *)sqlany_value->buffer;
		tmp->type = IS_LONG;
	    } else {
		php_sprintf( buffer, "%u", *(unsigned int*)sqlany_value->buffer );
		tmp->value.str.val = estrdup( buffer );
		tmp->value.str.len = strlen( buffer );
		tmp->type = IS_STRING;
	    }
	    break;
	case A_VAL16:
	    tmp->value.lval = *(short *)sqlany_value->buffer;
	    tmp->type = IS_LONG;
	    break;
	case A_UVAL16:
	    tmp->value.lval = *(unsigned short *)sqlany_value->buffer;
	    tmp->type = IS_LONG;
	    break;
	case A_VAL8:
	    tmp->value.lval = *(char *)sqlany_value->buffer;
	    tmp->type = IS_LONG;
	    break;
	case A_UVAL8:
	    tmp->value.lval = *(unsigned char *)sqlany_value->buffer;
	    tmp->type = IS_LONG;
	    break;
	default:
	    break;
    }
}

static 
void sasql_fetch_hash(INTERNAL_FUNCTION_PARAMETERS, int result_type )
/********************************************************************/
{
    zval ** 		  arg1;
    zval *		  tmp;
    sqlany_result_t	* sqlany_result;
    int 		  i;
    int 		  rc;

    if( zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }

    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, arg1, -1, "SQLAnywhere result", 
	    le_result );

    rc = result_fetch_next( sqlany_result, 1 );
    if( rc == 0 || rc == -1 ) {
	RETURN_FALSE;
    }

    if( array_init( return_value ) == FAILURE ) {
	RETURN_FALSE;
    }

    for( i = 0; i < sqlany_result->num_cols; i++ ) {
	a_sqlany_data_value dvalue;
	result_get_column_data( sqlany_result, i, &dvalue );

	ALLOC_INIT_ZVAL( tmp );
	Z_SET_REFCOUNT_P( tmp, 0 );
	assign_from_sqlany_value( tmp, &dvalue );
	if( result_type & FETCH_ROW ) {
	    Z_ADDREF_P( tmp );
	    zend_hash_index_update( Z_ARRVAL_P(return_value),
		    i,
		    (void *)&tmp, sizeof(zval*), NULL );
	}
	if( result_type & FETCH_OBJ ) {
	    a_sqlany_column_info cinfo;

	    result_get_column_info( sqlany_result, i, &cinfo );

	    Z_ADDREF_P( tmp );
	    zend_hash_update( Z_ARRVAL_P(return_value),
		    cinfo.name,
		    strlen( cinfo.name ) + 1,
		    (void *)&tmp, sizeof(zval*), NULL );
	}
    }
}

/* {{{ proto array sasql_fetch_array( sasql_result $result )
   Fetch result row as an associative array */
PHP_FUNCTION(sasql_fetch_array)
/******************************/
{
    zval ** args[2];
    int result_type = (FETCH_ROW|FETCH_OBJ);
    if( ZEND_NUM_ARGS() > 2 ) {
	WRONG_PARAM_COUNT;
    }
    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT
    }
    if( ZEND_NUM_ARGS() == 2 ) {
	convert_to_long_ex( args[1] );
	result_type = Z_LVAL_PP(args[1]);
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_array started " ) );
    sasql_fetch_hash( INTERNAL_FUNCTION_PARAM_PASSTHRU, result_type );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_array finish " ) );
}
/* }}} */

/* {{{ proto array sasql_fetch_assoc( sasql_result $result )
   Fetch result row as an associative array */
PHP_FUNCTION(sasql_fetch_assoc)
/******************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_assoc started " ) );
    sasql_fetch_hash( INTERNAL_FUNCTION_PARAM_PASSTHRU, FETCH_OBJ );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_assoc finish " ) );
}
/* }}} */

/* {{{ proto object sasql_fetch_object( sasql_result $result )
   Get row as object */
PHP_FUNCTION(sasql_fetch_object)
/*******************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_object started " ) );
    sasql_fetch_hash( INTERNAL_FUNCTION_PARAM_PASSTHRU, FETCH_OBJ );
    if(Z_TYPE_P(return_value)==IS_ARRAY) {
	object_and_properties_init( return_value, ZEND_STANDARD_CLASS_DEF_PTR, 
		Z_ARRVAL_P(return_value));
    }
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_object finish " ) );
}
/* }}} */

/* {{{ proto array sasql_fetch_row( sasql_result $result )
   Get row as enumerated array */
PHP_FUNCTION(sasql_fetch_row)
/****************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_row started " ) );
    sasql_fetch_hash( INTERNAL_FUNCTION_PARAM_PASSTHRU, FETCH_ROW );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_fetch_row finished " ) );
}
/* }}} */

/* {{{ proto bool sasql_commit( sasql_conn $conn )
   commit transaction on a onnection */
PHP_FUNCTION(sasql_commit)
/*************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;
    int ok;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, 
	    "SQLAnywhere connection resource", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_commit( %d )", sqlany_conn->id ));

    ok = api.sqlany_commit( sqlany_conn->handle );
    save_conn_error( sqlany_conn );
    if( ok ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_commit=>SUCCESS" ) );
	RETURN_TRUE;
    } else {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_commit=>FALSE" ) );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_rollback(int conn)
   rollback a transaction on a onnection */
PHP_FUNCTION(sasql_rollback)
/***************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;
    int ok;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, "SQLAnywhere connection resource", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_rollback( %d )", sqlany_conn->id ) );

    ok = api.sqlany_rollback( sqlany_conn->handle );
    save_conn_error( sqlany_conn );
    if( ok ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_rollback=>SUCCESS" ) );
	RETURN_TRUE;
    } else {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_rollback=>FALSE" ) );
	RETURN_FALSE;
    }
}
/* }}} */

typedef struct {
    int	   option_code;
    char * option_name;
    int	   option_type;
} option_setting;

#define OPT_NO_TYPE	0x0	
#define OPT_TRUEFALSE	0x00000001
#define OPT_ONOFF	0x00000002
#define OPT_NUMBER	0x00000004
#define OPT_STRING	0x00000008

#define OPC_AUTO_COMMIT		1
#define OPC_VERBOSE_ERRORS 	2
#define OPC_ROW_COUNTS		3

option_setting sqlany_php_options[] = 
{
    { OPC_AUTO_COMMIT, 		"auto_commit",    OPT_TRUEFALSE|OPT_ONOFF },
    { OPC_VERBOSE_ERRORS, 	"verbose_errors", OPT_TRUEFALSE|OPT_ONOFF },
    { OPC_ROW_COUNTS, 		"row_counts", 	  OPT_TRUEFALSE|OPT_ONOFF },
    { 0, NULL, 0 }
};

/* {{{ proto bool sasql_set_option(conn, option, value)
   set an option to a specific value */
PHP_FUNCTION(sasql_set_option)
/*****************************/
{
    zval ** args[3];
    int i;
    sqlany_connection_t * sqlany_conn;

    if(( ZEND_NUM_ARGS() <= 2) || 
	    ( zend_get_parameters_array_ex(3,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    convert_to_string_ex( args[1] );

    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_set_option( %d, %s )", 
		sqlany_conn->id, Z_STRVAL_PP( args[1] ) ) );

    i = 0;
    while( sqlany_php_options[i].option_name != NULL ) 
    {
	if( zend_binary_strcasecmp( Z_STRVAL_PP(args[1]), Z_STRLEN_PP(args[1]), 
		    sqlany_php_options[i].option_name, 
		    strlen(sqlany_php_options[i].option_name) ) == 0 )  
	{
	    int option_type = sqlany_php_options[i].option_type;
	    int option_code = sqlany_php_options[i].option_code;
	    zval option_value;


	    if( option_type & OPT_ONOFF ) {
		convert_to_string_ex( args[2] );
		if( zend_binary_strcasecmp( Z_STRVAL_PP(args[2]), Z_STRLEN_PP(args[2]),
			    "on", strlen( "on" ) ) == 0 ) {
		    ZVAL_BOOL( &option_value, 1 );
		    option_type  = 0;
		}
		if( zend_binary_strcasecmp( Z_STRVAL_PP(args[2]), Z_STRLEN_PP(args[2]),
			    "off", strlen( "off" ) ) == 0 ) {
		    ZVAL_BOOL( &option_value, 0 );
		    option_type  = 0;
		}
	    }

	    if( option_type & OPT_TRUEFALSE ) {
		convert_to_boolean_ex( args[2] );
		ZVAL_BOOL( &option_value, Z_BVAL_PP(args[2]) );
		option_type  = 0;
	    }

	    if( option_type & OPT_NUMBER ) {
		convert_to_long_ex( args[2] );
		ZVAL_LONG( &option_value, Z_LVAL_PP(args[2]) );
		option_type  = 0;
	    }

	    if( option_type & OPT_STRING ) {
		convert_to_string_ex( args[2] );
		ZVAL_STRING( &option_value, Z_STRVAL_PP(args[2]), 0);
		option_type  = 0;
	    }

	    if( option_type == 0 )
		switch( option_code ) 
		{
		    case OPC_ROW_COUNTS :
			{
			    char sql[256];
			    if( Z_BVAL_P(&option_value) ) {
				php_sprintf( sql, "SET OPTION ROW_COUNTS = 'on'" );
			    } else {
				php_sprintf( sql, "SET OPTION ROW_COUNTS = 'off'" );
			    }
			    if( api.sqlany_execute_immediate( sqlany_conn->handle, sql ) ) {
				RETURN_TRUE;
			    } else {
				VerboseErrors( sqlany_conn TSRMLS_CC );
				RETURN_FALSE;
			    }
			}
			break;

		    case OPC_VERBOSE_ERRORS :
			sqlany_conn->verbose_errors = ( Z_BVAL_P(&option_value) ? 1 : 0 );
			RETURN_TRUE;
			break;

		    case OPC_AUTO_COMMIT :
			sqlany_conn->auto_commit = ( Z_BVAL_P(&option_value) ? 1 : 0 );
			RETURN_TRUE;
			break;

		    default:
			RETURN_FALSE;
		}
	}
	i++;
    }

    php_error_docref(NULL TSRMLS_CC, E_WARNING, "Unknown option (%s)", Z_STRVAL_PP(args[1]) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_set_option=>FALSE" ) );
    RETURN_FALSE;
}
/* }}} */

/* {{{ proto int sasql_errorcode([int conn])
   returns the error code on the specified connection or the global error code */
PHP_FUNCTION(sasql_errorcode)
/****************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;

    if( !api.initialized ) {
	RETURN_FALSE;
    }

    if( ZEND_NUM_ARGS() == 1 ) {
	if( (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	    WRONG_PARAM_COUNT;
	}
	ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, "SQLAnywhere connection", le_conn, le_pconn );
	RETURN_LONG( sqlany_conn->errorcode );
    } else {
	RETURN_LONG( SAG(error_code) );
    }
}
/* }}} */

/* {{{ proto string sasql_error([int conn])
   returns the error msg on the specified connection or the global error code */
PHP_FUNCTION(sasql_error)
/************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;
    char * msg;

    if( !api.initialized ) {
	RETURN_STRING( DBCAPI_NOT_FOUND_ERROR, 1 );
    }

    if( ZEND_NUM_ARGS() == 1 ) {
	if( (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	    WRONG_PARAM_COUNT;
	}
	ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, "SQLAnywhere connection", le_conn, le_pconn );
	RETURN_STRING( sqlany_conn->error, 1 );
    } else {
	RETURN_STRING( SAG(error), 1 );
    }
}
/* }}} */

/* {{{ proto string sasql_sqlstate( sasql_conn $conn )
   returns the sqlstate of the speicifed connection */
PHP_FUNCTION(sasql_sqlstate)
/****************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;

    if( !api.initialized ) {
	RETURN_STRING( DBCAPI_NOT_FOUND_ERROR, 1 );
    }

    if( ZEND_NUM_ARGS() == 1 ) {
	if( (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	    WRONG_PARAM_COUNT;
	}
	ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, 
		"SQLAnywhere connection", le_conn, le_pconn );
	RETURN_STRINGL(sqlany_conn->sqlstate, sqlany_conn->len, 1);
    } else {
	RETURN_STRING( SAG(sqlstate), 1 );
    }
}
/* }}} */

static
int get_identity( sqlany_connection_t * sqlany_conn, zval * value ) 
/******************************************************************/
{
    a_sqlany_stmt * 	stmt_handle;
    a_sqlany_data_value dvalue;

    stmt_handle = api.sqlany_execute_direct( sqlany_conn->handle, "select @@identity" );
    if( stmt_handle == NULL ) {
	return 0;
    }
    if( !api.sqlany_fetch_next( stmt_handle ) ) {
	api.sqlany_free_stmt( stmt_handle );
	return 0;
    }
    if( !api.sqlany_get_column( stmt_handle, 0, &dvalue ) ) {
	api.sqlany_free_stmt( stmt_handle );
	return 0;
    }

    assign_from_sqlany_value( value, &dvalue );
    api.sqlany_free_stmt( stmt_handle );

    return 1;
}

static 
void SQLAnywhereIdentity( INTERNAL_FUNCTION_PARAMETERS )
/*******************************************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;

    if( (ZEND_NUM_ARGS() != 1) || 
	    (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, arg1, -1, "SQLAnywhere connection", le_conn, le_pconn );

    if( !get_identity( sqlany_conn, return_value ) ) {
	save_conn_error( sqlany_conn );
	RETURN_FALSE;
    }
}

/* {{{ proto int sasql_insert_id( sasql_conn $conn )
   returns the id generated from the previous insert operation */
PHP_FUNCTION(sasql_insert_id)
/****************************/
{
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_insert_id started " ) );
    SQLAnywhereIdentity( INTERNAL_FUNCTION_PARAM_PASSTHRU );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_insert_id finished " ) );
}
/* }}} */

/* {{{ proto bool sasql_message(conn, message)
   send a message to the console */
PHP_FUNCTION(sasql_message)
/**************************/
{
    sqlany_connection_t * sqlany_conn;
    char		* sql;
    int			  rc;
    zval	       ** args[2];

    if( (ZEND_NUM_ARGS() != 2) || 
	    (zend_get_parameters_array_ex(2,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, "SQLAnywhere connection", le_conn, le_pconn );

    convert_to_string_ex( args[1] );

    sql = emalloc( Z_STRLEN_PP(args[1]) + 10 );
    php_sprintf( sql, "message %s", Z_STRVAL_PP(args[1]) );
    rc = api.sqlany_execute_immediate( sqlany_conn->handle, sql );
    save_conn_error( sqlany_conn );
    efree( sql );
    if( rc ) {
	RETURN_TRUE;
    } else {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto sasql_stmt sasql_prepare( saconn $conn, string $sql )
   prepares the supplied query and returns a stmt handle */
PHP_FUNCTION(sasql_prepare)
/**************************/
{
    zval ** args[2];
    sqlany_connection_t * sqlany_conn;
    sqlany_stmt_t	* sqlany_stmt;

    if( ( ZEND_NUM_ARGS() != 2) || (zend_get_parameters_array_ex(2, args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );

    convert_to_string_ex( args[1] );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_prepare( conn=%d, sql=%s )", 
		Z_LVAL_PP( args[0] ), Z_STRVAL_PP(args[1]) ) );

    sqlany_stmt = (sqlany_stmt_t*)emalloc( sizeof(sqlany_stmt_t) );
    memset( sqlany_stmt, 0, sizeof(sqlany_stmt_t));
    clear_stmt_error( sqlany_stmt );

    sqlany_stmt->handle = api.sqlany_prepare( sqlany_conn->handle, Z_STRVAL_PP(args[1]) );
    save_conn_error( sqlany_conn );
    if( sqlany_stmt->handle == NULL ) {
	/* failed to prepare */
	VerboseErrors( sqlany_conn TSRMLS_CC );
	efree( sqlany_stmt );
	_debug_enabled( SQLAnyDebug( _LOCATION_, 
		    " sasql_query=>FALSE [%s]", sqlany_conn->error ); )
	RETURN_FALSE;
    }

    sqlany_stmt->id = zend_list_insert( sqlany_stmt, le_stmt TSRMLS_CC);
    sqlany_stmt->sqlany_conn = sqlany_conn;
    sqlany_stmt->num_params = api.sqlany_num_params( sqlany_stmt->handle );
    if( sqlany_stmt->num_params > 0 ) {
	sqlany_stmt->sqlany_params = (sqlany_stmt_param_t*)
	    ecalloc( sqlany_stmt->num_params, sizeof(sqlany_stmt_param_t) );
	sqlany_stmt->php_params = (php_stmt_param_t*)ecalloc( sqlany_stmt->num_params, sizeof(php_stmt_param_t) );
    }
    sqlany_stmt->next = sqlany_conn->stmt_list;
    sqlany_conn->stmt_list = sqlany_stmt;
    RETURN_RESOURCE( sqlany_stmt->id );
}
/* }}} */

/* {{{ proto int sasql_stmt_param_count( sasql $stmt )
   returns the number of parameters expected for the prepared statement stmt */
PHP_FUNCTION(sasql_stmt_param_count)
/***********************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_param_count( stmt=%d )", 
		sqlany_stmt->id ) );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_param_count=>[%d]", 
		sqlany_stmt->num_params ) );

    RETURN_LONG( sqlany_stmt->num_params );
}
/* }}} */

/* {{{ proto bool sasql_stmt_bind_param( stmt, types, &$var1 [, &$var2 ... ] );
   bind parameter to be used by prepared statement */
/* stmt statement handle
 * type is string of d,i,b,s
 * variables 
 */
PHP_FUNCTION(sasql_stmt_bind_param)
/**********************************/
{
    zval *** args;
    sqlany_stmt_t	* sqlany_stmt;
    int			  i;
    int			  param_number;
    int			  ok;

    if( ZEND_NUM_ARGS() < 3 ) {
	WRONG_PARAM_COUNT;
    }

    args = (zval ***)safe_emalloc( ZEND_NUM_ARGS(), sizeof(zval **), 0 );

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	efree( args );
	WRONG_PARAM_COUNT;
    }
    convert_to_string_ex( args[1] );
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( ZEND_NUM_ARGS() - 2 != Z_STRLEN_PP(args[1] ) ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"The num of type characters supplied (%d) does not match the number of parameters supplied (%d)",  
		Z_STRLEN_PP( args[1]), ZEND_NUM_ARGS() - 2 );
	efree( args );
	RETURN_FALSE;
    }

    if( (ZEND_NUM_ARGS() -2) > sqlany_stmt->num_params ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"More parameters supplied (%d) than expected (%d)", ZEND_NUM_ARGS() - 2, sqlany_stmt->num_params );
	efree( args );
	RETURN_FALSE;
    }

    // do a sanity check that the field types is valid.
    for( i = 0; i < Z_STRLEN_PP(args[1]); i++ ) {
	char field_type = Z_STRVAL_PP(args[1])[i];
	switch( field_type ) {
	    case 'd': case 'i': case 'b': case 's':
		break;
	    default:
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"Undefined fieldtype %c (parameter %d)", field_type, i+1 );
		efree( args );
		RETURN_FALSE;
	}
    }
    
    param_number = 0;
    for( i = 2; i < ZEND_NUM_ARGS(); i++ ) {
	a_sqlany_bind_param	param;
	char 			field_type = Z_STRVAL_PP(args[1])[i-2];

	ok = api.sqlany_describe_bind_param( sqlany_stmt->handle, param_number, &param );
	save_stmt_error( sqlany_stmt );
	if( !ok ) {
	    efree( args );
	    RETURN_FALSE;
	}
	
	if( param.direction & DD_OUTPUT ) {
	    a_sqlany_bind_param output;

	    output.direction = DD_OUTPUT;
	    output.name = NULL;
	    output.value.is_null = &(sqlany_stmt->sqlany_params[param_number].out_is_null);
	    output.value.length  = &(sqlany_stmt->sqlany_params[param_number].out_len);
	    switch( field_type ) {
		case 'd':
		    convert_to_double_ex( args[i] );
		    output.value.buffer = (char *)&Z_DVAL_PP(args[i]);
		    output.value.buffer_size = 4;
		    output.value.type = A_DOUBLE;
		    break;
		case 'i':
            convert_to_long_ex( args[i] );
		    output.value.buffer = (char *)&Z_LVAL_PP(args[i]);
		    if( sizeof(Z_LVAL_PP(args[i])) == 4 ) {
			output.value.type = A_VAL32;
			output.value.buffer_size = 4;
		    } else {
			output.value.type = A_VAL64;
			output.value.buffer_size = 8;
		    }
		    break;
		case 's':
		case 'b':
		    {
			// param.value.buffer_size is already set by the describe_bind_param
			char * buffer = emalloc( param.value.buffer_size + 1 );
			if( ZVAL_IS_NULL(*args[i]) ) {
			    memset( buffer, 0, param.value.buffer_size + 1 );
			    Z_STRLEN_PP(args[i]) = 0;
			} else {
			    convert_to_string_ex( args[i] );
			    memcpy( buffer, Z_STRVAL_PP(args[i]), Z_STRLEN_PP(args[i]) );
			    buffer[Z_STRLEN_PP(args[i])] = '\0';
			    efree( Z_STRVAL_PP(args[i]) );
			}
			Z_STRVAL_PP(args[i]) = buffer;
			Z_TYPE_PP(args[i]) = IS_STRING;
		    }
		    output.value.type = ( field_type == 's' ? A_STRING : A_BINARY );
		    output.value.buffer = (char *)Z_STRVAL_PP(args[i]);
		    output.value.buffer_size = param.value.buffer_size;
		    (*output.value.length) = Z_STRLEN_PP(args[i]);
		    break;
	    }
	    Z_ADDREF_P(*args[i]);
	    sqlany_stmt->php_params[param_number].out = *args[i];
	    sqlany_stmt->sqlany_params[param_number].out = output.value;

	    ok = api.sqlany_bind_param( sqlany_stmt->handle, param_number, &output );
	    save_stmt_error( sqlany_stmt );
	    if( !ok ) {
		efree( args );
		RETURN_FALSE;
	    }
	}
	if( param.direction & DD_INPUT ) {
	    a_sqlany_bind_param input;

	    input.direction = DD_INPUT;
	    input.name = NULL;
	    input.value.is_null = &(sqlany_stmt->sqlany_params[param_number].in_is_null);
	    input.value.length  = &(sqlany_stmt->sqlany_params[param_number].in_len);
	    input.value.buffer_size = 0;
	    if( ZVAL_IS_NULL(*args[i]) ) {
		(*input.value.is_null) = 1;
		(*input.value.length) = 0;
		input.value.buffer = NULL;
		switch( field_type ) {
		    case 'd': input.value.type = A_DOUBLE; break;
		    case 'i': input.value.type = A_VAL32; break;
		    case 'b': input.value.type = A_BINARY; break;
		    case 's': input.value.type = A_STRING; break;
		}
	    } else {
		(*input.value.is_null) = 0;
		switch( field_type ) {
		    case 'd':
			convert_to_double_ex( args[i] );
			input.value.buffer = (char *)&Z_DVAL_PP(args[i]);
			input.value.type = A_DOUBLE;
			break;
		    case 'i':
			convert_to_long_ex( args[i] );
			input.value.buffer = (char *)&Z_LVAL_PP(args[i]);
			if( sizeof(Z_LVAL_PP(args[i])) == 4 ) {
			    input.value.type = A_VAL32;
			} else {
			    input.value.type = A_VAL64;
			}
			break;
		    case 'b':
		    case 's':
			convert_to_string_ex( args[i] );
			(*input.value.length) = Z_STRLEN_PP(args[i]);
			input.value.type = ( field_type == 's' ? A_STRING : A_BINARY );
			input.value.buffer = (char *)Z_STRVAL_PP(args[i]);
			break;
		}
	    }
	    Z_ADDREF_P(*args[i]);
	    sqlany_stmt->php_params[param_number].in = *args[i];
	    sqlany_stmt->sqlany_params[param_number].in = input.value;

	    ok = api.sqlany_bind_param( sqlany_stmt->handle, param_number, &input );
	    save_stmt_error( sqlany_stmt );
	    if( !ok ) {
		efree( args );
		RETURN_FALSE;
	    }
	}
#if 0
	if( ZVAL_IS_NULL(*args[i]) ) {
	    param.value.buffer = NULL;
	    param.value.length = NULL;
	    switch( field_type ) {
		case 'd': param.value.type = A_DOUBLE; break;
		case 'i': param.value.type = A_VAL32; break;
		case 'b': param.value.type = A_BINARY; break;
		case 's': param.value.type = A_STRING; break;
		default:
		    php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			    "Undefined fieldtype %c (parameter %d)", field_type, i+1 );
		    efree( args );
		    RETURN_FALSE;
	    }
	} else {
	    switch( field_type ) {
		case 'd':
		    convert_to_double_ex( args[i] );
		    param.value.buffer = (char *)&Z_DVAL_PP(args[i]);
		    param.value.type = A_DOUBLE;
		    break;
		case 'i':
		    convert_to_long_ex( args[i] );
		    param.value.buffer = (char *)&Z_LVAL_PP(args[i]);
		    if( sizeof(Z_LVAL_PP(args[i])) == 4 ) {
			param.value.type = A_VAL32;
		    } else {
			param.value.type = A_VAL64;
		    }
		    break;
		case 'b':
		case 's':
		    convert_to_string_ex( args[i] );
		    if( param.direction & DD_OUTPUT ) {
			char * buffer = emalloc( param.value.buffer_size + 1 );
			memcpy( buffer, Z_STRVAL_PP(args[i]), Z_STRLEN_PP(args[i]) );
			buffer[Z_STRLEN_PP(args[i])] = '\0';
			efree( Z_STRVAL_PP(args[i]) );
			Z_STRVAL_PP(args[i]) = buffer;
			// param.value.buffer_size is already set by the describe_bind_param
			Z_TYPE_PP(args[i]) = IS_STRING;
		    }
		    sqlany_stmt->sqlany_params[param_number].in_len = Z_STRLEN_PP(args[i]);

		    param.value.type = ( field_type == 's' ? A_STRING : A_BINARY );
		    param.value.buffer = (char *)Z_STRVAL_PP(args[i]);
		    param.value.length = &(sqlany_stmt->sqlany_params[param_number].in_len);
		    break;
		default:
		    php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			    "Undefined fieldtype %c (parameter %d)", field_type, i+1 );
		    efree( args );
		    RETURN_FALSE;
	    }
	}
	if( param.direction & DD_INPUT ) {
	    param.value.is_null = &sqlany_stmt->sqlany_params[param_number].in_is_null;
	    *(param.value.is_null) = ZVAL_IS_NULL(*args[i]);
	}
	if( param.direction & DD_OUTPUT ) {
	    param.value.is_null = &sqlany_stmt->sqlany_params[param_number].out_is_null;
	    *(param.value.is_null) = ZVAL_IS_NULL(*args[i]);
	}

	ok = api.sqlany_bind_param( sqlany_stmt->handle, param_number, &param );
	save_stmt_error( sqlany_stmt );
	if( !ok ) {
	    efree( args );
	    RETURN_FALSE;
	}
	if( param.direction & DD_INPUT ) {
	    Z_ADDREF_P(*args[i]);
	    sqlany_stmt->php_params[param_number].in = *args[i];
	    sqlany_stmt->sqlany_params[param_number].in = param.value;
	}
	if( param.direction & DD_OUTPUT ) {
	    Z_ADDREF_P(*args[i]);
	    sqlany_stmt->php_params[param_number].out = *args[i];
	    sqlany_stmt->sqlany_params[param_number].out = param.value;
	}
#endif
	param_number++;
    }
    efree( args );
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto bool sasql_stmt_bind_param_ex( sasql $stmt, int $param_id, mixed $var, string $type [ bool is_null [, int $direction]] )
   bind parameter to be used by prepared statement */
/* var is the reference to PHP variable
 * type is d,i,b,s
 * is_null true or false
 * direction is SASQL_D_INPUT, SASQL_D_OUTPUT, or SASQL_D_INPUT_OUTPUT
 */
PHP_FUNCTION(sasql_stmt_bind_param_ex)
/*************************************/
{
    zval ** 		args[6];
    sqlany_stmt_t	*sqlany_stmt;
    a_sqlany_bind_param	param;
    a_sqlany_bind_param	desc_info;
    int			param_number;
    int			is_null = 0;
    int			ok;
    
    if( ZEND_NUM_ARGS() < 4 || ZEND_NUM_ARGS() > 6 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args ) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }

    param.value.is_null = NULL;
    param.direction = DD_INPUT;
    switch( ZEND_NUM_ARGS() ) {
	case 6:
	    // 5 direction
	    convert_to_long_ex( args[5] );
	    switch( Z_LVAL_PP(args[5]) ) {
		case 1:
		    param.direction = DD_INPUT;
		    break;
		case 2:
		    param.direction = DD_OUTPUT;
		    break;
		case 3:
		    param.direction = DD_INPUT_OUTPUT;
		    break;
		default:
		    php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			    "Argument 6 is not valid. Direction could only be 1,2, or 3"  );
		    RETURN_FALSE;
	    }
	case 5:
	    // 4 is_null
	    convert_to_boolean_ex( args[4] );
	    is_null = Z_BVAL_PP(args[4]);
	    break;
	case 4:
	    // 3 type
	    // 2 var
	    // 1 param_num
	    // 0 stmt
	    convert_to_string_ex( args[3] );
	    convert_to_long_ex( args[1] );
	    break;
	default:
	    WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );
    
    param_number = Z_LVAL_PP(args[1]);

    if( param_number >= sqlany_stmt->num_params ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Argument 2 (%d) is not valid. Expecting a number between 0 and %d", 
		param_number, sqlany_stmt->num_params - 1 );
	RETURN_FALSE;
    }
    param_number = Z_LVAL_PP(args[1]);
    
    ok = api.sqlany_describe_bind_param( sqlany_stmt->handle, param_number, &desc_info );
    save_stmt_error( sqlany_stmt );
    if( !ok ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Failed to find information about statement parameters" );
	RETURN_FALSE;
    }

    if( param.direction & DD_INPUT ) {
	param.value.is_null = &sqlany_stmt->sqlany_params[param_number].in_is_null;
    }
    if( param.direction & DD_OUTPUT ) {
	param.value.is_null = &sqlany_stmt->sqlany_params[param_number].out_is_null;
    }
    *(param.value.is_null) = is_null;

    switch( Z_STRVAL_PP(args[3])[0] ) {
	case 'd':
        if( !is_null ) {
            convert_to_double_ex( args[2] );
        }
	    param.value.type = A_DOUBLE;
	    param.value.buffer = (char *)&Z_DVAL_PP(args[2]);
	    break;
	case 'i':
        if( !is_null ) {
            convert_to_long_ex( args[2] );
        }
	    param.value.type = A_VAL32;
	    param.value.buffer = (char *)&Z_LVAL_PP(args[2]);
	    break;
	case 'b':
	    if( param.direction & DD_OUTPUT ) {
		char * buffer = emalloc( desc_info.value.buffer_size + 1 );
		memcpy( buffer, Z_STRVAL_PP(args[2]), Z_STRLEN_PP(args[2]) );
		buffer[Z_STRLEN_PP(args[2])] = '\0'; 
		efree( Z_STRVAL_PP(args[2]) );
		Z_STRVAL_PP(args[2]) = buffer;
		param.value.buffer_size = (size_t)desc_info.value.buffer_size;
	    } else {
		param.value.buffer_size = (size_t)Z_STRLEN_PP(args[2]);
	    }
	    param.value.type = A_BINARY;
	    param.value.buffer = (char *)Z_STRVAL_PP(args[2]);
	    param.value.length = (size_t*)&Z_STRLEN_PP(args[2]);
	    break;
	case 's':
	    if( param.direction & DD_OUTPUT ) {
		char * buffer = emalloc( desc_info.value.buffer_size + 1 );
		memcpy( buffer, Z_STRVAL_PP(args[2]), Z_STRLEN_PP(args[2]) );
		buffer[Z_STRLEN_PP(args[2])] = '\0'; 
		efree( Z_STRVAL_PP(args[2]) );
		Z_STRVAL_PP(args[2]) = buffer;
		param.value.buffer_size = (size_t)desc_info.value.buffer_size;
	    } else {
		param.value.buffer_size = (size_t)Z_STRLEN_PP(args[2]);
	    }
	    param.value.type = A_STRING;
	    param.value.buffer = (char *)Z_STRVAL_PP(args[2]);
	    param.value.length = (size_t*)&Z_STRLEN_PP(args[2]);
	    break;
	default:
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Unrecognized type information '%s'.", Z_STRVAL_PP(args[3]) );
	RETURN_FALSE;
    }
    
    ok = api.sqlany_bind_param( sqlany_stmt->handle, param_number, &param );
    save_stmt_error( sqlany_stmt );
    if( ok ) {
	if( param.direction & DD_INPUT ) {
	    Z_ADDREF_P(*args[2]);
	    sqlany_stmt->php_params[param_number].in = *args[2];
	    sqlany_stmt->sqlany_params[param_number].in = param.value;
	}
	if( param.direction & DD_OUTPUT ) {
	    Z_ADDREF_P(*args[2]);
	    sqlany_stmt->php_params[param_number].out = *args[2];
	    sqlany_stmt->sqlany_params[param_number].out = param.value;
	}
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_stmt_execute( sasql $stmt )
   sasql_stmt_execute() is used to execute a prepared statemtn */
PHP_FUNCTION(sasql_stmt_execute)
/*******************************/
{
    zval ** arg1;
    sqlany_connection_t * sqlany_conn;
    sqlany_stmt_t	* sqlany_stmt;
    sqlany_result_t	* sqlany_result;
    int			  rc;
    int			  i;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }
    if( zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );

    sqlany_conn = sqlany_stmt->sqlany_conn;

    // We have to rebind all A_STRING and A_BINARY input variables because they could change in size.
    for( i = 0; i < sqlany_stmt->num_params; i++ ) {
	if( sqlany_stmt->php_params[i].out != NULL && 
	    (sqlany_stmt->sqlany_params[i].out.type == A_BINARY ||
		    sqlany_stmt->sqlany_params[i].out.type == A_STRING ) &&
		sqlany_stmt->sqlany_params[i].out.buffer != Z_STRVAL_P(sqlany_stmt->php_params[i].out) ) {
	    a_sqlany_bind_param param;
	    a_sqlany_bind_param desc_info;
	    char		*buffer;

	    rc = api.sqlany_describe_bind_param( sqlany_stmt->handle, i, &desc_info );
	    save_stmt_error( sqlany_stmt );
	    if( !rc ) {
		php_error_docref(NULL TSRMLS_CC, E_WARNING, 
			"Failed to find information about statement parameters" );
		RETURN_FALSE;
	    }

	    buffer = emalloc( desc_info.value.buffer_size + 1 );
	    strcpy( buffer, Z_STRVAL_P(sqlany_stmt->php_params[i].out) );
	    efree( Z_STRVAL_P(sqlany_stmt->php_params[i].out) );
	    Z_STRVAL_P(sqlany_stmt->php_params[i].out) = buffer;
	    // don't change Z_STRLEN_P( of the out pointer )
	    sqlany_stmt->sqlany_params[i].out.buffer = (char *)Z_STRVAL_P(sqlany_stmt->php_params[i].out);
	    sqlany_stmt->sqlany_params[i].out.buffer_size = (size_t)desc_info.value.buffer_size;
	    sqlany_stmt->sqlany_params[i].out.length = &(sqlany_stmt->sqlany_params[i].out_len);

	    param.direction = DD_OUTPUT;
	    param.value = sqlany_stmt->sqlany_params[i].out;
	    api.sqlany_bind_param( sqlany_stmt->handle, i, &param );
	    save_stmt_error( sqlany_stmt );
	}
	if( sqlany_stmt->php_params[i].in != NULL && 
		sqlany_stmt->sqlany_params[i].using_send_data == 0 ) {
	    a_sqlany_bind_param param;

	    if( ZVAL_IS_NULL( sqlany_stmt->php_params[i].in ) ) {
		*(sqlany_stmt->sqlany_params[i].in.is_null) = 1;
	    } else {
		*(sqlany_stmt->sqlany_params[i].in.is_null) = 0;
		switch( sqlany_stmt->sqlany_params[i].in.type ) {
		    case A_STRING:
		    case A_BINARY:
			if( Z_TYPE_P(sqlany_stmt->php_params[i].in) != IS_STRING ) {
			    convert_to_string_ex( &sqlany_stmt->php_params[i].in );
			}
			sqlany_stmt->sqlany_params[i].in_len = Z_STRLEN_P(sqlany_stmt->php_params[i].in);
			sqlany_stmt->sqlany_params[i].in.buffer = Z_STRVAL_P(sqlany_stmt->php_params[i].in);
			sqlany_stmt->sqlany_params[i].in.length = &(sqlany_stmt->sqlany_params[i].in_len);
			break;
		    case A_VAL32:
		    case A_VAL64:
			sqlany_stmt->sqlany_params[i].in.type = 
			    ( sizeof(Z_LVAL_P(sqlany_stmt->php_params[i].in)) == 4 ?  A_VAL32 : A_VAL64 );
			sqlany_stmt->sqlany_params[i].in.buffer = (char *)&Z_LVAL_P(sqlany_stmt->php_params[i].in);
			break;
		    case A_DOUBLE:
			sqlany_stmt->sqlany_params[i].in.buffer = (char *)&Z_DVAL_P(sqlany_stmt->php_params[i].in);
			break;
		    default:
			break;
		}
	    }

	    param.direction = DD_INPUT;
	    param.value = sqlany_stmt->sqlany_params[i].in;
	    api.sqlany_bind_param( sqlany_stmt->handle, i, &param );
	    save_stmt_error( sqlany_stmt );
	}
    }
    if( sqlany_stmt->sqlany_result != NULL ) {
	zend_list_delete( sqlany_stmt->sqlany_result->id );
	assert( sqlany_stmt->sqlany_result == NULL );
    }
    
    rc = api.sqlany_execute( sqlany_stmt->handle );
    save_stmt_error( sqlany_stmt );
    if( rc == 0 ) {
	if( sqlany_conn->verbose_errors ) {
	    php_error_docref( NULL TSRMLS_CC, E_WARNING, "SQLAnywhere: [%d] %s", 
		    (int)sqlany_stmt->errorcode, sqlany_stmt->error );
	}
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_execute=>FALSE [%s]", 
		    sqlany_stmt->error ) );
	RETURN_FALSE;
    }

    if( api.sqlany_num_cols( sqlany_stmt->handle ) != 0 ) {
	sqlany_result = ecalloc( 1, sizeof(sqlany_result_t) );
	sqlany_result->num_cols = api.sqlany_num_cols( sqlany_stmt->handle );
	sqlany_result->num_rows = api.sqlany_num_rows( sqlany_stmt->handle );
	sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC);
	sqlany_result->sqlany_conn = sqlany_conn;
	sqlany_result->next = sqlany_conn->result_list;
	sqlany_result->sqlany_stmt = sqlany_stmt;
	sqlany_result->stmt_handle = sqlany_stmt->handle;
	sqlany_conn->result_list = sqlany_result;
	sqlany_stmt->sqlany_result = sqlany_result;
    } else {
	for( i = 0; i < sqlany_stmt->num_params; i++ ) {
	    if( sqlany_stmt->php_params[i].out != NULL && 
		    (sqlany_stmt->sqlany_params[i].out.type == A_BINARY ||
		     sqlany_stmt->sqlany_params[i].out.type == A_STRING ) ) {
		Z_STRLEN_P(sqlany_stmt->php_params[i].out) = sqlany_stmt->sqlany_params[i].out_len;
	    }
	}
	sqlany_stmt->sqlany_result = NULL;
    }
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto bool sasql_stmt_close( sasql $stmt )
   sasql_stmt_close() is used to close a prepared statement */
PHP_FUNCTION(sasql_stmt_close)
/*****************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 || zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_close( %d )", sqlany_stmt->id ) );

    zend_list_delete( sqlany_stmt->id );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_close=>SUCCESS" ) );
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto sasql_result sasql_stmt_result_metadata( sasql $stmt )
   sasql_stmt_result_metadata() is used to retrieve the result object associated with the stmt object */
PHP_FUNCTION(sasql_stmt_result_metadata)
/***************************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 || zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result != NULL ) {
	RETURN_RESOURCE( sqlany_stmt->sqlany_result->id );
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto int sasql_stmt_affected_rows( sasql $stmt )
   sasql_stmt_affected_rows() is used to retrieve the number of rows affected by the last sasql_stmt_execute() */
PHP_FUNCTION(sasql_stmt_affected_rows)
/***************************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;
    int			  ok;

    if( ZEND_NUM_ARGS() != 1 || zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", 
	    le_stmt );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_result_metadata( %d )", 
		sqlany_stmt->id ) );
    ok = api.sqlany_affected_rows( sqlany_stmt->handle );
    save_stmt_error( sqlany_stmt );
    RETURN_LONG( ok );
}
/* }}} */

/* {{{ proto int sasql_stmt_num_rows( sasql $stmt )
   sasql_stmt_num_rows() is used to retrieve the number of rows retreived by the last prepared statement */
PHP_FUNCTION(sasql_stmt_num_rows)
/***************************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 || zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_result_metadata( %d )", 
		sqlany_stmt->id ) );

    if( sqlany_stmt->sqlany_result ) {
	if( sqlany_stmt->sqlany_result->curr_row != NULL ) {
	    RETURN_LONG( sqlany_stmt->sqlany_result->num_rows );
	} else {
	    RETURN_LONG( 0 );
	}
    } else {
        RETURN_LONG( 0 );
    }
}
/* }}} */

/* {{{ proto int sasql_stmt_insert_id( sasql $stmt )
   sasql_stmt_insert_id() is used to retrieve the last inserted identity value */
PHP_FUNCTION(sasql_stmt_insert_id)
/***************************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 || zend_get_parameters_array_ex(1,&arg1) != SUCCESS ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_stmt_result_metadata( %d )", 
		sqlany_stmt->id ) );

    if( !get_identity( sqlany_stmt->sqlany_conn, return_value ) ) {
	save_stmt_error( sqlany_stmt );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_stmt_bind_result( sasql $stmt, mixed &$var1 [, mixed &$var2 ...] )
   sasql_stmt_bind_result() binds user supplied variables to result data */
PHP_FUNCTION(sasql_stmt_bind_result)
/***************************************/
{
    zval *** args;
    sqlany_stmt_t	* sqlany_stmt;
    int			  num_cols;
    int			  i;

    if( ZEND_NUM_ARGS() < 2 ) {
	WRONG_PARAM_COUNT;
    }

    args = (zval ***)safe_emalloc( ZEND_NUM_ARGS(), sizeof(zval **), 0 );

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	efree( args );
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    num_cols = api.sqlany_num_cols( sqlany_stmt->handle );
    if( num_cols == 0 ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Supplied statement does not return a result set" );
	efree( args );
	RETURN_FALSE;
    }

    if( (ZEND_NUM_ARGS() -1) > num_cols ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"More variables (%d) supplied than can be bound (%d)", ZEND_NUM_ARGS() -1, num_cols );
	efree( args );
	RETURN_FALSE;
    }

    if( sqlany_stmt->php_result_vars ) {
	for( i = 0; i < sqlany_stmt->num_result_vars; i++ ) {
	    Z_DELREF_P( sqlany_stmt->php_result_vars[i] );
	}
	efree( sqlany_stmt->php_result_vars );
	sqlany_stmt->num_result_vars = 0;
    }
    sqlany_stmt->num_result_vars = num_cols;
    sqlany_stmt->php_result_vars = ecalloc( num_cols, sizeof(zval*) );

    for( i = 1; i < ZEND_NUM_ARGS(); i++ ) {
	Z_ADDREF_P( *args[i] );
	sqlany_stmt->php_result_vars[i-1] = *args[i];
    }
    efree( args );
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto bool sasql_stmt_send_long_data( sasql_stmt $stmt, int $param_num, string $data )
   sasql_stmt_send_long_data() allow the user to send the data of a buffer in chunks */
PHP_FUNCTION(sasql_stmt_send_long_data)
/***************************************/
{
    zval ** args[3];
    sqlany_stmt_t	* sqlany_stmt;
    int			  i;
    int			  ok;

    if( ZEND_NUM_ARGS() != 3 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    convert_to_string_ex( args[2] );
    convert_to_long_ex( args[1] );
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    i = Z_LVAL_PP(args[1]);

    if( i >= sqlany_stmt->num_params ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Supplied argument 2 (%ld) is not a valid parameter number", Z_LVAL_PP(args[1]) );
	RETURN_FALSE;
    }

    if( sqlany_stmt->php_params[i].in == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Parameter number %d must be bound first using sasql_stmt_bind_param", i+1 );
	RETURN_FALSE;
    }
    sqlany_stmt->sqlany_params[i].using_send_data = 1;

    ok = api.sqlany_send_param_data( sqlany_stmt->handle, 
	    i, Z_STRVAL_PP(args[2]), Z_STRLEN_PP(args[2]) );
    save_stmt_error( sqlany_stmt );
    if( ok ) {
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_stmt_store_result( sasql_stmt $stmt )
   sasql_stmt_store_result() save the result set in the client */
PHP_FUNCTION(sasql_stmt_store_result)
/************************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    int			rc;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result == NULL ) {
	// The query does not return a result set
	RETURN_FALSE;
    }

    rc = cache_result( sqlany_stmt->sqlany_result );
    if( rc == 100 || rc == 0 ) {
	rc = 0;
	clear_stmt_error( sqlany_stmt );
    } else {
	save_stmt_error( sqlany_stmt );
    }
    if( sqlany_stmt->sqlany_result->num_rows > 0 || rc >= 0 ) {
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_stmt_free_result( sasql_stmt $stmt )
   sasql_stmt_free_result() frees the result set from the client */
PHP_FUNCTION(sasql_stmt_free_result)
/************************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result == NULL ) {
	RETURN_TRUE;
    }

    free_cached_result( sqlany_stmt->sqlany_result );
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto bool sasql_stmt_reset( sasql_stmt $stmt )
   sasql_stmt_reset() resets the statement to it's prepared state */
PHP_FUNCTION(sasql_stmt_reset)
/*****************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    int			ok;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    ok = api.sqlany_reset( sqlany_stmt->handle );
    save_stmt_error( sqlany_stmt );
    if( ok ) {
	//FIXME: free the result object and unbind all PHP zvals
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */
/* {{{ proto bool sasql_stmt_fetch( sasql_stmt $stmt )
   sasql_stmt_fetch() fetches the next result set */
PHP_FUNCTION(sasql_stmt_fetch)
/*****************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    sqlany_result_t	* sqlany_result;
    int			  i;
    int			  rc;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result == NULL ) {
	RETURN_FALSE;
    }
    sqlany_result = sqlany_stmt->sqlany_result;

    rc = result_fetch_next( sqlany_result, 0 );
    if( rc == 0 || rc == -1 ) {
	RETURN_FALSE;
    }

    if( sqlany_stmt->php_result_vars == NULL ) {
	// No variables were bound
	RETURN_TRUE;
    }

    for( i = 0; i < sqlany_result->num_cols; i++ ) {
	zval * zvalue;
	if( (zvalue = sqlany_stmt->php_result_vars[i]) != NULL ) {
	    a_sqlany_data_value dvalue;
	   
	    result_get_column_data( sqlany_result, i, &dvalue );

	    if( Z_TYPE_P(zvalue) == IS_STRING ) {
		efree( zvalue->value.str.val );
	    }

	    assign_from_sqlany_value( zvalue, &dvalue );
	}
    }
    RETURN_TRUE;
}
/* }}} */

/* {{{ proto int sasql_stmt_field_count( sasql_stmt $stmt )
   sasql_stmt_field_count() returns the number of columns */
PHP_FUNCTION(sasql_stmt_field_count)
/**********************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result == NULL ) {
	RETURN_LONG( 0 );
    }

    sqlany_stmt->sqlany_result->num_cols = api.sqlany_num_cols( sqlany_stmt->handle );
    RETURN_LONG( sqlany_stmt->sqlany_result->num_cols );
}
/* }}} */

/* {{{ proto bool sasql_stmt_data_seek( sasql_stmt $stmt, int $offset )
   sasql_stmt_data_seek() returns true or false */
PHP_FUNCTION(sasql_stmt_data_seek)
/**********************************/
{
    zval ** args[2];
    sqlany_stmt_t	* sqlany_stmt;
    sqlany_result_t	* sqlany_result;

    if( ZEND_NUM_ARGS() != 2 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    convert_to_long_ex( args[1] );
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Statement does not generate a result set" );
	RETURN_FALSE;
    }
    if( sqlany_stmt->sqlany_result->curr_row == NULL ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, 
		"Must call sasql_stmt_store_result() before attempting to call sasql_stmt_data_seek()" );
	RETURN_FALSE;
    }

    sqlany_result = sqlany_stmt->sqlany_result;

    if( Z_LVAL_PP(args[1]) >= sqlany_result->num_rows ) {
	php_error_docref(NULL TSRMLS_CC, E_WARNING, "Invalid seek offset (%ld)", Z_LVAL_PP(args[1]) );
	RETURN_FALSE;
    }

    if( result_data_seek( sqlany_result, Z_LVAL_PP(args[1]), 0 ) ) {
	RETURN_TRUE;
    }
    RETURN_FALSE;
}
/* }}} */

/* {{{ proto bool sasql_stmt_next_result( sasql $stmt )
   sasql_stmt_next_result() if there is another result it it will advance to next result set and return true, otherwise false */
PHP_FUNCTION(sasql_stmt_next_result)
/**********************************/
{
    zval ** arg1;
    sqlany_stmt_t	* sqlany_stmt;
    int			ok;

    if( ZEND_NUM_ARGS() != 1 || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS) ) {
	WRONG_PARAM_COUNT;
    }
    
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, arg1, -1, "SQLAnywhere statement", le_stmt );

    if( sqlany_stmt->sqlany_result ) {
	zend_list_delete( sqlany_stmt->sqlany_result->id );
    }
    assert( sqlany_stmt->sqlany_result == NULL );

    ok = api.sqlany_get_next_result( sqlany_stmt->handle );
    save_stmt_error( sqlany_stmt );
    if( ok ) {
	sqlany_result_t * sqlany_result = (sqlany_result_t *)ecalloc( 1, sizeof(sqlany_result_t) ); 
	sqlany_result->num_cols = api.sqlany_num_cols( sqlany_stmt->handle );
	sqlany_result->num_rows = api.sqlany_num_cols( sqlany_stmt->handle );
	sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
	sqlany_result->sqlany_conn = sqlany_stmt->sqlany_conn;
	sqlany_result->next = sqlany_stmt->sqlany_conn->result_list;
	sqlany_result->sqlany_stmt = sqlany_stmt;
	sqlany_result->stmt_handle = sqlany_stmt->handle;
	sqlany_stmt->sqlany_conn->result_list = sqlany_result;
	sqlany_stmt->sqlany_result = sqlany_result;
	RETURN_TRUE;
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_stmt_errno( sasql_stmt $stmt )
   sasql_stmt_errno() retrieves the last errno code stmt */
PHP_FUNCTION(sasql_stmt_errno)
/*****************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    int			  i;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", 
	    le_stmt );
    RETURN_LONG(sqlany_stmt->errorcode);
}
/* }}} */

/* {{{ proto bool sasql_stmt_error( sasql_stmt $stmt )
   sasql_stmt_error() retrieves the last error message from stmt */
PHP_FUNCTION(sasql_stmt_error)
/*****************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    int			  i;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", 
	    le_stmt );
    RETURN_STRING( sqlany_stmt->error, 1 );
}
/* }}} */

/* {{{ proto bool sasql_stmt_sqlstate( sasql_stmt $stmt )
   sasql_stmt_sqlstate() retrieves the last sqlstate from stmt */
PHP_FUNCTION(sasql_stmt_sqlstate)
/*****************************/
{
    zval ** args[1];
    sqlany_stmt_t	* sqlany_stmt;
    int			  i;

    if( ZEND_NUM_ARGS() != 1 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_stmt, sqlany_stmt_t*, args[0], -1, "SQLAnywhere statement", 
	    le_stmt );
    RETURN_STRING( sqlany_stmt->sqlstate, 1 );
}
/* }}} */


/* {{{ proto string sasql_real_escape_string( saconn $conn, string $escapestr )
   sasql_real_escape_string() escape a string for use in a SQL statement */
PHP_FUNCTION(sasql_real_escape_string)
/************************************/
{
    zval ** args[2];
    sqlany_connection_t	* sqlany_conn;
    int			  i;
    char *		  source;
    char *		  dest;
    int			  dest_len = 0;

    if( ZEND_NUM_ARGS() != 2 ) {
	WRONG_PARAM_COUNT;
    }

    if( zend_get_parameters_array_ex( ZEND_NUM_ARGS(), args) == FAILURE ) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    convert_to_string_ex( args[1] );

    source = Z_STRVAL_PP(args[1]);
    dest_len = 0;
    for( i = 0; i < Z_STRLEN_PP(args[1]); i++ ) {
	switch( source[i] ) {
	    case '\0':
	    case '\n':
	    case '\r':
	    case 26 /* ^Z */: 
	    case ';':
	    case '"':
		dest_len += 4;
		break;
	    case '\'':
	    case '\\':
		dest_len += 2;
		break;
	    default:
		dest_len++;
	}
    }

    dest = (char *)emalloc( dest_len + 1 );
    dest_len = 0;
    for( i = 0; i < Z_STRLEN_PP(args[1]); i++ ) {
	switch( source[i] ) {
	    case '\0':
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '0';
		dest[dest_len++] = '0';
		break;
	    case '\n':
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '0';
		dest[dest_len++] = 'a';
		break;
	    case '\r':
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '0';
		dest[dest_len++] = 'd';
		break;
	    case 26 : 
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '1';
		dest[dest_len++] = 'a';
		break;
	    case ';':
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '3';
		dest[dest_len++] = 'b';
		break;
	    case '"':
		dest[dest_len++] = '\\';
		dest[dest_len++] = 'x';
		dest[dest_len++] = '2';
		dest[dest_len++] = '2';
		break;
	    case '\'':
		dest[dest_len++] = '\'';
		dest[dest_len++] = '\'';
		break;
	    case '\\':
		dest[dest_len++] = '\\';
		dest[dest_len++] = '\\';
		break;
	    default:
		dest[dest_len++] = source[i];
		break;
	}
    }
    dest[dest_len] = '\0';
    RETURN_STRINGL(dest, dest_len, 0);
}
/* }}} */

/* {{{ proto string sasql_get_client_info( )
   sasql_get_client_info() returns a string that represents the client version */
PHP_FUNCTION(sasql_get_client_info)
/************************************/
{
    char   buffer[20];
    int	   rc;

    if( !api.initialized ) {
	RETURN_STRING( DBCAPI_NOT_FOUND_ERROR, 1 );
    }

    if( SAG(context) ) {
	rc = api.sqlany_client_version_ex( SAG(context), buffer, sizeof(buffer) );
    } else {
	rc = api.sqlany_client_version( buffer, sizeof(buffer) );
    }
    if( rc ) {
	RETURN_STRINGL(buffer, strlen(buffer), 1);
    } else {
	RETURN_FALSE;
    }
}
/* }}} */

/****************************************************************/
/******************** Deprecated functions **********************/
/****************************************************************/

/* {{{ proto sasql_result sqlanywhere_query(int conn, char * sql_str)
   Execute a query */
PHP_FUNCTION(sqlanywhere_query)
/*****************************/
{
    zval ** args[2];
    sqlany_connection_t * sqlany_conn;
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 2) || (zend_get_parameters_array_ex(2,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    convert_to_string_ex( args[1] );

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_query( conn=%d, sql=%s )", 
		Z_LVAL_PP( args[0] ), Z_STRVAL_PP(args[1]) ) );

    sqlany_result = (sqlany_result_t *)emalloc( sizeof(sqlany_result_t) ); 
    memset( sqlany_result, 0, sizeof(sqlany_result_t));

    sqlany_result->stmt_handle = api.sqlany_execute_direct( sqlany_conn->handle, 
	    Z_STRVAL_PP(args[1]) ) ;
    save_conn_error( sqlany_conn );
    if( sqlany_result->stmt_handle != NULL ) {
	// otherwise, create a result object
	sqlany_result->id = zend_list_insert( sqlany_result, le_result TSRMLS_CC); 
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_query=>%d", sqlany_result->id ) );
	sqlany_result->sqlany_conn = sqlany_conn;
	sqlany_result->next = sqlany_conn->result_list;
	sqlany_result->num_cols = api.sqlany_num_cols( sqlany_result->stmt_handle );
	sqlany_conn->result_list = sqlany_result;
	if( sqlany_conn->auto_commit ) {
	    api.sqlany_commit( sqlany_conn->handle );
	}
	RETURN_RESOURCE( sqlany_result->id );
    } else {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	efree( sqlany_result );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_query=>FALSE [%s]", 
		    sqlany_conn->error ) );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sqlanywhere_data_seek( sasql_result $result, int $row_num)
   Move internal row pointer */
PHP_FUNCTION(sqlanywhere_data_seek)
/*********************************/
{
    zval ** args[2];
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 2) || (zend_get_parameters_array_ex(2,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    convert_to_long_ex( args[1] );
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, args[0], -1, 
	    "SQLAnywhere result", le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_data_seek( %d, %d )", 
		sqlany_result->id, Z_LVAL_PP( args[1] )) );

    /* We don't want to look at the error code. We will just get it when we do the fetch */
    RETURN_BOOL( result_data_seek( sqlany_result, Z_LVAL_PP(args[1]), 1 ) );
}
/* }}} */

/* {{{ proto int sqlanywhere_num_rows( sasql_result $result )
   Get number of rows in result, if negative then number is an estimate */
PHP_FUNCTION(sqlanywhere_num_rows)
/********************************/
{
    zval ** arg1;
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, arg1, -1, 
	    "SQLAnywhere result", le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_num_rows( %d )", sqlany_result->id ) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanwhere_num_rows=>%d", 
		api.sqlany_num_rows( sqlany_result->stmt_handle ) ) );
    RETURN_LONG( api.sqlany_num_rows( sqlany_result->stmt_handle ) );
}
/* }}} */

/* {{{ proto bool sqlanywhere_execute( sasql_conn $conn, string $sql )
   executes the sql statement on connection conn */
PHP_FUNCTION(sqlanywhere_execute)
/*******************************/
{
    zval ** args[2];
    sqlany_connection_t * sqlany_conn;
    int ok;

    if( (ZEND_NUM_ARGS() != 2) || 
	    (zend_get_parameters_array_ex(2,args) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    convert_to_string_ex( args[1] );
    ZEND_FETCH_RESOURCE2( sqlany_conn, sqlany_connection_t*, args[0], -1, 
	    "SQLAnywhere connection", le_conn, le_pconn );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_execute=>[%s]", Z_STRVAL_PP(args[1]) ) );

    ok = api.sqlany_execute_immediate( sqlany_conn->handle, Z_STRVAL_PP(args[1]) );
    save_conn_error( sqlany_conn );
    if( ok ) {
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_execute=>SUCCESS" ) );
	RETURN_TRUE;
    } else {
	VerboseErrors( sqlany_conn TSRMLS_CC );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sqlanywhere_execute=>FAILED[%s]", 
		    sqlany_conn->error ) );
	RETURN_FALSE;
    }
}
/* }}} */

/* {{{ proto bool sasql_result_all(int result [,string table_format_str [,string th_format_str [,string tr_format_str [,string tc_format_str]]]] )
   Print result as an HTML table */
PHP_FUNCTION(sasql_result_all)
/**********************************/
{
    zval ** args[5] = { NULL, NULL, NULL, NULL, NULL };
    zval ** result_id, **format_str, **th_format_str, **tr_format_str, **td_format_str;
    sqlany_result_t	* sqlany_result;
    int num_rows;
    int i;
    char *  tr_even = NULL;
    char *  tr_odd = NULL;
    char * del = NULL;
    int	   rc;

    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_result_all started " ) );

    if( ZEND_NUM_ARGS() < 1 || ZEND_NUM_ARGS() > 5 ) {
	WRONG_PARAM_COUNT;
    }
    if( zend_get_parameters_array_ex(ZEND_NUM_ARGS(), args ) != SUCCESS) {
	WRONG_PARAM_COUNT;
    }
    result_id = args[0];
    format_str = args[1];
    th_format_str = args[2];
    tr_format_str = args[3];
    td_format_str = args[4];
    switch( ZEND_NUM_ARGS() ) {
	case 5:
	    convert_to_string_ex(td_format_str);
	    if( strcmp( Z_STRVAL_PP(td_format_str), "none" ) == 0 ) {
		Z_STRVAL_PP(td_format_str)[0] = '\0';
	    }
	case 4:
	    convert_to_string_ex(tr_format_str);
	    if( strcmp( Z_STRVAL_PP(tr_format_str), "none" ) == 0 ) {
		Z_STRVAL_PP(tr_format_str)[0] = '\0';
	    } else {
		del=strstr( Z_STRVAL_PP(tr_format_str) , "><" ) ;
		if ( del != NULL ) {
		    int x = (int)(del - Z_STRVAL_PP(tr_format_str));
		    tr_even = emalloc( x + 1 );
		    memcpy( tr_even, del + 2, x );
		    tr_even[x] = '\0';
		    *del = '\0';
		}
		tr_odd = emalloc( strlen( Z_STRVAL_PP(tr_format_str)) + 1 );
		strcpy( tr_odd, Z_STRVAL_PP(tr_format_str));
		if( del == NULL ) {
		    tr_even = tr_odd;
		}
	    }
	case 3:
	    convert_to_string_ex(th_format_str);
	    if( strcmp( Z_STRVAL_PP(th_format_str), "none" ) == 0 ) {
		Z_STRVAL_PP(th_format_str)[0] = '\0';
	    }
	case 2:
	    convert_to_string_ex(format_str);
	    if( strcmp( Z_STRVAL_PP(format_str), "none" ) == 0 ) {
		Z_STRVAL_PP(format_str)[0] = '\0';
	    }
	case 1:
	    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, result_id, -1, "SQLAnywhere result", le_result );
	    break;

	default: 
	    WRONG_PARAM_COUNT;
	    break;
    }

    if( sqlany_result->num_cols == 0 ) {
	//php_error_docref(NULL TSRMLS_CC, E_WARNING, "No DATA available " );
	_debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_result_all returned error2" ) );
	RETURN_FALSE;
    }

    if( format_str == NULL ) {
	php_printf( "<table>\n" );
    } else {
	php_printf( "<table %s>\n", Z_STRVAL_PP(format_str) );
    }

    if( tr_even == NULL ) {
	php_printf( "<tr>\n" );
    } else {
	php_printf( "<tr %s>\n", tr_even );
    }
    for( i = 0; i < sqlany_result->num_cols; i++ ) {
	a_sqlany_column_info	cinfo;
	result_get_column_info( sqlany_result, i, &cinfo );
	if( th_format_str == NULL ) {
	    php_printf("\t<th>" );
	} else {
	    php_printf("\t<th %s>", Z_STRVAL_PP(th_format_str) );
	}
	php_printf( "%s</th>\n", cinfo.name );
    }
    php_printf( "</tr>\n" );


    /* now fetch and print data */
    num_rows = 0;

    if( !result_data_seek( sqlany_result, 0, 1 ) ) {
	RETURN_FALSE;
    }

    while( 1 ) {
	rc = result_fetch_next( sqlany_result, 1 );
	if( rc == 0 || rc == -1 ) {
	    break;
	}

	num_rows++;
	if ( tr_odd == NULL ) {
	    php_printf( "<tr>\n" );
	} else {
	    php_printf( "<tr %s>\n", (num_rows % 2 == 0 ? tr_even : tr_odd )  );
	}
	for( i = 0; i < sqlany_result->num_cols; i ++ ) {
	    a_sqlany_data_value dvalue;

	    if( td_format_str == NULL ) {
		php_printf( "\t<td>" );
	    } else {
		php_printf( "\t<td %s>", Z_STRVAL_PP(td_format_str) );
	    }
	    
	    result_get_column_data( sqlany_result, i, &dvalue );
	    if( (*(dvalue.is_null)) == 0 ) {
		switch( dvalue.type ) {
		    case A_STRING:
		    case A_BINARY:
			php_printf( "%.*s", *(dvalue.length), (char *)dvalue.buffer );
			break;

		    case A_VAL32:
		    case A_UVAL32:
		    case A_VAL16:
		    case A_UVAL16:
		    case A_VAL8:
		    case A_UVAL8:
			{
			    long value;
			    switch( dvalue.type ) {
				case A_VAL32:
				    value = *((int *)dvalue.buffer);
				    break;
				case A_UVAL32:
				    value = *((unsigned int *)dvalue.buffer);
				    break;
				case A_VAL16:
				    value = *((short *)dvalue.buffer);
				    break;
				case A_UVAL16:
				    value = *((unsigned short *)dvalue.buffer);
				    break;
				case A_VAL8:
				    value = *((char *)dvalue.buffer);
				    break;
				case A_UVAL8:
				    value = *((unsigned char *)dvalue.buffer);
				    break;
				default:
				    value = 0;
			    }
			    php_printf( "%ld", value );
			}
			break;

		    case A_VAL64:
			php_printf( "%"SA_FMT64"d", *(sasql_int64*)dvalue.buffer );
			break;

		    case A_UVAL64:
			php_printf( "%"SA_FMT64"u", *(sasql_uint64*)dvalue.buffer );
			break;

		    case A_DOUBLE:
			php_printf( "%f", *(double *)dvalue.buffer );
			break;

		    default: 
			php_printf( "(Unkown Type)" );
			break;
		}
	    }
	    php_printf( "</td>\n" );
	}
	php_printf( "</tr>\n" );
    }
    
    php_printf("</table>\n" );

    if( tr_odd != NULL ) {
	efree( tr_odd );
    }
    if( del && tr_even != NULL ) {
	efree( tr_even );
    }

    if( num_rows == 0 ) {
	php_printf("<h2>No rows found</h2>\n");
    }

    _debug_enabled( SQLAnyDebug( _LOCATION_, "sasql_result_all returned" ) );
    RETURN_LONG( num_rows );
}
/* }}} */

/* {{{ proto int sasql_num_fields( sasql_result $result )
   Get num fields in result */
PHP_FUNCTION(sasql_num_fields)
/*************************************/
{
    zval ** arg1;
    sqlany_result_t	* sqlany_result;

    if( ( ZEND_NUM_ARGS() != 1) || (zend_get_parameters_array_ex(1,&arg1) != SUCCESS )) {
	WRONG_PARAM_COUNT;
    }
    ZEND_FETCH_RESOURCE( sqlany_result, sqlany_result_t*, arg1, -1, "SQLAnywhere result", 
	    le_result );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_num_fields( %d )", sqlany_result->id ) );
    _debug_enabled( SQLAnyDebug( _LOCATION_, " sasql_num_fields=>%d", sqlany_result->num_cols ) );
    RETURN_LONG( sqlany_result->num_cols );
}
/* }}} */

#endif

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 */
