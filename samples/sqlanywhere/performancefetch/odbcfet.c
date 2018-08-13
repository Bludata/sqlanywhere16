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

#include "sqlos.h"

#if defined( UNIX )
    #include <sys/time.h>
    #include "unixodbc.h"
    #include "strings.h"
    #define _strieq( s1, s2 ) ( strcasecmp( s1, s2 ) == 0 )
#else
    #if !defined( USE_HI_RES_TIMER )
	#define USE_HI_RES_TIMER
    #endif
    #include "windows.h"
    #include <stddef.h>
    #include "ntodbc.h"
    #define _strieq( s1, s2 ) ( stricmp( s1, s2 ) == 0 )
#endif
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <string.h>

HENV		env;
HDBC		dbc;
HSTMT		stmt;
char *		ConnectStr	= "UID=DBA;PWD=sql";
char *		CursorType	= "NOSCROLL";
int		DescribeCount   = 1;
BOOL		DisplayTypes	= FALSE;
BOOL		FetchAsString	= FALSE;
char *		JSONTable	= NULL;
char *		OutputFile	= NULL;
int		RowLimit	= 0x7fffffffL;
int		RowsFetched	= 0;
unsigned	RowsPerFetch	= 1;
struct tm	StartTime;
BOOL		UseFetch	= FALSE;
BOOL		UseGetData	= FALSE;

unsigned char		Statement[10000];

#ifdef UNIX
    typedef struct timeval a_clock;
#else
    // use high resolution counter
    typedef __int64	a_clock;
#endif

static void GetCurrentClock( a_clock * oTime )
/*******************************************/
{
#ifdef UNIX
    gettimeofday( oTime, NULL );
#else
    LARGE_INTEGER	now = {0};

    if( QueryPerformanceCounter( &now ) ) {
	*oTime = now.QuadPart;
    } else { 
	fprintf( stderr, "**** FAILED TO QueryPerformanceCounter ****\n" );
	*oTime = 0;
    }
#endif
}

static double Duration( a_clock * start, a_clock * finish )
/*********************************************************/
{
#ifdef UNIX
    double time;
    double frac;
#else    
    LARGE_INTEGER	freq = {0};
#endif

#ifdef UNIX
    time = (double) (finish->tv_sec - start->tv_sec);
    frac = (double) (finish->tv_usec - start->tv_usec) / (double) 1000000 ;

    time += frac;
    return time;
#else
    if( !QueryPerformanceFrequency( &freq ) ) {
	fprintf( stderr, "**** FAILED TO QueryPerformanceFrequency ****\n" );
	freq.QuadPart = 1;
    }
    return( ((double) (*finish - *start)) / freq.QuadPart );
#endif
}

static BOOL ReadStatement( char *fname )
/**************************************/
{    
    FILE *	    fp;
    int		    size;

    if( JSONTable != NULL ) {
	if( fname != NULL ) {
	    fprintf( stderr, "Cannot specify a SQL file with -oj\n" );
	    return( FALSE );
	}
	sprintf( (char *)Statement, "SELECT * FROM %s", JSONTable );
	return( TRUE );
    }
    if( fname == NULL ) {
	fname = "test.sql";
    }
    fp = fopen( fname, "rt" );
    if( fp == NULL ) {
	fprintf( stderr, "Unable to open %s -- %s\n", fname, strerror( errno ) );
	return( FALSE );
    }
    size = (int)fread( Statement, sizeof(char), sizeof(Statement), fp );
    fclose( fp );
    Statement[size] = '\0';
    return( TRUE );
}

#define TIME_STR_SIZE 30

void WriteOutputFile( double total_time, 
		      double open_time, 
		      double fetch_time, 
		      double close_time )
