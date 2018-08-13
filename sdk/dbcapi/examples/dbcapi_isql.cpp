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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <signal.h>

#if !defined( UNIX ) 
#include <windows.h>
#define get_time() GetTickCount()
#endif

#define _SACAPI_VERSION		2
#include "sacapi.h"
#include "sacapidll.h"

#if defined( UNIX )
#define strnicmp   strncasecmp
#define get_time() 0
#endif

SQLAnywhereInterface api;
a_sqlany_connection *sqlany_conn;


void print_blob( char * buffer, size_t length )
/**********************************************/
{
    size_t i;

    if( length == 0 ) {
	return;
    }
    printf( "0x" );
    i = 0;
    while( i < length ) {
	printf( "%.2X", (unsigned char)buffer[i] );
	i++;
    }
}


void execute( char * query )
/***************************/
{
    a_sqlany_stmt * sqlany_stmt;
    int		    err_code;
    char	    err_mesg[SACAPI_ERROR_SIZE];
    int		    i;
    int		    num_rows;
    int		    length;

    sqlany_stmt = api.sqlany_execute_direct( sqlany_conn, query );
    if( sqlany_stmt == NULL ) {
	err_code = api.sqlany_error( sqlany_conn, err_mesg, sizeof(err_mesg) );
	printf( "Failed: [%d] '%s'\n", err_code, err_mesg );
	return;
    }
    if( api.sqlany_error( sqlany_conn, NULL, 0 ) > 0 ) {
	err_code = api.sqlany_error( sqlany_conn, err_mesg, sizeof(err_mesg) );
	printf( "Warning: [%d] '%s'\n", err_code, err_mesg );
    }
    if( api.sqlany_num_cols( sqlany_stmt ) == 0 ) {
	printf( "Executed successfully.\n" );
	if( api.sqlany_affected_rows( sqlany_stmt ) > 0 ) {
	    printf( "%d affected rows.\n", api.sqlany_affected_rows( sqlany_stmt ) );
	}
	api.sqlany_free_stmt( sqlany_stmt );
	return;
    }

    for( ;; ) {
	printf( "Estimated number of rows: %d\n", api.sqlany_num_rows( sqlany_stmt ) );
	// first output column header
	length = 0;
	for( i = 0; i < api.sqlany_num_cols( sqlany_stmt ); i++ ) {
	    a_sqlany_column_info	column_info;

	    if( i > 0 ) {
		printf( "," );
		length += 1;
	    }
	    api.sqlany_get_column_info( sqlany_stmt, i, &column_info );
	    printf( "%s", column_info.name );
	    length += (int)strlen( column_info.name );
	}
	printf( "\n" );
	for( i = 0; i < length; i++ ) {
	    printf( "-" );
	}
	printf( "\n" );
	num_rows = 0;
	while( api.sqlany_fetch_next( sqlany_stmt ) ) {
	    num_rows++;
	    for( i = 0; i < api.sqlany_num_cols( sqlany_stmt ); i++ ) {
		a_sqlany_data_value dvalue;
		sacapi_bool	    ok;

		ok = api.sqlany_get_column( sqlany_stmt, i, &dvalue );
		err_code = api.sqlany_error( sqlany_conn, err_mesg, sizeof(err_mesg) );
		
		if( !ok ) { 
		    printf( "Error: [%d] '%s'\n", err_code, err_mesg );
		}
		if( err_code ) {
		    printf( "Warning: [%d] '%s'\n", err_code, err_mesg );
		}

		if( i > 0 ) {
		    printf( "," );
		}
		if( *(dvalue.is_null) ) {
		    printf( "(NULL)" );
		    continue;
		}
		switch( dvalue.type ) {
		    case A_BINARY:
			print_blob( dvalue.buffer, *(dvalue.length) );
			break;
		    case A_STRING:
			printf( "'%.*s'", (int)*(dvalue.length), (char *)dvalue.buffer );
			break;
		    case A_VAL64:
			printf( "%lld", *(long long*)dvalue.buffer);
			break;
		    case A_UVAL64:
			printf( "%lld", *(unsigned long long*)dvalue.buffer);
			break;
		    case A_VAL32:
			printf( "%d", *(int*)dvalue.buffer );
			break;
		    case A_UVAL32:
			printf( "%u", *(unsigned int*)dvalue.buffer );
			break;
		    case A_VAL16:
			printf( "%d", *(short*)dvalue.buffer );
			break;
		    case A_UVAL16:
			printf( "%u", *(unsigned short*)dvalue.buffer );
			break;
		    case A_VAL8:
			printf( "%d", *(char*)dvalue.buffer );
			break;
		    case A_UVAL8:
			printf( "%d", *(unsigned char*)dvalue.buffer );
			break;
		    case A_DOUBLE:
			printf( "%f", *(double*)dvalue.buffer );
			break;
                    default: break;
		}
	    }
	    printf( "\n" ); 
	}
	for( i = 0; i < length; i++ ) {
	    printf( "-" );
	}
	printf( "\n" );

	printf( "%d rows returned\n", num_rows );
	if( api.sqlany_error( sqlany_conn, NULL, 0 ) != 100 ) {
	    char buffer[256];
	    int  code = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer) );
	    printf( "Failed: [%d] '%s'\n", code, buffer );
	}
	printf( "\n" );

	sacapi_bool	    ok;
	ok = api.sqlany_get_next_result( sqlany_stmt );
	err_code = api.sqlany_error( sqlany_conn, err_mesg, sizeof(err_mesg));

	if( !ok ) {
	    printf( "%s: [%d] '%s'\n", (err_code > 0 ? "Warning" : "Error" ), err_code, err_mesg );
	    break;
	}
    }

    fflush( stdout );
    api.sqlany_free_stmt( sqlany_stmt );
}

