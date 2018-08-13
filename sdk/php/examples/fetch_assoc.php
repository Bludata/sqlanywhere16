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
    $conn = sasql_connect("UID=DBA;PWD=sql");
    
    /* check connection */
    if( sasql_errorcode() ) {
	printf("Connect failed: %s\n", sasql_error());
	exit();
    }
    
    $query = "SELECT Surname, Phone FROM Employees ORDER by EmployeeID";
    
    if( $result = sasql_query($conn, $query) ) {
    
	/* fetch associative array */
	while( $row = sasql_fetch_assoc($result) ) {
	    printf ("%s (%s)\n", $row["Surname"], $row["Phone"]);
	}
    
	/* free result set */
	sasql_free_result($result);
    }
    
    /* close connection */
    sasql_close($conn);
?>
