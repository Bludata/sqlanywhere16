// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/* +----------------------------------------------------------------------+
   | Authors: Mohammed Abouzour mabouzou@ianywhere.com                    |
   +----------------------------------------------------------------------+ */

#if defined( PHP_WIN32 )
#define _USE_32BIT_TIME_T 1
#endif

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <assert.h>
#include <stddef.h>
#include <string.h>
#include "php.h"
#include "php_main.h"
#include "php_ini.h"
#include "php_sqlanywhere_extenv.h"
#include "php_variables.h"
#include "ext/standard/info.h"
#include "zend_exceptions.h"


#include "sqlda.h"
#include "langload.h"
#include "extenv.h"
#include "sqldef.h"

#include <stdio.h>

#if PRODUCTION < 1
#define SQLANYWHERE_PHP_DEBUG
#endif

#if defined( SQLANYWHERE_PHP_DEBUG )
#if defined( PHP_WIN32 )
#define SQLANYWHERE_PHP_DEBUG_FILE "c:\\tmp\\php_debug.txt"
#else
#define SQLANYWHERE_PHP_DEBUG_FILE "/tmp/php_debug.txt"
#endif
FILE *debug_file;

#define DEBUG_BEGIN()	if( debug_file != NULL ) {
#define DEBUG_END()	}
#endif

#if HAVE_SQLANYWHERE 

#ifndef Z_ADDREF_P
#define Z_ADDREF_P(x)   (((x)->refcount)++)
#define Z_DELREF_P(x)   (((x)->refcount)--)
#define Z_SET_REFCOUNT_P(x,v)   ((x)->refcount = v)
#endif

typedef struct _sa_server_context {
    HashTable *headers;
    char *request_body;
    char *protocol_version;
    size_t headers_length;
    size_t request_body_length;
} sa_server_context;

typedef struct _sa_http_header {
    char *name;
    char *value;
} sa_http_header;

ZEND_FUNCTION(sqlanywhere_extenv_start);	
ZEND_FUNCTION(sqlanywhere_extenv_get_conn);	
ZEND_FUNCTION(sqlanywhere_extenv_get_code);	
ZEND_FUNCTION(sqlanywhere_extenv_get_args);	
ZEND_FUNCTION(sqlanywhere_extenv_set_output);	
ZEND_FUNCTION(sqlanywhere_extenv_set_error);	
ZEND_FUNCTION(sqlanywhere_extenv_get_error);	
ZEND_FUNCTION(sqlanywhere_extenv_log_error);	
ZEND_FUNCTION(sqlanywhere_extenv_start_http);	
ZEND_FUNCTION(sqlanywhere_extenv_force_exit);

/* 
 * Every user visible function must have an entry in 
 * sqlanywhere_extenv_functions[].
 */
zend_function_entry sqlanywhere_extenv_functions[] = {
	ZEND_FE(sqlanywhere_extenv_start,			NULL)
	ZEND_FE(sqlanywhere_extenv_get_conn,		NULL)
	ZEND_FE(sqlanywhere_extenv_get_code,		NULL)
	ZEND_FE(sqlanywhere_extenv_get_args,		NULL)
	ZEND_FE(sqlanywhere_extenv_set_output,		NULL)
	ZEND_FE(sqlanywhere_extenv_set_error,		NULL)
	ZEND_FE(sqlanywhere_extenv_get_error,		NULL)
	ZEND_FE(sqlanywhere_extenv_log_error,		NULL)
	ZEND_FE(sqlanywhere_extenv_start_http,		NULL)
	ZEND_FE(sqlanywhere_extenv_force_exit,		NULL)
	{NULL, NULL, NULL}	
};

zend_module_entry sqlanywhere_extenv_module_entry = {
    STANDARD_MODULE_HEADER,
	"sqlanywhere_extenv",
	sqlanywhere_extenv_functions,
	PHP_MINIT(sqlanywhere_extenv),
	PHP_MSHUTDOWN(sqlanywhere_extenv),
	NULL, //PHP_RINIT(sqlanywhere_extenv),
	NULL, //PHP_RSHUTDOWN(sqlanywhere_extenv),
	PHP_MINFO(sqlanywhere_extenv),
	NO_VERSION_YET,
	STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_SQLANYWHERE
ZEND_GET_MODULE(sqlanywhere_extenv)
#endif

char **_argv;
static void *  EeHandle;
static zval ** Exec;

static int get_sql_value( zval *dest, struct sqlvar *src );
static int set_sql_value( struct sqlvar *dest, zval *src );
static void * EXTENVCALL create_loader( void* ee_handle );
static EXTENVRET EXTENVCALL free_loader( void * ll_handle );
static EXTENVRET EXTENVCALL sa_extenv_execute( void *ll_handle, const char *method_sig );
static EXTENVRET EXTENVCALL interrupt( void *ll_handle );
static EXTENVRET EXTENVCALL set_thread( void *ll_handle, void *thread_handle );

static int _running = 0;
static void *sqlany_conn = NULL;
static zend_function *last_php_function = NULL;

/* SAPI stuff */
static int php_sqlanywhere_ub_write( const char *str, 
                                     uint str_length TSRMLS_DC );

static int php_sqlanywhere_header_handler( sapi_header_struct *sapi_header,
#if PHP_API_VERSION >= 20090626
                                           sapi_header_op_enum op,
#endif
                                           sapi_headers_struct *sapi_headers 
                                           TSRMLS_DC );
static int php_sqlanywhere_send_headers( sapi_headers_struct *sapi_headers
                                         TSRMLS_DC );
static int php_sqlanywhere_read_post(char *buf, uint count_bytes TSRMLS_DC);
static char * php_sqlanywhere_read_cookies( TSRMLS_D );
static void php_sqlanywhere_register_variables( zval *track_vars_array
                                                TSRMLS_DC );
static void php_sqlanywhere_hash_environment( TSRMLS_DC );
static void php_sqlanywhere_register_server_variables( TSRMLS_DC );
static void php_sqlanywhere_log_message( char *message TSRMLS_DC );

static void reset_request( TSRMLS_D );

static sapi_module_struct old_sapi_module;

/* {{{ sapi_module_struct sqlanywhere_sapi_module
 */
static sapi_module_struct sqlanywhere_sapi_module = {
	"sqlanywhere",					/* name */
	"SQL Anywhere",					/* pretty name */

	NULL,							/* startup */
	php_module_shutdown_wrapper,	/* shutdown */

	NULL,							/* activate */
	NULL,							/* deactivate */

	php_sqlanywhere_ub_write,		/* unbuffered write */
	NULL,							/* flush */
	NULL,							/* get uid */
	NULL,							/* getenv */

	php_error,						/* error handler */

	php_sqlanywhere_header_handler,	/* header handler */
	php_sqlanywhere_send_headers,	/* send headers handler */
	NULL,							/* send header handler */

	php_sqlanywhere_read_post,		/* read POST data */
	php_sqlanywhere_read_cookies,	/* read Cookies */

	php_sqlanywhere_register_variables,	/* register server variables */
	php_sqlanywhere_log_message,	/* Log message */

	STANDARD_SAPI_MODULE_PROPERTIES
};
/* }}} */


static int unlink_filename(char **filename TSRMLS_DC)
{
	VCWD_UNLINK(*filename);
	return 0;
}

PHP_INI_BEGIN()
    PHP_INI_END()
/* }}} */

PHP_MINIT_FUNCTION(sqlanywhere_extenv)
/************************************/
{
	REGISTER_INI_ENTRIES();

    REGISTER_LONG_CONSTANT( "SQLANYWHERE_EE_BAD_BODY", 17405, CONST_CS );
    REGISTER_LONG_CONSTANT( "SQLANYWHERE_EE_BAD_OPTION", 17406, CONST_CS );
    REGISTER_LONG_CONSTANT( "SQLANYWHERE_EE_BAD_ARG_LIST", 17407, CONST_CS );
    REGISTER_LONG_CONSTANT( "SQLANYWHERE_EE_UNKNOWN_KEY", 17408, CONST_CS );
    REGISTER_LONG_CONSTANT( "SQLANYWHERE_EE_PARSE_ERROR", 18022, CONST_CS );

    SG(rfc1867_uploaded_files) = NULL;
    
	return SUCCESS;
}


PHP_MSHUTDOWN_FUNCTION(sqlanywhere_extenv)
/****************************************/
{
    if( _running ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "Shutting down\n" );
        fflush( debug_file );
        DEBUG_END();
#endif

        ee_exit();
#if defined( PHP_WIN32 )
        Sleep( 1 );
#else
        sleep( 1 );
#endif
    }

	if (SG(rfc1867_uploaded_files)) {
        zend_hash_apply( SG(rfc1867_uploaded_files), 
                         (apply_func_t) unlink_filename TSRMLS_CC) ;
        zend_hash_destroy( SG(rfc1867_uploaded_files) );
        FREE_HASHTABLE( SG(rfc1867_uploaded_files) );
        SG(rfc1867_uploaded_files) = NULL;
	}

    if( old_sapi_module.name ) {
        sapi_module = old_sapi_module;
        old_sapi_module.name = NULL;
    }

    reset_request( TSRMLS_C );

	UNREGISTER_INI_ENTRIES();

	return SUCCESS;
}


