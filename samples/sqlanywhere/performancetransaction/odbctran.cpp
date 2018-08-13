// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/* *********************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// ****************************************************************** */

/****************************************************************************
 *									    *
 *	Sybase SQL Anywhere Transaction Test Utility			    *
 *									    *
 ****************************************************************************/

// ODBC API

#include "trantest.hpp"


#define _check( result )    CheckRetcode( environment, connection, NULL, result, thread )
#define _check_stmt( result, stmt )    CheckRetcode( environment, connection, stmt, result, thread )

a_bool CheckRetcode( HENV env, HDBC conn, HSTMT stmt, RETCODE rc, TransactionThread * thread )
/********************************************************************************************/
{
    char	sqlstate[6];
    char	error_msg[512];
    
    if( rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO ) {
	return( TRUE );
    }
    SQLError( env, conn, stmt, (unsigned char *) sqlstate, NULL,
	      (unsigned char *) error_msg, sizeof( error_msg ), NULL );
    PrintError( thread, error_msg );
    return( FALSE );
}

a_bool ODBCAPI::Connect( TransactionThread * thread )
/***************************************************/
{
    if( SQLAllocEnv( &environment ) != SQL_SUCCESS ) {
	return( FALSE );
    }
    if( SQLAllocConnect( environment, &connection ) != SQL_SUCCESS ) {
        SQLFreeEnv( environment );
        return( FALSE );
    }
    if( SQLDriverConnect( connection, (SQLHWND)NULL,
		    (unsigned char *) BMark->connect_string,
		    (short) strlen( BMark->connect_string ), NULL,
		    0, NULL, SQL_DRIVER_NOPROMPT ) != SQL_SUCCESS ) {
	PrintError( thread, "Unable to connect" );
	SQLFreeConnect( connection );
        SQLFreeEnv( environment );
	return( FALSE );
    }
    thread->connected = TRUE;
    return( TRUE );
}

a_bool ODBCAPI::Disconnect( TransactionThread * thread )
/******************************************************/
{
    if( thread->connected ) {
	SQLDisconnect( connection );
	SQLFreeConnect( connection );
	SQLFreeEnv( environment );
	thread->connected = FALSE;
    }
    return( TRUE );
}

a_bool ODBCAPI::Commit( TransactionThread * thread )
/**************************************************/
{
    return( _check( SQLEndTran( SQL_HANDLE_DBC, connection, SQL_COMMIT ) ) );
}

a_bool ODBCAPI::Rollback( TransactionThread * thread )
/****************************************************/
{
    return( _check( SQLEndTran( SQL_HANDLE_DBC, connection, SQL_ROLLBACK ) ) );
}

a_bool ODBCAPI::ExecSQLString( TransactionThread * thread, char * str )
/*********************************************************************/
{
    HSTMT	    stmt;
    RETCODE	    rc;
    a_bool	    okay = FALSE;

    if( SQLAllocStmt( connection, &stmt ) == SQL_SUCCESS ) {
	if( SQLPrepare( stmt, (unsigned char *) str, SQL_NTS ) == SQL_SUCCESS ) {
	    rc = SQLExecute( stmt );
	    okay = ( rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO );
	}
	SQLFreeStmt( stmt, SQL_DROP );
    }
    if( !okay ) {
	PrintError( thread, "Error executing statement" );
    }
    return( okay );
}

void ODBCAPI::MakeOutput( TransactionThread * thread, int stnum )
/***************************************************************/
{
    UWORD		col;
    SQLLEN		size;
    char **		cols;
    int *		params;
    HSTMT		stmt	= statement[stnum];
    SWORD		ncols;
    SWORD		nparams;
    SQLHDESC		desc;

    SQLNumResultCols( stmt, &ncols );
    num_cols[stnum] = ncols;
    if( ncols > 0 ) {
	cols = (char **) malloc( ncols * sizeof( char * ) );
	has_result_set[stnum] = TRUE;
    } else {
	cols = NULL;
    }
    columns[stnum] = cols;
    for( col = 0; col < ncols; ++col ) {
    	SQLColAttributes( stmt, (UWORD) (col + 1),
	    SQL_COLUMN_DISPLAY_SIZE, NULL, 0, NULL, &size );
    	if( size > MAX_FETCH_SIZE ) {
	    size = MAX_FETCH_SIZE;
    	}
    	cols[col] = (char *) malloc( (int)(size + 1) );
    	_check_stmt( SQLBindCol( stmt, (UWORD)(col + 1), SQL_C_CHAR,
	    cols[col], (size + 1), NULL ), stmt );
    }
    SQLNumParams( stmt, &nparams );
    num_params[stnum] = nparams;
    if( nparams > 0 ) {
	params = (int *) malloc( nparams * sizeof( int * ) );
    } else {
	params = NULL;
    }
    parm_types[stnum] = params;
    if( nparams > 0 ) {
	SQLGetStmtAttr( stmt, SQL_ATTR_IMP_PARAM_DESC, &desc, SQL_IS_POINTER, NULL );
	for( col = 0; col < nparams; ++col ) {
	    // Determine if any parameters are output; if so, can't have a
	    // result set.
	    SQLGetDescField( desc, (UWORD)(col+1), SQL_DESC_PARAMETER_TYPE,
		&params[col], SQL_IS_INTEGER, NULL );
	    if( params[col] == SQL_PARAM_INPUT_OUTPUT
	    ||  params[col] == SQL_PARAM_OUTPUT ) {
		has_result_set[stnum] = FALSE;
	    }
	}
    }
}