/***************************************/
{
    FILE *	outfile;
    time_t	now;
    struct tm *	end_time;
    char	time_str[ TIME_STR_SIZE ];

    if( OutputFile == NULL ) return;
    outfile = fopen( OutputFile, JSONTable != NULL ? "at" : "wt" );
    if( outfile == NULL ) {
	fprintf( stderr, "Unable to open %s\n", OutputFile );
	return;
    }
    if( JSONTable != NULL ) {
	now = time( NULL );
	end_time = localtime( &now );

	fprintf( outfile, "{\n  \"program\": \"odbcfet\",\n" );
	fprintf( outfile, "  \"test_type\": \"FETCH\",\n" );
	// start_time and finish_time is approximate (computed separately from
	// elapsed_time)
	strftime( time_str, TIME_STR_SIZE, "%Y-%m-%d %H:%M:%S", &StartTime );
	fprintf( outfile, "  \"start_time\": \"%s\",\n", time_str );
	strftime( time_str, TIME_STR_SIZE, "%Y-%m-%d %H:%M:%S", end_time );
	fprintf( outfile, "  \"finish_time\": \"%s\",\n", time_str );
	fprintf( outfile, "  \"table_name\": \"%s\",\n", JSONTable );
	fprintf( outfile, "  \"cursor_type\": \"%s\",\n", CursorType );
	fprintf( outfile, "  \"width\": %d,\n", RowsPerFetch );
	fprintf( outfile, "  \"column_count\": %d,\n", DescribeCount );
	fprintf( outfile, "  \"record_count\": %d,\n", RowsFetched );
	// elapsed time is accurate to microsecond on Windows
	fprintf( outfile, "  \"elapsed_time\": %.06f,\n", total_time );
	fprintf( outfile, "  \"open_time\": %.06f,\n", open_time );
	fprintf( outfile, "  \"fetch_time\": %.06f,\n", fetch_time );
	fprintf( outfile, "  \"close_time\": %.06f\n", close_time );
	fprintf( outfile, "}\n" );
    } else { 
	fprintf( outfile, "%7.03f\n", fetch_time );
    }
    fclose( outfile );
}


static int CheckReturn( RETCODE rcode, HSTMT stmt )
{
    unsigned char	sqlstate[ 6 ];
    unsigned char	msg[ 256 ];

    if( rcode == SQL_SUCCESS || rcode == SQL_SUCCESS_WITH_INFO ) {
	return( TRUE );
    } else {
	SQLError( env, dbc, stmt, sqlstate, NULL, msg, sizeof( msg ), NULL );
	printf( "SQL error %s -- %s\n", sqlstate, msg );
	return( FALSE );
    }
}


static BOOL SetCursorType()
/*************************/
{    
    RETCODE	retcode;
    SQLULEN	curs_type = SQL_CURSOR_FORWARD_ONLY;

    if( !_strieq( CursorType, "NOSCROLL" ) ) {
	if( _strieq( CursorType, "DYNAMIC" ) ) {
	    curs_type = SQL_CURSOR_DYNAMIC;
	} else if( _strieq( CursorType, "INSENSITIVE" ) ) {
	    curs_type = SQL_CURSOR_STATIC;
	} else if( _strieq( CursorType, "SCROLL" ) ) {
	    curs_type = SQL_CURSOR_DYNAMIC;
	} else {
	    printf( "Ignoring unknown cursor type of %s\n", CursorType );
	}
	retcode = SQLSetStmtAttr( stmt, SQL_ATTR_CURSOR_TYPE,
				  (SQLPOINTER) curs_type, SQL_IS_INTEGER );
	if( !CheckReturn( retcode, stmt ) ) return( FALSE );
    }
    return( TRUE );
}

typedef struct col_data {
    SQLSMALLINT		bind_type;
    SQLLEN		bind_size;
    char		*buf;
} col_data;

void FillBindColData( col_data *col, SQLLEN odbctype, SQLLEN display_size )
/*************************************************************************/
{
    SQLSMALLINT bind_type   = SQL_C_CHAR;
    SQLLEN	bind_size   = display_size + 1;
    SQLLEN	alloc_size  = display_size + 2;

    if( !FetchAsString ) {
	// bind native types
	switch( odbctype ) {
	case SQL_BIT:
	case SQL_TINYINT:
	case SQL_SMALLINT:
	case SQL_INTEGER:
	    bind_type = SQL_C_LONG;
	    bind_size = alloc_size = 4;
	    break;
	case SQL_BIGINT:
	    bind_type = SQL_C_SBIGINT;
	    bind_size = alloc_size = 8;
	    break;
	case SQL_REAL:
	    bind_type = SQL_C_FLOAT;
	    bind_size = alloc_size = 4;
	    break;
	case SQL_FLOAT:
	case SQL_DOUBLE:
	    bind_type = SQL_C_DOUBLE;
	    bind_size = alloc_size = 8;
	    break;
	case SQL_BINARY:
	case SQL_VARBINARY:
	case SQL_LONGVARBINARY:
	    bind_type = SQL_C_BINARY;
	    break;
	}
    }

    col->bind_type = bind_type;
    col->bind_size = bind_size;
    col->buf = (char *)malloc( (alloc_size) * RowsPerFetch );
    if( col->buf == NULL ) {
	printf( "Out of memory\n" );
    }
}

