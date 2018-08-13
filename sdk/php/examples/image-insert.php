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

    $conn = sasql_connect( "UID=DBA;PWD=sql" ) or die("Can't connect to db");
 
    sasql_query( $conn, "DROP TABLE my_images" );

    $result = sasql_query( $conn, "CREATE TABLE my_images ( id INT, image LONG BINARY) " );
    if( !$result ) {
	echo "Could not create my_images table<BR>";
	sasql_close( $conn );
	exit;
    }

    $filename = "ianywhere_logo.gif";
    $handle = fopen( $filename, "r" );
    if( !$handle ) {
        print "Could not open input file $filename";
         exit;	
    }
    $len = filesize( $filename );
    $content = fread( $handle, $len );
    fclose( $handle );

    echo "Inserting image from file '$filename' size $len ... ";

    $data = bin2hex( $content );
    $query = "INSERT INTO my_images VALUES ( 5, 0x" .$data . ") ";
    $result = sasql_query( $conn, $query );
    if( !$result ) {
	echo "failed!!!!<BR>\n";
	return 0;	
    } else {
        echo "succeeded!!!<BR>\n";
    }

    echo "Retrieving image from database ...";
    $ret_blob = "";
    $query = "SELECT image FROM my_images WHERE id = 5";
    $result = sasql_query( $conn, $query  );
    if( ! $result ) {
        echo "failed!!!<BR>\n";
        return 0;
    } else {
        $row = sasql_fetch_row( $result );
        if( !$row ) {
	    echo "failed fetching data<br>\n";
	    return 0;
	} else {
	    $ret_blob = $row[0];
	}
    }
    sasql_free_result( $result );

    echo "Comparing fetched image and inserted image ...";
    if( $ret_blob == $content ) {
        echo "success!!!<BR>\n";
    } else {
        echo "failure!!!<BR>\n";
    }
    sasql_commit( $conn );
    sasql_close( $conn );
?>
