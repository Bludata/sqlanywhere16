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
  if( $conn ) {
      // get the GROUPO user id
      $result = sasql_query( $conn, 
	    "SELECT user_id FROM SYS.SYSUSER WHERE user_name='GROUPO'" );
      if( $result ) {
	  $row = sasql_fetch_array( $result );
	  $user = $row[0];
      } else {
          $user = 0;
      }
      // get the tables created by user GROUPO
      $result = sasql_query( $conn, 
	    "SELECT table_id, table_name FROM SYS.SYSTABLE WHERE creator = $user" );
      if( $result ) {
          $num_rows = sasql_num_rows( $result );
          echo "Returned rows : $num_rows\n";
	  while( $row = sasql_fetch_array( $result ) ) {
              echo "Table: $row[1]\n";
              $query = "SELECT table_id, column_name FROM SYS.SYSCOLUMN WHERE table_id = '$row[table_id]'";
              $result2 = sasql_query( $conn, $query );
              if( $result2 ) {
		  echo "Columns:";
                  while( $detailed = sasql_fetch_array( $result2 ) ) {
                      echo " $detailed[column_name]";
                  }
                  sasql_free_result( $result2 );
              }
              echo "\n\n";
          }
          sasql_free_result( $result );
      }
      sasql_disconnect( $conn );
  }
?>