size_t read_file( char * file_name, char ** buffer )
/***************************************************/
{
    FILE * file = fopen( file_name, "rb" );
    size_t bytes_read;
    size_t size;

    if( file == NULL ) {
	return 0;
    }
    fseek( file, 0, SEEK_END );
    size = ftell( file );
    fseek( file, 0, SEEK_SET );
    (*buffer) = (char *)malloc( size + 1 );
    bytes_read = fread( (*buffer), 1, size, file );
    (*buffer)[bytes_read] = '\0';
    fclose( file );
    return bytes_read;
}



#if defined( WIN32 ) 
void __cdecl cancel_function( int )
#else
void cancel_function( int )
#endif
/*********************************/
{
    api.sqlany_cancel( sqlany_conn );
}

int main( int argc, char * argv[] )
/**********************************/
{
    unsigned int  max_api_ver;
    char 	  buffer[256];
    int		  len;
    int		  ch;
    char 	* sql;
    int		  free_sql = 0;
    unsigned int  start_time;

    if( argc < 1 ) {
	printf( "Usage: %s -c <connection_string>\n", argv[0] );
	exit( 0 );
    }
    if( !sqlany_initialize_interface( &api, NULL ) ) {
	printf( "Failed to initialize the interface!\n" );
	exit( 0 );
    }
    if( !api.sqlany_init( "isql", SQLANY_API_VERSION_2, &max_api_ver )) {
	printf( "Failed to initialize the interface! Supported version = %d\n", max_api_ver );
	sqlany_finalize_interface( &api );
	return -1;
    }
    sqlany_conn = api.sqlany_new_connection();

    if( !api.sqlany_connect( sqlany_conn, argv[1] ) ) {
	int code = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer) );
	printf( "Could not connect: [%d] %s\n", code, buffer );
	goto done;
    }

    signal( SIGINT, cancel_function );


    printf( "Connected successfully!\n" );
    while( 1 ) {
	printf( "\n%s> ", argv[0] );
	fflush( stdout );

	len = 0;
	while( len < (sizeof(buffer)-1) ) {
	    ch = fgetc( stdin );
	    if( ch == '\0' || ch == '\n' || ch == '\r' || ch == -1 ) {
		break;
	    }
	    buffer[len] = (char)ch;
	    len++;
	}
	buffer[len] = '\0';
	if(buffer[0] == '\0' ) {
	    break;
	}
	if( strcmp( buffer, "quit" ) == 0 ) {
	    break;
	} else if( strnicmp( buffer, "read ", 5 ) == 0 ) {
	    char * file_name = strdup( &buffer[5] );
	    size_t bytes_read;

	    bytes_read = read_file( file_name, &sql );
	    if( bytes_read == 0 ) {
		printf( "Could not read file %s\n", file_name );
		free( file_name );
		continue;
	    }
	    free_sql = 1;
	    free( file_name );
	} else {
	    sql = buffer;
	}
	start_time = get_time();
	execute( sql );
	unsigned int elapsed = get_time() - start_time;
	printf( "Total elapsed time = %dms\n", elapsed );
	if( free_sql ) {
	    free( sql );
	    free_sql = 0;
	}

    }

    signal( SIGINT, SIG_DFL );
    api.sqlany_disconnect( sqlany_conn );

done:
    api.sqlany_free_connection( sqlany_conn );
    api.sqlany_fini();
    sqlany_finalize_interface( &api );
}

