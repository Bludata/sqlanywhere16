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
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "sacapidll.h"
#include <assert.h>

SQLAnywhereInterface  api;

void
print_error( a_sqlany_connection * sqlany_conn, char * str )
{
    char buffer[SACAPI_ERROR_SIZE];
    int  rc;
    rc = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer));
    printf( "%s: [%d] %s\n", str, rc, buffer );
}

int main( )
{
    a_sqlany_connection * sqlany_conn;
    a_sqlany_stmt	* sqlany_stmt;
    unsigned int	  max_api_ver;

    if( !sqlany_initialize_interface( &api, NULL ) ) {
	printf( "Could not initialize the interface!\n" );
	exit( 0 );
    }

    if( !api.sqlany_init( "MyAPP", SQLANY_API_VERSION_1, &max_api_ver )) {
	printf( "Failed to initialize the interface! Supported version=%d\n", max_api_ver );
	sqlany_finalize_interface( &api );
	return -1;
    }

    /* A connection object needs to be created first */
    sqlany_conn = api.sqlany_new_connection();

    if( !api.sqlany_connect( sqlany_conn, "uid=dba;pwd=sql" ) ) { 
	print_error( sqlany_conn, "Failed connecting" );
	api.sqlany_free_connection( sqlany_conn );
	api.sqlany_fini();
	sqlany_finalize_interface( &api );
	exit( -1 );
    }
    printf( "Connected successfully!\n" );

    api.sqlany_execute_immediate( sqlany_conn, "drop table foo" );
    api.sqlany_execute_immediate( sqlany_conn, "create table foo ( id integer, name char(20))" );

    sqlany_stmt = api.sqlany_prepare( sqlany_conn, "insert into foo values( ?, ? )" );
    assert( sqlany_stmt );

    int i= 0;
    while( i < 10 ) {

	a_sqlany_bind_param 	param;
	char	   		buffer[256];
	size_t			buffer_length;

	assert( api.sqlany_describe_bind_param( sqlany_stmt, 0, &param ) );
	param.value.buffer  = (char *)&i;
	param.value.is_null = NULL;
	param.value.type    = A_UVAL32;
	assert( api.sqlany_bind_param( sqlany_stmt, 0, &param ) );

	assert( api.sqlany_describe_bind_param( sqlany_stmt, 1, &param ) );
	param.value.buffer = buffer;
	param.value.length = &buffer_length;
	param.value.type   = A_STRING;
	assert( api.sqlany_bind_param( sqlany_stmt, 1, &param ) );
							  
	sprintf( buffer, "Entry %d", i );
	buffer_length = strlen( buffer );

	/* We are not expecting a result set so the result set parameter could be NULL */
	if( !api.sqlany_execute( sqlany_stmt ) ) {
	    print_error( sqlany_conn, "Execute failed" );
	    break;
	}
	api.sqlany_commit( sqlany_conn );

	/* Free the statement object or there will be a memory leak */
	api.sqlany_reset( sqlany_stmt );
	i++;
    }

    api.sqlany_free_stmt( sqlany_stmt );


    sqlany_stmt = api.sqlany_execute_direct( sqlany_conn, "select * from foo" );
    assert( sqlany_stmt );
    while( api.sqlany_fetch_next( sqlany_stmt ) ) {
	i--;
    }
    assert( i == 0 );
    int  err_code;
    char err_msg[256];
    char sqlstate[6];
    err_code = api.sqlany_error( sqlany_conn, err_msg, sizeof(err_msg) );
    api.sqlany_sqlstate( sqlany_conn, sqlstate, sizeof(sqlstate) );
    assert( err_code == 100 );
    assert( strcmp( sqlstate, "02000" ) == 0 );

    api.sqlany_clear_error( sqlany_conn );
    err_code = api.sqlany_error( sqlany_conn, err_msg, sizeof(err_msg) );
    api.sqlany_sqlstate( sqlany_conn, sqlstate, sizeof(sqlstate) );
    assert( err_code == 0 );
    assert( strcmp( sqlstate, "00000" ) == 0 );

    api.sqlany_free_stmt( sqlany_stmt );


    api.sqlany_disconnect( sqlany_conn );

    /* Must free the connection object or there will be a memory leak */
    api.sqlany_free_connection( sqlany_conn );

    api.sqlany_fini();

    sqlany_finalize_interface( &api );

    return 0;
}
