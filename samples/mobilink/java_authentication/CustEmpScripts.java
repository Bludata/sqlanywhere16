// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// *******************************************************************
//
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
//
// *******************************************************************

// use a package when you create your own script

import	ianywhere.ml.script.InOutInteger;
import	ianywhere.ml.script.DBConnectionContext;
import	ianywhere.ml.script.ServerContext;
import	java.sql.*;

/**
 * Set of methods for use with Mobilink server. Synchronizes the
 * cust and emp tables also updates login_added and login_audit
 * when authenticating logins.
 * <p>
 * Note that class allows SQLException propagate up to Mobilink. Thus
 * any database errors will rollback the sync and cause the
 * connection to close.
 */
public class CustEmpScripts {
    /**
     * Context for this synchronization connection.
     */
    DBConnectionContext	_conn_context;
    /**
     * Same connection mobilink uses for sync
     * we can't commit or close this.
     */
    Connection			_sync_connection;
    /**
     * Connection we created, can commit and must
     * close this connection. Used for updates to
     * login_* tables which must be commited even
     * on sync rollback.
     */
    Connection			_audit_connection;
    /**
     * Prepared statement to get a user id given the
     * user name. On audit connection.
     */
    PreparedStatement		_get_user_id_pstmt;
    /**
     * Prepared statement to add record of user logins added.
     * On audit connection.
     */
    PreparedStatement		_insert_login_pstmt;
    /**
     * Prepared statement to add a record to the audit table.
     * On audit connection.
     */
    PreparedStatement		_insert_audit_pstmt;

    /**
     * Constructs sync logic class, allocating JDBC resources for
     * use later. We allocate all prepared statements now and will
     * use them for all the synchronizations on this connection.
     *
     * @param	cc  connection context allocated by Mobilink
     *
     * @throws	SQLException is passed up if thrown by any JDBC calls.
     */
    public CustEmpScripts(   DBConnectionContext   cc )
			throws SQLException
    {
	try {
	    _conn_context	    =   cc;
	    _sync_connection    =   _conn_context.getConnection();
    
	    ServerContext	serv_context = _conn_context.getServerContext();
	    _audit_connection   =   serv_context.makeConnection();
    
	    // get the prep statements ready
	    _get_user_id_pstmt = _audit_connection.prepareStatement(
		"select user_name from login_added where user_name = ?"
		);
	    _insert_login_pstmt= _audit_connection.prepareStatement(
		"insert into login_added( user_name, add_time ) " +
		" values( ?, { fn CONVERT( { fn NOW() }, SQL_VARCHAR ) })"
		);
	    _insert_audit_pstmt= _audit_connection.prepareStatement(
		"insert into login_audit( user_name, audit_time, audit_action ) " +
		" values( ?, { fn CONVERT( { fn NOW() }, SQL_VARCHAR ) }, ? ) "
		);
	} catch ( SQLException e ) {
	    freeJDBCResources();
	    throw e;
	} catch ( Error e ) {
	    freeJDBCResources();
	    throw e;
	}
    }
    /**
     * Makes sure that all Database resources have been freed. Should
     * only be needed if the end_connection script does not get called
     * before this class is freed. This should not happen but we want to
     * be safe.
     *
     * @throws	Throwable   if any exceptions occur while finalizing the
     *			    super class
     * @throws  SQLException if any JDBC errors occur while freeing JDBC
     *			     resources
     */
    protected void finalize()
			throws SQLException, Throwable
    {
	super.finalize();
	freeJDBCResources();
    }
    /**
     * Closes all prepared statements and the audit connection
     * we opened. This method may be called multiple times. Also
     * the class may have some null prepared statements 
     * if the constructor failed part way through.
     *
     * @throws SQLException if any JDBC instances through this
     *			    during cleanup
     */
    private void freeJDBCResources()
			throws SQLException
    {
	if( _get_user_id_pstmt != null ) {
	    _get_user_id_pstmt.close();
	}
	if( _insert_login_pstmt != null ) {
	    _insert_login_pstmt.close();
	}
	if( _insert_audit_pstmt != null ) {
	    _insert_audit_pstmt.close();
	}
	if( _audit_connection != null ) {
	    _audit_connection.close();
	}
	_conn_context	    = null;
	_sync_connection    = null;
	_audit_connection   = null;
	_get_user_id_pstmt  = null;
	_insert_login_pstmt = null;
	_insert_audit_pstmt = null;
    }
    /**
     * Cleans up resources before this connection is closed. This makes
     * sure that we don't leave _audit_connection open.
     *
     * @throws SQLException if an exception is created by cleanup of the JDBC resources
     */
    public void endConnection()
	    throws SQLException
    {
	freeJDBCResources();
    }
    /**
     * Approves all user logins and logs user information to database tables.
     * If the user is not in the login_added table we log to it.
     * If we find the user id in login_added we log to login_audit.
     * <p>
     * In a real system we would not ignore the user_password but in order
     * to keep this tutorial simple we approve all users.
     *
     * @param	auth_status set to inform mobilink of the authentication
     *			    result
     * @param	user_name   name of user we are authenticating
     *
     * @throws	SQLException if any of the database operations we perform
     *			     fail with an exception
     */
    public void authenticateUser(   InOutInteger	auth_status,
				    String		user_name )
			throws SQLException
				    // not using the following params
				    //String		user_password,
				    //String		user_new_password
    {
	// check if we've already seen the user
	_get_user_id_pstmt.setString( 1, user_name );
        ResultSet user_id_rs = _get_user_id_pstmt.executeQuery();
	
	if( user_id_rs.next() ) {
	    // if user is found, insert user name, time and action into the 
	    // audit table
	    _insert_audit_pstmt.setString( 1, user_name );
	    _insert_audit_pstmt.setString( 2, "LOGIN ALLOWED" );
	    _insert_audit_pstmt.executeUpdate(); 
	} else {
	    // if user is not found insert into logins_added
	    _insert_login_pstmt.setString( 1, user_name );
	    _insert_login_pstmt.executeUpdate();
	    // print some output to the mobilink log
	    java.lang.System.out.println( "user: " + user_name + " added. " );
	}

	// in this tutorial, always allow the login
	auth_status.setValue( 1000 );

	user_id_rs.close();
	user_id_rs = null;

	_audit_connection.commit();
	return;
    }
}
