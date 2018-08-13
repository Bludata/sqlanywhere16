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

    sasql_query( $conn, "DROP TABLE my_transactions" );
    $result = sasql_query( $conn, "CREATE TABLE my_transactions( id INT, value VARCHAR(20) )" );
    if( ! $result ) {
	echo "could not create table my_transactions";
	return;
    }
   
    if( !sasql_set_option( $conn, "auto_commit", false ) ) {
	echo "Could not turn off auto_commit";
	return;
    }

    // Add a few values 
    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 1, 'first item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 2, 'second item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 3, 'third item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    // now commit 
    sasql_commit( $conn );
  

    // now do the same operation as above but roll back
    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 4, 'first item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 5, 'second item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    sasql_query( $conn, "INSERT INTO my_transactions VALUES( 6, 'third item' )" );
    assert( sasql_affected_rows( $conn ) == 1 );

    // now rollback 
    sasql_rollback( $conn );

    // at this point, we should only have 1 to 3
    // verify that:
    $result = sasql_query( $conn, "SELECT id FROM my_transactions WHERE id >= 4" );
    $num_rows = 0;
    while($row = sasql_fetch_row( $result )) {
	$num_rows++;
    }
    assert( $num_rows == 0 );
    assert( sasql_num_rows( $result ) == 0 );
    sasql_free_result( $result );		

    $result = sasql_query( $conn, "SELECT id, value FROM my_transactions");
    assert( sasql_num_rows( $result ) == 3 );
    sasql_result_all( $result );
    sasql_free_result( $result );		

    sasql_query( $conn, "DROP TABLE my_transactions" );
    sasql_close( $conn );
    
?>
