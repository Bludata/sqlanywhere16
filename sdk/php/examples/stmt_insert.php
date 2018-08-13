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

   $conn = sasql_connect( "UID=DBA;PWD=sql" );
   if( !$conn ) {
       echo "Could not connect!\n";
       echo sasql_error();
       return;
   }
   echo "Connected successfully!\n";

   sasql_query( $conn, "DROP TABLE my_stmt_insert_test" );

   $create_table = "CREATE TABLE my_stmt_insert_test ( id INTEGER, value VARCHAR(256) )";
   if( !sasql_query( $conn, $create_table ) ) {
       echo "Failed to create table. Error: '" . sasql_error( $conn) . "'\n";
       return;
   }

   $stmt = sasql_prepare( $conn, "INSERT INTO my_stmt_insert_test VALUES( ?, ? )" );

   if( ! $stmt ) {
       echo "Could not prepare!\n";
       echo sasql_error( $conn );
       return;
   }

   sasql_stmt_bind_param( $stmt, "is", $id, $value );

   for( $id = 0; $id < 5000; $id++ ) {
       $value = "String_$id";
       if( !sasql_stmt_execute( $stmt ) ) {
	   echo "Failed to do insert number $id\n";
	   return;
       }
   }

   sasql_stmt_close( $stmt );

   sasql_close( $conn );

?>
