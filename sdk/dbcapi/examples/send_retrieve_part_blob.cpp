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
// This sample program contains a hard-coded userid and password
// to connect to the demo database. This is done to simplify the
// sample program. The use of hard-coded passwords is strongly
// discouraged in production code.  A best practice for production
// code would be to prompt the user for the userid and password.
// *********************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "sacapidll.h"

int main( )
{
    SQLAnywhereInterface  api;
    a_sqlany_connection *sqlany_conn;
    a_sqlany_stmt 	*sqlany_stmt;
    unsigned int	 i;
    unsigned char	*data;
    unsigned int	 size = 1024*1024; // 1MB blob
    int    	 	 code;
    a_sqlany_data_value	 value;
    int			 num_cols;
    unsigned char 	 retrieve_buffer[4096];
    a_sqlany_data_info 	 dinfo;
    int			 bytes_read;
    size_t  		 total_bytes_read;
    unsigned int	 max_api_ver;

    if( !sqlany_initialize_interface( &api, NULL ) ) {
	printf( "Could not initialize the interface!\n" );
	exit( 0 );
    }

    assert( api.sqlany_init( "my_php_app", SQLANY_API_VERSION_1, &max_api_ver ) );
    sqlany_conn = api.sqlany_new_connection();

    if( !api.sqlany_connect( sqlany_conn, "uid=dba;pwd=sql" ) ) {
	char buffer[SACAPI_ERROR_SIZE];
	code = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer) );
	printf( "Could not connection[%d]:%s\n", code, buffer );
	goto clean;
    }

    printf( "Connected successfully!\n" );

    api.sqlany_execute_immediate( sqlany_conn, "drop table my_blob_table" );
    assert( api.sqlany_execute_immediate( sqlany_conn, "create table my_blob_table (size integer, data long binary)" ) != 0);

    // 1. Starting to insert blob operation
    sqlany_stmt = api.sqlany_prepare( sqlany_conn, "insert into my_blob_table( size, data) values( ?, ? )" ); 
    assert( sqlany_stmt != NULL );


    // 1.1 We must first bind the parameters
    a_sqlany_bind_param param;

    api.sqlany_describe_bind_param( sqlany_stmt, 0, &param );
    param.value.buffer = (char *)&size;
    param.value.type   = A_VAL32;
    param.value.is_null= NULL;
    param.direction    = DD_INPUT;
    api.sqlany_bind_param( sqlany_stmt, 0, &param );

    api.sqlany_describe_bind_param( sqlany_stmt, 1, &param );
    param.value.buffer = NULL;
    param.value.type   = A_BINARY;
    param.value.is_null= NULL;
    param.direction    = DD_INPUT;
    api.sqlany_bind_param( sqlany_stmt, 1, &param );

    data = (unsigned char *)malloc( size );
    for( i = 0; i < size; i++ ) {
	data[i] = i % 256;
    }

    // 1.2 upload the blob data to the server in chunks
    for( i = 0; i < size; i += 4096 ) {
	if( !api.sqlany_send_param_data( sqlany_stmt, 1, (char *)&data[i], 4096 )) {
	    char buffer[SACAPI_ERROR_SIZE];
	    code = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer) );
	    printf( "Could not send param[%d]:%s\n", code, buffer );
	}
    }

    // 1.3 actually do the row insert operation
    assert( api.sqlany_execute( sqlany_stmt ) == 1 );

    api.sqlany_commit( sqlany_conn );

    api.sqlany_free_stmt( sqlany_stmt );


    // 2. Now let's retrieve the blob
    sqlany_stmt = api.sqlany_execute_direct( sqlany_conn, "select * from my_blob_table" );
    assert( sqlany_stmt != NULL );

    assert( api.sqlany_fetch_next( sqlany_stmt ) == 1 );

    num_cols = api.sqlany_num_cols( sqlany_stmt );

    assert( num_cols == 2 );

    api.sqlany_get_column( sqlany_stmt, 0, &value );

    assert( i == size );
    assert( value.type == A_VAL32 );

    api.sqlany_get_data_info( sqlany_stmt, 1, &dinfo );

    assert( dinfo.type == A_BINARY );
    assert( dinfo.data_size == size );
    assert( dinfo.is_null == 0 );

    // 2.1 Retrieve data in 4096 byte chunks
    total_bytes_read = 0;
    while( 1 ) {
	bytes_read = api.sqlany_get_data( sqlany_stmt, 1, total_bytes_read, retrieve_buffer, sizeof(retrieve_buffer) );
        if( bytes_read <= 0 ) {
	    break;
    	}
	// verify the buffer contents
	for( i = 0; i < (unsigned int)bytes_read; i++ ) {
	    assert( retrieve_buffer[i] == data[total_bytes_read+i] );
	}
	total_bytes_read += bytes_read;
    }
    assert( total_bytes_read == size );

    free(data );

    assert( api.sqlany_fetch_next( sqlany_stmt ) == 0 );

    api.sqlany_free_stmt( sqlany_stmt );

    api.sqlany_disconnect( sqlany_conn );

clean:
    api.sqlany_free_connection( sqlany_conn );

    api.sqlany_fini();

    sqlany_finalize_interface( &api );

    printf( "Success!\n" );
}

