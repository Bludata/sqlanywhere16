// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of
// any kind.
// 
// You may use, reproduce, modify and distribute this sample code without
// limitation, on the condition that you retain the foregoing copyright 
// notice and disclaimer as to the original code.  
// 
// *******************************************************************

// Example of performing server-side request using the C_ODBC external environment

#include "testsrc.h"

#include "odbc.h"

static HDBC GetConnection( an_extfn_api *api, void *arg_handle )
/*************************************************************/
{
    an_extfn_value	arg;

    // returns the server-side connection (note the connection already exists and is ready for use)
    if( api->get_value( arg_handle, EXTFN_CONNECTION_HANDLE_ARG_NUM, &arg ) && arg.data != NULL ) {
	return( (HDBC)arg.data );
    }

    return( SQL_NULL_HDBC );
}

static void RunQuery( an_extfn_api *api, void *arg_handle, SQLCHAR *query )
/*************************************************************************/
{
    // Run a query via ODBC using the server-side connection
    HDBC dbc = GetConnection( api, arg_handle );

    if( dbc == SQL_NULL_HDBC ) {
	return;
    }

    HSTMT stmt = SQL_NULL_HSTMT;
    SQLRETURN ret = SQLAllocHandle( SQL_HANDLE_STMT, dbc, &stmt );
    if( ret != SQL_SUCCESS ) {
	return;
    }

    SQLExecDirect( stmt, query, SQL_NTS );
    SQLFreeHandle( SQL_HANDLE_STMT, stmt );
}

_VOID_ENTRY CreateTable( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    RunQuery( api, arg_handle, (SQLCHAR *)"CREATE TABLE ExtServerSide_Tab( c1 int, c2 char(128), c3 smallint, c4 double, c5 numeric(30,6) )" );
}

_VOID_ENTRY UpdateTable( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    RunQuery( api, arg_handle, (SQLCHAR *)"UPDATE ExtServerSide_Tab SET c1 = c3" );
}

_VOID_ENTRY DeleteTable( an_extfn_api *api, void *arg_handle )
/************************************************************/
{
    RunQuery( api, arg_handle, (SQLCHAR *)"DELETE FROM ExtServerSide_Tab" );
}

_VOID_ENTRY DropTable( an_extfn_api *api, void *arg_handle )
/**********************************************************/
{
    RunQuery( api, arg_handle, (SQLCHAR *)"DROP TABLE ExtServerSide_Tab" );
}

_VOID_ENTRY PopulateTable( an_extfn_api *api, void *arg_handle )
/**************************************************************/
{
    HDBC dbc = GetConnection( api, arg_handle );

    if( dbc == SQL_NULL_HDBC ) {
	return;
    }

    HSTMT stmt = SQL_NULL_HSTMT;
    SQLRETURN ret = SQLAllocHandle( SQL_HANDLE_STMT, dbc, &stmt );
    if( ret != SQL_SUCCESS ) {
	return;
    }

    ret = SQLPrepare( stmt, (SQLCHAR *)"INSERT INTO ExtServerSide_Tab VALUES( ?, ?, ?, ?, ? )", SQL_NTS );
    if( ret != SQL_SUCCESS ) {
	SQLFreeHandle( SQL_HANDLE_STMT, stmt );
	return;
    }

    for( int i = 1; i <= 1000; ++i ) {
	SQLINTEGER	    c1;
	SQLCHAR 	    c2[128];
	SQLSMALLINT	    c3;
	SQLDOUBLE	    c4;
	SQLINTEGER	    c5;
    
	SQLLEN		    ind[5+1] = {0, sizeof(SQLINTEGER), 0, sizeof(SQLSMALLINT), sizeof(SQLDOUBLE), sizeof(SQLINTEGER)};
    
	c1 = i;
	sprintf( (char *)c2, "This is row #%d", i );
	ind[2] = (SQLLEN)strlen( (char *)c2 );
	c3 = (SQLSMALLINT)(8000 + i);
	c4 = ((SQLDOUBLE)i) / 0.03;
	c5 = i;

	ret = SQLBindParameter( stmt, 1, SQL_PARAM_INPUT, SQL_C_SLONG,  SQL_INTEGER,  ind[1],   0, &c1, 0,   &ind[1] );
	if( ret != SQL_SUCCESS ) {
	    break;
	}
	ret = SQLBindParameter( stmt, 2, SQL_PARAM_INPUT, SQL_C_CHAR,   SQL_CHAR   ,  ind[2],   0, c2,  128, &ind[2] );
	if( ret != SQL_SUCCESS ) {
	    break;
	}
	ret = SQLBindParameter( stmt, 3, SQL_PARAM_INPUT, SQL_C_SSHORT, SQL_SMALLINT, ind[3],   0, &c3, 0,   &ind[3] );
	if( ret != SQL_SUCCESS ) {
	    break;
	}
	ret = SQLBindParameter( stmt, 4, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE,   ind[4],   0, &c4, 0,   &ind[4] );
	if( ret != SQL_SUCCESS ) {
	    break;
	}
	ret = SQLBindParameter( stmt, 5, SQL_PARAM_INPUT, SQL_C_SLONG,  SQL_INTEGER,  ind[5],   0, &c5, 0,   &ind[5] );
	if( ret != SQL_SUCCESS ) {
	    break;
	}

	ret = SQLExecute( stmt );
	if( ret != SQL_SUCCESS ) {
	    break;
	}
    }

    SQLFreeHandle( SQL_HANDLE_STMT, stmt );
}