PHP_MINFO_FUNCTION(sqlanywhere_extenv)
/************************************/
{
    char *product_name = emalloc( 256 );
    char *product_version = emalloc( 256 );
    char *server_name = emalloc( 256 );
    char *database_name = emalloc( 256 );
    char *connection_user = emalloc( 256 );

    char *server_data[] = { product_name, product_version,
                            server_name,
                            database_name, connection_user };
    size_t server_data_lens[] = { 256, 256,
                                  256,
                                  256, 256 };

	php_info_print_table_start();
	php_info_print_table_header( 2, "SQLAnywhere External Environment support", 
                                 "enabled" );

    if( ee_execute_any( EeHandle, "select "
                        "property( 'ProductName' ), "
                        "property( 'ProductVersion' ), "
                        "property( 'Name' ), "
                        "db_property( 'Name' ), "
                        "CURRENT_USER", 
                        5, server_data, server_data_lens ) == 0 ) {
        php_info_print_table_row( 2, "Server product", product_name );
        php_info_print_table_row( 2, "Server version", product_version );
        php_info_print_table_row( 2, "Server name", server_name );
        php_info_print_table_row( 2, "Database name", database_name );
        php_info_print_table_row( 2, "Connection user", connection_user );
    }

	php_info_print_table_end();

	DISPLAY_INI_ENTRIES();
}


#define SETTYPEMAP( dt, str )                   \
    ret = ee_set_type_map( dt, str );		    \
    if( ret < 0 ) {                             \
        return( ret );                          \
    }

static long set_type_map()
/************************/
{
    long    ret;

    SETTYPEMAP( DT_BIT,		"B" );

    SETTYPEMAP( DT_TINYINT,	"I" );
    SETTYPEMAP( DT_SMALLINT,	"I" );
    SETTYPEMAP( DT_UNSSMALLINT,	"I" );
    SETTYPEMAP( DT_INT,		"I" );

    SETTYPEMAP( DT_UNSINT,	"D" );
    SETTYPEMAP( DT_BIGINT,	"D" );
    SETTYPEMAP( DT_UNSBIGINT,	"D" );
    SETTYPEMAP( DT_FLOAT,	"D" );
    SETTYPEMAP( DT_DOUBLE,	"D" );
    SETTYPEMAP( DT_DECIMAL,	"D" );

    SETTYPEMAP( DT_NOTYPE,	"S" ); // map all other types to string

    ee_set_return_separator( -1 );
    ee_set_arg_separator( 0 );
    return( 0 );
}

/* {{{ proto int sqlanywhere_extenv_start(void* execfn, string eng, string dbn,
   string uid, string pwd) 
   Connect back to the engine and run the external environment event loop */
ZEND_FUNCTION(sqlanywhere_extenv_start)
/*************************************/
{
    zval ** args[5];
    zval ** zv_exec, ** eng, ** dbn, ** uid, ** pwd;
    long ret;
    struct a_language_loader loader;

#if defined( SQLANYWHERE_PHP_DEBUG )
    char fname[50];
    sprintf( fname, SQLANYWHERE_PHP_DEBUG_FILE ".%d", getpid() );
    debug_file = fopen( fname, "w" );
    DEBUG_BEGIN();
    fprintf( debug_file, "entering sqlanywhere_extenv_start\n" );
    fflush( debug_file );
    DEBUG_END();
#endif
    
    if( ( ZEND_NUM_ARGS() != 5) || 
        (zend_get_parameters_array_ex( 5, args ) != SUCCESS) 
        ) {

#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "Wrong number of parameters to sqlanywhere_extenv_start\n" );
        fflush( debug_file );
        DEBUG_END();
#endif

        WRONG_PARAM_COUNT;
    }

    zv_exec = args[0];
    eng = args[1];
    dbn = args[2];
    uid = args[3];
    pwd = args[4];

    convert_to_string_ex( zv_exec );
    convert_to_string_ex( eng );
    convert_to_string_ex( dbn );
    convert_to_string_ex( uid );
    convert_to_string_ex( pwd );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "sqlanywhere_extenv_start(%s, %s, %s, %s, %s)\n",
             Z_STRVAL_PP(zv_exec),
             Z_STRVAL_PP(eng), Z_STRVAL_PP(dbn), 
             Z_STRVAL_PP(uid), Z_STRVAL_PP(pwd) );
    fflush( debug_file );
    DEBUG_END();
#endif

    Exec = zv_exec;
    memset( &old_sapi_module, 0, sizeof( sapi_module_struct ) );

    SG(request_info).no_headers = 1;

	loader.create_loader = create_loader;
	loader.free_loader = free_loader;
	loader.execute = sa_extenv_execute;
	loader.interrupt = interrupt;
	loader.set_thread = set_thread;
    
	ret = ee_init( loader, PHP );
	if( ret < 0 ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "ee_init failed\n" );
        fflush( debug_file );
        DEBUG_END();
#endif
        ee_fini();
	    RETURN_FALSE;
	}

	ret = set_type_map();
	if( ret < 0 ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "set_type_map failed\n" );
        fflush( debug_file );
        DEBUG_END();
#endif
        ee_fini();
	    RETURN_FALSE;
	}

    
	ret = ee_connect( Z_STRVAL_PP(eng), Z_STRVAL_PP(dbn), 
                      Z_STRVAL_PP(uid), Z_STRVAL_PP(pwd) );
	if( ret < 0 ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "ee_connect failed\n" );
        fflush( debug_file );
        DEBUG_END();
#endif

        ee_fini();
	    RETURN_FALSE;
	}

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "entering mainloop\n" );
    fflush( debug_file );
    DEBUG_END();
#endif

    _running = 1;

	ret = ee_mainloop();

    if( old_sapi_module.name ) {
        sapi_module = old_sapi_module;
        old_sapi_module.name = NULL;
    }

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "done mainloop\n" );
    fflush( debug_file );
    DEBUG_END();
#endif

    if( ret < 0 ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "ee_mainloop failed\n" );
        fflush( debug_file );
        DEBUG_END();
#endif
        ee_fini();
        _running = 0;
        exit( 1 );
    }

	ret = ee_fini();
    _running = 0;
	if( ret < 0 ) {
        RETURN_FALSE;
	}

    RETURN_LONG( ret );
}
/* }}} */

/* {{{ proto int sqlanywhere_extenv_get_conn()
   Retrieve the database connection object (really the SQLCA) */
