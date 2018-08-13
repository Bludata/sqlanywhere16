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
        echo "sasql_connect failed\n";
    } else {

	$result = sasql_query( $conn, "SELECT * FROM Customers" );

	if( ! $result ) {
	    echo "sasql_query failed!";

	} else {

	    $num_cols = sasql_field_count( $conn );
	    $num_rows = sasql_num_rows( $result );

	    echo "Num of rows = $num_rows<br>\n";
	    echo "Num of cols = $num_cols<br>\n";
	    echo "<br>\n";

	    $cur_row = 0;
	    $cur_col = 0;
	    while( ($row = sasql_fetch_object( $result ))) {
		echo "($cur_row): =========================== <br>\n";
		while(list($key,$val)=each($row)) {
		    echo "$key : $val \n"; 
		    $cur_col++;
		}
		echo "<br>\n";
	    	$cur_row++;
	    }
	    sasql_free_result( $result );
	}

	sasql_close( $conn );
	echo "<br>\n";
    }
?>

