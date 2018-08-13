// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer 
// as to the original code.  
// 
// *******************************************************************
/*
    ODBC.C     General ODBC code for ODBC example (all platforms)
*/

// This sample program contains a hard-coded userid and password
// to connect to the demo database. This is done to simplify the
// sample program. The use of hard-coded passwords is strongly
// discouraged in production code.  A best practice for production
// code would be to prompt the user for the userid and password.

#include <string.h>
#include <sqlos.h>

#if defined( _SQL_OS_UNIX_VARIANT_MACOSX ) || defined( _SQL_OS_UNIX_VARIANT_FREEBSD )
    #include <stdlib.h>
#else
    #include <malloc.h>
#endif
#include <ctype.h>
#include <stdlib.h>
#include "example.h"

#if defined( UNIX )
    #include "unixodbc.h"
#elif defined( UNDER_CE )
    #if !defined( UNICODE )
	#define UNICODE
    #endif
    #include "ntodbc.h"
    #if defined( SQL_NOUNICODEMAP )
	// These two macros are required since Windows CE is UNICODE, but we
	// define SQL_NOUNICODEMAP to get the ASCII ODBC functions
	#define EX_SQL_C_TCHAR   	SQL_C_CHAR
	#define EX_SQLTCHAR		SQLCHAR
    
	// This code is not thread-safe since it uses a global buffer.
    
	static wchar_t			UnicodeBuffer[ 256 ];
	static char			MultiByteBuffer[ 256 ];
    
	#define WindowToDB_cnv( s )	(WideCharToMultiByte(		\
						CP_ACP,			\
						0,			\
						s,			\
						-1,			\
						(LPSTR) MultiByteBuffer,\
						sizeof( MultiByteBuffer ),\
						NULL,			\
						NULL ),			\
					    MultiByteBuffer)
	#define DBToWindow_cnv( s )	(MultiByteToWideChar(		\
						CP_ACP,			\
						0,			\
						(LPCSTR) s,		\
						-1,			\
						UnicodeBuffer,		\
						_countof( UnicodeBuffer ) ),\
					    UnicodeBuffer)
	#define _DBTEXT( s )		(EX_SQLTCHAR ODBCFAR *) s
    #endif
#elif defined( __NT__ )  ||  defined( __386__ )  ||  defined( _M_I386 )
    #include "ntodbc.h"
#else
    #error "Not sure which platform is targeted."
#endif


#if !defined( EX_SQL_C_TCHAR )
    // SQL_C_TCHAR is multi-byte for UNICODE, and single byte otherwise
    #define EX_SQL_C_TCHAR   	SQL_C_TCHAR
#endif

#if !defined( EX_SQLTCHAR )
    #define EX_SQLTCHAR		SQLTCHAR
#endif

#if !defined( WindowToDB_cnv )
    #define WindowToDB_cnv( s )	(s)
#endif

#if !defined( DBToWindow_cnv )
    #define DBToWindow_cnv( s )	(s)
#endif

#if !defined( _DBTEXT )
    #define _DBTEXT( s )	(EX_SQLTCHAR ODBCFAR *) TEXT(s)
#endif

#define SQL_MAX_NAME_LEN	200

typedef struct a_column {
    EX_SQLTCHAR *	value;
    SQLLEN      	size;   /* size of value fetched */
    EX_SQLTCHAR *	colname;
    unsigned int      	width;
} a_column;

extern int      	PageSize;
TCHAR			TableName[ NAME_LEN ];
a_column *       	Columns = NULL;
SWORD        		NumColumns;
HENV         		Environment;
HDBC         		Connection;
HSTMT        		Statement;

static int test_cursor_open( void )
{
    if( Statement == NULL ) {
        Displaytext( 0, TEXT( "*** Error: Cursor not open." MY_NEWLINE_STR ) );
	return( FALSE );
    }
    return( TRUE );
}

static int warning( TCHAR *msg )
{
    Displaytext( 0, TEXT( "Not found - %s" MY_NEWLINE_STR), msg );
    return( TRUE );
}

static int retcode( RETCODE rcode, HSTMT stmt )
{
    EX_SQLTCHAR		sqlstate[ 6 ];
    EX_SQLTCHAR		error_msg[ 512 ];

    if( rcode == SQL_SUCCESS || rcode == SQL_SUCCESS_WITH_INFO ) {
	return( TRUE );
    } else if( rcode == SQL_NO_DATA_FOUND ) {
	return( FALSE );
    } else {
	SQLError( Environment, Connection, stmt, sqlstate, NULL,
		  error_msg, _countof( error_msg ), NULL );
	Displaytext( 0, TEXT( "SQL error ### -- %s" MY_NEWLINE_STR ),
			DBToWindow_cnv( error_msg ) );
	return( FALSE );
    }
}