ZEND_FUNCTION(sqlanywhere_extenv_get_conn)
/****************************************/
{
    void *  ret;
    
    if( ZEND_NUM_ARGS() != 0 ) {
        WRONG_PARAM_COUNT;
    }
    
    ret = EeHandle ? (void*)ee_get_conn( EeHandle ) : NULL;
    
    if( ret == NULL ) {
        RETURN_NULL();
    }

    /* ugly hack because Zend has no way of returning an object pointer
     * in a 64-bit process
     */
    RETVAL_STRINGL( ret, sizeof( void * ), 0 );

    /* we now set the type to be LONG so that the object doesn't get freed
     * when Zend does its garbage collection
     */
    Z_TYPE_P( return_value ) = IS_LONG;
}
/* }}} */

/* {{{ proto int sqlanywhere_extenv_force_exit()
   Retrieve the database connection object (really the SQLCA) */
ZEND_FUNCTION(sqlanywhere_extenv_force_exit)
/******************************************/
{
    if( ZEND_NUM_ARGS() != 0 ) {
        WRONG_PARAM_COUNT;
    }

    sapi_send_headers( TSRMLS_C );
    reset_request( TSRMLS_C );

    ee_force_exit( EeHandle );
    RETURN_NULL();
}
/* }}} */

/* {{{ proto int sqlanywhere_extenv_get_code(string file_name)
   Retrieve the code for a given file name from the database */
ZEND_FUNCTION(sqlanywhere_extenv_get_code)
/****************************************/
{
    zval ** file_name;
    char *  ret;
    
    if( ( ZEND_NUM_ARGS() != 1) || 
        (zend_get_parameters_array_ex( 1, &file_name) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

    convert_to_string_ex( file_name );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "ee_get_class( %s )\n", Z_STRVAL_PP( file_name ) );
    fflush( debug_file );
    DEBUG_END();
#endif

    ret = EeHandle ? 
        (char*) ee_get_class( EeHandle, Z_STRVAL_PP( file_name ) ) : NULL;

    if( ret == NULL ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "No code found\n" );
        fflush( debug_file );
        DEBUG_END();
#endif
        RETURN_NULL();
    }

    RETVAL_STRING( ret, 1); 
    ee_free( ret );
    return;
}
/* }}} */

/* {{{ proto int sqlanywhere_extenv_get_args(string args, int num_args,
   int has_return )
   Retrieve the arguments for matching the argument pattern */
