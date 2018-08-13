<?PHP
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
	echo "Connected successfully\n";
	# Execute a SELECT statement
	$result = sasql_query( $conn, "SELECT * FROM Customers" );
	if( ! $result ) {
	    echo "sasql_query failed!";
	} else {
	    echo "query completed successfully\n";
	    # Generate HTML from the result set
	    sasql_result_all( $result );
	    sasql_free_result( $result );
	}
	sasql_close( $conn );
    }
?>