static void make_columns( HSTMT statement )
{
    EX_SQLTCHAR         colname[ NAME_LEN + 1 ];
    SWORD		namelen;
    UWORD		col;
    SQLLEN		size;

    retcode( SQLNumResultCols( statement, &NumColumns ), statement );
    Columns = (a_column *) malloc( NumColumns * sizeof( a_column ) );
    memset( Columns, 0, NumColumns * sizeof( a_column ) );
    for( col = 0; col < NumColumns; ++col ) {
    	retcode( SQLColAttributes( statement, (UWORD) (col + 1),
	    SQL_COLUMN_DISPLAY_SIZE, NULL, 0, NULL, &size ), statement );
    	if( size > MAX_FETCH_SIZE ) {
	    size = MAX_FETCH_SIZE;
    	}
    	Columns[ col ].width = (int) size;  // display size, not buffer size
    	Columns[ col ].value = (EX_SQLTCHAR *) malloc( (int)(size + 1)
							* sizeof( EX_SQLTCHAR ) );
    	retcode( SQLBindCol( statement, (UWORD) (col + 1), EX_SQL_C_TCHAR,
	    Columns[ col ].value, (size + 1) * sizeof( EX_SQLTCHAR ),
	    &Columns[ col ].size ), statement );
    	retcode( SQLColAttributes( statement, (UWORD) (col + 1),
	    SQL_COLUMN_NAME, colname, NAME_LEN * sizeof( EX_SQLTCHAR ),
	    &namelen, NULL ), statement );
    	Columns[ col ].colname = (EX_SQLTCHAR *) malloc( namelen
							 + sizeof( EX_SQLTCHAR ) );
	#if defined( UNICODE ) && !defined( SQL_NOUNICODEMAP )
	    wcscpy( Columns[ col ].colname, colname );
	#else
	    strcpy( (char *) Columns[ col ].colname, (char *) colname );
	#endif
    	if( Columns[ col ].width < (unsigned) namelen ) {
	    Columns[ col ].width = namelen;
    	}
    	if( Columns[ col ].width < NULL_TEXT_LEN ) {
	    Columns[ col ].width = NULL_TEXT_LEN;
    	}
    }
}

static void free_columns()
{
    int			col;

    if( Columns != NULL ) {
	for( col = 0; col < NumColumns; ++col ) {
	    free( Columns[ col ].value );
	    free( Columns[ col ].colname );
	}
	free( Columns );
	Columns = NULL;
    }
    NumColumns = 0;
}

static int close_cursor()
{
    free_columns();
    SQLFreeStmt( Statement, SQL_DROP );
    Statement = NULL;
    return( TRUE );
}

static int open_cursor()
{
    TCHAR		buff[ 100 ];

    if( !retcode( SQLAllocStmt( Connection, &Statement ), NULL ) ) {
	return( FALSE ); 
    }
    if( !retcode( SQLSetScrollOptions( Statement, SQL_CONCUR_VALUES, SQL_SCROLL_DYNAMIC, 1 ), Statement ) ) {
	close_cursor();
	return( FALSE );
    }
    _tcscpy( buff, TEXT( "select * from " ) );
    _tcscat( buff, TableName );
    if( !retcode( SQLPrepare( Statement,
			      (EX_SQLTCHAR ODBCFAR *) WindowToDB_cnv( buff ),
			      SQL_NTS ),
		  Statement ) ) {
	close_cursor();
	return( FALSE );
    }
    SQLSetStmtOption( Statement, SQL_TXN_ISOLATION, 0 );
    if( !retcode( SQLExecute( Statement ), Statement ) ) {
	close_cursor();
	return( FALSE );
    }
    make_columns( Statement );
    return( TRUE );
}

static int fetch_row()
{
    int			okay;
    SQLULEN		numfetch;

    okay = retcode( SQLExtendedFetch( Statement, SQL_FETCH_NEXT, 0,
			&numfetch, NULL ), Statement );
    if( !okay ) return( FALSE );
    if( numfetch == 0 ) {
	warning( TEXT( "fetching" ) );
	return( FALSE );
    }
    return( TRUE );
}

static int move( long relpos )
{
    SQLULEN		numfetch;
    int			okay;

    if( !test_cursor_open() ) {
	return( FALSE );
    }
    if( relpos == 0 ) {
	return( TRUE );
    }
    okay = retcode( SQLExtendedFetch( Statement,
				      SQL_FETCH_RELATIVE,
				      relpos,
				      &numfetch,
				      NULL ),
		    Statement );
    if( okay ) {
	if( numfetch == 0 ) {
	    warning( TEXT( "moving" ));
	}
    }
    return( okay );
}

