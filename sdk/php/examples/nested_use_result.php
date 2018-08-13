<?php
    #
    # This sample program contains a hard-coded userid and password
    # to connect to the demo database. This is done to simplify the
    # sample program. The use of hard-coded passwords is strongly
    # discouraged in production code.  A best practice for production
    # code would be to prompt the user for the userid and password.
    #
    $conn = sasql_connect( "UID=DBA;PWD=sql" );
    if( !$conn ) {
        echo "Failed to connect!\n";
        return;
    }
    // get the GROUPO user id
    $result1 = sasql_query( $conn, "SELECT user_id , user_name FROM SYS.SYSUSER", SASQL_USE_RESULT );
    if( !$result1 ) {
        echo "Failed to get first result!\n";
        return;
    }
    $total_indexes = 0;
    $num_rows = sasql_num_rows( $result1 );
    echo "Returned rows: $num_rows\n";
    while( ($row = sasql_fetch_row( $result1 )) ) {
        $sql = "SELECT table_id, table_name FROM SYS.SYSTABLE WHERE creator = $row[0]";
        $result2 = sasql_query( $conn, $sql, SASQL_USE_RESULT );
        if( $result2 ) {
	    echo "Tables for user $row[1] : \n";
	    while( ($row2 = sasql_fetch_row( $result2 )) ) {
	        echo "\t$row2[0]:$row2[1]\n";

	        $sql = "SELECT table_id, index_id, index_name FROM SYSINDEX where table_id = $row2[0]";
	        $result3 = sasql_query( $conn, $sql, SASQL_USE_RESULT );
	        if( $result3 ) {
		    echo "\t\tIndexes for table id $row2[0] : \n";
		    while( $row3 = sasql_fetch_row( $result3 ) ) {
		        echo "\t\t$row3[1]:$row3[2]\n";
			$total_indexes++;
		    }
		    sasql_free_result( $result3 );
	        }
	    }
	    sasql_free_result( $result2 );
        }
    }
    sasql_free_result( $result1 );

    $result = sasql_query( $conn, "select count(*) from sysindex" );
    if( !$result ) {
	echo "FAiled !\n";
    }
    $row = sasql_fetch_row( $result );
    if( $row[0] != $total_indexes ) {
	echo "Total indexes does not match!\n";
    }
    sasql_free_result( $result );
    sasql_close( $conn );
?>
