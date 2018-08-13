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
    function db_test_blob($test_num, $size, $conn) {
	$blob_data = "";
	echo "    creating blob ... ";
	for( $i = 0; $i < $size ; $i++ ) {
	    $blob_data .= "C";
	}
	echo "completed<br>";

	
	echo "    Inserting a blob of size $size ... ";
	$data = bin2hex( $blob_data );
	$query = "INSERT INTO blob_table VALUES ( $test_num, 0x" .$data . ") ";
	$result = sasql_query( $conn, $query );
	if( ! $result ) {
	    echo "failed!!!<br>";
	    return 0;
	} else {
	    echo "passed!!!<br>";
	}

	echo "    Retrieving blob ... ";
	$ret_blob = "";
	$query = "SELECT b FROM  blob_table WHERE row = $test_num";
	echo "query:$query ";
	$result = sasql_query( $conn, $query  );
	if( ! $result ) {
	    echo "failed!!!<br>";
	    return 0;
	} else {
	    $row = sasql_fetch_row( $result );
	    if( !$row ) {
		echo "failed fetching data<br>";
		return 0;
	    } else {
		$ret_blob = $row[0];
		echo "passed!!!<br>";
	    }
	}

	echo "    Comparing data ... ";
	if( $ret_blob == $blob_data ) {
#	    echo "original   len =".  strlen($blob_data) ." <br>";
#	    echo "retrieved  len =".  strlen($ret_blob) ." <br>";
	    echo " blob_data:$ret_blob.";
	    echo "success<br>";
	} else {
	    echo "failure: <br>";
	    echo "    original len=" .strlen($blob_data) . " : $blob<br>";
	    echo "    retrieve len=" .strlen($ret_blob)  . " :$ret_blob<br>";
	    return 0;
	}
	sasql_free_result( $result );
	return 1;
    }

    $conn = sasql_connect( "UID=DBA;PWD=sql" );

    if( ! $conn ) {
	echo "sasql_connect failed\n";
    } else {

	sasql_query( $conn, "DROP TABLE blob_table " );

	echo "Creating blob table ... ";
	$result = sasql_query( $conn, "CREATE TABLE blob_table( row INT PRIMARY KEY, b LONG BINARY)" );
	if( ! $result ) {
	    echo "failed!!!";
	    return;
	} else {
	    echo "passed!!!";
        }
  	echo "<BR>";
	

	$blob_sizes = array( 0 => "1", 
			     1 => "5", 
			     2 => "10", 
			     3 => "100", 
			     4 => "1024", 	# 1K
			     5 => "10000", 	# 10k 
			     6 => "32000",	# ~32K 
			     7 => "32768",	# 32K 
			     8 => "65536",  	# 64K
			     9 => "850000", 	# 
			     10 => "1048576", 	# 1024K
			     11 => "-1" );
	$test_num = 0;
	$success = 1;
	while( $blob_sizes[$test_num] != -1 && $success == 1 ) {
	    echo "Testing blob of size $blob_sizes[$test_num] ... <br>";
	    $success = db_test_blob( $test_num, $blob_sizes[$test_num], $conn );
	    $test_num++;
	}

	sasql_disconnect( $conn );
    }

?>