static int top()
{
    SQLULEN		numfetch;
    int			okay;
    RETCODE		rcode;

    if( !test_cursor_open() ) {
	return( FALSE );
    }
    okay = retcode( SQLExtendedFetch( Statement, SQL_FETCH_FIRST, 0,
			&numfetch, NULL ), Statement );
    if( okay ) {
	rcode = SQLExtendedFetch( Statement,
				   SQL_FETCH_RELATIVE,
				   -1,
				   &numfetch,
				   NULL );
	if( rcode != SQL_NO_DATA_FOUND ) {
	    okay = retcode( rcode, Statement );
	}
    }
    return( okay );
}

static int bottom()
{
    SQLULEN		numfetch;
    int			okay;

    if( !test_cursor_open() ) {
	return( FALSE );
    }
    okay = retcode( SQLExtendedFetch( Statement, SQL_FETCH_LAST, 0,
			&numfetch, NULL ), Statement );
    return( okay );
}

static void print_headings()
{
    int                 i;
    int                 width;
    int                 total;

    total = 0;
    for( i = 0; i < NumColumns; ++i ) {
	width = Columns[ i ].width;
	total += Displaystringtext( total, width, (TCHAR *)DBToWindow_cnv( Columns[i].colname ) ) + 1;
    }
    Displaytext( 0, TEXT( "\n" ) );
}

static void print_data()
{
    int                 i;
    int                 width;
    int                 total;
    TCHAR		*data;

    total = 0;
    for( i = 0; i < NumColumns; ++i ) {
	width = Columns[ i ].width;
	if( Columns[ i ].size == SQL_NULL_DATA ) {
	    data = NULL_TEXT;
	} else {
	    data = (TCHAR *) DBToWindow_cnv( Columns[ i ].value );
	}
	total += Displaystringtext( total, width, data ) + 1;
    }
    Displaytext( 0, TEXT( "\n" ) );
}

static void print()
{
    int                 i;

    if( !test_cursor_open() ) {
	return;
    }
    print_headings();
    for( i = 0; i < PageSize; ) {
        ++i;
        if( !fetch_row() ) {
	    break;
	}
	print_data();
    }
    move( -i );
}

static void help()
{
    Displaytext( 0, TEXT( "ODBC Cursor Demonstration Program Commands:" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "p - Print current page" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "u - Move up a page" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "d - Move down a page" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "b - Move to bottom page" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "t - Move to top page" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "n - New table" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "q - Quit" MY_NEWLINE_STR ) );
    Displaytext( 0, TEXT( "h - Help (this screen)" MY_NEWLINE_STR ) );
}

int WSQLEX_Init( void )
{
    SQLRETURN rcode;
    
    if( SQLAllocEnv( &Environment ) != SQL_SUCCESS ) return( FALSE );
    if( SQLAllocConnect( Environment, &Connection ) != SQL_SUCCESS ) {
        SQLFreeEnv( Environment );
        return( FALSE );
    }
    if( (rcode = SQLDriverConnect( Connection, (SQLHWND)NULL,
			    _DBTEXT( "Driver=SQL Anywhere 16;UID=DBA;PWD=sql" ),
			    SQL_NTS,
			    NULL, 0,
			    NULL, SQL_DRIVER_NOPROMPT ) ) != SQL_SUCCESS ) {
	if( !retcode( SQLConnect( Connection,
			      _DBTEXT( "SQL Anywhere 16 Demo" ), SQL_NTS,
			      _DBTEXT( "DBA" ), SQL_NTS,
			      _DBTEXT( "sql" ), SQL_NTS ),
		  NULL ) ) {
	    SQLFreeConnect( Connection );
	    Display_systemerror( TEXT( "Unable to open data source" ) );
	    return( FALSE );
	}
    }
    GetTableName( TableName, MAX_TABLE_NAME );
    open_cursor();
    help(); 
    return( TRUE );
}

void WSQLEX_Process_Command( int selection )
{
    switch( tolower( selection ) ) {
    	case 'p':   	print();
			break;

	case 'u':	if( move( -PageSize ) ) {
			    print();
			}
			break;

	case 'd':	if( move( PageSize ) ) {
			    print();
			}
			break;

	case 't':	if( top() ) {
			    print();
			}
			break;

	case 'b':	if( bottom() ) {
			    move( -PageSize );
			    print();
			}
			break;

	case 'h':	help();
			break;

	case 'n':	close_cursor();
                    	GetTableName( TableName, MAX_TABLE_NAME);
                    	open_cursor();
			break;
			
	default:	Displaytext( 0, 
			    TEXT( "Invalid command, press 'h' for help" MY_NEWLINE_STR ) );
    }
}
			
int WSQLEX_Finish()
{
    close_cursor();
    SQLTransact( Environment, Connection, SQL_ROLLBACK );
    SQLDisconnect( Connection );
    SQLFreeConnect( Connection );
    SQLFreeEnv( Environment );
    return( TRUE );
}
