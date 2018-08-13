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
    if( !$conn ) {
	echo "Could not connect!\n";
	echo sasql_error();
	return;
    }
    echo "Connected successfully!\n";
 
    if( !sasql_query( $conn, "DROP PROCEDURE foo" ) ) {
	$error = sasql_error( $conn );
	echo "Could not drop procedures because : $error\n";
    }

    $sql  = "CREATE PROCEDURE foo( IN prefix CHAR(10), INOUT buffer VARCHAR(256), ";
    $sql .= "                      OUT str_len INT, IN suffix CHAR(10) ) ";
    $sql .= "BEGIN ";
    $sql .= "    SET buffer = prefix || buffer || suffix; ";
    $sql .= "    select length( buffer ) INTO str_len; ";
    $sql .= "END";


    if( sasql_query( $conn, $sql ) ) {
	echo "Procedure foo created successfully.\n";
    }
 
    $stmt = sasql_prepare( $conn, "CALL foo( ?, ?, ?, ? )" );
 
    if( ! $stmt ) {
	echo "Could not prepare!\n";
	echo sasql_error( $conn );
	return;
    }
 
    $prefix = "PREFIX";
    $my_var = "-some_string-";
    $suffix = "SUFFIX";
 
    sasql_stmt_bind_param( $stmt, "ssis", $prefix, $my_var, $str_len, $suffix );
 
    echo "Changing my bound var!\n";
    $my_var = "very_very_very_very_long_string";
 
    if( sasql_stmt_execute( $stmt ) ) {
	echo "Execute success!\n";
    } else {
	echo "Execute FAIL!\n";
	return;
    }
    echo "str=$my_var length=$str_len\n";
 
    if( sasql_stmt_execute( $stmt ) ) {
	echo "Execute success!\n";
    } else {
	echo "Execute FAIL!\n";
	return;
    }
    echo "str=$my_var length=$str_len\n";
 
    if( sasql_stmt_execute( $stmt ) ) {
	echo "Execute success!\n";
    } else {
	echo "Execute FAIL!\n";
	return;
    }
    echo "str=$my_var length=$str_len\n";
 
    sasql_stmt_close( $stmt );
 
    sasql_query( $conn, "DROP PROCEDURE foo" );
 
    sasql_close( $conn );
?>
