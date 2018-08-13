// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#include <stdio.h>
#include "ulcpp.h"

// Our error callback function: this is called automatically when an UltraLite
// database error occurs. 
static ul_error_action UL_CALLBACK_FN my_error_callback(
    const ULError *	error,
    void *		userData )
{
    char		buf[100];

    switch( error->GetSQLCode() ) {
	// Ignore SQLE_NOTFOUND warnings:
	case SQLE_NOTFOUND:
	    break;
	// Print a special message when the database doesn't exist:
	case SQLE_ULTRALITE_DATABASE_NOT_FOUND:
	    error->GetParameter( 1, buf, sizeof(buf) );
	    printf( "note: database '%s' does not exist\n", buf );
	    break;
	default:
	    error->GetString( buf, sizeof(buf) );
	    printf( "%s: %s\n", error->GetSQLCode() < 0 ? "Error" : "Warning", buf );
	    break;
    }
    return UL_ERROR_ACTION_DEFAULT;
}

static void fetch_all( ULResultSet * rs )
{
    ULResultSetSchema const & schema = rs->GetResultSetSchema();
    ul_column_num	cid;
    char const *	sep;
    const int		max_data = 80;
    char		data_buf[max_data];

    rs->BeforeFirst(); // ensure the cursor is in the "just opened" state
    printf( "\n" );
    sep = "";
    for( cid = 1; cid <= schema.GetColumnCount(); cid++ ) {
	printf( "%s%s", sep, schema.GetColumnName( cid ) );
	sep = ",\t";
    }
    printf( "\n" );
    while( rs->Next() ) {
	sep = "";
	for( cid = 1; cid <= schema.GetColumnCount(); cid++ ) {
	    rs->GetString( cid, data_buf, max_data );
	    printf( "%s'%s'", sep, data_buf );
	    sep = ",\t";
	}
	printf( "\n" );
    }
}

static void create_schema( ULConnection * conn )
{
    printf( "creating schema\n" );
    conn->ExecuteStatement(
	    "create table table1 "
	    "( pkey int not null default autoincrement primary key"
	    ", data varchar(300)"
	    ")" );
    conn->ExecuteStatement(
	    "create index table1_data on table1 (data asc)"
	    );
}

static void inserts( ULConnection * conn )
{
    int			i;
    const int		width = 8;
    char		data_buf[width];
    ULPreparedStatement * ps;
    ULTable *		table;

    // Insert data using a prepared statement object with parameters.
    i = 0;
    ps = conn->PrepareStatement( "insert into table1 ( data ) values( ? )" );
    if( ps ) {
	for( ; i < width/2; i++ ) {
	    data_buf[i] = '\0';
	    ps->SetParameterString( 1, data_buf );
	    data_buf[i] = (char)('A' + i);
	    ps->ExecuteStatement();
	}
	ps->Close();
    }
    // Insert data using a table object.
    table = conn->OpenTable( "table1" );
    if( table ) {
	for( ; i < width; i++ ) {
	    table->InsertBegin();
	    data_buf[i] = '\0';
	    table->SetString( 2, data_buf );
	    data_buf[i] = (char)('A' + i);
	    table->Insert();
	}
	table->Close();
    }
    // Commit all inserts as one transaction.
    conn->Commit();
}

static void fetches( ULConnection * conn )
{
    ULTable *		table;
    ULPreparedStatement * ps;
    ULResultSet *	rs;

    // Fetch data using a table object...
    table = conn->OpenTable( "table1" );
    if( table ) {
	fetch_all( table );
	table->Close();
    }
    // ...and a SQL query.
    ps = conn->PrepareStatement( "select pkey, data from table1 order by data desc" );
    if( ps ) {
	rs = ps->ExecuteQuery();
	if( rs ) {
	    fetch_all( rs );
	    rs->Close();
	}
	ps->Close();
    }
}

static void test()
{
    ULError		error;
    ULConnection *	conn;
    char const *	connect_parms = "DBF=ulsample.udb";

    conn = ULDatabaseManager::OpenConnection( connect_parms, &error );
    if( ! conn ) {
	// Connection failed - create the database if need be.
	if( error.GetSQLCode() == SQLE_ULTRALITE_DATABASE_NOT_FOUND ) {
	    printf( "creating database\n" );
	    conn = ULDatabaseManager::CreateDatabase( connect_parms, NULL, &error );
	    if( conn ) {
		create_schema( conn );
	    }
	}
    }
    if( conn ) {
	inserts( conn );
	fetches( conn );
	conn->Close();
    } else {
	printf( "Error! unable to find or create database\n" );
    }
}

int main()
{
    // Call Init() first (on a single thread).
    if( ULDatabaseManager::Init() ) {
	// Register callback for errors - useful especially during development.
	ULDatabaseManager::SetErrorCallback( &my_error_callback, NULL );

	test();

	// Call Fini last.
	ULDatabaseManager::Fini();
    } else {
	printf( "Error! basic initialization failed\n" );
    }
    return 0;
}