ZEND_FUNCTION(sqlanywhere_extenv_get_args)
/****************************************/
{
    zval **args_array[3];
    zval **args, **argc, **has_return;
    int real_argc, i;
    EXTENVRET ret;
    short* types;
	struct sqlda*  da = NULL;
	struct sqlvar* sqlvars = NULL;
    
    if( ( ZEND_NUM_ARGS() != 3) || 
        (zend_get_parameters_array_ex( 3, args_array ) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

    args = args_array[0];
    argc = args_array[1];
    has_return = args_array[2];

    convert_to_string_ex( args );
    convert_to_long_ex( argc );
    convert_to_boolean_ex( has_return );

    real_argc = Z_LVAL_PP( argc );
	if( Z_BVAL_PP( has_return ) ) {
	    real_argc++;
	}

    types = (short*) ee_malloc( sizeof( short ) * real_argc );
    for( i = 0; i < real_argc; i++ ) {
        switch( Z_STRVAL_PP( args )[ i ] ) {
        case 'I': /* I */
            types[i] = DT_INT;
            break;
        case 'D': /* D */
            types[i] = DT_DOUBLE;
            break;
        case 'B': /* B */
            types[i] = DT_BIT;
            break;
        case 'S': /* S */
            types[i] = DT_LONGBINARY;
            break;
        default:
            RETURN_NULL();
        }
    }

	ret = EeHandle ? ee_get_args( EeHandle, (void**)&da, Z_LVAL_PP( argc ), 
                                  Z_BVAL_PP( has_return ), types ) : -1 ;
    sqlvars = da->sqlvar;
    ee_free( types );

    if( ret < 0 ) {
	    RETURN_NULL();
	}

    array_init( return_value );
    for( i = 0; i < Z_LVAL_PP( argc ); i++ ) {
        zval* val;
        MAKE_STD_ZVAL( val );

        if( i == 0 ) { /* we want to have a 1-index array */
            ZVAL_NULL( val );
            zend_hash_next_index_insert( return_value->value.ht, &val, 
                                         sizeof(zval *), NULL );
            MAKE_STD_ZVAL( val );
        }

	    if( *sqlvars[i].sqlind >= 0 ) {
            if( ! get_sql_value( val, &sqlvars[i] ) ) {
                RETURN_NULL();
            }
        } else {
            ZVAL_NULL( val );
        }

        zend_hash_next_index_insert( return_value->value.ht, &val, 
                                     sizeof(zval *), NULL );
    }
}
/* }}} */

/* {{{ proto int sqlanywhere_extenv_set_output( mixed argv[] )
   Sends the values to be output to the engine.  
   argv[0] is the string return value
   the remaining argv[] entries match up with the procedure parameters */
ZEND_FUNCTION(sqlanywhere_extenv_set_output)
/******************************************/
{
    zval *argv;
    int argc, i, has_return;
    EXTENVRET ret;
    short* types;
	struct sqlda*  da = NULL;
	struct sqlvar* sqlvars = NULL;
    
    if( ( ZEND_NUM_ARGS() != 1 ) || 
        zend_parse_parameters( ZEND_NUM_ARGS() TSRMLS_CC, 
                               "a", &argv ) == FAILURE ) {
        WRONG_PARAM_COUNT;
    }

    argc = zend_hash_num_elements( Z_ARRVAL_P( argv ) );

	da = EeHandle ? ee_get_descriptor( EeHandle ) : NULL ;

    if( da == NULL ) {
        RETURN_NULL();
    }

    sqlvars = da->sqlvar;
    has_return = ( da->sqln >= argc ) ? 1 : 0;
    argc = ( has_return ) ? da->sqln - 1 : da->sqln;

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "setting output with%s %d parameters\n",
             ((has_return) ? " return and" : ""), argc);
    fflush( debug_file );
    DEBUG_END();
#endif

    /* first send the in/out/inout params */
    for( i = 0; i < argc; i++ ) {
        /* sqlvars[i] = argv[i+1] */
        zval **val;
        if( zend_hash_index_find( Z_ARRVAL_P( argv ), i+1, 
                                  (void**)&val ) == FAILURE ) {
            RETURN_NULL();
        }
        
        if( !set_sql_value( &sqlvars[i], *val ) ) {
            RETURN_NULL();
        } else {
            *sqlvars[i].sqlind = 0;
        }
    }

    /* now send the return value (if there is one) */
    if( has_return ) {
        /* sqlvars[argc] = argv[0] */
        zval **val;
        if( zend_hash_index_find( Z_ARRVAL_P( argv ), 0, 
                                  (void**)&val ) == FAILURE ) {
            RETURN_NULL();
        }

        if( !set_sql_value( &sqlvars[argc], *val ) ) {
            RETURN_NULL();
        } else {
            *sqlvars[argc].sqlind = 0;
        }
    }

    ret = EeHandle ? ee_set_output( EeHandle ) : -1;
	if( ret < 0 ) {        
        RETURN_NULL();
	}
    
    RETURN_LONG( ret );

}
/* }}} */

/* {{{ proto void sqlanywhere_extenv_set_error( char *error_str )
   sets the error on the request to error_str */
ZEND_FUNCTION(sqlanywhere_extenv_set_error)
/*****************************************/
{
    zval **error_str;
    
    if( ( ZEND_NUM_ARGS() != 1) || 
        (zend_get_parameters_array_ex( 1, &error_str) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "setting error <%s>\n", Z_STRVAL_PP( error_str ) );
    fflush( debug_file );
    DEBUG_END();
#endif

    convert_to_string_ex( error_str );

    if( EeHandle )
        ee_set_error( EeHandle, Z_STRVAL_PP( error_str ) );
}
/* }}} */

/* {{{ proto void sqlanywhere_extenv_get_error( int error_code )
   get the textual representation of the error represented by error_code */
ZEND_FUNCTION(sqlanywhere_extenv_get_error)
/*****************************************/
{
    zval **error_code;
    int ret;
    char buff[1024];
    
    if( ( ZEND_NUM_ARGS() != 1) || 
        (zend_get_parameters_array_ex( 1, &error_code) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

    convert_to_long_ex( error_code );
	ret = ee_get_string( Z_LVAL_PP( error_code ), buff, sizeof( buff ) );

    if( ret != 0 ) {
        RETURN_NULL();
    }
    
    RETURN_STRING( buff, 1 );

}
/* }}} */

/* {{{ proto void sqlanywhere_extenv_log_error( char *error_str )
   logs the error message to the engine console (if available) */
ZEND_FUNCTION(sqlanywhere_extenv_log_error)
/*****************************************/
{
    zval **error_str;
    
    if( ( ZEND_NUM_ARGS() != 1) || 
        (zend_get_parameters_array_ex( 1, &error_str) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

    convert_to_string_ex( error_str );

    php_sqlanywhere_log_message( Z_STRVAL_PP( error_str ) TSRMLS_CC );
}
/* }}} */

/* {{{ sqlanywhere_extenv_autoglobal_merge
 */
static void sqlanywhere_extenv_autoglobal_merge( HashTable *dest,
                                                 HashTable *src TSRMLS_DC )
/*************************************************************************/
{
	zval **src_entry, **dest_entry;
	char *string_key;
	uint string_key_len;
	ulong num_key;
	HashPosition pos;
	int key_type;
	int globals_check = (dest == (&EG(symbol_table)))
#if PHP_API_VERSION < 20100412
        && PG(register_globals)
#endif
        ;

	zend_hash_internal_pointer_reset_ex(src, &pos);
	while (zend_hash_get_current_data_ex(src, (void **)&src_entry, &pos) == SUCCESS) {
		key_type = zend_hash_get_current_key_ex(src, &string_key, &string_key_len, &num_key, 0, &pos);
		if (Z_TYPE_PP(src_entry) != IS_ARRAY
			|| (key_type == HASH_KEY_IS_STRING && zend_hash_find(dest, string_key, string_key_len, (void **) &dest_entry) != SUCCESS)
			|| (key_type == HASH_KEY_IS_LONG && zend_hash_index_find(dest, num_key, (void **)&dest_entry) != SUCCESS)
			|| Z_TYPE_PP(dest_entry) != IS_ARRAY
            ) {
			Z_ADDREF_P(*src_entry);
			if (key_type == HASH_KEY_IS_STRING) {
				/* if register_globals is on and working with main symbol table, prevent overwriting of GLOBALS */
				if (!globals_check || string_key_len != sizeof("GLOBALS") || memcmp(string_key, "GLOBALS", sizeof("GLOBALS") - 1)) {
					zend_hash_update(dest, string_key, string_key_len, src_entry, sizeof(zval *), NULL);
				} else {
					Z_DELREF_P(*src_entry);
				}
			} else {
				zend_hash_index_update(dest, num_key, src_entry, sizeof(zval *), NULL);
			}
		} else {
			SEPARATE_ZVAL(dest_entry);
			sqlanywhere_extenv_autoglobal_merge(Z_ARRVAL_PP(dest_entry), Z_ARRVAL_PP(src_entry) TSRMLS_CC);
		}
		zend_hash_move_forward_ex(src, &pos);
	}
}
/* }}} */

/* {{{ php_sqlanywhere_hash_environment
 */
static void php_sqlanywhere_hash_environment( TSRMLS_D )
/******************************************************/
{
	char *p;
	zval *form_variables;
	unsigned char _gpc_flags[5] = {0, 0, 0, 0, 0};
	zval *dummy_track_vars_array = NULL;
	zend_bool initialized_dummy_track_vars_array=0;

	struct auto_global_record {
		char *name;
		uint name_len;
		char *long_name;
		uint long_name_len;
	} auto_global_records[] = {
		{ "_POST", sizeof("_POST"), "HTTP_POST_VARS", sizeof("HTTP_POST_VARS") },
		{ "_GET", sizeof("_GET"), "HTTP_GET_VARS", sizeof("HTTP_GET_VARS") },
		{ "_COOKIE", sizeof("_COOKIE"), "HTTP_COOKIE_VARS", sizeof("HTTP_COOKIE_VARS") },
		{ "_SERVER", sizeof("_SERVER"), "HTTP_SERVER_VARS", sizeof("HTTP_SERVER_VARS") },
		{ "_ENV", sizeof("_ENV"), "HTTP_ENV_VARS", sizeof("HTTP_ENV_VARS") },
		{ "_FILES", sizeof("_FILES"), "HTTP_POST_FILES", sizeof("HTTP_POST_FILES") },
	};
	size_t num_track_vars = sizeof(auto_global_records)/sizeof(struct auto_global_record);
	size_t i;

    /* start up the request */
    PG(http_globals)[TRACK_VARS_POST] = NULL;
    PG(http_globals)[TRACK_VARS_GET] = NULL;
    PG(http_globals)[TRACK_VARS_COOKIE] = NULL;
    PG(http_globals)[TRACK_VARS_SERVER] = NULL;
    PG(http_globals)[TRACK_VARS_FILES] = NULL;
    
#if PHP_API_VERSION < 20100412
	ALLOC_ZVAL(form_variables);
	array_init(form_variables);
	INIT_PZVAL(form_variables);
#endif

#if defined( SQLANYWHERE_PHP_DEBUG )
                DEBUG_BEGIN();
                fprintf( debug_file, "hashing environment variables %s\n",
                         PG(variables_order) );
                fflush( debug_file );
                DEBUG_END();
#endif

	for (p=PG(variables_order); p && *p; p++) {
		switch(*p) {
        case 'p':
        case 'P':
#if defined( SQLANYWHERE_PHP_DEBUG )
            DEBUG_BEGIN();
            fprintf( debug_file, "headers_sent: %d; method: %s\n",
                     SG(headers_sent),
                     SG(request_info).request_method );
            fflush( debug_file );
            DEBUG_END();
#endif
            if (!_gpc_flags[0] && !SG(headers_sent) && 
                SG(request_info).request_method && 
                !strcasecmp(SG(request_info).request_method, "POST")) {
                /* POST Data */

#if defined( SQLANYWHERE_PHP_DEBUG )
                DEBUG_BEGIN();
                fprintf( debug_file, "treating POST data "
                         "(content-type: %s; entry: %p; data:%s)\n",
                         SG(request_info).content_type_dup,
                         SG(request_info).post_entry,
                         SG(request_info).post_data );
                fflush( debug_file );
                DEBUG_END();
#endif

                sapi_module.treat_data(PARSE_POST, NULL, NULL TSRMLS_CC);
                _gpc_flags[0] = 1;

#if PHP_API_VERSION < 20100412
                if (PG(register_globals)) {
                    sqlanywhere_extenv_autoglobal_merge(&EG(symbol_table), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_POST]) TSRMLS_CC);
                    sqlanywhere_extenv_autoglobal_merge(&EG(symbol_table), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_FILES]) TSRMLS_CC);
                }
                sqlanywhere_extenv_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_POST]) TSRMLS_CC);
#endif
            }
            break;
        case 'c':
        case 'C':
            if (!_gpc_flags[1]) {
                /* Cookie Data */

#if defined( SQLANYWHERE_PHP_DEBUG )
                DEBUG_BEGIN();
                fprintf( debug_file, "treating COOKIE data\n" );
                fflush( debug_file );
                DEBUG_END();
#endif

                sapi_module.treat_data(PARSE_COOKIE, NULL, NULL TSRMLS_CC);
                _gpc_flags[1] = 1;

#if PHP_API_VERSION < 20100412
                if (PG(register_globals)) {
                    sqlanywhere_extenv_autoglobal_merge(&EG(symbol_table), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_COOKIE]) TSRMLS_CC);
                }

                sqlanywhere_extenv_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_COOKIE]) TSRMLS_CC);
