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
    SQLAnywhereInterface api;
    a_sqlany_connection *sqlany_conn;
    a_sqlany_stmt 	*sqlany_stmt;
    unsigned int	 i;
    unsigned char	*data;
    unsigned int	 size = 1024*1024; // 1MB blob
    size_t		 my_size;
    int    	 	 code;
    a_sqlany_data_value  value;
    int 		 num_cols;
    unsigned int	 max_api_ver;
    a_sqlany_bind_param  param;

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

    sqlany_stmt = api.sqlany_prepare( sqlany_conn, "insert into my_blob_table( size, data ) values( ?, ?)" );
    assert( sqlany_stmt != NULL );

    data = (unsigned char *)malloc( size );
    // initialize the buffer
    for( i = 0; i < size; i++ ) {
	data[i] = i % 256;
    }


    // initialize the parameters
    api.sqlany_describe_bind_param( sqlany_stmt, 0, &param );
    param.value.buffer = (char *)&size;
    param.value.type   = A_VAL32;		// This needs to be set as the server does not 
    						// know what data will be inserting.
    api.sqlany_bind_param( sqlany_stmt, 0, &param );

    my_size = size;
    api.sqlany_describe_bind_param( sqlany_stmt, 1, &param );
    param.value.buffer = (char *)data;
    param.value.length = &my_size;
    param.value.type   = A_BINARY;		// This needs to be set for the same reason as above.
    api.sqlany_bind_param( sqlany_stmt, 1, &param );

    assert( api.sqlany_execute( sqlany_stmt ) );

    api.sqlany_free_stmt( sqlany_stmt );

    api.sqlany_commit( sqlany_conn );

    sqlany_stmt = api.sqlany_execute_direct( sqlany_conn, "select * from my_blob_table" );
    assert( sqlany_stmt != NULL );

    assert( api.sqlany_fetch_next( sqlany_stmt ) == 1 );

    num_cols = api.sqlany_num_cols( sqlany_stmt );

    assert( num_cols == 2 );

    api.sqlany_get_column( sqlany_stmt, 0, &value );

    assert( *((int*)value.buffer) == size );
    assert( value.type == A_VAL32 );

    api.sqlany_get_column( sqlany_stmt, 1, &value );

    assert( value.type == A_BINARY );
    assert( *(value.length) == my_size );

    for( i = 0; i < (*value.length); i++ ) {
	assert( (unsigned char)(value.buffer[i]) == data[i]);
    }

    assert( api.sqlany_fetch_next( sqlany_stmt ) == 0 );
    api.sqlany_free_stmt( sqlany_stmt );

    api.sqlany_disconnect( sqlany_conn );

clean:
    api.sqlany_free_connection( sqlany_conn );

    api.sqlany_fini();

    sqlany_finalize_interface( &api );
    printf( "Success!\n" );
}

