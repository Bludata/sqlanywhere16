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

    echo "<HTML>\n";
    echo "<body onload=\"document.getElementById('qbox').focus()\">\n";

    $qname = $_POST[qname];
    $qname = str_replace( "\\", "", $qname );
    echo "<form method=post action=webisql.php>\n";
    echo "<br>Query : <input id=qbox type=text size=80 name=qname value=\"$qname\">\n";
    echo "<input type=submit>\n";
    echo "</form>\n";
    echo "<HR><br>\n";

    if( ! $qname ) {
        echo "No Current Query\n";
        return; 
    } 

    $conn = sasql_connect( "UID=DBA;PWD=sql" );

    if( ! $conn ) {
	echo "sasql_connect failed\n";
    } else {

	$qname = str_replace( "\\", "", $qname );
	$result = sasql_query( $conn, $qname );

	if( ! $result ) {
	    echo "sasql_query failed!";
	} else {

	    if( sasql_field_count( $conn ) > 0 ) {
		sasql_result_all( $result, "border=1" );
		sasql_free_result( $result );
	    } else {
		echo "The statement <h3>$qname></h3> executed successfully!";
	    }
	}

	sasql_close( $conn );
    }

    echo "</body>\n";
    echo "</html>\n";
?>