#endif
            }
            break;
        case 'g':
        case 'G':
            if (!_gpc_flags[2]) {
                /* GET Data */

#if defined( SQLANYWHERE_PHP_DEBUG )
                DEBUG_BEGIN();
                fprintf( debug_file, "treating GET data\n" );
                fflush( debug_file );
                DEBUG_END();
#endif

                sapi_module.treat_data(PARSE_GET, NULL, NULL TSRMLS_CC);
                _gpc_flags[2] = 1;

#if PHP_API_VERSION < 20100412
                if (PG(register_globals)) {
                    sqlanywhere_extenv_autoglobal_merge(&EG(symbol_table), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_GET]) TSRMLS_CC);
                }

                sqlanywhere_extenv_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_GET]) TSRMLS_CC);
#endif
            }
            break;
            // PHP 5.4.0 and up take will re-register the server variables
            // so it is redundant to do so here
        case 's':
        case 'S':
            if (!_gpc_flags[4]) {
                php_sqlanywhere_register_server_variables();
                _gpc_flags[4] = 1;
            }
            break;
		}
	}

	for( i=0; i<num_track_vars; i++ ) {
		if (!PG(http_globals)[i]) {
			if( !initialized_dummy_track_vars_array ) {
				ALLOC_ZVAL( dummy_track_vars_array );
				array_init( dummy_track_vars_array );
				INIT_PZVAL( dummy_track_vars_array );
				initialized_dummy_track_vars_array = 1;
			} else {
				Z_ADDREF_P(dummy_track_vars_array);
			}
			PG(http_globals)[i] = dummy_track_vars_array;
		}
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "updating global hash for %s "
                "with table containing %s\n",
                auto_global_records[i].name,
                ( PG(http_globals)[i] != NULL &&
                PG(http_globals)[i]->value.ht != NULL &&
                PG(http_globals)[i]->value.ht->nNumOfElements > 0 ?
                PG(http_globals)[i]->value.ht->pListHead->arKey : "" ) );
        fflush( debug_file );
        DEBUG_END();
#endif

		Z_ADDREF_P( PG(http_globals)[i] );
		zend_hash_update( &EG(symbol_table), auto_global_records[i].name,
                          auto_global_records[i].name_len,
                          &PG(http_globals)[i], sizeof(zval *), NULL);

#if PHP_API_VERSION < 20100412
		if (PG(register_long_arrays)) {
			zend_hash_update( &EG(symbol_table),
                              auto_global_records[i].long_name,
                              auto_global_records[i].long_name_len,
                              &PG(http_globals)[i], sizeof(zval *), NULL );
			Z_ADDREF_P( PG(http_globals)[i] );
		}
#endif
	}

#if PHP_API_VERSION < 20100412
	zend_hash_update(&EG(symbol_table), "_REQUEST", sizeof("_REQUEST"), 
                     &form_variables, sizeof(zval *), NULL);
#endif
}
/* }}} */

/* {{{ proto void sqlanywhere_extenv_start_http( char *method, char *url, 
   char *version, char *http_headers, char *request_body )
   starts an http request through the SAPI module */
ZEND_FUNCTION(sqlanywhere_extenv_start_http)
/******************************************/
{
    zval **args[5];
    zval **method_val, **url_val, **version_val;
    zval **http_headers_val, **request_body_val;
    char *http_headers, *next_header, *url, *qs, *version;
    int http_version = 0;
    char *headers = NULL;
    sa_server_context *sc = emalloc( sizeof( sa_server_context ) );

    if( (ZEND_NUM_ARGS() != 5) || 
        (zend_get_parameters_array_ex( 5, args ) != SUCCESS) ) {
        WRONG_PARAM_COUNT;
    }

    method_val = args[0];
    url_val = args[1];
    version_val = args[2];
    http_headers_val = args[3];
    request_body_val = args[4];

    convert_to_string_ex( method_val );

    convert_to_string_ex( method_val );
    convert_to_string_ex( url_val );
    convert_to_string_ex( version_val );
    convert_to_string_ex( http_headers_val );
    convert_to_string_ex( request_body_val );
    http_headers = Z_STRVAL_PP( http_headers_val );
    url = Z_STRVAL_PP( url_val );
    
    headers = Z_STRVAL_PP( http_headers_val );
    sc->headers_length = Z_STRLEN_PP( http_headers_val );
    sc->protocol_version = Z_STRVAL_PP( version_val );
    sc->request_body = Z_STRVAL_PP( request_body_val );
    sc->request_body_length = Z_STRLEN_PP( request_body_val );

    SG(server_context) = sc;
    
#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "starting HTTP request with headers <%s>\n", 
             http_headers );
    fflush( debug_file );
    DEBUG_END();
#endif
    
    SG(request_info).request_method = Z_STRVAL_PP( method_val );
    
    qs = strchr( url, '?' );
    if( qs != NULL ) {
        *qs = '\0';
        qs++;
    }
    
    SG(request_info).path_translated = url;
    SG(request_info).request_uri = url;
    SG(request_info).query_string = qs;
    
    
#if PHP_API_VERSION >= 20041225
    version = strchr( sc->protocol_version, '/' );
    if( version != NULL ) {
        version++;
        http_version = 1000 * atoi( version );
        version = strchr( version, '.' ) + 1;
        if( version != NULL ) {
            http_version += atoi( version );
        }
    }
#endif

    if( http_headers != NULL ) {
        ALLOC_HASHTABLE( sc->headers );
        zend_hash_init( sc->headers, 13, NULL, NULL, 0 );

        next_header = strchr( http_headers, '\n' );
        if( next_header == NULL ) {
            next_header = http_headers + strlen( http_headers );
        }

        while( next_header != NULL && next_header != http_headers ) {
            sa_http_header header;
            header.name = http_headers;
            
            if( *next_header != '\0' ) {
                *next_header = '\0';
                if( *(next_header-1) == '\r' )
                    *(next_header-1) = '\0';
                http_headers = next_header + 1;
            } else {
                http_headers = next_header;
            }
                
            header.value = strchr( header.name, ':' );
            if( header.value == NULL ) {
                break;
            }
            *header.value = '\0';
            header.value++;
            
            while( *header.value == ' ' || *header.value == '\t' ) {
                *header.value = '\0';
                header.value++;
            }

            zend_hash_update( sc->headers,
                              header.name, strlen( header.name ) + 1,
                              &header, sizeof( header ), NULL );

            if( strcmp( header.name, "Content-Length" ) == 0 ) {
                SG(request_info).content_length = atoi( header.value );
            } else if( strcmp( header.name, "Content-Type" ) == 0 ) {
                SG(request_info).content_type = header.value;
            }

            next_header = strchr( http_headers, '\n' );
            if( next_header == NULL ) {
                next_header = http_headers + strlen( http_headers );
            }
        }
    }
    
    SG(request_info).auth_user = NULL;
    SG(request_info).auth_password = NULL;
#if PHP_API_VERSION >= 20041225
    SG(request_info).auth_digest = NULL;
#endif
    
#if PHP_API_VERSION >= 20041225
    SG(request_info).proto_num = http_version;
#endif
    
#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "request_method = <%s>\n", SG(request_info).request_method );
    fprintf( debug_file, "query_string = <%s>\n", SG(request_info).query_string );
    fprintf( debug_file, "content_length = <%d>\n", SG(request_info).content_length );
    fprintf( debug_file, "request_uri = <%s>\n", SG(request_info).request_uri );
    fprintf( debug_file, "content_type = <%s>\n", SG(request_info).content_type );
#if PHP_API_VERSION >= 20041225
    fprintf( debug_file, "proto_num = <%d>\n", SG(request_info).proto_num );
