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

int main( int argc, char * argv[] )
{
    SQLAnywhereInterface  api;
    a_sqlany_connection   *sqlany_conn;
    unsigned int	  max_api_ver;

    if( !sqlany_initialize_interface( &api, NULL ) ) {
	printf( "Could not initialize the interface!\n" );
	exit( 0 );
    }

    if( !api.sqlany_init( "MyAPP", SQLANY_API_VERSION_1, &max_api_ver )) {
	printf( "Failed to initialize the interface! Supported version = %d\n", max_api_ver );
	sqlany_finalize_interface( &api );
	return -1;
    }

    /* A connection object needs to be created first */
    sqlany_conn = api.sqlany_new_connection();

    if( !api.sqlany_connect( sqlany_conn, "uid=dba;pwd=sql" ) ) { 
        /* failed to connect */
	char buffer[SACAPI_ERROR_SIZE];
	int  rc;
	rc = api.sqlany_error( sqlany_conn, buffer, sizeof(buffer) );
	printf( "Failed to connect: error code=%d error message=%s\n", 
	    rc, buffer );
    } else {
	printf( "Connected successfully!\n" );
	api.sqlany_disconnect( sqlany_conn );
    }

    /* Must free the connection object or there will be a memory leak */
    api.sqlany_free_connection( sqlany_conn );

    api.sqlany_fini();

    sqlany_finalize_interface( &api );

    return 0;
}