a_bool ODBCAPI::Prepare( TransactionThread * thread, char * str, int stnum )
/**************************************************************************/
{
    if( !_check( SQLAllocStmt( connection, &statement[stnum] ) ) ) {
	return( FALSE );
    }
    if( !_check_stmt( SQLPrepare( statement[stnum], (unsigned char *) str, SQL_NTS ),
	    statement[stnum] ) ) {
	SQLFreeStmt( statement[stnum], SQL_DROP );
	return( FALSE );
    }
    has_result_set[stnum] = FALSE;

    MakeOutput( thread, stnum );
    return( TRUE );
}

a_bool ODBCAPI::SetParm( TransactionThread * thread, int parmnum, char * parmval, int stnum )
/*******************************************************************************************/
{
    SQLLEN		len;
    HSTMT		stmt = statement[stnum];
    SQLLEN		ind = SQL_NULL_DATA;
    SQLLEN *		indptr;
    int *		parms;

    if( parmval == NULL ) {
	len = 0;
	indptr = &ind;
    } else {
	len = (SQLLEN)strlen( parmval ) + 1;
	indptr = NULL;
    }
    if( parmnum < num_params[stnum] ) {
	parms = parm_types[stnum];
	_check_stmt( SQLBindParameter( stmt, (UWORD)(parmnum+1), (SWORD) parms[parmnum],
			SQL_C_CHAR, SQL_VARCHAR, (UDWORD) len, 0, parmval, len, indptr ), stmt );
    }
    return( TRUE );
}

a_bool ODBCAPI::Execute( TransactionThread * thread, int stnum )
/**************************************************************/
{
    HSTMT		stmt = statement[stnum];
    a_bool		result;
    RETCODE		rc;
    
    result = _check_stmt( SQLExecute( stmt ), stmt );
    if( has_result_set[stnum] ) {
	for( ;; ) {
	    rc = SQLFetch( stmt );
	    if( rc == SQL_NO_DATA_FOUND ) break;
	    result = _check_stmt( rc, stmt );
	    if( !result ) break;
	}
	SQLFreeStmt( stmt, SQL_CLOSE );
    }
    return( result );
}

a_bool ODBCAPI::Drop( TransactionThread * /* thread */, int stnum )
/*****************************************************************/
{
    int			col;
    char **		cols = columns[stnum];

    SQLFreeStmt( statement[stnum], SQL_DROP );
    for( col = 0; col < num_cols[stnum]; ++col ) {
	free( cols[ col ] );
    }
    free( cols );
    for( col = 0; col < num_params[stnum]; ++col ) {
	free( parm_types[ col ] );
    }
    columns[stnum] = NULL;
    num_cols[stnum] = 0;
    num_params[stnum] = 0;
    return( TRUE );
}

a_bool ODBCAPI::GetIntQuery( TransactionThread * thread, char * str, int * result )
/*********************************************************************************/
{
    HSTMT	    stmt;
    RETCODE	    rc;
    a_bool	    okay = FALSE;

    if( SQLAllocStmt( connection, &stmt ) == SQL_SUCCESS ) {
	if( SQLPrepare( stmt, (unsigned char *) str, SQL_NTS ) == SQL_SUCCESS ) {
	    rc = SQLExecute( stmt );
	    okay = ( rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO );
	    SQLBindCol( stmt, 1, SQL_C_LONG, result, sizeof(*result), NULL );
	    okay = _check_stmt( SQLFetch( stmt ), stmt );
	}
	SQLFreeStmt( stmt, SQL_DROP );
    }
    if( !okay ) {
	PrintError( thread, "Error executing statement" );
    }
    return( okay );
}