#endif
    fflush( debug_file );
    DEBUG_END();
#endif

    sapi_activate( TSRMLS_C );
    php_sqlanywhere_hash_environment( TSRMLS_C );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "http request is started\n" );
    fflush( debug_file );
    DEBUG_END();
#endif
}
/* }}} */

static int set_sql_value( struct sqlvar *dest, zval *src )
/********************************************************/
{
	unsigned long	l;
	LONGBINARY *	longdata;

    switch( dest->sqltype & 0xfffe ) {
    case DT_INT: /* I */
    {
        convert_to_long( src );
        *(unsigned *)dest->sqldata = Z_LVAL_P( src ); 
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "output (int): %d\n", Z_LVAL_P( src ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    }
    case DT_DOUBLE: /* D */
    {
        convert_to_double( src );
        *(double *)dest->sqldata = Z_DVAL_P( src ); 
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "output (double): %f\n", Z_DVAL_P( src ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    }
    case DT_BIT: /* B */
    {
        convert_to_boolean( src );
        *(unsigned char *)dest->sqldata = Z_BVAL_P( src );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "output (bit): %d\n", Z_BVAL_P( src ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    }
    case DT_LONGBINARY: /* S */
    {
        convert_to_string( src );
        l = Z_STRLEN_P( src );
        longdata = (LONGBINARY*) dest->sqldata;
    
        if( longdata == NULL || longdata->array_len < l ) {
            longdata = (LONGBINARY*) malloc( LONGBINARYSIZE( l ) );
            if( longdata == NULL ) {
                return 0;
            }
            longdata->array_len = l; 		    
            dest->sqldata = longdata;
        }
		
        longdata->stored_len = l;
        memcpy( longdata->array, Z_STRVAL_P( src ), l ); 	    

#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "output (string): %s\n", Z_STRVAL_P( src ) );
        fflush( debug_file );
        DEBUG_END();
#endif

        break;
    }
    default:
        return 0;
    }

    return 1;
}

static int get_sql_value( zval *dest, struct sqlvar *src )
/********************************************************/
{
    switch( src->sqltype & 0xfffe ) {
    case DT_INT: /* I */
        ZVAL_LONG( dest, *(unsigned*) src->sqldata );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "%d", Z_LVAL_P( dest ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    case DT_DOUBLE: /* D */
        ZVAL_DOUBLE( dest, *(double*) src->sqldata );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "%f", Z_DVAL_P( dest ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    case DT_BIT: /* B */
        ZVAL_BOOL( dest, * (unsigned char*) src->sqldata );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "%d", Z_BVAL_P( dest ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    case DT_LONGBINARY: /* S */
    {
        LONGBINARY* chardata = (LONGBINARY*) src->sqldata;
        ZVAL_STRINGL( dest, chardata->array, chardata->stored_len, 1 );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "%s", Z_STRVAL_P( dest ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        break;
    }
    default:
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "%d", Z_LVAL_P( dest ) );
        fflush( debug_file );
        DEBUG_END();
#endif
        return 0;
    }

    return 1;
}

static void* EXTENVCALL create_loader( void* ee_handle )
/******************************************************/
{
    TSRMLS_FETCH();

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "create_loader( %p )\n", ee_handle );
    fflush( debug_file );
    DEBUG_END();
#endif

    EeHandle = ee_handle;

    old_sapi_module = sapi_module;
    sapi_module = sqlanywhere_sapi_module;

    sapi_module.default_post_reader = old_sapi_module.default_post_reader;
    sapi_module.treat_data = old_sapi_module.treat_data;
    sapi_module.input_filter = old_sapi_module.input_filter;

#if PHP_API_VERSION < 20100412
    OG(php_header_write) = sapi_module.ub_write;
#endif
    EG(error_reporting) = -1;
    PG(html_errors) = 0;
    PG(register_argc_argv) = 0;

    reset_request( TSRMLS_C );

    return (void*) 1;
}

static EXTENVRET EXTENVCALL free_loader( void* ll_handle )
/********************************************************/
{
    TSRMLS_FETCH();

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "free_loader( %p )\n", ll_handle );
    fflush( debug_file );
    DEBUG_END();
#endif

    if( old_sapi_module.name ) {
        sapi_module = old_sapi_module;
        old_sapi_module.name = NULL;

        SG(request_info).no_headers = 1;
    }
    

    EeHandle = NULL;
    return EXTENV_OK;
}

static int should_remove_function( zend_function *function TSRMLS_DC )
/********************************************************************/
{
    if( function == last_php_function )
        return ZEND_HASH_APPLY_STOP;

    return ZEND_HASH_APPLY_REMOVE;
}

static EXTENVRET EXTENVCALL
sa_extenv_execute( void *ll_handle, const char *method_sig )
/**********************************************************/
{
    TSRMLS_FETCH();
    long ret = -1;
    zend_fcall_info fci;
    zval **args;
    zval *retval_ptr;
	zend_fcall_info_cache exec_cache = empty_fcall_info_cache;

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "sa_extenv_execute( %p, %s ) with conn %p\n", 
             ll_handle, method_sig, (void*)ee_get_conn( EeHandle ) );
    fflush( debug_file );
    DEBUG_END();
#endif

    args = (zval**)ee_malloc( sizeof( zval* ) );
    MAKE_STD_ZVAL( args[0] );
    ZVAL_STRING( args[0], method_sig, 1 );
    
    memset( &fci, 0, sizeof( fci ) );
    fci.size = sizeof( fci );
    fci.function_table = CG( function_table );
    fci.function_name = *Exec;
    fci.retval_ptr_ptr = &retval_ptr;
    fci.param_count = 1;
    fci.params = (zval***)&args;

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "calling exec function <%s> with args <%s> )\n", 
             Z_STRVAL_PP( Exec ), method_sig );
    fflush( debug_file );
    DEBUG_END();
#endif

    /* set up the _SERVER global variable with request-specific information */
    sapi_activate( TSRMLS_C );
    php_sqlanywhere_hash_environment( TSRMLS_C );

    /* We need to clean up any newly-declared functions so that subsequent
     * calls to the same procedure don't have naming conflicts.
     */
    last_php_function = (zend_function*)CG(function_table)->pListTail->pData;


    if( zend_call_function( &fci, &exec_cache TSRMLS_CC ) == SUCCESS
        && retval_ptr ) {
        convert_to_long_ex( &retval_ptr );
        ret = Z_LVAL_P( retval_ptr );
        zval_ptr_dtor( &retval_ptr );

#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "exec function returned %d\n", ret );
        fflush( debug_file );
        DEBUG_END();
#endif
    }

    /* Now actually remove the newly-created functions from the list */
    /* Note the assumption that all new functions are at the end of the list */
    zend_hash_reverse_apply( CG( function_table ), 
                             (apply_func_t)should_remove_function TSRMLS_CC );

    if( SG(server_context) ) {
        sa_server_context *sc = (sa_server_context*)SG(server_context);
        FREE_HASHTABLE( sc->headers );
        sc->headers = NULL;
        efree( SG(server_context) );
        SG(server_context) = NULL;
    }

    sapi_send_headers( TSRMLS_C );
    reset_request( TSRMLS_C );
	SG(sapi_headers).http_response_code = 200;

	if (SG(rfc1867_uploaded_files)) {
        zend_hash_apply( SG(rfc1867_uploaded_files), 
                         (apply_func_t) unlink_filename TSRMLS_CC) ;
        zend_hash_destroy( SG(rfc1867_uploaded_files) );
        FREE_HASHTABLE( SG(rfc1867_uploaded_files) );
        SG(rfc1867_uploaded_files) = NULL;
	}

    if( ret != 0 )
        ret = EXTENV_ERROR;

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "sa_extenv_execute returning %d\n", ret );
    fflush( debug_file );
    DEBUG_END();
#endif

    zval_ptr_dtor( &args[0] );
    ee_free( args );

    return ret;
}

static EXTENVRET EXTENVCALL interrupt( void* ll_handle )
/******************************************************/
{
#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "interrupt!\n", ll_handle );
    fflush( debug_file );
    DEBUG_END();
#endif

    return 0;
}

static EXTENVRET EXTENVCALL set_thread( void* ll_handle, void* thread_handle )
/****************************************************************************/
{
    return 0;
}

static int php_sqlanywhere_ub_write( const char *str, 
                                     uint str_length TSRMLS_DC )
/**************************************************************/
{
    if( EeHandle )
        ee_write_string( EeHandle, (char*)str, str_length );
    else if( old_sapi_module.ub_write )
        old_sapi_module.ub_write( str, str_length TSRMLS_CC );
}

static int php_sqlanywhere_header_handler( sapi_header_struct *sapi_header,
#if PHP_API_VERSION >= 20090626
                                           sapi_header_op_enum op,
#endif
                                           sapi_headers_struct *sapi_headers 
                                           TSRMLS_DC )
/**************************************************************************/
{
    char *header;
    char *value;
    char *query;
    size_t name_len;

    value = strchr( sapi_header->header, ':' );

    name_len = value - sapi_header->header;

    header = malloc( name_len + 1 );
    memcpy( header, sapi_header->header, name_len );
    header[ name_len ] = '\0';

    value ++;
    while( *value == ' ' || *value == '\t' )
        value ++;

    query = malloc( 4 + 1 + 24 + 3 + 3 + sapi_header->header_len + 1 );
    sprintf( query, "call sa_set_http_header('%s','%s');", header, value );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "setting header <%s> with query <%s>\n", 
             sapi_header->header, query );
    fflush( debug_file );
    DEBUG_END();
#endif

    if( EeHandle )
        ee_execute( EeHandle, query );

    free( header );
    free( query );

    SG(request_info).no_headers = 0;

    return SAPI_HEADER_ADD;
}

