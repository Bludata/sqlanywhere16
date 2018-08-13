<?php
#   *******************************************************************
#   Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
#   This sample code is provided AS IS, without warranty or liability of
#   any kind.
#  
#   You may use, reproduce, modify and distribute this sample code without
#   limitation, on the condition that you retain the foregoing copyright 
#   notice and disclaimer as to the original code.  
#   
#   *******************************************************************
?>
<?php
# Functions for demonstrating server-side php support

function sphp_create_table()
{
    # function to create a table using server-side php
    $conn = sasql_pconnect( '' );
    if( !sasql_query( $conn,
                              "CREATE TABLE sphp_Tab( c1 int, c2 char(128), " .
                              "c3 smallint, c4 double, " . 
                              "c5 numeric(30,6) )" ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }
}

function sphp_populate_table( $in1 )
{
    # function to populate the above table using server-side php
    # input variable is the number of rows to populate
    
    $conn = sasql_pconnect( '' );
    for( $i = 1; $i <= $in1; $i++ ) {
        if( !sasql_query( $conn, "INSERT INTO sphp_Tab VALUES( $i, " .
                                  "'This is row #$i', " . 
                                  ( 8000 + $i ) . ", " .
                                  ( $i / 0.03 ) . ", 0.0$i )" ) ) {
            throw new Exception( sasql_error( $conn ), 
                                 sasql_errorcode( $conn ) );
        }
    }

    sasql_commit( $conn );
}

function sphp_update_table()
{
    # function to update the above table using server-side php
    $conn = sasql_pconnect( '' );
    if( !sasql_query( $conn, "UPDATE sphp_Tab SET c1 = c3" ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }

    if( !sasql_commit( $conn ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }
}

function sphp_delete_table()
{
    # function to delete from the above table using server-side php
    $conn = sasql_pconnect( '' );
    if( !sasql_query( $conn, "DELETE FROM sphp_Tab" ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }
    
    if( !sasql_commit( $conn ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }
}

function sphp_drop_table()
{
    # function to drop the above table using server-side php
    $conn = sasql_pconnect( '' );
    if( !sasql_query( $conn, "DROP TABLE sphp_Tab" ) ) {
        throw new Exception( sasql_error( $conn ), 
                             sasql_errorcode( $conn ) );
    }
}

?>
