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

    $start = $_GET[start];
    if ( !$start || $start < 0 ) {
	   echo $start;
	   $start = 1;
    } 
    $next = $start + 20;
    $previous = $start - 20 ;
    $conn = sasql_connect( "UID=DBA;PWD=sql" );

    if( ! $conn ) {
	echo "sasql_connect failed\n";
    } else {

	$result = sasql_query( $conn, "SELECT TOP 20 START AT " . $start . " xmlelement( name \"a\",xmlattributes ('details.php?id='||id as href)  ,'Details') AS link,GivenName,Surname,Street,State FROM Customers ORDER BY ID" );

	if( ! $result ) {
	    echo "sasql_query failed!";
	} else {

	    echo "query completed successfully\n";
	    sasql_result_all( $result );
	
	    sasql_free_result( $result );
	}

	echo "Connected successfully\n";
	echo "<a href=\"master.php?start=" . $next . "\">Next</a>\n";
	echo "<a href=\"master.php?start=" . $previous  . "\">Previous</a>\n";
	sasql_close( $conn );
    }
?>
