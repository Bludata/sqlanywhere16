<?php
function sa_session_open( $path, $name )
{
    return true;
}

function sa_session_close()
{
    # for security, we should unset the $_SESSION variable here
    # to ensure that subsequent calls will not get access
    # to our session variables
    if( isset( $_SESSION ) ) {
        unset( $_SESSION );
    }
    return true;
}

function sa_session_read( $session_id )
{
    $data;
    $conn = sasql_pconnect( '' );
    if( !$conn ) {
        return '';
    }

    $stmt = sasql_prepare( $conn,
                           'select data from sessions where session_id = ?' );
    if( !$stmt ) {
        return '';
    }

    sasql_stmt_bind_param( $stmt, "s", $session_id );
    sasql_stmt_bind_result( $stmt, $data );

    $result = sasql_stmt_execute( $stmt );

    if( !$result ) {
        sasql_stmt_close( $stmt );
        return '';
    }

    $result = sasql_stmt_fetch( $stmt );
    
    if( !$result ) {
        sasql_stmt_close( $stmt );
        return '';
    }

    sasql_stmt_close( $stmt );

    return $data;
}

function sa_session_write( $session_id, $data )
{
    $conn = sasql_pconnect( '' );
    if( !$conn ) {
        return false;
    }

    $stmt = sasql_prepare( $conn, 
                           'insert into sessions( ' .
                           '  session_id, updated, data ) ' .
                           'on existing update ' .
                           'values( ?, current timestamp, ? )' );
    if( !$stmt ) {
        sasql_error( $conn ) . "<br/>";
        return false;
    }
    
    sasql_stmt_bind_param( $stmt, "ss", $session_id, $data );

    $result = sasql_stmt_execute( $stmt );

    if( $result ) {
        sasql_commit( $conn );
    }

    sasql_stmt_close( $stmt );

    return (bool)$result;
}

function sa_session_destroy( $sesion_id )
{
    $conn = sasql_pconnect( '' );
    $stmt = sasql_prepare( $conn, 'delete from sessions where session_id = ?' );
    sasql_stmt_bind_param( $stmt, "s", $session_id );

    $result = sasql_stmt_execute( $stmt );

    if( $result ) {
        sasql_commit( $conn );
    }

    sasql_stmt_close( $stmt );

    return (bool)$result;
}

function sa_session_gc( $life )
{
    $conn = sasql_pconnect( '' );
    $stmt = sasql_prepare( $conn, 
                           'delete from sessions where datediff( ' .
                           '  second, current timestamp, updated ) > ?' );
    sasql_stmt_bind_param( $stmt, "i", $life );

    $result = sasql_stmt_execute( $stmt );

    if( $result ) {
        sasql_commit( $conn );
    }

    sasql_stmt_close( $stmt );

    return (bool)$result;
}

session_set_save_handler ('sa_session_open',
                          'sa_session_close',
                          'sa_session_read',
                          'sa_session_write',
                          'sa_session_destroy',
                          'sa_session_gc');
?> 