void TestFetchSpeed()
/*******************/    
{
    RETCODE	retcode;
    a_clock	total_start, total_end;
    a_clock	fetch_start;
    a_clock	close_start;
    time_t	now;
    double	total_time, open_time, fetch_time, close_time;
    SWORD	i;
    SWORD	count;
    col_data	*col;
    SQLLEN 	size;
    SQLLEN *	pcbValue;
    SQLULEN	rowcount;
    SQLLEN	odbctype;

    now = time( NULL );
    memcpy( &StartTime, localtime( &now ), sizeof( StartTime ) );
    GetCurrentClock( &total_start );
    SQLAllocStmt( dbc, &stmt );
    if( !SetCursorType() ) return;
    retcode = SQLExecDirect( stmt, Statement, SQL_NTS );
    if( !CheckReturn( retcode, stmt ) ) return;
    retcode = SQLNumResultCols( stmt, &count );
    if( !CheckReturn( retcode, stmt ) ) return;
    DescribeCount = count;
    col = (col_data *)malloc( count * sizeof( col_data ) );
    pcbValue = (SQLLEN *)malloc( RowsPerFetch * sizeof( SQLLEN ) );
    for( i = 0; i < count; ++i ) {
	retcode = SQLColAttributes( stmt, (UWORD) (i + 1), SQL_COLUMN_TYPE, NULL, 0, NULL, &odbctype );
	if( !CheckReturn( retcode, stmt ) ) return;
	if( DisplayTypes ) {
	    printf( "col[%2d]:  %ld\n", i + 1, odbctype );
	}
    	retcode = SQLColAttributes( stmt, (UWORD) (i + 1), SQL_COLUMN_DISPLAY_SIZE, NULL, 0, NULL, &size );
	if( !CheckReturn( retcode, stmt ) ) return;
	FillBindColData( &col[i], odbctype, size );
	if( !UseGetData ) {
	    retcode = SQLBindCol( stmt, (UWORD) (i + 1), col[i].bind_type,
				    col[i].buf, col[i].bind_size, pcbValue );
	    if( !CheckReturn( retcode, stmt ) ) return;
	}
    }

    if( RowsPerFetch > 0 && !UseFetch ) {
	retcode = SQLSetStmtOption( stmt, SQL_ROWSET_SIZE, RowsPerFetch );
	if( !CheckReturn( retcode, stmt ) ) return;
    }

    GetCurrentClock( &fetch_start );
    open_time = Duration( &total_start, &fetch_start );

    for( ;; ) {
	if( UseFetch ) {
	    retcode = SQLFetch( stmt );
	    rowcount = 1;
	} else {
	    retcode = SQLExtendedFetch( stmt, SQL_FETCH_NEXT, 0, &rowcount, NULL );
	}
	if( retcode == SQL_NO_DATA_FOUND ) break;
	if( !CheckReturn( retcode, stmt ) ) return;
	if( UseGetData ) {
	    for( i = 0; i < (UWORD) (count*RowsPerFetch); ++i ) {
		retcode = SQLGetData( stmt, (UWORD) (i + 1), col[i].bind_type, 
				     col[i].buf, col[i].bind_size, pcbValue );
		if( !CheckReturn( retcode, stmt ) ) return;
	    }
	}
	RowsFetched += (int)rowcount;
	if( rowcount < RowsPerFetch && !UseFetch ) break;
	if( RowsFetched >= RowLimit ) break;
    }
    GetCurrentClock( &close_start );
    fetch_time = Duration( &fetch_start, &close_start );
    retcode = SQLFreeStmt( stmt, SQL_CLOSE );
    if( !CheckReturn( retcode, stmt ) ) return;
    retcode = SQLFreeStmt( stmt, SQL_DROP );
    if( retcode != SQL_SUCCESS ) {
	printf( "SQLFreeStmt( stmt, SQL_DROP ) returned %d", retcode );
    }
    GetCurrentClock( &total_end );
    close_time = Duration( &close_start, &total_end );
    total_time = Duration( &total_start, &total_end );
    printf( "Open Time:  %.03f seconds\n", open_time );
    printf( "Fetch Time: %.03f seconds\n", fetch_time );
    printf( "Close Time: %.03f seconds\n", close_time );
    printf( "Total Time: %.03f seconds\n", total_time );
    printf( "Retrieved %d rows in %.03f seconds - %ld per second\n",
	    RowsFetched, 
	    fetch_time, 
	    (fetch_time == 0.0) ? 0 : (long)((double)RowsFetched / fetch_time) );
    
    WriteOutputFile( total_time, open_time, fetch_time, close_time );
}

