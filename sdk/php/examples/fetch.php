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

    # Connect using the default user ID and password
    $conn = sasql_connect( "UID=DBA;PWD=sql" );
    if( ! $conn ) {
	die ("Connection failed");
    } else {
	# Connected successfully.
    }
    # Execute a SELECT statement
    $result = sasql_query( $conn, "SELECT * FROM Customers" );
    if( ! $result ) {
	echo "sasql_query failed!";
	return 0;
    } else {
	echo "query completed successfully\n";
    }
    # Retrieve meta information about the results
    $num_cols = sasql_num_fields( $result );
    $num_rows = sasql_num_rows( $result );
    echo "Num of rows = $num_rows\n";
    echo "Num of cols = $num_cols\n";
    while( ($field = sasql_fetch_field( $result )) ) {
	echo "Field # : $field->id \n";  
	echo "\tname   : $field->name \n";  
	echo "\tlength : $field->length \n";   
	echo "\ttype   : $field->type \n";  
    }
    # Fetch all the rows
    $curr_row = 0;
    while( ($row = sasql_fetch_row( $result )) ) {
	$curr_row++;
	$curr_col = 0;
	while( $curr_col < $num_cols ) {
	    echo "$row[$curr_col]\t|"; 
	    $curr_col++;
	}
	echo "\n";
    }
    # Clean up.
    sasql_free_result( $result );
    sasql_disconnect( $conn );
?>