static int php_sqlanywhere_send_headers( sapi_headers_struct *sapi_headers
                                         TSRMLS_DC )
/************************************************************************/
{
    char *query;

    int http_response_code = SG(sapi_headers).http_response_code;
    if( http_response_code == 0 ) {
        http_response_code = 200;
    }

    query = malloc( 4 + 1 + 42 + 3 + 1 );
    sprintf( query, "call sa_set_http_header('@HttpStatus','%03d');", 
             http_response_code );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "setting response code <%03d> with query <%s>\n", 
             http_response_code, query );
    fflush( debug_file );
    DEBUG_END();
#endif

    if( EeHandle )
        ee_execute( EeHandle, query );

    free( query );
    
    return SAPI_HEADER_SENT_SUCCESSFULLY;
}

static int php_sqlanywhere_read_post( char *buf, uint count_bytes TSRMLS_DC )
/***************************************************************************/
{
    sa_server_context *sc = (sa_server_context*)SG(server_context);
    size_t remaining = sc->request_body_length - SG(read_post_bytes);
    size_t len = ( count_bytes < remaining ) ? count_bytes : remaining;

    memcpy( buf, sc->request_body + SG(read_post_bytes), len );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "reading %d bytes of post data <%s>\n", len, buf );
    fflush( debug_file );
    DEBUG_END();
#endif

    return len;
}

static char * php_sqlanywhere_read_cookies( TSRMLS_D ) 
/****************************************************/
{
    sa_server_context *ctx = (sa_server_context*)SG(server_context);
    sa_http_header *http_header = NULL;
    HashTable *http_headers = ctx->headers;

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "reading cookies\n" );
    fflush( debug_file );
    DEBUG_END();
#endif

    if( http_headers == NULL )
        return NULL;

    if( zend_hash_find( http_headers, "Cookie", sizeof( "Cookie" ), 
                        (void*)&http_header ) == SUCCESS ) {
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "Found cookie: <%s>\n", http_header->value );
        fflush( debug_file );
        DEBUG_END();
#endif
        return http_header->value;
    }

    return NULL;
}

/* {{{ php_sqlanywhere_register_variable
 */
static inline void php_sqlanywhere_register_variable( const char *name,
                                                      char *value,
                                                      zval *track_vars_array
                                                      TSRMLS_DC )
/**************************************************************************/
{
    php_register_variable( (char*)name, value, track_vars_array TSRMLS_CC );

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "registering variable <%s> = <%s>\n", name, value );
    fflush( debug_file );
    DEBUG_END();
#endif
}
/* }}} */


/* {{{ php_sqlanywhere_register_server_variables
 */
static void php_sqlanywhere_register_server_variables( TSRMLS_D )
/***************************************************************/
{
    zval *array_ptr = NULL;
    /* turn off magic_quotes while importing server variables */
#if PHP_API_VERSION < 20100412
    int magic_quotes_gpc = PG(magic_quotes_gpc);
#endif

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "registering server variables\n" );
    fflush( debug_file );
    DEBUG_END();
#endif

    ALLOC_ZVAL(array_ptr);
    array_init(array_ptr);
    INIT_PZVAL(array_ptr);
    if( PG(http_globals)[TRACK_VARS_SERVER] ) {
        zval_ptr_dtor( &PG(http_globals)[TRACK_VARS_SERVER] );
    }
    PG(http_globals)[TRACK_VARS_SERVER] = array_ptr;
#if PHP_API_VERSION < 20100412
    PG(magic_quotes_gpc) = 0;
#endif

    /* Server variables */
    if( sapi_module.register_server_variables ) {
        sapi_module.register_server_variables( array_ptr TSRMLS_CC );
    }

    /* PHP Authentication support */
    if( SG(request_info).auth_user ) {
        php_sqlanywhere_register_variable( "PHP_AUTH_USER",
                                           SG(request_info).auth_user,
                                           array_ptr TSRMLS_CC );
    }
    if( SG(request_info).auth_password ) {
        php_sqlanywhere_register_variable( "PHP_AUTH_PW",
                                           SG(request_info).auth_password,
                                           array_ptr TSRMLS_CC );
    }
#if PHP_API_VERSION >= 20041225
    if( SG(request_info).auth_digest ) {
        php_sqlanywhere_register_variable( "PHP_AUTH_DIGEST",
                                           SG(request_info).auth_digest,
                                           array_ptr TSRMLS_CC );
    }
    /* store request init time */
    {
        zval new_entry;
        Z_TYPE(new_entry) = IS_LONG;
        Z_LVAL(new_entry) = (int)sapi_get_request_time( TSRMLS_C );
        php_register_variable_ex( "REQUEST_TIME", &new_entry,
                                  array_ptr TSRMLS_CC );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file, "registering variable <REQUEST_TIME>: <%d>\n",
                 Z_LVAL( new_entry ) );
        fflush( debug_file );
        DEBUG_END();
#endif
    }
#if PHP_API_VERSION >= 20100412
    {
        zval new_entry;
        Z_TYPE(new_entry) = IS_DOUBLE;
        Z_DVAL(new_entry) = sapi_get_request_time( TSRMLS_C );
        php_register_variable_ex( "REQUEST_TIME_FLOAT", &new_entry,
                                  array_ptr TSRMLS_CC );
#if defined( SQLANYWHERE_PHP_DEBUG )
        DEBUG_BEGIN();
        fprintf( debug_file,
                 "registering variable <REQUEST_TIME_FLOAT>: <%f>\n",
                 Z_DVAL( new_entry ) );
        fflush( debug_file );
        DEBUG_END();
#endif
    }
#endif
#endif

#if PHP_API_VERSION < 20100412
    PG(magic_quotes_gpc) = magic_quotes_gpc;
#endif

#if PHP_API_VERSION < 20100412
    if( PG(register_globals) ) {
        sqlanywhere_extenv_autoglobal_merge(
            &EG(symbol_table),
            Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_SERVER]) TSRMLS_CC );
    }