static int ArgumentIsASwitch( char * arg )
/****************************************/
{
#if defined( UNIX )
    return ( arg[0] == '-' );
#else
    return ( arg[0] == '-' ) || ( arg[0] == '/' );
#endif
}

static int ProcessOptions( char *argv[] )
/*************************************/
{
    int		    argc;
    char *	    arg;
    char	    opt;

#define _get_arg_param()						\
	    arg += 2;							\
	    if( !arg[0] ) arg = argv[++argc];				\
	    if( arg == NULL ) {						\
		fprintf( stderr, "Missing argument parameter\n" );	\
		return( -1 );						\
	    }

    for( argc = 1; (arg = argv[argc]) != NULL; ++ argc ) {
	if( !ArgumentIsASwitch( arg ) ) break;	
	opt = arg[1];
	switch( opt ) {
	case 'b':
	    _get_arg_param();
	    RowsPerFetch = atol( arg );
	    break;
	case 'c':
	    _get_arg_param();
	    ConnectStr = arg;
	    break;
	case 'd':
	    DisplayTypes = TRUE;
	    break;
	case 'f':
	    UseFetch = TRUE;
	    break;
	case 'g':
	    UseGetData = TRUE;
	    break;
	case 'o':
	    if( arg[2] == 'j' ) {
		arg++;
		_get_arg_param();
		JSONTable = arg;
	    } else {
		_get_arg_param();
		OutputFile = arg;
	    }
	    break;
	case 'l':
	    _get_arg_param();
	    RowLimit = atol( arg );
	    break;
	case 't':
	    _get_arg_param();
	    CursorType = arg;
	    break;
	case 'z':
	    FetchAsString = TRUE;
	    break;
	default:
	    fprintf( stderr, "Usage: ODBCFET [options] fname\n" );
	    fprintf( stderr, "Options:\n" );
	    fprintf( stderr, "   -b nnn          : fetch nnn rows at a time\n" );
	    fprintf( stderr, "   -c conn_str     : database connection string\n" );
	    fprintf( stderr, "   -d              : display datatypes\n" );
	    fprintf( stderr, "   -f              : use SQLFetch (not SQLExtendedFetch)\n" );
	    fprintf( stderr, "   -g              : use SQLGetData (not SQLBindCol)\n" );
	    fprintf( stderr, "   -l nnn          : stop after nnn rows\n" );
	    fprintf( stderr, "   -o file         : record fetch duration to file\n" );
	    fprintf( stderr, "   -oj table       : output JSON format, truncate then insert into table\n" );
	    fprintf( stderr, "   -t cursor_type  : DYNAMIC, INSENSITIVE, or SCROLL (default NOSCROLL)\n" );
	    fprintf( stderr, "   -z              : fetch as string (default uses native types)\n" );
	    return( -1 );
	}
    }
    return( argc );
}

int main( int argc, char * argv[] )
/*********************************/    
{
    char *	    fetch_type;
    char *	    bind_type;
    RETCODE	    retcode;

    argc = ProcessOptions( argv );
    if( argc < 0 ) {
	return( -1 );
    }

    if( !ReadStatement( argv[argc] ) ) {
	return( -2 );
    }
    
    SQLAllocHandle( SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env );
    SQLSetEnvAttr( env, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, 0 );
    SQLAllocHandle( SQL_HANDLE_DBC, env, &dbc );
    retcode = SQLDriverConnect( dbc, (SQLHWND)NULL, (SQLCHAR *) ConnectStr, SQL_NTS, NULL, 0, NULL, SQL_DRIVER_NOPROMPT );
    if( !CheckReturn( retcode, stmt ) ) return( -2 );

    fetch_type = UseFetch ? (char *)"SQLFetch" : (char *)"SQLExtendedFetch";
    bind_type = UseGetData ? (char *)"SQLGetData" : (char *)"SQLBindCol";
    printf( "Using %s and %s ...\n", bind_type, fetch_type );
    
    TestFetchSpeed();

    SQLDisconnect( dbc );
    SQLFreeHandle( SQL_HANDLE_DBC, dbc );
    SQLFreeHandle( SQL_HANDLE_STMT, env );

    return( 0 );
}

