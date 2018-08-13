<?php
    #*********************************************************************
    # Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
    #
    # This sample code is provided AS IS, without warranty or liability
    # of any kind.
    # 
    # You may use, reproduce, modify and distribute this sample code
    # without limitation, on the condition that you retain the foregoing
    # copyright notice and disclaimer as to the original code.
    # 
    #*********************************************************************
    #
    # This sample program contains a hard-coded userid and password
    # to connect to the demo database. This is done to simplify the
    # sample program. The use of hard-coded passwords is strongly
    # discouraged in production code.  A best practice for production
    # code would be to prompt the user for the userid and password.
    #

    $conn = sasql_connect( "UID=DBA;PWD=sql" );
    if( ! $conn ) {
	echo "sasql_conn_failed";
	return;
    }
    sasql_set_option( $conn, "verbose_errors", false );

    if( !sasql_query( $conn, "DROP TABLE my_transactions" ) ) {
	$str = sasql_error( $conn );
	$code = sasql_errorcode( $conn );
	echo "Failed to drop table because of error: [$code] $str";
    }
    if( !sasql_query( $conn, "CREATE TABLE my_transactions( id INT, value VARCHAR(20) )" ) ) {
	$str = sasql_error( $conn );
	$code = sasql_errorcode( $conn );
	echo "Failed to create table code=$code str=$str";
	return;
    }
    sasql_query( $conn, "DROP TABLE my_transactions" );

    sasql_close( $conn );
    
?>