#else
    zend_hash_update( &EG(symbol_table), "_SERVER", 8,
                      &PG(http_globals)[TRACK_VARS_SERVER], sizeof(zval *),
                      NULL );
    Z_ADDREF_P( PG(http_globals)[TRACK_VARS_SERVER] );
#endif

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "done registering server variables\n" );
    fflush( debug_file );
    DEBUG_END();
#endif


}
/* }}} */

static int php_sqlanywhere_register_header_variable(
    void *h, void *t TSRMLS_DC )
/**************************************************/
{
    sa_http_header *header = (sa_http_header*)h;
    zval *track_vars_array = (zval*)t;

    if( strcmp( header->name, "Content-Length" ) == 0 ) {
        php_sqlanywhere_register_variable( "CONTENT_LENGTH", header->value, 
                                           track_vars_array TSRMLS_CC);
    } else if( strcmp( header->name, "Content-Type" ) == 0 ) {
        php_sqlanywhere_register_variable( "CONTENT_TYPE", header->value,
                                           track_vars_array TSRMLS_CC);
    } else if( *header->name != '@' &&
               strcmp( header->name, "Authorization" ) != 0 &&
               strcmp( header->name, "Proxy-Authorization" ) != 0 ) {
        char *env_key = malloc( sizeof( "HTTP_" ) + strlen( header->name ) );
        char *cp = env_key;
        
        
        *cp++ = 'H';
        *cp++ = 'T';
        *cp++ = 'T';
        *cp++ = 'P';
        *cp++ = '_';
        
        for( ; *header->name != '\0'; header->name++ ) {
            *cp++ = ( ( *header->name >= 'A' && *header->name <= 'Z' ) ||
                      ( *header->name >= 'a' && *header->name <= 'z' ) ||
                      ( *header->name >= '0' && *header->name <= '9' ) ) ? 
                toupper( *header->name ) : '_';
        }
        *cp = '\0';
        
        
        php_sqlanywhere_register_variable( env_key, header->value,
                                           track_vars_array TSRMLS_CC);
    }
    

    return ZEND_HASH_APPLY_KEEP;
}

static void php_sqlanywhere_register_variables( zval *track_vars_array
                                                TSRMLS_DC )
/********************************************************************/
{
    char *server_software = emalloc( 256 );
    char *server_name = emalloc( 256 );
    char *server_port = emalloc( 10 );
    char *remote_addr = emalloc( 40 );
    char *auth_type = emalloc( 256 );
    char *remote_user = emalloc( 256 );
    sa_server_context *ctx = (sa_server_context*)SG(server_context);
    HashTable *http_headers = ctx ? ctx->headers : NULL;

    char *server_data[] = { server_software, server_name, server_port, 
                            remote_addr, auth_type, remote_user };
    size_t server_data_lens[] = { 256, 256, 10,
								  40, 256, 256 };

#if defined( SQLANYWHERE_PHP_DEBUG )
    DEBUG_BEGIN();
    fprintf( debug_file, "registering variables\n" );
    fflush( debug_file );
    DEBUG_END();
#endif
    
    if( ee_execute_any( EeHandle, "select "
                        "property( 'ProductName' ) || ' ' || "
                        "property( 'ProductVersion' ), "
                        "isnull( http_header( 'Host' ), "
                        "        if connection_property( 'ServerNodeAddress' ) "
                        "                = '' then "
                        "            property( 'MachineName' ) "
                        "        else "
                        "            connection_property( 'ServerNodeAddress' )"
                        "        endif ),"
                        "connection_property( 'ServerPort' ), "
                        "if connection_property( 'ClientNodeAddress' ) = '' "
                        "then "
                        "    property( 'MachineName' ) "
                        "else "
                        "    connection_property( 'ClientNodeAddress' ) "
                        "endif, "
                        "connection_property( 'AuthType' ), "
                        "connection_property( 'UserID' )", 
                        6, server_data, server_data_lens ) == 0 ) {
        php_sqlanywhere_register_variable( "SERVER_SOFTWARE", server_software, 
                                           track_vars_array TSRMLS_CC );
        php_sqlanywhere_register_variable( "SERVER_NAME", server_name, 
                                           track_vars_array TSRMLS_CC );
        php_sqlanywhere_register_variable( "SERVER_PORT", server_port, 
                                           track_vars_array TSRMLS_CC );
        php_sqlanywhere_register_variable( "REMOTE_ADDR", remote_addr, 
                                           track_vars_array TSRMLS_CC );

        if( auth_type != NULL && auth_type[0] != '\0' ) {
            php_sqlanywhere_register_variable( "AUTH_TYPE", auth_type, 
                                               track_vars_array TSRMLS_CC );
            php_sqlanywhere_register_variable( "REMOTE_USER", remote_user, 
                                               track_vars_array TSRMLS_CC );
        }
    }

    php_sqlanywhere_register_variable( "GATEWAY_INTERFACE", "CGI/1.1",
                                       track_vars_array TSRMLS_CC );

    if( ctx ) {
        php_sqlanywhere_register_variable( "SERVER_PROTOCOL",
                                           ctx->protocol_version,
                                           track_vars_array TSRMLS_CC );
    }

    if( SG(request_info).request_method ) {
        php_sqlanywhere_register_variable(
            "REQUEST_METHOD", 
            (char*)SG(request_info).request_method,
            track_vars_array TSRMLS_CC );
    }
    if( SG(request_info).path_translated ) {
        php_sqlanywhere_register_variable(
            "PATH_INFO",
            (char*)SG(request_info).path_translated,
            track_vars_array TSRMLS_CC );
        php_sqlanywhere_register_variable(
            "PATH_TRANSLATED",
            (char*)SG(request_info).path_translated,
            track_vars_array TSRMLS_CC );
        php_sqlanywhere_register_variable(
            "SCRIPT_NAME",
            (char*)SG(request_info).path_translated,
            track_vars_array TSRMLS_CC );
    }
        
    if( SG(request_info).query_string ) {
        php_sqlanywhere_register_variable( "QUERY_STRING",
                                           (char*)SG(request_info).query_string,
                                           track_vars_array TSRMLS_CC);
    }
    
    if( SG(request_info).request_uri ) {
        php_sqlanywhere_register_variable( "PHP_SELF",
                                           SG(request_info).request_uri, 
                                           track_vars_array TSRMLS_CC);
    }

    if( http_headers == NULL )
        return;

    zend_hash_apply_with_argument( http_headers, 
                                   php_sqlanywhere_register_header_variable,
                                   track_vars_array TSRMLS_CC );
}

static void php_sqlanywhere_log_message( char *message TSRMLS_DC )
/****************************************************************/
{
    if( EeHandle )
        ee_write_string( EeHandle, message, strlen( message ) );
    else if( old_sapi_module.log_message )
        old_sapi_module.log_message( message TSRMLS_CC );
}

static void reset_request( TSRMLS_D )
/************************************/
{
    sa_server_context *sc = (sa_server_context*)SG(server_context);
    if( sc != NULL ) {
        FREE_HASHTABLE( sc->headers );
        sc->headers = NULL;
    }
    SG(server_context) = NULL;
	SG(request_info).path_translated = NULL;
	SG(request_info).request_method = NULL;
	SG(request_info).cookie_data = NULL;
#if PHP_API_VERSION >= 20041225
	SG(request_info).proto_num = 1000;
#endif
	SG(request_info).query_string = NULL;
	SG(request_info).request_uri = NULL;
	SG(request_info).content_type = NULL;
	SG(request_info).content_length = 0;
	SG(sapi_headers).http_response_code = 200;
    SG(request_info).auth_user = NULL;
    SG(request_info).auth_password = NULL;
#if PHP_API_VERSION >= 20041225
    SG(request_info).auth_digest = NULL;
#endif
    SG(request_info).no_headers = 1;
    SG(headers_sent) = 0;
}

#endif

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 */
