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

    # Ensure that the SQL Anywhere PHP module is loaded
    if( !extension_loaded('sqlanywhere') ) {
	# Find out which version of PHP is running
	$version = phpversion();
	$module_name = 'php-'.$version.'_sqlanywhere';
	if( strtoupper(substr(PHP_OS, 0, 3) == 'WIN' )) {
	    $module_ext = '.dll';
	} else {
	    $module_ext = '.so';
	}
	if( !dl( $module_name.$module_ext ) ) {
	    exit;
	}
    }
    echo "<HTML>\n";

    $qname = $_POST[qname];
    echo "<form method=post action=webisql.php>\n";
    echo "<br>Query : <input type=text name=qname value=\"$qname\">\n";
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

	$result = sasql_query( $conn, $qname );

	if( ! $result ) {
	    echo "sasql_query failed!";
	} else {

	    // echo "query completed successfully\n";
	    sasql_result_all( $result, "border=1" );
	
	    sasql_free_result( $result );
	}

	sasql_close( $conn );
    }

    echo "</html>\n";
?>
