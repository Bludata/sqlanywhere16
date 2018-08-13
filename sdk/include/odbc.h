// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _ODBC_H_INCLUDED
#define _ODBC_H_INCLUDED
#define __ODBC_H_INCLUDED

#include "sqlos.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/*	ODBC.H
	Definitions for using ODBC functions
*/

/* Platform-specific definitions */

#if defined( UNIX ) && ! defined( ODBC_UNIX )
    #define ODBC_UNIX
#endif
#ifndef ODBC_UNIX
  #ifndef ODBC_WINNT
    /* Default platform is Microsoft Windows NT */
    #define ODBC_WINNT
  #endif
#endif
#ifdef ODBC_WINNT
    #define ODBC_API	__stdcall
    #define ODBCFAR
#endif /* ODBC_WINNT */
#ifdef ODBC_UNIX
    #define ODBC_API
    #define ODBCFAR
#endif /* ODBC_UNIX */

#ifndef ODBCVER
#define ODBCVER		0x0351
#endif /* ODBCVER */
  
#if defined( UNIX64 ) && !defined( LONG_IS_64BITS )
    #define LONG_IS_64BITS
#endif

#if !defined( ODBC_64BIT ) && (ODBCVER >= 0x0300)
    #if defined( _WIN64 ) || defined( UNIX64 )
        #define ODBC_64BIT     
    #endif
#endif

// Driver-specific connection and statement attributes
#include "saodbc.h"

/******************************************************************/
/*  Define structure packing macro based on environment           */
/******************************************************************/

#if defined( ODBC_WINNT )
    #define _ODBC_PACK_STRUCTURES    1
#endif

/* RETCODES */

enum enumRETCODE {
    SQL_INVALID_HANDLE	= -2,
    SQL_ERROR,
    SQL_SUCCESS,
    SQL_SUCCESS_WITH_INFO,
    SQL_STILL_EXECUTING,
    SQL_NEED_DATA	= 99,
    SQL_NO_DATA_FOUND	= 100
    #if (ODBCVER >= 0x0300)
    ,
    SQL_NO_DATA		= 100
    #endif /* ODBCVER >= 0x0300 */
};

typedef signed short	RETCODE;

/* Test for SQL_SUCCESS or SQL_SUCCESS_WITH_INFO */
#define SQL_SUCCEEDED( rc )	(((rc)&(~1))==0)

/* SQL Types */

enum enumSQLTYPE {
    SQL_TYPE_NULL	= 0,
    SQL_UNKNOWN_TYPE	= 0,
    /* ANSI numbering */
    SQL_CHAR,
    SQL_NUMERIC,
    SQL_DECIMAL,
    SQL_INTEGER,
    SQL_SMALLINT,
    SQL_FLOAT,
    SQL_REAL,
    SQL_DOUBLE,
    SQL_DATE,
    #if (ODBCVER >= 0x0300)
    SQL_DATETIME	= 9,
    #endif /* ODBCVER >= 0x0300 */
    SQL_TIME,
    #if (ODBCVER >= 0x0300)
    SQL_INTERVAL	= 10,
    #endif /* ODBCVER >= 0x0300 */
    SQL_TIMESTAMP,
    SQL_VARCHAR,
    #if (ODBCVER >= 0x0300)
    /* Shortcuts */
    SQL_TYPE_DATE	= 91,
    SQL_TYPE_TIME,
    SQL_TYPE_TIMESTAMP,
    /* Miscellaneous types */
    SQL_DEFAULT		= 99,
    SQL_ARD_TYPE	= -99,
    #endif /* ODBCVER >= 0x0300 */
    /* ODBC extensions */
    SQL_BIT		= -7,
    SQL_TINYINT,
    SQL_BIGINT,
    SQL_LONGVARBINARY,
    SQL_VARBINARY,
    SQL_BINARY,
    SQL_LONGVARCHAR,
    #if (ODBCVER >= 0x0350)
    SQL_GUID	= -11,
    #endif  /* ODBCVER >= 0x0350 */

	SQL_WCHAR		 = -8,
	SQL_WVARCHAR 	 = -9,
	SQL_WLONGVARCHAR = -10

};

#if (ODBCVER <= 0x0300)
enum enumUNICODE {
    SQL_UNICODE_LONGVARCHAR	= -97,
    SQL_UNICODE_VARCHAR,
    SQL_UNICODE_CHAR,		/* = SQL_UNICODE */
    SQL_UNICODE			= -95
};
#else
/* The previous definitions for SQL_UNICODE_ are historical and obsolete */

#define	SQL_UNICODE				SQL_WCHAR
#define	SQL_UNICODE_VARCHAR		SQL_WVARCHAR
#define SQL_UNICODE_LONGVARCHAR	SQL_WLONGVARCHAR
#define SQL_UNICODE_CHAR		SQL_WCHAR
#endif

#if (ODBCVER >= 0x0300)
enum enumDateTimeCode {
    SQL_CODE_DATE	= 1,
    SQL_CODE_TIME,
    SQL_CODE_TIMESTAMP
};

enum enumIntervalCode {
    SQL_CODE_YEAR	= 1,
    SQL_CODE_MONTH,
    SQL_CODE_DAY,
    SQL_CODE_HOUR,
    SQL_CODE_MINUTE,
    SQL_CODE_SECOND,
    SQL_CODE_YEAR_TO_MONTH,
    SQL_CODE_DAY_TO_HOUR,
    SQL_CODE_DAY_TO_MINUTE,
    SQL_CODE_DAY_TO_SECOND,
    SQL_CODE_HOUR_TO_MINUTE,
    SQL_CODE_HOUR_TO_SECOND,
    SQL_CODE_MINUTE_TO_SECOND
};
#define SQL_INTERVAL_YEAR		(100 + SQL_CODE_YEAR)
#define SQL_INTERVAL_MONTH		(100 + SQL_CODE_MONTH)
#define SQL_INTERVAL_DAY		(100 + SQL_CODE_DAY) 
#define SQL_INTERVAL_HOUR		(100 + SQL_CODE_HOUR) 
#define SQL_INTERVAL_MINUTE		(100 + SQL_CODE_MINUTE) 
#define SQL_INTERVAL_SECOND		(100 + SQL_CODE_SECOND)
#define SQL_INTERVAL_YEAR_TO_MONTH	(100 + SQL_CODE_YEAR_TO_MONTH)
#define SQL_INTERVAL_DAY_TO_HOUR	(100 + SQL_CODE_DAY_TO_HOUR) 
#define SQL_INTERVAL_DAY_TO_MINUTE	(100 + SQL_CODE_DAY_TO_MINUTE) 
#define SQL_INTERVAL_DAY_TO_SECOND	(100 + SQL_CODE_DAY_TO_SECOND) 
#define SQL_INTERVAL_HOUR_TO_MINUTE	(100 + SQL_CODE_HOUR_TO_MINUTE)
#define SQL_INTERVAL_HOUR_TO_SECOND	(100 + SQL_CODE_HOUR_TO_SECOND) 
#define SQL_INTERVAL_MINUTE_TO_SECOND	(100 + SQL_CODE_MINUTE_TO_SECOND)
#else
#define SQL_INTERVAL_YEAR		(-80)
#define SQL_INTERVAL_MONTH		(-81)
#define SQL_INTERVAL_YEAR_TO_MONTH	(-82)
#define SQL_INTERVAL_DAY		(-83)
#define SQL_INTERVAL_HOUR		(-84)
#define SQL_INTERVAL_MINUTE		(-85)
#define SQL_INTERVAL_SECOND		(-86)
#define SQL_INTERVAL_DAY_TO_HOUR	(-87)
#define SQL_INTERVAL_DAY_TO_MINUTE	(-88)
#define SQL_INTERVAL_DAY_TO_SECOND	(-89)
#define SQL_INTERVAL_HOUR_TO_MINUTE	(-90)
#define SQL_INTERVAL_HOUR_TO_SECOND	(-91)
#define SQL_INTERVAL_MINUTE_TO_SECOND	(-92)
#endif /* ODBCVER >= 0x0300 */

#if (ODBCVER < 0x0300)
#define SQL_TYPE_DRIVER_START	SQL_INTERVAL_YEAR
#define SQL_TYPE_DRIVER_END	SQL_UNICODE_LONGVARCHAR
#define SQL_TYPE_MIN		SQL_BIT
#define SQL_TYPE_MAX		SQL_VARCHAR
#endif /* ODBCVER < 0x0300 */
#define SQL_ALL_TYPES		0

#if (ODBCVER >= 0x0200)
    #define SQL_SIGNED_OFFSET	(-20)
    #define SQL_UNSIGNED_OFFSET	(-22)
#endif /* ODBCVER >= 0x0200 */

/* C types -- defined in terms of corresponding SQL types */

#define SQL_C_CHAR		SQL_CHAR
#define SQL_C_LONG		SQL_INTEGER
#define SQL_C_SHORT		SQL_SMALLINT
#define SQL_C_FLOAT		SQL_REAL
#define SQL_C_DOUBLE		SQL_DOUBLE
#define SQL_C_DEFAULT		99
#define SQL_C_DATE		SQL_DATE
#define SQL_C_TIME		SQL_TIME
#define SQL_C_TIMESTAMP		SQL_TIMESTAMP
#define SQL_C_BINARY		SQL_BINARY
#define SQL_C_BIT		SQL_BIT
#define SQL_C_TINYINT		SQL_TINYINT
#if (ODBCVER >= 0x0200)
    #define SQL_C_SLONG		(SQL_C_LONG+SQL_SIGNED_OFFSET)
    #define SQL_C_SSHORT	(SQL_C_SHORT+SQL_SIGNED_OFFSET)
    #define SQL_C_STINYINT	(SQL_TINYINT+SQL_SIGNED_OFFSET)
    #define SQL_C_ULONG		(SQL_C_LONG+SQL_UNSIGNED_OFFSET)
    #define SQL_C_USHORT	(SQL_C_SHORT+SQL_UNSIGNED_OFFSET)
    #define SQL_C_UTINYINT	(SQL_TINYINT+SQL_UNSIGNED_OFFSET)
    #if defined( ODBC_64BIT )
	#define SQL_C_BOOKMARK	SQL_C_UBIGINT
    #else
	#define SQL_C_BOOKMARK	SQL_C_ULONG
    #endif
#endif /* ODBCVER >= 0x0200 */
#if (ODBCVER >= 0x0300)
#define SQL_C_NUMERIC			SQL_NUMERIC
#define SQL_C_TYPE_DATE			SQL_TYPE_DATE
#define SQL_C_TYPE_TIME			SQL_TYPE_TIME
#define SQL_C_TYPE_TIMESTAMP		SQL_TYPE_TIMESTAMP
#define SQL_C_INTERVAL_YEAR		SQL_INTERVAL_YEAR
#define SQL_C_INTERVAL_MONTH		SQL_INTERVAL_MONTH
#define SQL_C_INTERVAL_DAY		SQL_INTERVAL_DAY
#define SQL_C_INTERVAL_HOUR		SQL_INTERVAL_HOUR
#define SQL_C_INTERVAL_MINUTE		SQL_INTERVAL_MINUTE
#define SQL_C_INTERVAL_SECOND		SQL_INTERVAL_SECOND
#define SQL_C_INTERVAL_YEAR_TO_MONTH	SQL_INTERVAL_YEAR_TO_MONTH
#define SQL_C_INTERVAL_DAY_TO_HOUR	SQL_INTERVAL_DAY_TO_HOUR
#define SQL_C_INTERVAL_DAY_TO_MINUTE	SQL_INTERVAL_DAY_TO_MINUTE
#define SQL_C_INTERVAL_DAY_TO_SECOND	SQL_INTERVAL_DAY_TO_SECOND
#define SQL_C_INTERVAL_HOUR_TO_MINUTE	SQL_INTERVAL_HOUR_TO_MINUTE
#define SQL_C_INTERVAL_HOUR_TO_SECOND	SQL_INTERVAL_HOUR_TO_SECOND
#define SQL_C_INTERVAL_MINUTE_TO_SECOND	SQL_INTERVAL_MINUTE_TO_SECOND
#define SQL_C_SBIGINT			(SQL_BIGINT+SQL_SIGNED_OFFSET)
#define SQL_C_UBIGINT			(SQL_BIGINT+SQL_UNSIGNED_OFFSET)
#define SQL_C_VARBOOKMARK		SQL_C_BINARY
#endif /* ODBCVER >= 0x0300 */
#if (ODBCVER >= 0x0350)
#define SQL_C_GUID	SQL_GUID
#endif  /* ODBCVER >= 0x0350 */
#define SQL_C_WCHAR			SQL_WCHAR

#ifdef UNICODE
#define SQL_C_TCHAR			SQL_C_WCHAR
#else
#define SQL_C_TCHAR			SQL_C_CHAR
#endif


/* Portable C data types */

// need to undefine some stuff for CodeWarrior
#if defined(UCHAR)
#undef UCHAR
#endif
#if defined(ULONG)
#undef ULONG
#endif

typedef unsigned char		UCHAR;
typedef signed char		SCHAR;
typedef unsigned short		UWORD;
typedef signed short		SWORD;
#if defined(__alpha) || defined(LONG_IS_64BITS)
  typedef unsigned int		UDWORD;
  typedef signed int		SDWORD;
  typedef signed int		SLONG;
  typedef unsigned int		ULONG;
#else
  typedef unsigned long		UDWORD;
  typedef signed long		SDWORD;
  typedef signed long		SLONG;
  typedef unsigned long		ULONG;
#endif
typedef signed short		SSHORT;
typedef unsigned short		USHORT;
typedef double			SDOUBLE;
typedef double			LDOUBLE;
typedef float			SFLOAT;
typedef void ODBCFAR *		PTR;

/* API data types */

typedef unsigned char		SQLCHAR;
#if defined(__alpha) || defined(LONG_IS_64BITS)
  typedef int			SQLINTEGER;
  typedef unsigned int		SQLUINTEGER;
#else
  typedef long			SQLINTEGER;
  typedef unsigned long		SQLUINTEGER;
#endif
typedef void ODBCFAR *		SQLPOINTER;
typedef short			SQLSMALLINT;
typedef unsigned short		SQLUSMALLINT;
typedef SQLSMALLINT		SQLRETURN;
typedef unsigned short		SQLWCHAR;
#ifdef UNICODE
typedef SQLWCHAR		SQLTCHAR;
#else
typedef SQLCHAR			SQLTCHAR;
#endif /* UNICODE */
typedef PTR			SQLHANDLE;
typedef SQLHANDLE		SQLHENV;
typedef SQLHANDLE		SQLHDBC;
typedef SQLHANDLE		SQLHSTMT;
typedef SQLHANDLE		SQLHDESC;
#if (ODBCVER >= 0x0300)
typedef signed char		SQLSCHAR;
typedef unsigned char		SQLDATE;
typedef unsigned char		SQLDECIMAL;
typedef double			SQLDOUBLE;
typedef double			SQLFLOAT;
typedef unsigned char		SQLNUMERIC;
typedef float			SQLREAL;
typedef unsigned char		SQLTIME;
typedef unsigned char		SQLTIMESTAMP;
typedef unsigned char		SQLVARCHAR;
#if defined(_MSC_VER)
  #if (_MSC_VER >= 900)
    #define ODBCINT64		__int64
    #define ODBCUINT64		unsigned __int64
  #endif /* _MSC_VER >= 900 */
#endif
#if defined(__WATCOMC__)
  #if __WATCOMC__ >= 1100
    #define ODBCINT64		__int64
    #define ODBCUINT64		unsigned __int64
  #endif
#endif
#if defined(__BORLANDC__)
  #if defined (_INTEGRAL_MAX_BITS) && (_INTEGRAL_MAX_BITS >= 64)
    #define ODBCINT64		__int64
  #endif
#endif
#endif /* (ODBCVER >= 0x0300) */

#if ( defined( ODBC_UNIX ) || defined (  ODBC_64BIT ) ) && defined( UNIX64 )
    #define ODBCINT64		long
    #define ODBCUINT64		unsigned long
#elif defined( ODBC_UNIX )
    #define ODBCINT64		long long
    #define ODBCUINT64		unsigned long long
#endif
#ifdef ODBCINT64
  typedef ODBCINT64		SQLBIGINT;
  typedef unsigned ODBCINT64	SQLUBIGINT;
#endif /* ODBCINT64 */

// The following is derived from MSVC7 include files & allows us to enable
// 64-bit warnings for certain types during 32-bit builds
#if !defined(_W64)
    #if !defined(POINTERS_ARE_64BITS) && !defined(_WIN64) && _MSC_VER+0 >= 1300
	#define _W64 __w64
    #else
	#define _W64
    #endif
#endif

#if defined( ODBC_64BIT )
    typedef ODBCINT64 		SQLLEN;
    typedef ODBCUINT64 		SQLULEN;
    typedef ODBCUINT64 		SQLSETPOSIROW;
#else
    typedef SQLINTEGER _W64	SQLLEN;
    typedef SQLUINTEGER	_W64	SQLULEN;
    typedef SQLUSMALLINT 	SQLSETPOSIROW;
#endif

/* Define some common things often found in WINDOWS.H */

#if defined( __BORLANDC__ ) && defined( __WINDOWS_H ) && !defined( _INC_WINDOWS )
    #define _INC_WINDOWS
#endif

#if !defined(_INC_WINDOWS) && !defined(_WINDEF_)
     #if !defined(_OBJC_OBJC_H_)
     /* When using Project Builder to build a Cocoa Application
        on Mac OS X, BOOL is already typedef'ed */
         typedef int                   BOOL;
     #endif
    typedef unsigned int		HWND;
#endif

#if !defined(TRUE)
#define TRUE		1
#endif /* !defined( TRUE ) */
#if !defined(FALSE)
#define FALSE		0
#endif /* !defined( FALSE ) */

/* CLI option values */
#if (ODBCVER >= 0x0300)
#define SQL_FALSE	0
#define SQL_TRUE	1
#endif /* ODBCVER >= 0x0300 */

/* Handle types */

typedef void ODBCFAR * HENV;
typedef void ODBCFAR * HDBC;
typedef void ODBCFAR * HSTMT;

#if defined( ODBC_WINNT )
  typedef HWND		SQLHWND;
#elif defined( ODBC_UNIX ) && ( defined(__alpha) || defined(LONG_IS_64BITS) )
  typedef unsigned int	SQLHWND;
#elif defined( ODBC_UNIX )
  typedef unsigned long	SQLHWND;
#else
  typedef SQLPOINTER	SQLHWND;
#endif

#define SQL_NULL_HENV	0
#define SQL_NULL_HDBC	0
#define SQL_NULL_HSTMT	0
#if (ODBCVER >= 0x0300)
#define SQL_NULL_HDESC	0
#define SQL_NULL_HANDLE	0L
#endif /* ODBCVER >= 0x0300 */

#if (ODBCVER >= 0x0300)
enum enumHANDLETYPE {
    SQL_HANDLE_ENV	= 1,
    SQL_HANDLE_DBC,
    SQL_HANDLE_STMT,
    SQL_HANDLE_DESC,
    SQL_HANDLE_SENV
};
#endif /* ODBCVER >= 0x0300 */

/* Special length values */

enum enumLENGTH {
    SQL_IGNORE		= -6,
    SQL_DEFAULT_PARAM,
    SQL_NO_TOTAL,
    SQL_NTS,
    SQL_DATA_AT_EXEC,
    SQL_NULL_DATA
};
#if (ODBCVER >= 0x0300)
#define SQL_COLUMN_IGNORE		SQL_IGNORE
#endif /* ODBCVER >= 0x0300 */

#define SQL_NTSL	-3L
    
/* Miscellaneous constants */
#define SQL_SPEC_MAJOR			3
#define SQL_SPEC_MINOR			51
#define SQL_SPEC_STRING			"03.51"
#define SQL_SQLSTATE_SIZE		5
#define	SQL_MAX_MESSAGE_LENGTH		512
#define SQL_MAX_DSN_LENGTH		32
#define SQL_MAX_OPTION_STRING_LENGTH	256

/* C structures */

#if (ODBCVER >= 0x0300)
#define SQL_DATE_LEN		10
#define	SQL_TIME_LEN		8
#define SQL_TIMESTAMP_LEN	19
#endif /* ODBCVER >= 0x0300 */

#ifndef __SQLDATE
#define __SQLDATE
#if defined( ODBC_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk2.h"
#endif
typedef struct tagDATE_STRUCT {
    SQLSMALLINT		year;
    SQLUSMALLINT	month;
    SQLUSMALLINT	day;
} DATE_STRUCT;

typedef struct tagTIME_STRUCT {
    SQLUSMALLINT	hour;
    SQLUSMALLINT	minute;
    SQLUSMALLINT	second;
} TIME_STRUCT;

typedef struct tagTIMESTAMP_STRUCT {
    SQLSMALLINT		year;
    SQLUSMALLINT	month;
    SQLUSMALLINT	day;
    SQLUSMALLINT	hour;
    SQLUSMALLINT	minute;
    SQLUSMALLINT	second;
    SQLUINTEGER		fraction;
} TIMESTAMP_STRUCT;

#if (ODBCVER >= 0x0300)
typedef DATE_STRUCT		SQL_DATE_STRUCT;
typedef TIME_STRUCT		SQL_TIME_STRUCT;
typedef TIMESTAMP_STRUCT	SQL_TIMESTAMP_STRUCT;

typedef enum {
    SQL_IS_YEAR = 1,
    SQL_IS_MONTH,
    SQL_IS_DAY,
    SQL_IS_HOUR,
    SQL_IS_MINUTE,
    SQL_IS_SECOND,
    SQL_IS_YEAR_TO_MONTH,
    SQL_IS_DAY_TO_HOUR,
    SQL_IS_DAY_TO_MINUTE,
    SQL_IS_DAY_TO_SECOND,
    SQL_IS_HOUR_TO_MINUTE,
    SQL_IS_HOUR_TO_SECOND,
    SQL_IS_MINUTE_TO_SECOND
} SQLINTERVAL;

typedef struct tagSQL_YEAR_MONTH {
    SQLUINTEGER		year;
    SQLUINTEGER		month;
} SQL_YEAR_MONTH_STRUCT;

typedef struct tagSQL_DAY_SECOND {
    SQLUINTEGER		day;
    SQLUINTEGER		hour;
    SQLUINTEGER		minute;
    SQLUINTEGER		second;
    SQLUINTEGER		fraction;
} SQL_DAY_SECOND_STRUCT;

typedef struct tagSQL_INTERVAL_STRUCT {
    SQLINTERVAL		interval_type;
    SQLSMALLINT		interval_sign;
    union {
	SQL_YEAR_MONTH_STRUCT	year_month;
	SQL_DAY_SECOND_STRUCT	day_second;
    } intval;
} SQL_INTERVAL_STRUCT;
#endif /* ODBCVER >= 0x0300 */
#endif /* __SQLDATE */

#if (ODBCVER >= 0x0300)
#define SQL_MAX_NUMERIC_LEN	16
typedef struct tagSQL_NUMERIC_STRUCT {
    SQLCHAR		precision;
    SQLSCHAR		scale;
    SQLCHAR		sign;	/* 1 if positive, 0 if negative */
    SQLCHAR		val[ SQL_MAX_NUMERIC_LEN ];
} SQL_NUMERIC_STRUCT;
#endif  /* ODBCVER >= 0x0300 */


#if (ODBCVER >= 0x0350)
#ifdef GUID_DEFINED
typedef GUID	SQLGUID;
#else
/* size is 16 */
typedef struct  tagSQLGUID {
    SDWORD 		Data1;
    SWORD 		Data2;
    SWORD 		Data3;
    UCHAR 		Data4[ 8 ];
} SQLGUID;
#endif  /* GUID_DEFINED */
#endif  /* ODBCVER >= 0x0350 */

#if (ODBCVER >= 0x0200)
#if defined(__alpha) || defined(LONG_IS_64BITS)
  typedef unsigned int		BOOKMARK;
#else
  typedef unsigned long int	BOOKMARK;
#endif
#endif /* ODBCVER >= 0x0200 */

#if defined( ODBC_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

/* Values that may be defined elsewhere */

#ifndef NULL
#define NULL		0
#endif /* NULL */

/* API functions -- handles */

#ifndef UL_ODBC
#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLAllocHandle(	/* CORE */
    SQLSMALLINT		HandleType,
    SQLHANDLE		InputHandle,
    SQLHANDLE ODBCFAR *	OutputHandle );

SQLRETURN ODBC_API SQLFreeHandle(	/* CORE */
    SQLSMALLINT		HandleType,
    SQLHANDLE		Handle );

SQLRETURN ODBC_API SQLAllocHandleStd(
    SQLSMALLINT		fHandleType,
    SQLHANDLE		hInput,
    SQLHANDLE ODBCFAR *	phOutput );
#endif /* ODBCVER >= 0x0300 */
#endif // UL_ODBC

/* -------------------------------------------------------------------- */
/* SQLAllocHandleStd implemented to be compatible with X/Open standard  */
/* An application should not call SQLAllocHandleStd directly            */
/* -------------------------------------------------------------------- */
#ifdef ODBC_STD
#define SQLAllocHandle		SQLAllocHandleStd
#define SQLAllocEnv( phenv )	SQLAllocHandleStd( \
				SQL_HANDLE_ENV, SQL_NULL_HANDLE, phenv )

/* Internal type subcodes */
#define SQL_YEAR		SQL_CODE_YEAR
#define SQL_MONTH		SQL_CODE_MONTH
#define SQL_DAY			SQL_CODE_DAY
#define SQL_HOUR		SQL_CODE_HOUR
#define SQL_MINUTE		SQL_CODE_MINUTE
#define SQL_SECOND		SQL_CODE_SECOND
#define SQL_YEAR_TO_MONTH	SQL_CODE_YEAR_TO_MONTH
#define SQL_DAY_TO_HOUR		SQL_CODE_DAY_TO_HOUR
#define SQL_DAY_TO_MINUTE	SQL_CODE_DAY_TO_MINUTE
#define SQL_DAY_TO_SECOND	SQL_CODE_DAY_TO_SECOND
#define SQL_HOUR_TO_MINUTE	SQL_CODE_HOUR_TO_MINUTE
#define SQL_HOUR_TO_SECOND	SQL_CODE_HOUR_TO_SECOND
#define SQL_MINUTE_TO_SECOND	SQL_CODE_MINUTE_TO_SECOND
#endif /* ODBC_STD */

/* API functions -- environment */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLAllocEnv(		/* CORE */
    SQLHENV ODBCFAR *	EnvironmentHandle );

SQLRETURN ODBC_API SQLError(				/* CORE */
    SQLHENV			EnvironmentHandle,
    SQLHDBC			ConnectionHandle,
    SQLHSTMT			StatementHandle,
    SQLCHAR ODBCFAR *		Sqlstate,		/* Always SQLSTATE_SIZE+1 bytes */
    SQLINTEGER ODBCFAR *	NativeError,
    SQLCHAR ODBCFAR *		MessageText,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	TextLength );

SQLRETURN ODBC_API SQLDataSources(	/* Level 2 */
    SQLHENV			EnvironmentHandle,
    SQLUSMALLINT		Direction,	/* enumSQLFetchType */
    SQLCHAR ODBCFAR *		ServerName,
    SQLSMALLINT			BufferLength1,
    SQLSMALLINT ODBCFAR *	NameLength1,
    SQLCHAR ODBCFAR *		Description,
    SQLSMALLINT			BufferLength2,
    SQLSMALLINT ODBCFAR *	NameLength2 );

SQLRETURN ODBC_API SQLFreeEnv(		/* CORE */
    SQLHENV			EnvironmentHandle );
#endif // UL_ODBC

#if (ODBCVER >= 0x0300)
enum enumODBCVersion {
    SQL_OV_ODBC2		= 2UL,
    SQL_OV_ODBC3		= 3UL
};

enum enumConnectionPooling {
    SQL_CP_OFF			= 0UL,
    SQL_CP_ONE_PER_DRIVER	= 1UL,
    SQL_CP_ONE_PER_HENV		= 2UL
};

enum enumCPMatch {
    SQL_CP_STRICT_MATCH		= 0UL,
    SQL_CP_RELAXED_MATCH	= 1UL
};

/* Special values for certain options */
#define SQL_CP_DEFAULT		SQL_CP_OFF
#define SQL_CP_MATCH_DEFAULT	SQL_CP_STRICT_MATCH

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLSetEnvAttr(
    SQLHENV			EnvironmentHandle,
    SQLINTEGER			Attribute,	/* enumSQLEnvAttr */
    SQLPOINTER			Value,
    SQLINTEGER			StringLength );

SQLRETURN ODBC_API SQLGetEnvAttr(
    SQLHENV			EnvironmentHandle,
    SQLINTEGER			Attribute,	/* enumSQLEnvAttr */
    SQLPOINTER			Value,
    SQLINTEGER			BufferLength,
    SQLINTEGER ODBCFAR *	StringLength );
#endif // UL_ODBC
#endif /* ODBCVER >= 0x0300 */

/* API functions -- connections */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLAllocConnect(	/* CORE */
    SQLHENV		EnvironmentHandle,
    SQLHDBC ODBCFAR *	ConnectionHandle );

SQLRETURN ODBC_API SQLConnect(		/* CORE */
    SQLHDBC		ConnectionHandle,
    SQLCHAR ODBCFAR *	ServerName,
    SQLSMALLINT		NameLength1,
    SQLCHAR ODBCFAR *	UserName,
    SQLSMALLINT		NameLength2,
    SQLCHAR ODBCFAR *	Authentication,
    SQLSMALLINT		NameLength3 );
#endif // UL_ODBC

enum enumSQLMode {
    SQL_MODE_READ_WRITE		= 0UL,
    SQL_MODE_READ_ONLY		= 1UL
};
    
enum enumSQLDriverConnect {
    SQL_DRIVER_NOPROMPT,
    SQL_DRIVER_COMPLETE,
    SQL_DRIVER_PROMPT,
    SQL_DRIVER_COMPLETE_REQUIRED
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLDriverConnect(			/* Level 1 */
    SQLHDBC			hdbc,
    SQLHWND			hwnd,
    SQLCHAR ODBCFAR *		szConnStrIn,		/* input connection string */
    SQLSMALLINT			cbConnStrIn,
    SQLCHAR ODBCFAR *		szConnStrOut,
    SQLSMALLINT			cbConnStrOutMax,
    SQLSMALLINT ODBCFAR *	pcbConnStrOut,
    SQLUSMALLINT		fDriverCompletion );	/* enumSQLDriverConnect */

SQLRETURN ODBC_API SQLBrowseConnect(		/* Level 2 */
    SQLHDBC			hdbc,
    SQLCHAR ODBCFAR *		szConnStrIn,	/* input connection string */
    SQLSMALLINT			cbConnStrIn,
    SQLCHAR ODBCFAR *		szConnStrOut,
    SQLSMALLINT			cbConnStrOutMax,
    SQLSMALLINT ODBCFAR *	pcbConnStrOut );

#if (ODBCVER >= 0x0200)
SQLRETURN ODBC_API SQLDrivers(
    SQLHENV			henv,
    SQLUSMALLINT		fDirection,
    SQLCHAR ODBCFAR *		szDriverDesc,
    SQLSMALLINT			cbDriverDescMax,
    SQLSMALLINT ODBCFAR *	pcbDriverDesc,
    SQLCHAR ODBCFAR *		szDriverAttributes,
    SQLSMALLINT			cbDrvrAttrMax,
    SQLSMALLINT ODBCFAR *	pcbDrvrAttr );
#endif /* ODBCVER >= 0x0200 */
#endif // UL_ODBC

enum enumSQLOption {
    /* Statement attribtues (can also be used with connections) */
    SQL_QUERY_TIMEOUT,
    SQL_MAX_ROWS,
    SQL_NOSCAN,
    SQL_MAX_LENGTH,
    SQL_ASYNC_ENABLE,
    SQL_BIND_TYPE,
    #if (ODBCVER >= 0x0200)
    SQL_CURSOR_TYPE,
    SQL_CONCURRENCY,
    SQL_KEYSET_SIZE,
    SQL_ROWSET_SIZE,
    SQL_SIMULATE_CURSOR,
    SQL_RETRIEVE_DATA,
    SQL_USE_BOOKMARKS,
    SQL_GET_BOOKMARK,		/* GetStmtOption only */
    SQL_ROW_NUMBER,		/* GetStmtOption only */
    #if (ODBCVER >= 0x0300)
    SQL_ATTR_ENABLE_AUTO_IPD,
    SQL_ATTR_FETCH_BOOKMARK_PTR,
    SQL_ATTR_PARAM_BIND_OFFSET_PTR,
    SQL_ATTR_PARAM_BIND_TYPE,
    SQL_ATTR_PARAM_OPERATION_PTR,
    SQL_ATTR_PARAM_STATUS_PTR,
    SQL_ATTR_PARAMS_PROCESSED_PTR,
    SQL_ATTR_PARAMSET_SIZE,
    SQL_ATTR_ROW_BIND_OFFSET_PTR,
    SQL_ATTR_ROW_OPERATION_PTR,
    SQL_ATTR_ROW_STATUS_PTR,
    SQL_ATTR_ROWS_FETCHED_PTR,
    SQL_ATTR_ROW_ARRAY_SIZE,
    SQL_ATTR_CURSOR_SENSITIVITY	= -2,
    SQL_ATTR_CURSOR_SCROLLABLE,
    SQL_ATTR_METADATA_ID	= 10014,
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */

    /* Environment attributes */
    #if (ODBCVER >= 0x0300)
    SQL_ATTR_ODBC_VERSION	= 200,
    SQL_ATTR_CONNECTION_POOLING = 201,
    SQL_ATTR_CP_MATCH           = 202,
    SQL_ATTR_OUTPUT_NTS		= 10001,
    #endif /* ODBCVER >= 0x0300 */

    /* Connect attribtues */
    SQL_ACCESS_MODE	= 101,
    SQL_AUTOCOMMIT,
    SQL_LOGIN_TIMEOUT,
    SQL_OPT_TRACE,
    SQL_OPT_TRACEFILE,
    SQL_TRANSLATE_DLL,
    SQL_TRANSLATE_OPTION,
    SQL_TXN_ISOLATION,		/* enumSQLIsolation */
    SQL_CURRENT_QUALIFIER,
    #if (ODBCVER >= 0x0200)
    SQL_ODBC_CURSORS,
    SQL_QUIET_MODE,
    SQL_PACKET_SIZE,
    #if (ODBCVER >= 0x0300)
    SQL_ATTR_CONNECTION_TIMEOUT,
    SQL_ATTR_DISCONNECT_BEHAVIOUR,
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */

    #if (ODBCVER < 0x0300)
    /* Driver specific attribtues -- not meaningful for ODBC 3.0 driver */
    SQL_CONNECT_OPT_DRVR_START = 1000,
    #else
    SQL_ATTR_ENLIST_IN_DTC	= 1207,
    SQL_ATTR_ENLIST_IN_XA,
    #endif /* ODBCVER < 0x0300 */

	SQL_ATTR_CONNECTION_DEAD	/* GetConnectAttr only */

	#if (ODBCVER >= 0x0351)
	/* ODBC Driver Manager sets this connection attribute to a unicode driver
	(which supports SQLConnectW) when the application is an ANSI application
	(which calls SQLConnect, SQLDriverConnect, or SQLBrowseConnect). 
	This is SetConnectAttr only and application does not set this attribute
	This attribute was introduced because some unicode driver's some APIs may 
	need to behave differently on ANSI or Unicode applications. A unicode 
	driver, which  has same behavior for both ANSI or Unicode applications,
	should return SQL_ERROR when the driver manager sets this connection 
	attribute. When a unicode driver returns SQL_SUCCESS on this attribute,
	the driver manager treates ANSI and Unicode connections differently in
	connection pooling.*/
	, SQL_ATTR_ANSI_APP		= 115
	#endif

};

#if (ODBCVER >= 0x0300)
/* Statement Attributes */
#define SQL_ATTR_ASYNC_ENABLE		SQL_ASYNC_ENABLE
#define SQL_ATTR_CONCURRENCY		SQL_CONCURRENCY
#define SQL_ATTR_CURSOR_TYPE		SQL_CURSOR_TYPE
#define SQL_ATTR_KEYSET_SIZE		SQL_KEYSET_SIZE
#define SQL_ATTR_MAX_LENGTH		SQL_MAX_LENGTH
#define SQL_ATTR_MAX_ROWS		SQL_MAX_ROWS
#define SQL_ATTR_NOSCAN			SQL_NOSCAN
#define SQL_ATTR_QUERY_TIMEOUT		SQL_QUERY_TIMEOUT
#define SQL_ATTR_RETRIEVE_DATA		SQL_RETRIEVE_DATA
#define	SQL_ATTR_ROW_BIND_TYPE		SQL_BIND_TYPE
#define SQL_ATTR_ROW_NUMBER		SQL_ROW_NUMBER	/* GetStmtAttr */
#define SQL_ATTR_SIMULATE_CURSOR	SQL_SIMULATE_CURSOR
#define SQL_ATTR_USE_BOOKMARKS		SQL_USE_BOOKMARKS	

/* Connction attributes */
#define SQL_ATTR_ACCESS_MODE		SQL_ACCESS_MODE
#define SQL_ATTR_AUTOCOMMIT		SQL_AUTOCOMMIT
#define SQL_ATTR_CURRENT_CATALOG	SQL_CURRENT_QUALIFIER
#define SQL_ATTR_LOGIN_TIMEOUT		SQL_LOGIN_TIMEOUT
#define SQL_ATTR_ODBC_CURSORS		SQL_ODBC_CURSORS
#define SQL_ATTR_PACKET_SIZE		SQL_PACKET_SIZE
#define SQL_ATTR_QUIET_MODE		SQL_QUIET_MODE
#define SQL_ATTR_TRACE			SQL_OPT_TRACE
#define SQL_ATTR_TRACEFILE		SQL_OPT_TRACEFILE
#define SQL_ATTR_TRANSLATE_LIB		SQL_TRANSLATE_DLL
#define SQL_ATTR_TRANSLATE_OPTION	SQL_TRANSLATE_OPTION
#define SQL_ATTR_TXN_ISOLATION		SQL_TXN_ISOLATION

/* Type of attribute */
enum enumAttrType {
    SQL_IS_SMALLINT	= -8,
    SQL_IS_USMALLINT,
    SQL_IS_INTEGER,
    SQL_IS_UINTEGER,
    SQL_IS_POINTER
};
#endif /* ODBCVER >= 0x0300 */

#if (ODBCVER < 0x0300)
/* Statement attributes */
#define SQL_STMT_OPT_MAX		SQL_ROW_NUMBER
#define SQL_STMT_OPT_MIN		SQL_QUERY_TIMEOUT

/* Connection attributes */
#define SQL_CONN_OPT_MAX		SQL_PACKET_SIZE
#define SQL_CONN_OPT_MIN		SQL_ACCESS_MODE
#endif /* ODBCVER < 0x0300 */

enum enumSQLIsolation {
    SQL_TXN_READ_UNCOMMITTED	= 0x00000001L,
    SQL_TXN_READ_COMMITTED	= 0x00000002L,
    SQL_TXN_REPEATABLE_READ	= 0x00000004L,
    SQL_TXN_SERIALIZABLE	= 0x00000008L
    /* SQL_TXN_VERSIONING	= 0x00000010L No longer suported */
};

#define SQL_TRANSACTION_READ_UNCOMMITED	SQL_TXN_READ_UNCOMMITTED
#define SQL_TRANSACTION_READ_COMMITTED	SQL_TXN_READ_COMMITTED
#define SQL_TRANSACTION_REPEATABLE_READ	SQL_TXN_REPEATABLE_READ
#define SQL_TRANSACTION_SERIALIZABLE	SQL_TXN_SERIALIZABLE

enum enumNoScanOps {
    SQL_NOSCAN_OFF		= 0UL,
    SQL_NOSCAN_ON		= 1UL
};

enum enumAsyncEnable {
    SQL_ASYNC_ENABLE_OFF,
    SQL_ASYNC_ENABLE_ON	
};

enum enumAutoCommit {
    SQL_AUTOCOMMIT_OFF		= 0UL,
    SQL_AUTOCOMMIT_ON		= 1UL
};

enum enumTraceOpt {
    SQL_OPT_TRACE_OFF		= 0UL,
    SQL_OPT_TRACE_ON		= 1UL
};

#if (ODBCVER >= 0x0200)

enum enumODBCCursors {
    SQL_CUR_USE_IF_NEEDED	= 0UL,
    SQL_CUR_USE_ODBC		= 1UL,
    SQL_CUR_USE_DRIVER		= 2UL
};

#define SQL_CUR_DEFAULT 		SQL_CUR_USE_DRIVER

#endif /* ODBCVER >= 0x0200 */

#if (ODBCVER >= 0x0300)
enum enumSQLConnectAttr {
    SQL_ATTR_AUTO_IPD		= 10001
//    SQL_ATTR_METADATA_ID	= 10014
};
#endif /* ODBCVER >= 0x0300 */

/* Special values for certain options  */
#define SQL_QUERY_TIMEOUT_DEFAULT	0UL
#define SQL_NOSCAN_DEFAULT		SQL_NOSCAN_OFF
#define SQL_ASYNC_ENABLE_DEFAULT	SQL_ASYNC_ENABLE_OFF
#define SQL_MAX_ROWS_DEFAULT		0UL
#define SQL_MAX_LENGTH_DEFAULT		0UL
#define SQL_BIND_BY_COLUMN 		0UL
#define SQL_BIND_TYPE_DEFAULT		SQL_BIND_BY_COLUMN
#if (ODBCVER >= 0x0300)
#define SQL_PARAM_BIND_BY_COLUMN	0UL
#define SQL_PARAM_BIND_TYPE_DEFAULT	SQL_PARAM_BIND_BY_COLUMN
#endif  /* ODBCVER >= 0x0300 */
#define SQL_MODE_DEFAULT		SQL_MODE_READ_WRITE
#define SQL_AUTOCOMMIT_DEFAULT 		SQL_AUTOCOMMIT_ON
#define SQL_LOGIN_TIMEOUT_DEFAULT	15UL
#define SQL_OPT_TRACE_DEFAULT 		SQL_OPT_TRACE_OFF
#define SQL_OPT_TRACE_FILE_DEFAULT	"\\SQL.LOG"

#ifndef UL_ODBC
#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLGetConnectAttr(
    SQLHDBC			ConnectionHandle,
    SQLINTEGER			Attribute,
    SQLPOINTER			Value,
    SQLINTEGER			BufferLength,
    SQLINTEGER ODBCFAR *	StringLength );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLGetConnectOption(	/* Level 1 */
    SQLHDBC		ConnectionHandle,
    SQLUSMALLINT	Option,		/* enumSQLOption */
    SQLPOINTER		Value );

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLSetConnectAttr(
    SQLHDBC		ConnectionHandle,
    SQLINTEGER		Attribute,
    SQLPOINTER		Value,
    SQLINTEGER		StringLength );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLSetConnectOption(	/* Level 1 */
    SQLHDBC		hdbc,
    SQLUSMALLINT	Option,		/* enumSQLOption */
    SQLULEN		Value );

SQLRETURN ODBC_API SQLNativeSql(	/* Level 2 */
    SQLHDBC			hdbc,
    SQLCHAR ODBCFAR *		szSqlStrIn,
    SQLINTEGER			cbSqlStrIn,
    SQLCHAR ODBCFAR *		szSqlStr,
    SQLINTEGER			cbSqlStrMax,
    SQLINTEGER ODBCFAR *	pcbSqlStr );
#endif // UL_ODBC

enum enumSQLEndTran {
    SQL_COMMIT,
    SQL_ROLLBACK
};

#ifndef UL_ODBC
#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLEndTran(
    SQLSMALLINT		HandleType,
    SQLHANDLE		Handle,
    SQLSMALLINT		CompletionType );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLTransact(			/* CORE */
    SQLHENV		EnvironmentHandle,
    SQLHDBC		ConnectionHandle,
    SQLUSMALLINT	CompletionType );	/* enumSQLEndTran */
#endif // UL_ODBC

#if (ODBCVER >= 0x0300)
enum enumDisconnectBehaviour {
    SQL_DB_RETURN_TO_POOL	= 0UL,
    SQL_DB_DISCONNECT		= 1UL
};
#define SQL_DB_DEFAULT		SQL_DB_RETURN_TO_POOL

#define SQL_DTC_DONE		0L
#endif /* ODBCVER >= 0x0300 */

/* values for SQL_ATTR_CONNECTION_DEAD */
#define SQL_CD_TRUE					1L		/* Connection is closed/dead */
#define SQL_CD_FALSE				0L		/* Connection is open/available */

/* values for SQL_ATTR_ANSI_APP */
#if (ODBCVER >= 0x0351)
#define SQL_AA_TRUE					1L	/* the application is an ANSI app */
#define SQL_AA_FALSE					0L	/* the application is a Unicode app */
#endif

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLDisconnect(	/* CORE */
    SQLHDBC		ConnectionHandle );

SQLRETURN ODBC_API SQLFreeConnect(	/* CORE */
    SQLHDBC		ConnectionHandle );
#endif // UL_ODBC

/* API functions -- driver information */

enum enumSQLFunctions {
    /* CORE functions */
    SQL_API_SQLALLOCCONNECT	= 1,
    SQL_API_SQLALLOCENV,
    SQL_API_SQLALLOCSTMT,
    SQL_API_SQLBINDCOL,
    SQL_API_SQLCANCEL,
    SQL_API_SQLCOLATTRIBUTES,
    #if (ODBCVER >= 0x0300)
    SQL_API_SQLCOLATTRIBUTE	= 6,
    #endif /* ODBCVER >= 0x0300 */
    SQL_API_SQLCONNECT,
    SQL_API_SQLDESCRIBECOL,
    SQL_API_SQLDISCONNECT,
    SQL_API_SQLERROR,
    SQL_API_SQLEXECDIRECT,
    SQL_API_SQLEXECUTE,
    SQL_API_SQLFETCH,
    SQL_API_SQLFREECONNECT,
    SQL_API_SQLFREEENV,
    SQL_API_SQLFREESTMT,
    SQL_API_SQLGETCURSORNAME,
    SQL_API_SQLNUMRESULTCOLS,
    SQL_API_SQLPREPARE,
    SQL_API_SQLROWCOUNT,
    SQL_API_SQLSETCURSORNAME,
    SQL_API_SQLSETPARAM,
    SQL_API_SQLTRANSACT,
    #if (ODBCVER >= 0x0300)
    SQL_API_SQLBULKOPERATIONS,
    #endif /* ODBCVER >= 0x0300 */

    /* Level 1 functions */
    SQL_API_SQLCOLUMNS	= 40,
    SQL_API_SQLDRIVERCONNECT,
    SQL_API_SQLGETCONNECTOPTION,
    SQL_API_SQLGETDATA,
    SQL_API_SQLGETFUNCTIONS,
    SQL_API_SQLGETINFO,
    SQL_API_SQLGETSTMTOPTION,
    SQL_API_SQLGETTYPEINFO,
    SQL_API_SQLPARAMDATA,
    SQL_API_SQLPUTDATA,
    SQL_API_SQLSETCONNECTOPTION,
    SQL_API_SQLSETSTMTOPTION,
    SQL_API_SQLSPECIALCOLUMNS,
    SQL_API_SQLSTATISTICS,
    SQL_API_SQLTABLES,

    /* Level 2 functions */
    SQL_API_SQLBROWSECONNECT,
    SQL_API_SQLCOLUMNPRIVILEGES,
    SQL_API_SQLDATASOURCES,
    SQL_API_SQLDESCRIBEPARAM,
    SQL_API_SQLEXTENDEDFETCH,
    SQL_API_SQLFOREIGNKEYS,
    SQL_API_SQLMORERESULTS,
    SQL_API_SQLNATIVESQL,
    SQL_API_SQLNUMPARAMS,
    SQL_API_SQLPARAMOPTIONS,
    SQL_API_SQLPRIMARYKEYS,
    SQL_API_SQLPROCEDURECOLUMNS,
    SQL_API_SQLPROCEDURES,
    SQL_API_SQLSETPOS,
    SQL_API_SQLSETSCROLLOPTIONS,
    SQL_API_SQLTABLEPRIVILEGES
    #if (ODBCVER >= 0x0200)
,   SQL_API_SQLDRIVERS,
    SQL_API_SQLBINDPARAMETER
    #endif /* ODBCVER >= 0x0200 */
    #if (ODBCVER >= 0x0300)
,   SQL_API_SQLALLOCHANDLESTD,

    SQL_API_SQLALLOCHANDLE	= 1001,
    SQL_API_SQLBINDPARAM,
    SQL_API_SQLCLOSECURSOR,
    SQL_API_SQLCOPYDESC,
    SQL_API_SQLENDTRAN,
    SQL_API_SQLFREEHANDLE,
    SQL_API_SQLGETCONNECTATTR,
    SQL_API_SQLGETDESCFIELD,
    SQL_API_SQLGETDESCREC,
    SQL_API_SQLGETDIAGFIELD,
    SQL_API_SQLGETDIAGREC,
    SQL_API_SQLGETENVATTR,
    SQL_API_SQLGETSTMTATTR	= 1014,
    SQL_API_SQLSETCONNECTATTR	= 1016,
    SQL_API_SQLSETDESCFIELD,
    SQL_API_SQLSETDESCREC,
    SQL_API_SQLSETENVATTR,
    SQL_API_SQLSETSTMTATTR,
    SQL_API_SQLFETCHSCROLL
    #endif /* ODBCVER >= 0x0300 */
};

/* SQL_EXT_API_LAST --------------------------------------------------- */
/* Not useful with ODBC 3.0 since X/Open values > 10000.  Must contact  */
/* X/Open directly to get a range of numbers for driver-specific values */
/* -------------------------------------------------------------------- */
#if (ODBCVER < 0x0300)
#define SQL_NUM_FUNCTIONS	SQL_API_SQLTRANSACT		/* 23 */
#define SQL_EXT_API_LAST	SQL_API_SQLBINDPARAMETER
#define SQL_EXT_API_START	SQL_API_SQLCOLUMNS		/* 40 */
#define SQL_NUM_EXTENSIONS	(SQL_EXT_API_LAST - SQL_EXT_API_START + 1)
#endif /* ODBCVER < 0x0300 */

/* SQL_API_ALL_FUNCTIONS ---------------------------------------------- */
/* Only functions defined in ODBC version 2.0 and earlier are returned. */
/* X/Open functions break this scheme--see SQL_API_ODBC3_ALL_FUNCTIONS  */
/* -------------------------------------------------------------------- */
#define SQL_API_ALL_FUNCTIONS	0

/* SQL_API_LOADBYORDINAL ---------------------------------------------- */
/* 2.x drivers export a dummy function to speed up loading under        */
/* Windows.  Not supported in ODBC 3.0 and above.                       */
/* -------------------------------------------------------------------- */
#define SQL_API_LOADBYORDINAL	199

/* SQL_API_ODBC3_ALL_FUNCTIONS ---------------------------------------- */
/* Returns a bitmap, which handles higher values.  Use SQL_FUNC_EXIST() */
/* to determine if the function exists.                                 */
/* -------------------------------------------------------------------- */
#if (ODBCVER >= 0x0300)
#define SQL_API_ODBC3_ALL_FUNCTIONS		999
#define	SQL_API_ODBC3_ALL_FUNCTIONS_SIZE	250
#define SQL_FUNC_EXISTS(pfExists, uwAPI) \
	( (*( ((UWORD*) (pfExists)) + ((uwAPI) >> 4) ) \
	& (1 << ((uwAPI) & 0x000F))) ? SQL_TRUE : SQL_FALSE )
#endif /* ODBCVER >= 0x0300 */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLGetFunctions(	/* Level 1 */
    SQLHDBC			ConnectionHandle,
    SQLUSMALLINT		FunctionId,	/* enumSQLFuntions */
    SQLUSMALLINT ODBCFAR *	Supported );	/* TRUE or FALSE */
#endif // UL_ODBC

enum enumSQLFetchDirection {
    SQL_FD_FETCH_NEXT		= 0x00000001L,
    SQL_FD_FETCH_FIRST		= 0x00000002L,
    SQL_FD_FETCH_LAST		= 0x00000004L,
    SQL_FD_FETCH_PRIOR		= 0x00000008L,
    SQL_FD_FETCH_ABSOLUTE	= 0x00000010L,
    SQL_FD_FETCH_RELATIVE	= 0x00000020L,
    /* SQL_FD_FETCH_RESUME	= 0x00000040L, SQL_FETCH_RESUME no longer supported */
    SQL_FD_FETCH_BOOKMARK	= 0x00000080L
};

#define SQL_FD_FETCH_PREV	SQL_FD_FETCH_PRIOR

enum enumSQLConcurMask {
    SQL_SCCO_READ_ONLY		= 0x0000001L,
    SQL_SCCO_LOCK		= 0x0000002L,
    SQL_SCCO_OPT_ROWVER		= 0x0000004L,
    SQL_SCCO_OPT_VALUES		= 0x0000008L
};

#define SQL_SCCO_OPT_TIMESTAMP	SQL_SCCO_OPT_ROWVER

enum enumSQLScrollOptions {
    SQL_SO_FORWARD_ONLY		= 0x00000001L,
    SQL_SO_KEYSET_DRIVEN	= 0x00000002L,
    SQL_SO_DYNAMIC		= 0x00000004L,
    SQL_SO_MIXED		= 0x00000008L
#if (ODBCVER >= 0x0200)
    ,
    SQL_SO_STATIC		= 0x00000010L
#endif /* ODBCVER >= 0x0200 */
};

enum enumODBCAPIConform {
    SQL_OAC_NONE		= 0x0000,
    SQL_OAC_LEVEL1		= 0x0001,
    SQL_OAC_LEVEL2		= 0x0002
};

enum enumCliSagConform {
    SQL_OSCC_NOT_COMPLIANT	= 0x0000,
    SQL_OSCC_COMPLIANT		= 0x0001
};

enum enumODBCSQLConform {
    SQL_OSC_MINIMUM	= 0x0000,
    SQL_OSC_CORE	= 0x0001,
    SQL_OSC_EXTENDED	= 0x0002
};

enum enumConcatNullBehavior {
    SQL_CB_NULL		= 0x0000,
    SQL_CB_NON_NULL	= 0x0001
};

enum enumCursorCommitBehavior {
    SQL_CB_DELETE,
    SQL_CB_CLOSE,
    SQL_CB_PRESERVE
};

#define SQL_CC_DELETE	SQL_CB_DELETE
#define SQL_CR_DELETE	SQL_CB_DELETE
#define SQL_CC_CLOSE	SQL_CB_CLOSE
#define SQL_CR_CLOSE	SQL_CB_CLOSE
#define SQL_CC_PRESERVE	SQL_CB_PRESERVE
#define SQL_CR_PRESERVE	SQL_CB_PRESERVE

/* Cursor bitmasks */

#if (ODBCVER >= 0x0300)
enum enumCAFetchOrientation {
    SQL_CA1_NEXT	= 0x00000001L,
    SQL_CA1_ABSOLUTE	= 0x00000002L,
    SQL_CA1_RELATIVE	= 0x00000004L,
    SQL_CA1_BOOKMARK	= 0x00000008L
};

enum enumCALockTypes {
    SQL_CA1_LOCK_NO_CHANGE	= 0x00000040L,
    SQL_CA1_LOCK_EXCLUSIVE	= 0x00000080L,
    SQL_CA1_LOCK_UNLOCK		= 0x00000100L
};

enum enumCASetPos {
    SQL_CA1_POS_POSITION	= 0x00000200L,
    SQL_CA1_POS_UPDATE		= 0x00000400L,
    SQL_CA1_POS_DELETE		= 0x00000800L,
    SQL_CA1_POS_REFRESH		= 0x00001000L
};

enum enumCAPositioned {
    SQL_CA1_POSITIONED_UPDATE		= 0x00002000L,
    SQL_CA1_POSITIONED_DELETE		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_CA1_SELECT_FOR_UPDATE	  0x00008000L
};

/* Enums are of type int: the rest can't be enums with 16 bit compilers */
#define SQL_CA1_BULK_ADD		0x00010000L
#define SQL_CA1_BULK_UPDATE_BY_BOOKMARK	0x00020000L
#define SQL_CA1_BULK_DELETE_BY_BOOKMARK	0x00040000L
#define SQL_CA1_BULK_FETCH_BY_BOOKMARK	0x00080000L

enum enumCAScrollConcurrency {
    SQL_CA2_READ_ONLY_CONCURRENCY	= 0x00000001L,
    SQL_CA2_LOCK_CONCURRENCY		= 0x00000002L,
    SQL_CA2_OPT_ROWVER_CONCURRENCY	= 0x00000004L,
    SQL_CA2_OPT_VALUES_CONCURRENCY	= 0x00000008L
};

enum enumCASensitivity {
    SQL_CA2_SENSITIVITY_ADDITIONS	= 0x00000010L,
    SQL_CA2_SENSITIVITY_DELETIONS	= 0x00000020L,
    SQL_CA2_SENSITIVITY_UPDATES		= 0x00000040L
};

enum enumCAMaxRows {
    SQL_CA2_MAX_ROWS_SELECT		= 0x00000080L,
    SQL_CA2_MAX_ROWS_INSERT		= 0x00000100L,
    SQL_CA2_MAX_ROWS_DELETE		= 0x00000200L,
    SQL_CA2_MAX_ROWS_UPDATE		= 0x00000400L,
    SQL_CA2_MAX_ROWS_CATALOG		= 0x00000800L
    /* We don't define enums in terms of enums values in the same enum type */
    #define SQL_CA2_MAX_ROWS_AFFECTS_ALL  (SQL_CA2_MAX_ROWS_SELECT | \
					   SQL_CA2_MAX_ROWS_INSERT | \
					   SQL_CA2_MAX_ROWS_DELETE | \
					   SQL_CA2_MAX_ROWS_UPDATE | \
					   SQL_CA2_MAX_ROWS_CATALOG)
};

enum enumCADiagCRC {
    SQL_CA2_CRC_EXACT		= 0x00001000L,
    SQL_CA2_CRC_APPROXIMATE	= 0x00002000L
};

enum enumCASim {
    SQL_CA2_SIMULATE_NON_UNIQUE		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_CA2_SIMULATE_TRY_UNIQUE	  0x00008000L
    #define SQL_CA2_SIMULATE_UNIQUE	  0x00010000L
};

#endif /* ODBCVER >= 0x0300 -- Cursor bitmasks */

enum enumIDCase {
    SQL_IC_UPPER	= 1,
    SQL_IC_LOWER,
    SQL_IC_SENSITIVE,
    SQL_IC_MIXED
};

enum enumTxnValues {
    SQL_TC_NONE,
    SQL_TC_DML,
    SQL_TC_ALL,
    SQL_TC_DDL_COMMIT,
    SQL_TC_DDL_IGNORE
};

enum enumCorrelationName {
    SQL_CN_NONE		= 0x0000,
    SQL_CN_DIFFERENT	= 0x0001,
    SQL_CN_ANY		= 0x0002
};

enum enumNonNullableCol {
    SQL_NNC_NULL	= 0x0000,
    SQL_NNC_NON_NULL	= 0x0001
};

#if (ODBCVER >= 0x0200)

enum enumNullCollation {
    SQL_NC_HIGH		= 0x0000,
    SQL_NC_LOW		= 0x0001,
    SQL_NC_START	= 0x0002,
    SQL_NC_END		= 0x0004
};

enum enumFileUsage {
    SQL_FILE_NOT_SUPPORTED	= 0x0000,
    SQL_FILE_TABLE		= 0x0001,
    SQL_FILE_QUALIFIER		= 0x0002
};
#define SQL_FILE_CATALOG	SQL_FILE_QUALIFIER

enum enumGetDataExtensions {
    SQL_GD_ANY_COLUMN		= 0x00000001L,
    SQL_GD_ANY_ORDER		= 0x00000002L,
    SQL_GD_BLOCK		= 0x00000004L,
    SQL_GD_BOUND		= 0x00000008L
};

enum enumAlterTable {
    SQL_AT_ADD_COLUMN				= 0x00000001L,
    SQL_AT_DROP_COLUMN				= 0x00000002L
    #if (ODBCVER >= 0x0300)
    ,
    SQL_AT_ADD_CONSTRAINT			= 0x00000008L,
    SQL_AT_ADD_COLUMN_SINGLE			= 0x00000020L,
    SQL_AT_ADD_COLUMN_DEFAULT			= 0x00000040L,
    SQL_AT_ADD_COLUMN_COLLATION			= 0x00000080L,
    SQL_AT_SET_COLUMN_DEFAULT			= 0x00000100L,
    SQL_AT_DROP_COLUMN_DEFAULT			= 0x00000200L,
    SQL_AT_DROP_COLUMN_CASCADE			= 0x00000400L,
    SQL_AT_DROP_COLUMN_RESTRICT			= 0x00000800L,
    SQL_AT_ADD_TABLE_CONSTRAINT			= 0x00001000L,
    SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE	= 0x00002000L,
    SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT	= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_AT_CONSTRAINT_NAME_DEFINITION	  0x00008000L
    #define SQL_AT_CONSTRAINT_INITIALLY_DEFERRED  0x00010000L
    #define SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE 0x00020000L
    #define SQL_AT_CONSTRAINT_DEFERRABLE	  0x00040000L
    #define SQL_AT_CONSTRAINT_NON_DEFERRABLE	  0x00080000L
    #endif /* ODBCVER >= 0x0300 */
};

enum enumPosStmts {
    SQL_PS_POSITIONED_DELETE	= 0x00000001L,
    SQL_PS_POSITIONED_UPDATE	= 0x00000002L,
    SQL_PS_SELECT_FOR_UPDATE	= 0x00000004L
};

enum enumGroupBy {
    SQL_GB_NOT_SUPPORTED		= 0x0000,
    SQL_GB_GROUP_BY_EQUALS_SELECT	= 0x0001,
    SQL_GB_GROUP_BY_CONTAINS_SELECT	= 0x0002,
    SQL_GB_NO_RELATION			= 0x0003
    #if (ODBCVER >= 0x0300)
    ,
    SQL_GB_COLLATE			= 0x0004
    #endif /* ODBCVER >= 0x0300 */
};

enum enumOwnerUsage {
    SQL_OU_DML_STATEMENTS	= 0x00000001L,
    SQL_OU_PROCEDURE_INVOCATION	= 0x00000002L,
    SQL_OU_TABLE_DEFINITION	= 0x00000004L,
    SQL_OU_INDEX_DEFINITION	= 0x00000008L,
    SQL_OU_PRIVILEGE_DEFINITION	= 0x00000010L
};

#if (ODBCVER >= 0x0300)
#define SQL_SU_DML_STATEMENTS			SQL_OU_DML_STATEMENTS 
#define SQL_SU_PROCEDURE_INVOCATION		SQL_OU_PROCEDURE_INVOCATION
#define SQL_SU_TABLE_DEFINITION			SQL_OU_TABLE_DEFINITION
#define SQL_SU_INDEX_DEFINITION			SQL_OU_INDEX_DEFINITION
#define SQL_SU_PRIVILEGE_DEFINITION		SQL_OU_PRIVILEGE_DEFINITION
#endif /* ODBCVER >= 0x0300 */

enum enumQualifierUsage {
    SQL_QU_DML_STATEMENTS	= 0x00000001L,
    SQL_QU_PROCEDURE_INVOCATION	= 0x00000002L,
    SQL_QU_TABLE_DEFINITION	= 0x00000004L,
    SQL_QU_INDEX_DEFINITION	= 0x00000008L,
    SQL_QU_PRIVILEGE_DEFINITION	= 0x00000010L
};

#if (ODBCVER >= 0x0300)
#define SQL_CU_DML_STATEMENTS			SQL_QU_DML_STATEMENTS
#define SQL_CU_PROCEDURE_INVOCATION		SQL_QU_PROCEDURE_INVOCATION 
#define SQL_CU_TABLE_DEFINITION			SQL_QU_TABLE_DEFINITION
#define SQL_CU_INDEX_DEFINITION			SQL_QU_INDEX_DEFINITION 
#define SQL_CU_PRIVILEGE_DEFINITION		SQL_QU_PRIVILEGE_DEFINITION 
#endif /* ODBCVER >= 0x0300 */

enum enumSubqueries {
    SQL_SQ_COMPARISON			= 0x00000001L,
    SQL_SQ_EXISTS			= 0x00000002L,
    SQL_SQ_IN				= 0x00000004L,
    SQL_SQ_QUANTIFIED			= 0x00000008L,
    SQL_SQ_CORRELATED_SUBQUERIES	= 0x00000010L
};

enum enumUnion {
    SQL_U_UNION		= 0x00000001L,
    SQL_U_UNION_ALL	= 0x00000002L
};

enum enumBookmark {
    SQL_BP_CLOSE	= 0x00000001L,
    SQL_BP_DELETE	= 0x00000002L,
    SQL_BP_DROP		= 0x00000004L,
    SQL_BP_TRANSACTION	= 0x00000008L,
    SQL_BP_UPDATE	= 0x00000010L,
    SQL_BP_OTHER_HSTMT	= 0x00000020L,
    SQL_BP_SCROLL	= 0x00000040L
};

enum enumStaticSensitivity {
    SQL_SS_ADDITIONS	= 0x00000001L,
    SQL_SS_DELETIONS	= 0x00000002L,
    SQL_SS_UPDATES	= 0x00000004L
};

enum enumView {
    SQL_CV_CREATE_VIEW	= 0x00000001L,
    SQL_CV_CHECK_OPTION	= 0x00000002L,
    SQL_CV_CASCADED	= 0x00000004L,
    SQL_CV_LOCAL	= 0x00000008L
};

enum enumLockTypes {
    SQL_LCK_NO_CHANGE	= 0x00000001L,
    SQL_LCK_EXCLUSIVE	= 0x00000002L,
    SQL_LCK_UNLOCK	= 0x00000004L
};

enum enumPosOps {
    SQL_POS_POSITION	= 0x00000001L,
    SQL_POS_REFRESH	= 0x00000002L,
    SQL_POS_UPDATE	= 0x00000004L,
    SQL_POS_DELETE	= 0x00000008L,
    SQL_POS_ADD		= 0x00000010L
};

enum enumQualifierLocation {
    SQL_QL_START	= 0x0001,
    SQL_QL_END		= 0x0002
};

#if (ODBCVER >= 0x0201)

enum enumOJCapabilities {
    SQL_OJ_LEFT			= 0x00000001L,
    SQL_OJ_RIGHT		= 0x00000002L,
    SQL_OJ_FULL			= 0x00000004L,
    SQL_OJ_NESTED		= 0x00000008L,
    SQL_OJ_NOT_ORDERED		= 0x00000010L,
    SQL_OJ_INNER		= 0x00000020L,
    SQL_OJ_ALL_COMPARISON_OPS	= 0x00000040L
};

#endif /* (ODBCVER >= 0x0201) */

#endif /* (ODBCVER >= 0x0200) */

#if (ODBCVER >= 0x0300)
enum enumAsyncMode {
    SQL_AM_NONE,
    SQL_AM_CONNECTION,
    SQL_AM_STATEMENT
};
#endif /* ODBCVER >= 0x0300 */

enum enumSQLConvertFunctions {
    SQL_FN_CVT_CONVERT		= 0x00000001L
    #if (ODBCVER >= 0x0300)
    ,
    SQL_FN_CVT_CAST		= 0x00000002L
    #endif /* ODBCVER >= 0x0300 */
};

enum enumSQLNumericFunctions {
    SQL_FN_NUM_ABS		= 0x00000001L,
    SQL_FN_NUM_ACOS		= 0x00000002L,
    SQL_FN_NUM_ASIN		= 0x00000004L,
    SQL_FN_NUM_ATAN		= 0x00000008L,
    SQL_FN_NUM_ATAN2		= 0x00000010L,
    SQL_FN_NUM_CEILING		= 0x00000020L,
    SQL_FN_NUM_COS		= 0x00000040L,
    SQL_FN_NUM_COT		= 0x00000080L,
    SQL_FN_NUM_EXP		= 0x00000100L,
    SQL_FN_NUM_FLOOR		= 0x00000200L,
    SQL_FN_NUM_LOG		= 0x00000400L,
    SQL_FN_NUM_MOD		= 0x00000800L,
    SQL_FN_NUM_SIGN		= 0x00001000L,
    SQL_FN_NUM_SIN		= 0x00002000L,
    SQL_FN_NUM_SQRT		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_FN_NUM_TAN	  0x00008000L
    #define SQL_FN_NUM_PI	  0x00010000L
    #define SQL_FN_NUM_RAND	  0x00020000L
    #if (ODBCVER >= 0x0200)
    #define SQL_FN_NUM_DEGREES	  0x00040000L
    #define SQL_FN_NUM_LOG10	  0x00080000L
    #define SQL_FN_NUM_POWER	  0x00100000L
    #define SQL_FN_NUM_RADIANS	  0x00200000L
    #define SQL_FN_NUM_ROUND	  0x00400000L
    #define SQL_FN_NUM_TRUNCATE	  0x00800000L
    #endif /* ODBCVER >= 0x0200 */
};

#if (ODBCVER >= 0x0300)
enum enumSQL92NumericValueFunctions {
    SQL_SNVF_BIT_LENGTH		= 0x00000001L,
    SQL_SNVF_CHAR_LENGTH	= 0x00000002L,
    SQL_SNVF_CHARACTER_LENGTH	= 0x00000004L,
    SQL_SNVF_EXTRACT		= 0x00000008L,
    SQL_SNVF_OCTET_LENGTH	= 0x00000010L,
    SQL_SNVF_POSITION		= 0x00000020L
};
#endif /* ODBCVER >= 0x0300 */

enum enumSQLStringFunctions {
    SQL_FN_STR_CONCAT			= 0x00000001L,
    SQL_FN_STR_INSERT			= 0x00000002L,
    SQL_FN_STR_LEFT			= 0x00000004L,
    SQL_FN_STR_LTRIM			= 0x00000008L,
    SQL_FN_STR_LENGTH			= 0x00000010L,
    SQL_FN_STR_LOCATE			= 0x00000020L,
    SQL_FN_STR_LCASE			= 0x00000040L,
    SQL_FN_STR_REPEAT			= 0x00000080L,
    SQL_FN_STR_REPLACE			= 0x00000100L,
    SQL_FN_STR_RIGHT			= 0x00000200L,
    SQL_FN_STR_RTRIM			= 0x00000400L,
    SQL_FN_STR_SUBSTRING		= 0x00000800L,
    SQL_FN_STR_UCASE			= 0x00001000L,
    SQL_FN_STR_ASCII			= 0x00002000L,
    SQL_FN_STR_CHAR			= 0x00004000L
    #if (ODBCVER >= 0x0200)
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_FN_STR_DIFFERENCE	  0x00008000L
    #define SQL_FN_STR_LOCATE_2		  0x00010000L
    #define SQL_FN_STR_SOUNDEX		  0x00020000L
    #define SQL_FN_STR_SPACE		  0x00040000L
    #if (ODBCVER >= 0x0300)
    #define SQL_FN_STR_BIT_LENGTH	  0x00080000L
    #define SQL_FN_STR_CHAR_LENGTH	  0x00100000L
    #define SQL_FN_STR_CHARACTER_LENGTH	  0x00200000L
    #define SQL_FN_STR_OCTET_LENGTH	  0x00400000L
    #define SQL_FN_STR_POSITION		  0x00800000L
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */
};

#if (ODBCVER >= 0x0300)
enum enumSQL92StringFunctions {
    SQL_SSF_CONVERT		= 0x00000001L,
    SQL_SSF_LOWER		= 0x00000002L,
    SQL_SSF_UPPER		= 0x00000004L,
    SQL_SSF_SUBSTRING		= 0x00000008L,
    SQL_SSF_TRANSLATE		= 0x00000010L,
    SQL_SSF_TRIM_BOTH		= 0x00000020L,
    SQL_SSF_TRIM_LEADING	= 0x00000040L,
    SQL_SSF_TRIM_TRAILING	= 0x00000080L
};
#endif /* ODBCVER >= 0x0300 */

enum enumSQLSystemFunctions {
    SQL_FN_SYS_USERNAME		= 0x00000001L,
    SQL_FN_SYS_DBNAME		= 0x00000002L,
    SQL_FN_SYS_IFNULL		= 0x00000004L
};

enum enumSQLTimedateFunctions {
    SQL_FN_TD_NOW			= 0x00000001L,
    SQL_FN_TD_CURDATE			= 0x00000002L,
    SQL_FN_TD_DAYOFMONTH		= 0x00000004L,
    SQL_FN_TD_DAYOFWEEK			= 0x00000008L,
    SQL_FN_TD_DAYOFYEAR			= 0x00000010L,
    SQL_FN_TD_MONTH			= 0x00000020L,
    SQL_FN_TD_QUARTER			= 0x00000040L,
    SQL_FN_TD_WEEK			= 0x00000080L,
    SQL_FN_TD_YEAR			= 0x00000100L,
    SQL_FN_TD_CURTIME			= 0x00000200L,
    SQL_FN_TD_HOUR			= 0x00000400L,
    SQL_FN_TD_MINUTE			= 0x00000800L,
    SQL_FN_TD_SECOND			= 0x00001000L
    #if (ODBCVER >= 0x0200)
    ,
    SQL_FN_TD_TIMESTAMPADD		= 0x00002000L,
    SQL_FN_TD_TIMESTAMPDIFF		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_FN_TD_DAYNAME		  0x00008000L
    #define SQL_FN_TD_MONTHNAME		  0x00010000L
    #if (ODBCVER >= 0x0300)
    #define SQL_FN_TD_CURRENT_DATE	  0x00020000L
    #define SQL_FN_TD_CURRENT_TIME	  0x00040000L
    #define SQL_FN_TD_CURRENT_TIMESTAMP	  0x00080000L
    #define SQL_FN_TD_EXTRACT		  0x00100000L
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */
};

#if (ODBCVER >= 0x0300)
enum enumSQL92DateTimeFunctions {
    SQL_SDF_CURRENT_DATE	= 0x00000001L,
    SQL_SDF_CURRENT_TIME	= 0x00000002L,
    SQL_SDF_CURRENT_TIMESTAMP	= 0x00000004L
};
#endif /* ODBCVER >= 0x0300 */

enum enumSQLTSI {
    SQL_FN_TSI_FRAC_SECOND	= 0x00000001L,
    SQL_FN_TSI_SECOND		= 0x00000002L,
    SQL_FN_TSI_MINUTE		= 0x00000004L,
    SQL_FN_TSI_HOUR		= 0x00000008L,
    SQL_FN_TSI_DAY		= 0x00000010L,
    SQL_FN_TSI_WEEK		= 0x00000020L,
    SQL_FN_TSI_MONTH		= 0x00000040L,
    SQL_FN_TSI_QUARTER		= 0x00000080L,
    SQL_FN_TSI_YEAR		= 0x00000100L
};

enum enumSQLConvert {
    SQL_CVT_CHAR			= 0x00000001L,
    SQL_CVT_NUMERIC			= 0x00000002L,
    SQL_CVT_DECIMAL			= 0x00000004L,
    SQL_CVT_INTEGER			= 0x00000008L,
    SQL_CVT_SMALLINT			= 0x00000010L,
    SQL_CVT_FLOAT			= 0x00000020L,
    SQL_CVT_REAL			= 0x00000040L,
    SQL_CVT_DOUBLE			= 0x00000080L,
    SQL_CVT_VARCHAR			= 0x00000100L,
    SQL_CVT_LONGVARCHAR			= 0x00000200L,
    SQL_CVT_BINARY			= 0x00000400L,
    SQL_CVT_VARBINARY			= 0x00000800L,
    SQL_CVT_BIT				= 0x00001000L,
    SQL_CVT_TINYINT			= 0x00002000L,
    SQL_CVT_BIGINT			= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_CVT_DATE		  0x00008000L
    #define SQL_CVT_TIME		  0x00010000L
    #define SQL_CVT_TIMESTAMP		  0x00020000L
    #define SQL_CVT_LONGVARBINARY	  0x00040000L
    #if (ODBCVER >= 0x0300)
    #define SQL_CVT_INTERVAL_YEAR_MONTH	  0x00080000L
    #define SQL_CVT_INTERVAL_DAY_TIME	  0x00100000L
    #define SQL_CVT_WCHAR		  0x00200000L
    #define SQL_CVT_WLONGVARCHAR	  0x00400000L
    #define SQL_CVT_WVARCHAR		  0x00800000L
    #define SQL_CVT_GUID		  0x01000000L
    #endif /* ODBCVER >= 0x0300 */
};

/* ODBC 3.0 SQLGetInfo return values */
#if (ODBCVER >= 0x0300)
enum enumAggregateFunctions {
    SQL_AF_AVG		= 0x00000001L,
    SQL_AF_COUNT	= 0x00000002L,
    SQL_AF_MAX		= 0x00000004L,
    SQL_AF_MIN		= 0x00000008L,
    SQL_AF_SUM		= 0x00000010L,
    SQL_AF_DISTINCT	= 0x00000020L,
    SQL_AF_ALL		= 0x00000040L
};

enum enumSQLConformance {
    SQL_SC_SQL92_ENTRY			= 0x00000001L,
    SQL_SC_FIPS127_2_TRANSITIONAL	= 0x00000002L,
    SQL_SC_SQL92_INTERMEDIATE		= 0x00000004L,
    SQL_SC_SQL92_FULL			= 0x00000008L
};

enum enumDateTimeLiterals {
    SQL_DL_SQL92_DATE					= 0x00000001L,
    SQL_DL_SQL92_TIME					= 0x00000002L,
    SQL_DL_SQL92_TIMESTAMP				= 0x00000004L,
    SQL_DL_SQL92_INTERVAL_YEAR				= 0x00000008L,
    SQL_DL_SQL92_INTERVAL_MONTH				= 0x00000010L,
    SQL_DL_SQL92_INTERVAL_DAY				= 0x00000020L,
    SQL_DL_SQL92_INTERVAL_HOUR				= 0x00000040L,
    SQL_DL_SQL92_INTERVAL_MINUTE			= 0x00000080L,
    SQL_DL_SQL92_INTERVAL_SECOND			= 0x00000100L,
    SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH			= 0x00000200L,
    SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR			= 0x00000400L,
    SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE			= 0x00000800L,
    SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND			= 0x00001000L,
    SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE		= 0x00002000L,
    SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND	  0x00008000L
};

#define SQL_CL_START	SQL_QL_START
#define SQL_CL_END	SQL_QL_END

enum enumBatchRowCount {
    SQL_BRC_PROCEDURES	= 0x0000001,
    SQL_BRC_EXPLICIT	= 0x0000002,
    SQL_BRC_ROLLED_UP	= 0x0000004
};

enum enumBatchSupport {
    SQL_BS_SELECT_EXPLICIT	= 0x00000001L,
    SQL_BS_ROW_COUNT_EXPLICIT	= 0x00000002L,
    SQL_BS_SELECT_PROC		= 0x00000004L,
    SQL_BS_ROW_COUNT_PROC	= 0x00000008L
};

enum enumParamArrayRC {
    SQL_PARC_BATCH	= 1,
    SQL_PARC_NO_BATCH
};

enum enumParamArraySB {
    SQL_PAS_BATCH	= 1,
    SQL_PAS_NO_BATCH,
    SQL_PAS_NO_SELECT
};

enum enumIndexKeywords {
    SQL_IK_NONE		= 0x00000000L,
    SQL_IK_ASC		= 0x00000001L,
    SQL_IK_DESC		= 0x00000002L
    /* We don't define enums in terms of enums values in the same enum type */
    #define SQL_IK_ALL	  (SQL_IK_ASC | SQL_IK_DESC)
};

enum enumInfoSchemaViews {
    SQL_ISV_ASSERTIONS			= 0x00000001L,
    SQL_ISV_CHARACTER_SETS		= 0x00000002L,
    SQL_ISV_CHECK_CONSTRAINTS		= 0x00000004L,
    SQL_ISV_COLLATIONS			= 0x00000008L,
    SQL_ISV_COLUMN_DOMAIN_USAGE		= 0x00000010L,
    SQL_ISV_COLUMN_PRIVILEGES		= 0x00000020L,
    SQL_ISV_COLUMNS			= 0x00000040L,
    SQL_ISV_CONSTRAINT_COLUMN_USAGE	= 0x00000080L,
    SQL_ISV_CONSTRAINT_TABLE_USAGE	= 0x00000100L,
    SQL_ISV_DOMAIN_CONSTRAINTS		= 0x00000200L,
    SQL_ISV_DOMAINS			= 0x00000400L,
    SQL_ISV_KEY_COLUMN_USAGE		= 0x00000800L,
    SQL_ISV_REFERENTIAL_CONSTRAINTS	= 0x00001000L,
    SQL_ISV_SCHEMATA			= 0x00002000L,
    SQL_ISV_SQL_LANGUAGES		= 0x00004000L
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    #define SQL_ISV_TABLE_CONSTRAINTS	  0x00008000L
    #define SQL_ISV_TABLE_PRIVILEGES	  0x00010000L
    #define SQL_ISV_TABLES		  0x00020000L
    #define SQL_ISV_TRANSLATIONS	  0x00040000L
    #define SQL_ISV_USAGE_PRIVILEGES	  0x00080000L
    #define SQL_ISV_VIEW_COLUMN_USAGE	  0x00100000L
    #define SQL_ISV_VIEW_TABLE_USAGE	  0x00200000L
    #define SQL_ISV_VIEWS		  0x00400000L
};

enum enumAlterDomain {
    SQL_AD_CONSTRAINT_NAME_DEFINITION		= 0x00000001L,
    SQL_AD_ADD_DOMAIN_CONSTRAINT		= 0x00000002L,
    SQL_AD_DROP_DOMAIN_CONSTRAINT		= 0x00000004L,
    SQL_AD_ADD_DOMAIN_DEFAULT 	 		= 0x00000008L,
    SQL_AD_DROP_DOMAIN_DEFAULT  		= 0x00000010L,
    SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED	= 0x00000020L,
    SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE	= 0x00000040L,
    SQL_AD_ADD_CONSTRAINT_DEFERRABLE		= 0x00000080L,
    SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE	= 0x00000100L
};

enum enumCreateSchema {
    SQL_CS_CREATE_SCHEMA		= 0x00000001L,
    SQL_CS_AUTHORIZATION		= 0x00000002L,
    SQL_CS_DEFAULT_CHARACTER_SET	= 0x00000004L
};

enum enumCreateTranslation {
    SQL_CTR_CREATE_TRANSLATION	= 0x00000001L
};

enum enumCreateAssertion {
    SQL_CA_CREATE_ASSERTION			= 0x00000001L,
    SQL_CA_CONSTRAINT_INITIALLY_DEFERRED	= 0x00000010L,
    SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE	= 0x00000020L,
    SQL_CA_CONSTRAINT_DEFERRABLE		= 0x00000040L,
    SQL_CA_CONSTRAINT_NON_DEFERRABLE		= 0x00000080L
};

enum enumCreateCharSet {
    SQL_CCS_CREATE_CHARACTER_SET	= 0x00000001L,
    SQL_CCS_COLLATE_CLAUSE		= 0x00000002L,
    SQL_CCS_LIMITED_COLLATION		= 0x00000004L
};

enum enumCreateCollation {
    SQL_CCOL_CREATE_COLLATION	= 0x00000001L
};

enum enumCreateDomain {
    SQL_CDO_CREATE_DOMAIN			= 0x00000001L,
    SQL_CDO_DEFAULT				= 0x00000002L,
    SQL_CDO_CONSTRAINT				= 0x00000004L,
    SQL_CDO_COLLATION				= 0x00000008L,
    SQL_CDO_CONSTRAINT_NAME_DEFINITION		= 0x00000010L,
    SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED	= 0x00000020L,
    SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE	= 0x00000040L,
    SQL_CDO_CONSTRAINT_DEFERRABLE		= 0x00000080L,
    SQL_CDO_CONSTRAINT_NON_DEFERRABLE		= 0x00000100L
};

enum enumCreateTable {
    SQL_CT_CREATE_TABLE				= 0x00000001L,
    SQL_CT_COMMIT_PRESERVE			= 0x00000002L,
    SQL_CT_COMMIT_DELETE			= 0x00000004L,
    SQL_CT_GLOBAL_TEMPORARY			= 0x00000008L,
    SQL_CT_LOCAL_TEMPORARY			= 0x00000010L,
    SQL_CT_CONSTRAINT_INITIALLY_DEFERRED	= 0x00000020L,
    SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE	= 0x00000040L,
    SQL_CT_CONSTRAINT_DEFERRABLE		= 0x00000080L,
    SQL_CT_CONSTRAINT_NON_DEFERRABLE		= 0x00000100L,
    SQL_CT_COLUMN_CONSTRAINT			= 0x00000200L,
    SQL_CT_COLUMN_DEFAULT			= 0x00000400L,
    SQL_CT_COLUMN_COLLATION			= 0x00000800L,
    SQL_CT_TABLE_CONSTRAINT			= 0x00001000L,
    SQL_CT_CONSTRAINT_NAME_DEFINITION		= 0x00002000L
};

enum enumDDLIndex {
    SQL_DI_CREATE_INDEX	= 0x00000001L,
    SQL_DI_DROP_INDEX	= 0x00000002L
};

enum enumDropCollation {
    SQL_DC_DROP_COLLATION	= 0x00000001L
};

enum enumDropDomain {
    SQL_DD_DROP_DOMAIN	= 0x00000001L,
    SQL_DD_RESTRICT	= 0x00000002L,
    SQL_DD_CASCADE	= 0x00000004L
};

enum enumDropSchema {
    SQL_DS_DROP_SCHEMA	= 0x00000001L,
    SQL_DS_RESTRICT	= 0x00000002L,
    SQL_DS_CASCADE	= 0x00000004L
};

enum enumDropCharSet {
    SQL_DCS_DROP_CHARACTER_SET	= 0x00000001L
};

enum enumDropAssertion {
    SQL_DA_DROP_ASSERTION	= 0x00000001L
};

enum enumDropTable {
    SQL_DT_DROP_TABLE	= 0x00000001L,
    SQL_DT_RESTRICT	= 0x00000002L,
    SQL_DT_CASCADE	= 0x00000004L
};

enum enumDropTranslation {
    SQL_DTR_DROP_TRANSLATION	= 0x00000001L
};

enum enumDropView {
    SQL_DV_DROP_VIEW	= 0x00000001L,
    SQL_DV_RESTRICT	= 0x00000002L,
    SQL_DV_CASCADE	= 0x00000004L
};

enum enumInsertStatement {
    SQL_IS_INSERT_LITERALS	= 0x00000001L,
    SQL_IS_INSERT_SEARCHED	= 0x00000002L,
    SQL_IS_SELECT_INTO		= 0x00000004L
};

enum enumODBCInterfaceConformance {
    SQL_OIC_CORE	= 1UL,
    SQL_OIC_LEVEL1	= 2UL,
    SQL_OIC_LEVEL2	= 3UL
};

enum enumSQL92ForeignKeyDelete {
    SQL_SFKD_CASCADE		= 0x00000001L,
    SQL_SFKD_NO_ACTION		= 0x00000002L,
    SQL_SFKD_SET_DEFAULT	= 0x00000004L,
    SQL_SFKD_SET_NULL		= 0x00000008L
};

enum enumSQL92ForeignKeyUpdate {
    SQL_SFKU_CASCADE		= 0x00000001L,
    SQL_SFKU_NO_ACTION		= 0x00000002L,
    SQL_SFKU_SET_DEFAULT	= 0x00000004L,
    SQL_SFKU_SET_NULL		= 0x00000008L
};

enum enumSQL92Grant {
    SQL_SG_USAGE_ON_DOMAIN		= 0x00000001L,
    SQL_SG_USAGE_ON_CHARACTER_SET	= 0x00000002L,
    SQL_SG_USAGE_ON_COLLATION		= 0x00000004L,
    SQL_SG_USAGE_ON_TRANSLATION		= 0x00000008L,
    SQL_SG_WITH_GRANT_OPTION		= 0x00000010L,
    SQL_SG_DELETE_TABLE			= 0x00000020L,
    SQL_SG_INSERT_TABLE			= 0x00000040L,
    SQL_SG_INSERT_COLUMN		= 0x00000080L,
    SQL_SG_REFERENCES_TABLE		= 0x00000100L,
    SQL_SG_REFERENCES_COLUMN		= 0x00000200L,
    SQL_SG_SELECT_TABLE			= 0x00000400L,
    SQL_SG_UPDATE_TABLE			= 0x00000800L,
    SQL_SG_UPDATE_COLUMN		= 0x00001000L
};

enum enumSQL92Predicates {
    SQL_SP_EXISTS			= 0x00000001L,
    SQL_SP_ISNOTNULL			= 0x00000002L,
    SQL_SP_ISNULL			= 0x00000004L,
    SQL_SP_MATCH_FULL			= 0x00000008L,
    SQL_SP_MATCH_PARTIAL		= 0x00000010L,
    SQL_SP_MATCH_UNIQUE_FULL		= 0x00000020L,
    SQL_SP_MATCH_UNIQUE_PARTIAL		= 0x00000040L,
    SQL_SP_OVERLAPS			= 0x00000080L,
    SQL_SP_UNIQUE			= 0x00000100L,
    SQL_SP_LIKE				= 0x00000200L,
    SQL_SP_IN				= 0x00000400L,
    SQL_SP_BETWEEN			= 0x00000800L,
    SQL_SP_COMPARISON			= 0x00001000L,
    SQL_SP_QUANTIFIED_COMPARISON	= 0x00002000L
};

enum enumSQL92RelationalJoinOps {
    SQL_SRJO_CORRESPONDING_CLAUSE	= 0x00000001L,
    SQL_SRJO_CROSS_JOIN			= 0x00000002L,
    SQL_SRJO_EXCEPT_JOIN		= 0x00000004L,
    SQL_SRJO_FULL_OUTER_JOIN		= 0x00000008L,
    SQL_SRJO_INNER_JOIN			= 0x00000010L,
    SQL_SRJO_INTERSECT_JOIN		= 0x00000020L,
    SQL_SRJO_LEFT_OUTER_JOIN		= 0x00000040L,
    SQL_SRJO_NATURAL_JOIN		= 0x00000080L,
    SQL_SRJO_RIGHT_OUTER_JOIN		= 0x00000100L,
    SQL_SRJO_UNION_JOIN			= 0x00000200L
};

enum enumSQL92Revoke {
    SQL_SR_USAGE_ON_DOMAIN		= 0x00000001L,
    SQL_SR_USAGE_ON_CHARACTER_SET	= 0x00000002L,
    SQL_SR_USAGE_ON_COLLATION		= 0x00000004L,
    SQL_SR_USAGE_ON_TRANSLATION		= 0x00000008L,
    SQL_SR_GRANT_OPTION_FOR		= 0x00000010L,
    SQL_SR_CASCADE			= 0x00000020L,
    SQL_SR_RESTRICT			= 0x00000040L,
    SQL_SR_DELETE_TABLE			= 0x00000080L,
    SQL_SR_INSERT_TABLE			= 0x00000100L,
    SQL_SR_INSERT_COLUMN		= 0x00000200L,
    SQL_SR_REFERENCES_TABLE		= 0x00000400L,
    SQL_SR_REFERENCES_COLUMN		= 0x00000800L,
    SQL_SR_SELECT_TABLE			= 0x00001000L,
    SQL_SR_UPDATE_TABLE			= 0x00002000L,
    SQL_SR_UPDATE_COLUMN		= 0x00004000L
};

enum enumSQL92RowValueConstructor {
    SQL_SRVC_VALUE_EXPRESSION	= 0x00000001L,
    SQL_SRVC_NULL		= 0x00000002L,
    SQL_SRVC_DEFAULT		= 0x00000004L,
    SQL_SRVC_ROW_SUBQUERY	= 0x00000008L
};

enum enumSQL92ValueExpressions {
    SQL_SVE_CASE	= 0x00000001L,
    SQL_SVE_CAST	= 0x00000002L,
    SQL_SVE_COALESCE	= 0x00000004L,
    SQL_SVE_NULLIF	= 0x00000008L
};

enum enumSQL92StandardCLIConformance {
    SQL_SCC_XOPEN_CLI_VERSION1	= 0x00000001L,
    SQL_SCC_ISO92_CLI		= 0x00000002L
};

#define SQL_US_UNION		SQL_U_UNION
#define SQL_US_UNION_ALL	SQL_U_UNION_ALL

#endif /* ODBCVER >= 0x0300 -- ODBC 3.0 SQLGetInfo return values */

/* SQL_DTC_TRANSITION_COST bitmasks */
enum enumSQLDTCTransitionCosts {
	SQL_DTC_ENLIST_EXPENSIVE	= 0x00000001L,
	SQL_DTC_UNENLIST_EXPENSIVE	= 0x00000002L
};

enum enumSQLGetInfo {			/* Types of information available */
    /* Driver information */
    SQL_INFO_FIRST,			/* first GetInfo type */
    SQL_ACTIVE_CONNECTIONS = 0,		/* returns short */
    #if (ODBCVER >= 0x0300)
    SQL_MAX_DRIVER_CONNECTIONS = 0,
    SQL_MAX_CONCURRENT_ACTIVITIES,
    #endif /* ODBCVER >= 0x0300 */
    SQL_ACTIVE_STATEMENTS = 1,		/* returns short */
    SQL_DATA_SOURCE_NAME,		/* returns string */
    SQL_DRIVER_HDBC,			/* returns HDBC */
    SQL_DRIVER_HENV,			/* returns HENV */
    SQL_DRIVER_HSTMT,			/* returns HSTMT */
    SQL_DRIVER_NAME,			/* returns string */
    SQL_DRIVER_VER,			/* returns string */
    SQL_FETCH_DIRECTION,		/* returns mask of enumSQLFetchDirection */
    SQL_ODBC_API_CONFORMANCE,		/* returns integer 0, 1 or 2*/
    SQL_ODBC_VER,		/* 10 */ /* returns string */
    SQL_ROW_UPDATES,			/* returns string "Y" or "N" */
    SQL_ODBC_SAG_CLI_CONFORMANCE,	/* returns short TRUE or FALSE */
    SQL_SERVER_NAME,			/* returns string */
    SQL_SEARCH_PATTERN_ESCAPE,		/* returns string */
    SQL_ODBC_SQL_CONFORMANCE,		/* returns short 0, 1 or 2 */
    /* DBMS information */
    SQL_DATABASE_NAME,			/* Use SQLGetConnectOption/SQL_CURRENT_QUALIFIER */
    SQL_DBMS_NAME,			/* returns string */
    SQL_DBMS_VER,			/* returns string */
    /* Data source capabilities */
    SQL_ACCESSIBLE_TABLES,		/* returns string "Y" or "N" */
    SQL_ACCESSIBLE_PROCEDURES,	/* 20 */ /* returns string "Y" or "N" */
    SQL_PROCEDURES,			/* returns string "Y" or "N" */
    SQL_CONCAT_NULL_BEHAVIOR,		/* returns short 0=NULL 1=empty string */
    SQL_CURSOR_COMMIT_BEHAVIOR,		/* returns short 0=close/del 1=close 2=open */
    SQL_CURSOR_ROLLBACK_BEHAVIOR,	/* same as above */
    SQL_DATA_SOURCE_READ_ONLY,		/* returns string "Y" or "N" */
    SQL_DEFAULT_TXN_ISOLATION,		/* returns mask of enumSQLIsolation */
    SQL_EXPRESSIONS_IN_ORDERBY,		/* returns string "Y" or "N" */
    SQL_IDENTIFIER_CASE,		/* returns short 0=UPR 1=LWR 2=case sens 3=ins*/
    SQL_IDENTIFIER_QUOTE_CHAR,		/* returns string */
    SQL_MAX_COLUMN_NAME_LEN,	/* 30 */ /* returns short */
    SQL_MAX_CURSOR_NAME_LEN,		/* returns short */
    SQL_MAX_OWNER_NAME_LEN,		/* returns short */
    SQL_MAX_SCHEMA_NAME_LEN = 32,
    SQL_MAX_PROCEDURE_NAME_LEN,		/* returns short */
    SQL_MAX_QUALIFIER_NAME_LEN,		/* returns short */
    SQL_MAX_CATALOG_NAME_LEN = 34,
    SQL_MAX_TABLE_NAME_LEN,		/* returns short */
    SQL_MULT_RESULT_SETS,		/* returns string "Y" or "N" */
    SQL_MULTIPLE_ACTIVE_TXN,		/* returns string "Y" or "N" */
    SQL_OUTER_JOINS,			/* returns string "Y" or "N" */
    SQL_OWNER_TERM,			/* returns string */
    SQL_PROCEDURE_TERM,		/* 40 */ /* returns string */
    SQL_QUALIFIER_NAME_SEPARATOR,	/* returns string */
    SQL_QUALIFIER_TERM,			/* returns string */
    SQL_SCROLL_CONCURRENCY,		/* returns mask of enumSQLConcurMask */
    SQL_SCROLL_OPTIONS,			/* returns mask of enumSQLScrollOptions */
    SQL_TABLE_TERM,			/* returns string */
    SQL_TXN_CAPABLE,			/* returns short 0=none 1=DML 2=DML&DDL */
    SQL_USER_NAME,			/* returns string */
    /* Available functions */
    SQL_CONVERT_FUNCTIONS,		/* returns mask of enumSQLConvertFunctions */
    SQL_NUMERIC_FUNCTIONS,		/* returns mask of enumSQLNumericFunctions */
    SQL_STRING_FUNCTIONS,	/* 50 */ /* returns mask of enumSQLStringFunctions */
    SQL_SYSTEM_FUNCTIONS,		/* returns mask of enumSQLSystemFunctions */
    SQL_TIMEDATE_FUNCTIONS,		/* returns mask of enumSQLTimedateFunctions */
    /* Conversion capabilities -- all return mask of enumSQLConvert */
    SQL_CONVERT_BIGINT,
    SQL_CONVERT_BINARY,
    SQL_CONVERT_BIT,
    SQL_CONVERT_CHAR,
    SQL_CONVERT_DATE,
    SQL_CONVERT_DECIMAL,
    SQL_CONVERT_DOUBLE,
    SQL_CONVERT_FLOAT,			/* 60 */
    SQL_CONVERT_INTEGER,
    SQL_CONVERT_LONGVARCHAR,
    SQL_CONVERT_NUMERIC,
    SQL_CONVERT_REAL,
    SQL_CONVERT_SMALLINT,
    SQL_CONVERT_TIME,
    SQL_CONVERT_TIMESTAMP,
    SQL_CONVERT_TINYINT,
    SQL_CONVERT_VARBINARY,
    SQL_CONVERT_VARCHAR,		/* 70 */
    SQL_CONVERT_LONGVARBINARY,
    /* Afterthought -- should be in Data source capabilities */
    SQL_TXN_ISOLATION_OPTION,		/* returns enumSQLIsolation */
    SQL_ODBC_SQL_OPT_IEF,
    SQL_INTEGRITY = 73,
    SQL_CORRELATION_NAME,
    SQL_NON_NULLABLE_COLUMNS
    #if (ODBCVER >= 0x0200)
,   SQL_DRIVER_HLIB,
    SQL_DRIVER_ODBC_VER,
    SQL_LOCK_TYPES,
    SQL_POS_OPERATIONS,
    SQL_POSITIONED_STATEMENTS,		/* 80 */
    SQL_GETDATA_EXTENSIONS,
    SQL_BOOKMARK_PERSISTENCE,
    SQL_STATIC_SENSITIVITY,
    SQL_FILE_USAGE,
    SQL_NULL_COLLATION,
    SQL_ALTER_TABLE,
    SQL_COLUMN_ALIAS,
    SQL_GROUP_BY,
    SQL_KEYWORDS,
    SQL_ORDER_BY_COLUMNS_IN_SELECT,	/* 90 */
    SQL_OWNER_USAGE,
    SQL_QUALIFIER_USAGE,
    SQL_QUOTED_IDENTIFIER_CASE,
    SQL_SPECIAL_CHARACTERS,
    SQL_SUBQUERIES,
    SQL_UNION,
    SQL_MAX_COLUMNS_IN_GROUP_BY,
    SQL_MAX_COLUMNS_IN_INDEX,
    SQL_MAX_COLUMNS_IN_ORDER_BY,
    SQL_MAX_COLUMNS_IN_SELECT,		/* 100 */
    SQL_MAX_COLUMNS_IN_TABLE,
    SQL_MAX_INDEX_SIZE,
    SQL_MAX_ROW_SIZE_INCLUDES_LONG,
    SQL_MAX_ROW_SIZE,
    SQL_MAX_STATEMENT_LEN,
    SQL_MAX_TABLES_IN_SELECT,
    SQL_MAX_USER_NAME_LEN,
    SQL_MAX_CHAR_LITERAL_LEN,
    SQL_TIMEDATE_ADD_INTERVALS,
    SQL_TIMEDATE_DIFF_INTERVALS,	/* 110 */
    SQL_NEED_LONG_DATA_LEN,
    SQL_MAX_BINARY_LITERAL_LEN,
    SQL_LIKE_ESCAPE_CLAUSE,
    SQL_QUALIFIER_LOCATION,

    #if (ODBCVER >= 0x0300)
    SQL_OJ_CAPABILITIES,
    SQL_ACTIVE_ENVIRONMENTS,
    SQL_ALTER_DOMAIN,
    SQL_SQL_CONFORMANCE,
    SQL_DATETIME_LITERALS,
    SQL_BATCH_ROW_COUNT,		/* 120 */
    SQL_BATCH_SUPPORT,
    SQL_CONVERT_WCHAR,
    SQL_CONVERT_INTERVAL_DAY_TIME,
    SQL_CONVERT_INTERVAL_YEAR_MONTH,
    SQL_CONVERT_WLONGVARCHAR,
    SQL_CONVERT_WVARCHAR,
    SQL_CREATE_ASSERTION,
    SQL_CREATE_CHARACTER_SET,
    SQL_CREATE_COLLATION,
    SQL_CREATE_DOMAIN,			/* 130 */
    SQL_CREATE_SCHEMA,
    SQL_CREATE_TABLE,
    SQL_CREATE_TRANSLATION,
    SQL_CREATE_VIEW,
    SQL_DRIVER_HDESC,
    SQL_DROP_ASSERTION,
    SQL_DROP_CHARACTER_SET,
    SQL_DROP_COLLATION,
    SQL_DROP_DOMAIN,
    SQL_DROP_SCHEMA,			/* 140 */
    SQL_DROP_TABLE,
    SQL_DROP_TRANSLATION,
    SQL_DROP_VIEW,
    SQL_DYNAMIC_CURSOR_ATTRIBUTES1,
    SQL_DYNAMIC_CURSOR_ATTRIBUTES2,
    SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1,
    SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2,
    SQL_INDEX_KEYWORDS,
    SQL_INFO_SCHEMA_VIEWS,
    SQL_KEYSET_CURSOR_ATTRIBUTES1,	/* 150 */
    SQL_KEYSET_CURSOR_ATTRIBUTES2,
    SQL_ODBC_INTERFACE_CONFORMANCE,
    SQL_PARAM_ARRAY_ROW_COUNTS,
    SQL_PARAM_ARRAY_SELECTS,
    SQL_SQL92_DATETIME_FUNCTIONS,
    SQL_SQL92_FOREIGN_KEY_DELETE_RULE,
    SQL_SQL92_FOREIGN_KEY_UPDATE_RULE,
    SQL_SQL92_GRANT,
    SQL_SQL92_NUMERIC_VALUE_FUNCTIONS,
    SQL_SQL92_PREDICATES,		/* 160 */
    SQL_SQL92_RELATIONAL_JOIN_OPERATORS,
    SQL_SQL92_REVOKE,
    SQL_SQL92_ROW_VALUE_CONSTRUCTOR,
    SQL_SQL92_STRING_FUNCTIONS,
    SQL_SQL92_VALUE_EXPRESSIONS,
    SQL_STANDARD_CLI_CONFORMANCE,
    SQL_STATIC_CURSOR_ATTRIBUTES1,
    SQL_STATIC_CURSOR_ATTRIBUTES2,
    SQL_AGGREGATE_FUNCTIONS,
    SQL_DDL_INDEX,			/* 170 */
    SQL_DM_VER,
    SQL_INSERT_STATEMENT,
    SQL_CONVERT_GUID,

    SQL_XOPEN_CLI_YEAR = 10000,		/* 10000 */
    SQL_CURSOR_SENSITIVITY,
    SQL_DESCRIBE_PARAMETER,
    SQL_CATALOG_NAME,
    SQL_COLLATION_SEQ,
    SQL_MAX_IDENTIFIER_LEN,
    SQL_ASYNC_MODE = 10021,		/* 10021 */
    SQL_MAX_ASYNC_CONCURRENT_STATEMENTS,
    #elif (ODBCVER >= 0x0201)
    /* Enums are of type int: the rest can't be enums with 16 bit compilers */
    SQL_OJ_CAPABILITIES	= 65003,	/* Temp value until ODBC 3.0 */
    #endif /* ODBCVER >= 0x0300 */

    #endif /* ODBCVER >= 0x0200 */

	SQL_DTC_TRANSITION_COST = 1750

};
#if (ODBCVER >= 0x0300)
#define SQL_CATALOG_LOCATION		SQL_QUALIFIER_LOCATION
#define SQL_CATALOG_NAME_SEPARATOR	SQL_QUALIFIER_NAME_SEPARATOR
#define SQL_CATALOG_TERM		SQL_QUALIFIER_TERM
#define SQL_CATALOG_USAGE		SQL_QUALIFIER_USAGE
#define SQL_SCHEMA_TERM			SQL_OWNER_TERM
#define SQL_SCHEMA_USAGE		SQL_OWNER_USAGE
#define SQL_UNION_STATEMENT		SQL_UNION
#endif /* ODBCVER >= 0x0300 */

/* SQL_INFO_LAST and SQL_INFO_DRIVER_START ---------------------------- */
/* Not useful with ODBC 3.0 since X/Open values > 10000.  Must contact  */
/* X/Open directly to get a range of numbers for driver-specific values */
/* -------------------------------------------------------------------- */
#if (ODBCVER < 0x0300)
#define SQL_INFO_LAST		SQL_QUALIFIER_LOCATION
#define SQL_INFO_DRIVER_START	1000
#endif /* ODBCVER >= 0x0300 */

/* Aliases for SQLGetInfo types */
#if (ODBCVER >= 0x0300)
#define SQL_MAXIMUM_DRIVER_CONNECTIONS		SQL_MAX_DRIVER_CONNECTIONS
#define SQL_MAXIMUM_CONCURRENT_ACTIVITIES	SQL_MAX_CONCURRENT_ACTIVITIES
#define SQL_MAXIMUM_COLUMN_NAME_LENGTH		SQL_MAX_COLUMN_NAME_LEN
#define SQL_MAXIMUM_CURSOR_NAME_LENGTH		SQL_MAX_CURSOR_NAME_LEN
#define SQL_MAXIMUM_SCHEMA_NAME_LENGTH		SQL_MAX_SCHEMA_NAME_LEN
#define SQL_MAXIMUM_CATALOG_NAME_LENGTH		SQL_MAX_CATALOG_NAME_LEN
#define SQL_MAXIMUM_TABLE_NAME_LENGTH		SQL_MAX_TABLE_NAME_LEN
#define SQL_TRANSACTION_CAPABLE			SQL_TXN_CAPABLE
#define SQL_TRANSACTION_ISOLATION_OPTION	SQL_TXN_ISOLATION_OPTION
#define SQL_MAXIMUM_COLUMNS_IN_GROUP_BY		SQL_MAX_COLUMNS_IN_GROUP_BY
#define SQL_MAXIMUM_COLUMNS_IN_INDEX		SQL_MAX_COLUMNS_IN_INDEX
#define SQL_MAXIMUM_COLUMNS_IN_ORDER_BY		SQL_MAX_COLUMNS_IN_ORDER_BY
#define SQL_MAXIMUM_COLUMNS_IN_SELECT		SQL_MAX_COLUMNS_IN_SELECT
#define SQL_MAXIMUM_INDEX_SIZE			SQL_MAX_INDEX_SIZE
#define SQL_MAXIMUM_ROW_SIZE			SQL_MAX_ROW_SIZE
#define SQL_MAXIMUM_STATEMENT_LENGTH		SQL_MAX_STATEMENT_LEN
#define SQL_MAXIMUM_TABLES_IN_SELECT		SQL_MAX_TABLES_IN_SELECT
#define SQL_MAXIMUM_USER_NAME_LENGTH		SQL_MAX_USER_NAME_LEN
#define SQL_OUTER_JOIN_CAPABILITIES		SQL_OJ_CAPABILITIES
#define SQL_MAXIMUM_IDENTIFIER_LENGTH		SQL_MAX_IDENTIFIER_LEN
#endif /* ODBCVER >= 0x0300 */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLGetInfo(			/* Level 1 */
    SQLHDBC			ConnectionHandle,
    SQLUSMALLINT		InfoType,	/* enumSQLGetInfo */
    SQLPOINTER			InfoValue,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength );
#endif // UL_ODBC

/* API functions -- descriptors */

#if (ODBCVER >= 0x0300)
enum enumWhereSearchable {	/* Shows WHERE clause supported in
				   SQLGetTypeInfo, SQLColAttributes,
				   SQLSetDescField */
    SQL_PRED_NONE,
    SQL_PRED_CHAR,
    SQL_PRED_BASIC
};

enum enumUnnamed {
    SQL_NAMED,
    SQL_UNNAMED
};

enum enumAllocType {
    SQL_DESC_ALLOC_AUTO	= 1,
    SQL_DESC_ALLOC_USER
};

enum enumSQLDescField {
    /* Extended descriptor fields */
    SQL_DESC_ARRAY_SIZE			= 20,
    SQL_DESC_ARRAY_STATUS_PTR,
    SQL_DESC_BASE_COLUMN_NAME,
    SQL_DESC_BASE_TABLE_NAME,
    SQL_DESC_BIND_OFFSET_PTR,
    SQL_DESC_BIND_TYPE,
    SQL_DESC_DATETIME_INTERVAL_PRECISION,
    SQL_DESC_LITERAL_PREFIX,
    SQL_DESC_LITERAL_SUFFIX,
    SQL_DESC_LOCAL_TYPE_NAME,
    SQL_DESC_MAXIMUM_SCALE,
    SQL_DESC_MINIMUM_SCALE,
    SQL_DESC_NUM_PREC_RADIX,
    SQL_DESC_PARAMETER_TYPE,
    SQL_DESC_ROWS_PROCESSED_PTR,
    #if (ODBCVER >= 0x0350)
    SQL_DESC_ROWVER,
    #endif /* ODBCVER >= 0x0350 */

    /* Identifiers of fields */
    SQL_DESC_COUNT			= 1001,
    SQL_DESC_TYPE,
    SQL_DESC_LENGTH,
    SQL_DESC_OCTET_LENGTH_PTR,
    SQL_DESC_PRECISION,
    SQL_DESC_SCALE,
    SQL_DESC_DATETIME_INTERVAL_CODE,
    SQL_DESC_NULLABLE,
    SQL_DESC_INDICATOR_PTR,
    SQL_DESC_DATA_PTR,
    SQL_DESC_NAME,
    SQL_DESC_UNNAMED,
    SQL_DESC_OCTET_LENGTH,
    SQL_DESC_ALLOC_TYPE			= 1099
};

/* Extended descriptor fields */
#define SQL_DESC_AUTO_UNIQUE_VALUE	SQL_COLUMN_AUTO_INCREMENT
#define SQL_DESC_CASE_SENSITIVE		SQL_COLUMN_CASE_SENSITIVE
#define SQL_DESC_CATALOG_NAME		SQL_COLUMN_QUALIFIER_NAME
#define SQL_DESC_CONCISE_TYPE		SQL_COLUMN_TYPE
#define SQL_DESC_DISPLAY_SIZE		SQL_COLUMN_DISPLAY_SIZE
#define SQL_DESC_FIXED_PREC_SCALE	SQL_COLUMN_MONEY
#define SQL_DESC_LABEL			SQL_COLUMN_LABEL
#define SQL_DESC_SCHEMA_NAME		SQL_COLUMN_OWNER_NAME
#define SQL_DESC_SEARCHABLE		SQL_COLUMN_SEARCHABLE
#define SQL_DESC_TYPE_NAME		SQL_COLUMN_TYPE_NAME
#define SQL_DESC_TABLE_NAME		SQL_COLUMN_TABLE_NAME
#define SQL_DESC_UNSIGNED		SQL_COLUMN_UNSIGNED
#define SQL_DESC_UPDATABLE		SQL_COLUMN_UPDATABLE

enum enumDescArrayStatusPtr {
    SQL_PARAM_PROCEED		= 0,
    SQL_PARAM_IGNORE,
    SQL_PARAM_SUCCESS		= 0,
    SQL_PARAM_DIAG_UNAVAILABLE,
    SQL_PARAM_ERROR		= 5,
    SQL_PARAM_SUCCESS_WITH_INFO,
    SQL_PARAM_UNUSED
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLCopyDesc(
    SQLHDESC	SourceDescHandle,
    SQLHDESC	TargetDescHandle );

SQLRETURN ODBC_API SQLGetDescField(
    SQLHDESC			DescriptorHandle,
    SQLSMALLINT			RecNumber,
    SQLSMALLINT			FieldIdentifier,
    SQLPOINTER			Value,
    SQLINTEGER 			BufferLength,
    SQLINTEGER ODBCFAR *	StringLength );

SQLRETURN ODBC_API SQLSetDescField(
    SQLHDESC			DescriptorHandle,
    SQLSMALLINT			RecNumber,
    SQLSMALLINT			FieldIdentifier,
    SQLPOINTER			Value,
    SQLINTEGER			BufferLength );

SQLRETURN ODBC_API SQLGetDescRec(
    SQLHDESC			DescriptorHandle,
    SQLSMALLINT			RecNumber,
    SQLCHAR ODBCFAR *		Name,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength,
    SQLSMALLINT ODBCFAR *	Type,
    SQLSMALLINT ODBCFAR *	SubType, 
    SQLLEN ODBCFAR *		Length,
    SQLSMALLINT ODBCFAR *	Precision, 
    SQLSMALLINT ODBCFAR *	Scale,
    SQLSMALLINT ODBCFAR *	Nullable );

SQLRETURN ODBC_API SQLSetDescRec(
    SQLHDESC			DescriptorHandle,
    SQLSMALLINT			RecNumber,
    SQLSMALLINT			Type,
    SQLSMALLINT			SubType,
    SQLLEN			Length,
    SQLSMALLINT			Precision,
    SQLSMALLINT			Scale,
    SQLPOINTER			Data,
    SQLLEN ODBCFAR *		StringLength,
    SQLLEN ODBCFAR *		Indicator );
#endif // UL_ODBC

#endif /* ODBCVER >= 0x0300 */

/* API functions -- diagnostics */

#if (ODBCVER >= 0x0300)
enum enumDiagRowNumber {
    SQL_ROW_NUMBER_UNKNOWN	= -2,
    SQL_NO_ROW_NUMBER
};

enum enumDiagColumnNumber {
    SQL_COLUMN_NUMBER_UNKNOWN	= -2,
    SQL_NO_COLUMN_NUMBER
};

enum enumSQLDiagField {
    SQL_DIAG_CURSOR_ROW_COUNT	= -1249,
    SQL_DIAG_ROW_NUMBER,
    SQL_DIAG_COLUMN_NUMBER,
    SQL_DIAG_RETURNCODE		= 1,
    SQL_DIAG_NUMBER,
    SQL_DIAG_ROW_COUNT,
    SQL_DIAG_SQLSTATE,
    SQL_DIAG_NATIVE,
    SQL_DIAG_MESSAGE_TEXT,
    SQL_DIAG_DYNAMIC_FUNCTION,
    SQL_DIAG_CLASS_ORIGIN,
    SQL_DIAG_SUBCLASS_ORIGIN,
    SQL_DIAG_CONNECTION_NAME,
    SQL_DIAG_SERVER_NAME,
    SQL_DIAG_DYNAMIC_FUNCTION_CODE
};

enum enumDynamicFunction {
    SQL_DIAG_ALTER_DOMAIN		= 3,
    SQL_DIAG_ALTER_TABLE		= 4,
    SQL_DIAG_CALL			= 7,
	SQL_DIAG_CREATE_ASSERTION	= 6,
	SQL_DIAG_CREATE_CHARACTER_SET = 8,
	SQL_DIAG_CREATE_COLLATION	= 10,
	SQL_DIAG_CREATE_DOMAIN		= 23,
    SQL_DIAG_CREATE_INDEX		= -1,
	SQL_DIAG_CREATE_SCHEMA		= 64,
    SQL_DIAG_CREATE_TABLE		= 77,
	SQL_DIAG_CREATE_TRANSLATION	= 79,
    SQL_DIAG_CREATE_VIEW		= 84,
    SQL_DIAG_DELETE_WHERE		= 19,
	SQL_DIAG_DROP_ASSERTION		= 24,
	SQL_DIAG_DROP_CHARACTER_SET	= 25,
	SQL_DIAG_DROP_COLLATION		= 26,
	SQL_DIAG_DROP_DOMAIN		= 27,
    SQL_DIAG_DROP_INDEX			= -2,
	SQL_DIAG_DROP_SCHEMA		= 31,
    SQL_DIAG_DROP_TABLE			= 32,
	SQL_DIAG_DROP_TRANSLATION   = 33,
    SQL_DIAG_DROP_VIEW			= 36,
    SQL_DIAG_DYNAMIC_DELETE_CURSOR	= 38,
    SQL_DIAG_DYNAMIC_UPDATE_CURSOR	= 81,
    SQL_DIAG_GRANT			= 48,
    SQL_DIAG_INSERT			= 50,
    SQL_DIAG_REVOKE			= 59,
    SQL_DIAG_SELECT_CURSOR		= 85,
    SQL_DIAG_UNKNOWN_STATEMENT		= 0,
    SQL_DIAG_UPDATE_WHERE		= 82
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLGetDiagField(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle,
    SQLSMALLINT			RecNumber,
    SQLSMALLINT			DiagIdentifier,
    SQLPOINTER			DiagInfo,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength );

SQLRETURN ODBC_API SQLGetDiagRec(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle,
    SQLSMALLINT			RecNumber,
    SQLCHAR ODBCFAR *		Sqlstate,
    SQLINTEGER ODBCFAR *	NativeError,
    SQLCHAR ODBCFAR *		MessageText,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	TextLength );
#endif // UL_ODBC

#endif /* ODBCVER >= 0x0300 */

/* API functions -- statements */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLAllocStmt(	/* CORE */
    SQLHDBC		ConnectionHandle,
    SQLHSTMT ODBCFAR *	StatementHandle );

SQLRETURN ODBC_API SQLCancel(		/* CORE */
    SQLHSTMT		hstmt );

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLCloseCursor(
    SQLHSTMT		StatementHandle );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLExecDirect(	/* CORE */
    SQLHSTMT		StatementHandle,
    SQLCHAR ODBCFAR *	StatementText,
    SQLINTEGER		TextLength );

SQLRETURN ODBC_API SQLPrepare(		/* CORE */
    SQLHSTMT		StatementHandle,
    SQLCHAR ODBCFAR *	StatementText,
    SQLINTEGER		TextLength );

SQLRETURN ODBC_API SQLExecute(		/* CORE */
    SQLHSTMT		StatementHandle );

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLGetStmtAttr(
    SQLHSTMT			StatementHandle,
    SQLINTEGER			Attribute,
    SQLPOINTER			Value,
    SQLINTEGER			BufferLength,
    SQLINTEGER ODBCFAR *	StringLength );

SQLRETURN ODBC_API SQLSetStmtAttr(
    SQLHSTMT			StatementHandle,
    SQLINTEGER			Attribute,
    SQLPOINTER			Value,
    SQLINTEGER			StringLength );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLGetStmtOption(	/* Level 1 */
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		Option,	/* enumSQLOption */
    SQLPOINTER			Value );

SQLRETURN ODBC_API SQLSetStmtOption(	/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLUSMALLINT	Option,		/* enumSQLOption */
    SQLULEN		Value );
#endif // UL_ODBC

enum enumSQLFreeStmt {
    SQL_CLOSE,
    SQL_DROP,
    SQL_UNBIND,
    SQL_RESET_PARAMS
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLFreeStmt(		/* CORE */
    SQLHSTMT		StatementHandle,
    SQLUSMALLINT	Option );	/* enumSQLFreeStmt */
#endif // UL_ODBC

#if (ODBCVER >= 0x0300)
enum enumSQLStmtAttr {
    SQL_ATTR_APP_ROW_DESC	= 10010,
    SQL_ATTR_APP_PARAM_DESC,
    SQL_ATTR_IMP_ROW_DESC,
    SQL_ATTR_IMP_PARAM_DESC
};

/* SQL_ATTR_CURSOR_SCROLLABLE values */
enum enumSQLAttrCursor {
    SQL_NONSCROLLABLE,
    SQL_SCROLLABLE
};

enum enumCursorSensitivity {
    SQL_UNSPECIFIED,
    SQL_INSENSITIVE,
    SQL_SENSITIVE
};
#endif /* ODBCVER >= 0x0300 */

/* Result related functions */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLBindCol(			/* CORE */
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,	/* 1..n */
    SQLSMALLINT			TargetType,	/* SQL_C_... */
    SQLPOINTER			TargetValue,
    SQLLEN			BufferLength,
    SQLLEN ODBCFAR *		StrLen_or_Ind );
#endif // UL_ODBC

enum enumSQLColAttrType {	/* SQLColAttributes FieldIdentifier values */
    SQL_COLUMN_COUNT,
    SQL_COLUMN_NAME,
    SQL_COLUMN_TYPE,
    SQL_COLUMN_LENGTH,
    SQL_COLUMN_PRECISION,
    SQL_COLUMN_SCALE,
    SQL_COLUMN_DISPLAY_SIZE,
    SQL_COLUMN_NULLABLE,	/* returns enumSQLNullable */
    SQL_COLUMN_UNSIGNED,
    SQL_COLUMN_MONEY,
    SQL_COLUMN_UPDATABLE,	/* returns enumSQLUpdatable */
    SQL_COLUMN_AUTO_INCREMENT,
    SQL_COLUMN_CASE_SENSITIVE,
    SQL_COLUMN_SEARCHABLE,	/* returns enumSQLSearchable */
    SQL_COLUMN_TYPE_NAME
    #if (ODBCVER >= 0x0200)
    ,
    SQL_COLUMN_TABLE_NAME,
    SQL_COLUMN_OWNER_NAME,
    SQL_COLUMN_QUALIFIER_NAME,
    SQL_COLUMN_LABEL
    #endif /* ODBCVER >= 0x0200 */
};

#define SQL_COLATT_OPT_MAX		SQL_COLUMN_LABEL
#define SQL_COLATT_OPT_MIN		SQL_COLUMN_COUNT
#define SQL_COLUMN_DRIVER_START		1000

enum enumSQLNullable {		/* Output from SQLColAttributes,
				   SQLDescribeCol and SQLSpecialColumns */
    SQL_NO_NULLS,
    SQL_NULLABLE,
    SQL_NULLABLE_UNKNOWN
};

enum enumSQLUpdatable {		/* Output from SQLColAttributes */
    SQL_ATTR_READONLY,
    SQL_ATTR_WRITE,
    SQL_ATTR_READWRITE_UNKNOWN
};

enum enumSQLSearchable {	/* Output from SQLColAttributes */
    SQL_UNSEARCHABLE,
    SQL_LIKE_ONLY,
    SQL_ALL_EXCEPT_LIKE,
    SQL_SEARCHABLE
};
#define SQL_PRED_SEARCHABLE	SQL_SEARCHABLE

#ifndef UL_ODBC
#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLColAttribute(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,
    SQLUSMALLINT		FieldIdentifier,
    SQLPOINTER			CharacterAttribute,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength,
    SQLLEN ODBCFAR *		NumericAttribute );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLColAttributes(		/* CORE */
    SQLHSTMT			hstmt,
    SQLUSMALLINT		icol,		/* 1..n */
    SQLUSMALLINT		fDescType,	/* enumSQLColAttrType */
    SQLPOINTER			rgbDesc,
    SQLSMALLINT			cbDescMax,
    SQLSMALLINT ODBCFAR *	pcbDesc,
    SQLLEN ODBCFAR *		pfDesc );

SQLRETURN ODBC_API SQLDescribeCol(		/* CORE */
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,	/* 1..n */
    SQLCHAR ODBCFAR *		ColumnName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	NameLength,
    SQLSMALLINT ODBCFAR *	DataType,	/* enumSQLTYPE */
    SQLULEN ODBCFAR *		ColumnSize,
    SQLSMALLINT ODBCFAR *	DecimalDigits,
    SQLSMALLINT ODBCFAR *	Nullable );	/* enumSQLNullable */

SQLRETURN ODBC_API SQLFetch(		/* CORE */
    SQLHSTMT		StatementHandle );
#endif // UL_ODBC

enum enumSQLFetchType {
    SQL_FETCH_NEXT		= 1,
    SQL_FETCH_FIRST,
    SQL_FETCH_LAST,
    SQL_FETCH_PRIOR,
    SQL_FETCH_ABSOLUTE,
    SQL_FETCH_RELATIVE
    /* SQL_FETCH_RESUME		not supported by 2.0+ drivers */
    #if (ODBCVER >= 0x0200)
    ,
    SQL_FETCH_BOOKMARK		= 8
    #if (ODBCVER >= 0x0300)
    ,
    SQL_FETCH_FIRST_USER	= 31,
    SQL_FETCH_FIRST_SYSTEM
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */
};

#define SQL_FETCH_PREV		SQL_FETCH_PRIOR

enum enumSQLRowStatus {
    #if (ODBCVER >= 0x0300)
    SQL_ROW_PROCEED	= 0,
    SQL_ROW_IGNORE,
    #endif /* ODBCVER >= 0x0300 */
    SQL_ROW_SUCCESS	= 0,
    SQL_ROW_DELETED,
    SQL_ROW_UPDATED,
    SQL_ROW_NOROW
    #if (ODBCVER >= 0x0200)
    ,
    SQL_ROW_ADDED,
    SQL_ROW_ERROR
    #if (ODBCVER >= 0x0300)
    ,
    SQL_ROW_SUCCESS_WITH_INFO
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */
};

#ifndef UL_ODBC
#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLFetchScroll(
    SQLHSTMT		StatementHandle,
    SQLSMALLINT		FetchOrientation,
    SQLLEN		FetchOffset );
#endif /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLExtendedFetch(		/* Level 2 */
    SQLHSTMT			hstmt,
    SQLUSMALLINT		fFetchType,	/* enumSQLFetchType */
    SQLLEN			irow,
    SQLULEN ODBCFAR *		pcrow,		/* number of rows actually fetched */
    SQLUSMALLINT ODBCFAR *	rgfRowStatus );	/* array of enumSQLRowStatus */

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLBulkOperations(
    SQLHSTMT		StatementHandle,
    SQLSMALLINT		Operation );
#endif /* ODBCVER >= 0x0300 */
#endif // UL_ODBC

enum enumSetPosOps {
    SQL_POSITION,
    SQL_REFRESH
    #if (ODBCVER >= 0x0200)
    ,
    SQL_UPDATE,
    SQL_DELETE,
    SQL_ADD
    #if (ODBCVER >= 0x0300)
    ,
    SQL_UPDATE_BY_BOOKMARK,
    SQL_DELETE_BY_BOOKMARK,
    SQL_FETCH_BY_BOOKMARK
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0200 */
};
#define SQL_SETPOS_MAX_OPTION_VALUE	SQL_ADD

enum enumSetPosLocks {
    SQL_LOCK_NO_CHANGE,
    SQL_LOCK_EXCLUSIVE
    #if (ODBCVER >= 0x0200)
    ,
    SQL_LOCK_UNLOCK
    #endif /* ODBCVER >= 0x0200 */
};
#define SQL_SETPOS_MAX_LOCK_VALUE	SQL_LOCK_UNLOCK

#define SQL_ENTIRE_ROWSET	0
#if (ODBCVER >= 0x0200)
    #define SQL_POSITION_TO(hstmt,irow) \
    		SQLSetPos(hstmt,irow,SQL_POSITION,SQL_LOCK_NO_CHANGE)
    #define SQL_LOCK_RECORD(hstmt,irow,fLock) \
    		SQLSetPos(hstmt,irow,SQL_POSITION,fLock)
    #define SQL_REFRESH_RECORD(hstmt,irow,fLock) \
    		SQLSetPos(hstmt,irow,SQL_REFRESH,fLock)
    #define SQL_UPDATE_RECORD(hstmt,irow) \
    		SQLSetPos(hstmt,irow,SQL_UPDATE,SQL_LOCK_NO_CHANGE)
    #define SQL_DELETE_RECORD(hstmt,irow) \
    		SQLSetPos(hstmt,irow,SQL_DELETE,SQL_LOCK_NO_CHANGE)
    #define SQL_ADD_RECORD(hstmt,irow) \
    		SQLSetPos(hstmt,irow,SQL_ADD,SQL_LOCK_NO_CHANGE)
    #define SQL_ODBC_KEYWORDS \
"ABSOLUTE,ACTION,ADA,ADD,ALL,ALLOCATE,ALTER,AND,ANY,ARE,AS,"\
"ASC,ASSERTION,AT,AUTHORIZATION,AVG,"\
"BEGIN,BETWEEN,BIT,BIT_LENGTH,BOTH,BY,CASCADE,CASCADED,CASE,CAST,CATALOG,"\
"CHAR,CHAR_LENGTH,CHARACTER,CHARACTER_LENGTH,CHECK,CLOSE,COALESCE,"\
"COLLATE,COLLATION,COLUMN,COMMIT,CONNECT,CONNECTION,CONSTRAINT,"\
"CONSTRAINTS,CONTINUE,CONVERT,CORRESPONDING,COUNT,CREATE,CROSS,CURRENT,"\
"CURRENT_DATE,CURRENT_TIME,CURRENT_TIMESTAMP,CURRENT_USER,CURSOR,"\
"DATE,DAY,DEALLOCATE,DEC,DECIMAL,DECLARE,DEFAULT,DEFERRABLE,"\
"DEFERRED,DELETE,DESC,DESCRIBE,DESCRIPTOR,DIAGNOSTICS,DISCONNECT,"\
"DISTINCT,DOMAIN,DOUBLE,DROP,"\
"ELSE,END,END-EXEC,ESCAPE,EXCEPT,EXCEPTION,EXEC,EXECUTE,"\
"EXISTS,EXTERNAL,EXTRACT,"\
"FALSE,FETCH,FIRST,FLOAT,FOR,FOREIGN,FORTRAN,FOUND,FROM,FULL,"\
"GET,GLOBAL,GO,GOTO,GRANT,GROUP,HAVING,HOUR,"\
"IDENTITY,IMMEDIATE,IN,INCLUDE,INDEX,INDICATOR,INITIALLY,INNER,"\
"INPUT,INSENSITIVE,INSERT,INT,INTEGER,INTERSECT,INTERVAL,INTO,IS,ISOLATION,"\
"JOIN,KEY,LANGUAGE,LAST,LEADING,LEFT,LEVEL,LIKE,LOCAL,LOWER,"\
"MATCH,MAX,MIN,MINUTE,MODULE,MONTH,"\
"NAMES,NATIONAL,NATURAL,NCHAR,NEXT,NO,NONE,NOT,NULL,NULLIF,NUMERIC,"\
"OCTET_LENGTH,OF,ON,ONLY,OPEN,OPTION,OR,ORDER,OUTER,OUTPUT,OVERLAPS,"\
"PAD,PARTIAL,PASCAL,PLI,POSITION,PRECISION,PREPARE,PRESERVE,"\
"PRIMARY,PRIOR,PRIVILEGES,PROCEDURE,PUBLIC,"\
"READ,REAL,REFERENCES,RELATIVE,RESTRICT,REVOKE,RIGHT,ROLLBACK,ROWS"\
"SCHEMA,SCROLL,SECOND,SECTION,SELECT,SESSION,SESSION_USER,SET,SIZE,"\
"SMALLINT,SOME,SPACE,SQL,SQLCA,SQLCODE,SQLERROR,SQLSTATE,SQLWARNING,"\
"SUBSTRING,SUM,SYSTEM_USER,"\
"TABLE,TEMPORARY,THEN,TIME,TIMESTAMP,TIMEZONE_HOUR,TIMEZONE_MINUTE,"\
"TO,TRAILING,TRANSACTION,TRANSLATE,TRANSLATION,TRIM,TRUE,"\
"UNION,UNIQUE,UNKNOWN,UPDATE,UPPER,USAGE,USER,USING,"\
"VALUE,VALUES,VARCHAR,VARYING,VIEW,WHEN,WHENEVER,WHERE,WITH,WORK,WRITE,"\
"YEAR,ZONE"
#endif /* ODBCVER >= 0x0200 */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLSetPos(		/* Level 2 */
    SQLHSTMT		hstmt,
    SQLSETPOSIROW	irow,		/* 1..n */
    SQLUSMALLINT	fRefresh,	/* TRUE or FALSE */
    SQLUSMALLINT	fLock );	/* TRUE or FALSE */
#endif // UL_ODBC

enum enumSQLConcurrency {
    SQL_CONCUR_READ_ONLY	= 1,
    SQL_CONCUR_LOCK,
    SQL_CONCUR_ROWVER,
    SQL_CONCUR_VALUES
};

#define SQL_CONCUR_TIMESTAMP	SQL_CONCUR_ROWVER

#if (ODBCVER >= 0x0200)

enum enumCursorType {
    SQL_CURSOR_FORWARD_ONLY	= 0UL,
    SQL_CURSOR_KEYSET_DRIVEN	= 1UL,
    SQL_CURSOR_DYNAMIC		= 2UL,
    SQL_CURSOR_STATIC		= 3UL
};

enum enumSimCursor {
    SQL_SC_NON_UNIQUE		= 0UL,
    SQL_SC_TRY_UNIQUE		= 1UL,
    SQL_SC_UNIQUE		= 2UL
};

enum enumRetrieveData {
    SQL_RD_OFF			= 0UL,
    SQL_RD_ON			= 1UL
};

enum enumUseBookmarks {
    SQL_UB_OFF			= 0UL,
    SQL_UB_ON			= 1UL
    #if (ODBCVER >= 0x0300)
    ,
    SQL_UB_FIXED		= 1UL,
    SQL_UB_VARIABLE		= 2UL
    #endif /* ODBCVER >= 0x0300 */
};

/* Special values for certain options  */
#define SQL_CONCUR_DEFAULT		SQL_CONCUR_READ_ONLY
#define SQL_CURSOR_TYPE_DEFAULT		SQL_CURSOR_FORWARD_ONLY
#define SQL_ROWSET_SIZE_DEFAULT		1UL
#define SQL_KEYSET_SIZE_DEFAULT		0UL
#define	SQL_RD_DEFAULT			SQL_RD_ON
#define	SQL_UB_DEFAULT			SQL_UB_OFF

#endif /* ODBCVER >= 0x0200 */

enum enumSQLKeySet {
    SQL_SCROLL_FORWARD_ONLY	= 0L,	/* SQL_CURSOR_FORWARD_ONLY */
    SQL_SCROLL_KEYSET_DRIVEN	= -1L,	/* SQL_CURSOR_KEYSET_DRIVEN */
    SQL_SCROLL_DYNAMIC		= -2L	/* SQL_CURSOR_DYNAMIC */
    #if (ODBCVER >= 0x0200)
    ,
    SQL_SCROLL_STATIC		= -3L	/* SQL_CURSOR_STATIC */
    #endif /* ODBCVER >= 0x0200 */
};

#ifndef UL_ODBC
/* Use SQLSetStmtOption */
SQLRETURN ODBC_API SQLSetScrollOptions(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLUSMALLINT	fConcurrency,	/* enumSQLConcurrency */
    SQLLEN		crowKeySet,	/* number or enumSQLKeySet */
    SQLUSMALLINT	crowRowSet );	/* number of rows */

SQLRETURN ODBC_API SQLGetCursorName(	/* CORE */
    SQLHSTMT			StatementHandle,
    SQLCHAR ODBCFAR *		CursorName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	NameLength );

SQLRETURN ODBC_API SQLGetData(			/* Level 1 */
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,	/* 1..n */
    SQLSMALLINT			TargetType,	/* SQL_C_... */
    SQLPOINTER			TargetValue,
    SQLLEN			BufferLength,
    SQLLEN ODBCFAR *		StrLen_or_Ind );

SQLRETURN ODBC_API SQLNumResultCols(	/* CORE */
    SQLHSTMT			StatementHandle,
    SQLSMALLINT ODBCFAR *	ColumnCount );

SQLRETURN ODBC_API SQLRowCount(		/* CORE */
    SQLHSTMT			StatementHandle,
    SQLLEN ODBCFAR *		RowCount );

SQLRETURN ODBC_API SQLSetCursorName(	/* CORE */
    SQLHSTMT		StatementHandle,
    SQLCHAR ODBCFAR *	CursorName,
    SQLSMALLINT		NameLength );

/* Parameters */

SQLRETURN ODBC_API SQLNumParams(		/* Level 2 */
    SQLHSTMT			hstmt,
    SQLSMALLINT ODBCFAR *	pcpar );

SQLRETURN ODBC_API SQLDescribeParam(		/* Level 2 */
    SQLHSTMT			hstmt,
    SQLUSMALLINT		ipar,		/* 1..n */
    SQLSMALLINT ODBCFAR *	pfSqlType,	/* enumSQLTYPE */
    SQLULEN ODBCFAR *		pcbColDef,
    SQLSMALLINT ODBCFAR *	pibScale,
    SQLSMALLINT ODBCFAR *	pfNullable );	/* enumSQLNullable */

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLBindParam(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ParameterNumber,
    SQLSMALLINT			ValueType,
    SQLSMALLINT			ParameterType,
    SQLULEN			LengthPrecision,
    SQLSMALLINT			ParameterScale,
    SQLPOINTER			ParameterValue,
    SQLLEN ODBCFAR *		StrLen_or_Ind );
#endif /* ODBCVER >= 0x0300 */
#endif // UL_ODBC

#if (ODBCVER >= 0x0200)
#define SQL_LEN_DATA_AT_EXEC_OFFSET	(-100)
#define SQL_LEN_DATA_AT_EXEC(length)	(-(length)+SQL_LEN_DATA_AT_EXEC_OFFSET)
#define SQL_LEN_BINARY_ATTR_OFFSET	(-100)
#define SQL_LEN_BINARY_ATTR(length)	(-(length)+SQL_LEN_BINARY_ATTR_OFFSET)

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLBindParameter(
    SQLHSTMT			hstmt,
    SQLUSMALLINT		ipar,
    SQLSMALLINT			fParamType,
    SQLSMALLINT			fCType,
    SQLSMALLINT			fSqlType,
    SQLULEN			cbColDef,
    SQLSMALLINT			ibScale,
    SQLPOINTER			rgbValue,
    SQLLEN			cbValueMax,
    SQLLEN ODBCFAR *		pcbValue );
#endif // UL_ODBC
    
#endif /* ODBCVER >= 0x0200 */

#ifndef UL_ODBC
/* Use SQLBindParameter */
SQLRETURN ODBC_API SQLSetParam(			/* CORE */
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ParameterNumber,
    SQLSMALLINT			ValueType,
    SQLSMALLINT			ParameterType,	/* enumSQLTYPE */
    SQLULEN			LengthPrecision,
    SQLSMALLINT			ParameterScale,
    SQLPOINTER			ParameterValue,
    SQLLEN ODBCFAR *		StrLen_or_Ind );

SQLRETURN ODBC_API SQLParamData(		/* Level 1 */
    SQLHSTMT			StatementHandle,
    SQLPOINTER ODBCFAR *	Value );	/* returns rgbValue from SQLSetParam */

SQLRETURN ODBC_API SQLPutData(		/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLPOINTER		Data,		/* Note: type set by SQLSetParam */
    SQLLEN		StrLen_or_Ind );

SQLRETURN ODBC_API SQLMoreResults(	/* Level 2 */
    SQLHSTMT		hstmt );

SQLRETURN ODBC_API SQLParamOptions(	/* Level 2 */
    SQLHSTMT			hstmt,
    SQLULEN			crow,
    SQLULEN ODBCFAR *		pirow );

/* Catalog information */

SQLRETURN ODBC_API SQLColumnPrivileges(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szCatalogName,
    SQLSMALLINT		cbCatalogName,
    SQLCHAR ODBCFAR *	szSchemaName,
    SQLSMALLINT		cbSchemaName,
    SQLCHAR ODBCFAR *	szTableName,
    SQLSMALLINT		cbTableName,
    SQLCHAR ODBCFAR *	szColumnName,
    SQLSMALLINT		cbColumnName );

SQLRETURN ODBC_API SQLTablePrivileges(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szCatalogName,
    SQLSMALLINT		cbCatalogName,
    SQLCHAR ODBCFAR *	szSchemaName,
    SQLSMALLINT		cbSchemaName,
    SQLCHAR ODBCFAR *	szTableName,
    SQLSMALLINT		cbTableName );

SQLRETURN ODBC_API SQLColumns(		/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLCHAR ODBCFAR *	CatalogName,
    SQLSMALLINT		NameLength1,
    SQLCHAR ODBCFAR *	SchemaName,
    SQLSMALLINT		NameLength2,
    SQLCHAR ODBCFAR *	TableName,
    SQLSMALLINT		NameLength3,
    SQLCHAR ODBCFAR *	ColumnName,
    SQLSMALLINT		NameLength4 );
#endif // UL_ODBC

enum enumSQLForeignKeyAction {	/* in SQLForeignKeys result set */
    SQL_CASCADE,
    SQL_RESTRICT,
    SQL_SET_NULL
    #if (ODBCVER >= 0x0250)
    ,
    SQL_NO_ACTION,
    SQL_SET_DEFAULT
    #if (ODBCVER >= 0x0300)
    ,
    SQL_INITIALLY_DEFERRED,
    SQL_INITIALLY_IMMEDIATE,
	SQL_NOT_DEFERRABLE
    #endif /* ODBCVER >= 0x0300 */
    #endif /* ODBCVER >= 0x0250 */
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLForeignKeys(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szPkCatalogName,
    SQLSMALLINT		cbPkCatalogName,
    SQLCHAR ODBCFAR *	szPkSchemaName,
    SQLSMALLINT		cbPkSchemaName,
    SQLCHAR ODBCFAR *	szPkTableName,
    SQLSMALLINT		cbPkTableName,
    SQLCHAR ODBCFAR *	szFkCatalogName,
    SQLSMALLINT		cbFkCatalogName,
    SQLCHAR ODBCFAR *	szFkSchemaName,
    SQLSMALLINT		cbFkSchemaName,
    SQLCHAR ODBCFAR *	szFkTableName,
    SQLSMALLINT		cbFkTableName );
#endif // UL_ODBC

#if (ODBCVER >= 0x0300)
#define	SQL_COL_PRED_CHAR	SQL_LIKE_ONLY
#define	SQL_COL_PRED_BASIC	SQL_ALL_EXCEPT_LIKE
#endif /* ODBCVER >= 0x0300 */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLGetTypeInfo(	/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLSMALLINT		DateType );	/* enumSQLTYPE or SQL_ALL_TYPES */

SQLRETURN ODBC_API SQLPrimaryKeys(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szCatalogName,
    SQLSMALLINT		cbCatalogName,
    SQLCHAR ODBCFAR *	szSchemaName,
    SQLSMALLINT		cbSchemaName,
    SQLCHAR ODBCFAR *	szTableName,
    SQLSMALLINT		cbTableName );
#endif // UL_ODBC

enum enumSQLProcColUse {	/* in SQLProcedureColumns result set */
    SQL_PARAM_TYPE_UNKNOWN,
    SQL_PARAM_INPUT,
    SQL_PARAM_INPUT_OUTPUT,
    SQL_RESULT_COL
    #if (ODBCVER >= 0x0200)
    ,
    SQL_PARAM_OUTPUT,
    SQL_RETURN_VALUE
    #endif /* ODBCVER >= 0x0200 */
};

#define SQL_PARAM_TYPE_DEFAULT 	SQL_PARAM_INPUT_OUTPUT
#define	SQL_SETPARAM_VALUE_MAX	(-1L)

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLProcedureColumns(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szCatalogName,
    SQLSMALLINT		cbCatalogName,
    SQLCHAR ODBCFAR *	szSchemaName,
    SQLSMALLINT		cbSchemaName,
    SQLCHAR ODBCFAR *	szProcName,
    SQLSMALLINT		cbProcName,
    SQLCHAR ODBCFAR *	szColumnName,
    SQLSMALLINT		cbColumnName );

SQLRETURN ODBC_API SQLProcedures(	/* Level 2 */
    SQLHSTMT		hstmt,
    SQLCHAR ODBCFAR *	szCatalogName,
    SQLSMALLINT		cbCatalogName,
    SQLCHAR ODBCFAR *	szSchemaName,
    SQLSMALLINT		cbSchemaName,
    SQLCHAR ODBCFAR *	szProcName,
    SQLSMALLINT		cbProcName );
#endif // UL_ODBC

enum enumSQLSpecialType {
    SQL_BEST_ROWID	= 1,
    #if (ODBCVER >= 0x0300)
    SQL_ROW_IDENTIFIER	= 1,		/* Reserved value */
    #endif /* ODBCVER >= 0x0300 */
    SQL_ROWVER
};

enum enumSQLScope {
    SQL_SCOPE_CURROW,
    SQL_SCOPE_TRANSACTION,
    SQL_SCOPE_SESSION
};

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLSpecialColumns(	/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLUSMALLINT	IdentifierType,	/* enumSQLSpecialType */
    SQLCHAR *		CatalogName,
    SQLSMALLINT		NameLength1,
    SQLCHAR *		SchemaName,
    SQLSMALLINT		NameLength2,
    SQLCHAR *		TableName,
    SQLSMALLINT		NameLength3,
    SQLUSMALLINT	Scope,		/* enumSQLScope */
    SQLUSMALLINT	Nullable );	/* enumSQLNullable */
#endif // UL_ODBC

enum enumSQLUnique {
    SQL_INDEX_UNIQUE,
    SQL_INDEX_ALL
};

enum enumSQLAccuracy {
    SQL_QUICK,
    SQL_ENSURE
};

enum enumSQLTableStat {
    SQL_TABLE_STAT,
    SQL_INDEX_CLUSTERED,
    SQL_INDEX_HASHED,
    SQL_INDEX_OTHER
};

#if (ODBCVER >= 0x0200)
enum enumProcType {
    SQL_PT_UNKNOWN,
    SQL_PT_PROCEDURE,
    SQL_PT_FUNCTION
};

enum enumPseudoCol {
    SQL_PC_UNKNOWN,
    SQL_PC_NOT_PSEUDO,
    #if (ODBCVER >= 0x0300)
    SQL_PC_NON_PSEUDO	= 1,
    #endif /* ODBCVER >= 0x0300 */
    SQL_PC_PSEUDO
};

#define SQL_PC_NON_PSEUDO	SQL_PC_NOT_PSEUDO

#if (ODBCVER >= 0x0300)
#define SQL_ALL_CATALOGS	"%"
#define SQL_ALL_SCHEMAS		"%"
#define SQL_ALL_TABLE_TYPES	"%"
#endif /* ODBCVER >= 0x0300 */

#endif /* ODBCVER >= 0x0200 */

#ifndef UL_ODBC
SQLRETURN ODBC_API SQLStatistics(	/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLCHAR *		CatalogName,
    SQLSMALLINT		NameLength1,
    SQLCHAR *		SchemaName,
    SQLSMALLINT		NameLength2,
    SQLCHAR *		TableName,
    SQLSMALLINT		NameLength3,
    SQLUSMALLINT	Unique,		/* enumSQLUnique */
    SQLUSMALLINT	Reserved );	/* enumSQLAccuracy */

SQLRETURN ODBC_API SQLTables(		/* Level 1 */
    SQLHSTMT		StatementHandle,
    SQLCHAR *		CatalogName,
    SQLSMALLINT		NameLength1,
    SQLCHAR *		SchemaName,
    SQLSMALLINT		NameLength2,
    SQLCHAR *		TableName,
    SQLSMALLINT		NameLength3,
    SQLCHAR *		TableType,	/* string 'TABLE', 'VIEW' */
    SQLSMALLINT		NameLength4 );


//
//
// Unicode function prototypes
//
//


SQLRETURN ODBC_API SQLColAttributeW(
	SQLHSTMT		hstmt,
	SQLUSMALLINT		iCol,
	SQLUSMALLINT		iField,
	SQLPOINTER		pCharAttr,
	SQLSMALLINT		cbCharAttrMax,	
	SQLSMALLINT *		pcbCharAttr,
	SQLLEN *		pNumAttr );

SQLRETURN ODBC_API SQLColAttributesW(
    	SQLHSTMT           	hstmt,
    	SQLUSMALLINT       	icol,
    	SQLUSMALLINT       	fDescType,
    	SQLPOINTER         	rgbDesc,
    	SQLSMALLINT        	cbDescMax,
    	SQLSMALLINT *		pcbDesc,
    	SQLLEN * 		pfDesc );

SQLRETURN ODBC_API SQLConnectW(
    	SQLHDBC            	hdbc,
    	SQLWCHAR *		szDSN,
    	SQLSMALLINT        	cbDSN,
    	SQLWCHAR *		szUID,
    	SQLSMALLINT        	cbUID,
    	SQLWCHAR *		szAuthStr,
    	SQLSMALLINT        	cbAuthStr );


SQLRETURN ODBC_API SQLDescribeColW(
    	SQLHSTMT           	hstmt,
    	SQLUSMALLINT       	icol,
    	SQLWCHAR *		szColName,
    	SQLSMALLINT        	cbColNameMax,
    	SQLSMALLINT *		pcbColName,
    	SQLSMALLINT *		pfSqlType,
    	SQLULEN *		pcbColDef,
    	SQLSMALLINT *		pibScale,
    	SQLSMALLINT *		pfNullable );


SQLRETURN ODBC_API SQLErrorW(
    	SQLHENV            	henv,
    	SQLHDBC            	hdbc,
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szSqlState,
    	SQLINTEGER *		pfNativeError,
    	SQLWCHAR *		szErrorMsg,
    	SQLSMALLINT		cbErrorMsgMax,
    	SQLSMALLINT *		pcbErrorMsg );

SQLRETURN ODBC_API SQLExecDirectW(
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szSqlStr,
    	SQLINTEGER         	cbSqlStr );

SQLRETURN ODBC_API SQLGetConnectAttrW(
    	SQLHDBC            	hdbc,
    	SQLINTEGER         	fAttribute,
    	SQLPOINTER         	rgbValue,
    	SQLINTEGER         	cbValueMax,
    	SQLINTEGER *		pcbValue );

SQLRETURN ODBC_API SQLGetCursorNameW(
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szCursor,
    	SQLSMALLINT        	cbCursorMax,
    	SQLSMALLINT *		pcbCursor );

#if (ODBCVER >= 0x0300)
SQLRETURN  ODBC_API SQLSetDescFieldW(
	SQLHDESC 		DescriptorHandle,
        SQLSMALLINT 		RecNumber,
	SQLSMALLINT 		FieldIdentifier,
        SQLPOINTER 		Value,
	SQLINTEGER 		BufferLength );

SQLRETURN ODBC_API SQLGetDescFieldW(
    	SQLHDESC           	hdesc,
    	SQLSMALLINT        	iRecord,
    	SQLSMALLINT        	iField,
    	SQLPOINTER         	rgbValue,
    	SQLINTEGER		cbValueMax,
    	SQLINTEGER *		pcbValue );

SQLRETURN ODBC_API SQLGetDescRecW(
    	SQLHDESC           	hdesc,
    	SQLSMALLINT        	iRecord,
    	SQLWCHAR *		szName,
    	SQLSMALLINT        	cbNameMax,
    	SQLSMALLINT *		pcbName,
    	SQLSMALLINT *		pfType,
    	SQLSMALLINT *		pfSubType,
    	SQLLEN  *		pLength,
    	SQLSMALLINT *		pPrecision,
    	SQLSMALLINT *		pScale,
    	SQLSMALLINT *		pNullable );

SQLRETURN ODBC_API SQLGetDiagFieldW(
    	SQLSMALLINT        	fHandleType,
    	SQLHANDLE          	handle,
    	SQLSMALLINT        	iRecord,
    	SQLSMALLINT        	fDiagField,
    	SQLPOINTER         	rgbDiagInfo,
    	SQLSMALLINT        	cbDiagInfoMax,
    	SQLSMALLINT *		pcbDiagInfo );

SQLRETURN ODBC_API SQLGetDiagRecW(
    	SQLSMALLINT        	fHandleType,
    	SQLHANDLE          	handle,
    	SQLSMALLINT        	iRecord,
    	SQLWCHAR *		szSqlState,
    	SQLINTEGER *		pfNativeError,
    	SQLWCHAR *		szErrorMsg,
    	SQLSMALLINT        	cbErrorMsgMax,
    	SQLSMALLINT *		pcbErrorMsg );

#endif  /* ODBCVER >= 0x0300 */

SQLRETURN ODBC_API SQLPrepareW(
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szSqlStr,
    	SQLINTEGER         	cbSqlStr );

SQLRETURN ODBC_API SQLSetConnectAttrW(
    	SQLHDBC            	hdbc,
    	SQLINTEGER         	fAttribute,
    	SQLPOINTER         	rgbValue,
    	SQLINTEGER         	cbValue );

SQLRETURN ODBC_API SQLSetCursorNameW(
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szCursor,
    	SQLSMALLINT        	cbCursor );

SQLRETURN ODBC_API SQLColumnsW(
    	SQLHSTMT           	hstmt,
    	SQLWCHAR *		szCatalogName,
    	SQLSMALLINT        	cbCatalogName,
    	SQLWCHAR *		szSchemaName,
    	SQLSMALLINT        	cbSchemaName,
    	SQLWCHAR *		szTableName,
    	SQLSMALLINT        	cbTableName,
    	SQLWCHAR *		szColumnName,
    	SQLSMALLINT        	cbColumnName );

SQLRETURN ODBC_API SQLGetConnectOptionW(
    	SQLHDBC            	hdbc,
    	SQLUSMALLINT       	fOption,
    	SQLPOINTER         	pvParam );

SQLRETURN ODBC_API SQLGetInfoW(
    	SQLHDBC            	hdbc,
    	SQLUSMALLINT       	fInfoType,
    	SQLPOINTER         	rgbInfoValue,
    	SQLSMALLINT        	cbInfoValueMax,
    	SQLSMALLINT *		pcbInfoValue );

SQLRETURN ODBC_API	SQLGetTypeInfoW(
	SQLHSTMT		StatementHandle,
	SQLSMALLINT		DataType );


SQLRETURN ODBC_API SQLSetConnectOptionW(
    	SQLHDBC            	hdbc,
    	SQLUSMALLINT       	fOption,
    	SQLULEN	        	vParam );


SQLRETURN ODBC_API SQLSpecialColumnsW(
	SQLHSTMT           	hstmt,
	SQLUSMALLINT       	fColType,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName,
	SQLUSMALLINT       	fScope,
	SQLUSMALLINT       	fNullable );

SQLRETURN ODBC_API SQLStatisticsW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName,
	SQLUSMALLINT       	fUnique,
	SQLUSMALLINT       	fAccuracy );

SQLRETURN ODBC_API SQLTablesW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName,
	SQLWCHAR *		szTableType,
	SQLSMALLINT        	cbTableType );
    
SQLRETURN ODBC_API SQLDataSourcesW(
	SQLHENV            	henv,
	SQLUSMALLINT       	fDirection,
	SQLWCHAR *		szDSN,
	SQLSMALLINT        	cbDSNMax,
	SQLSMALLINT *		pcbDSN,
	SQLWCHAR *		szDescription,
	SQLSMALLINT        	cbDescriptionMax,
	SQLSMALLINT *		pcbDescription );

SQLRETURN ODBC_API SQLDriverConnectW(
	SQLHDBC            	hdbc,
	SQLHWND            	hwnd,
	SQLWCHAR *		szConnStrIn,
	SQLSMALLINT        	cbConnStrIn,
	SQLWCHAR *		szConnStrOut,
	SQLSMALLINT        	cbConnStrOutMax,
	SQLSMALLINT *		pcbConnStrOut,
	SQLUSMALLINT       	fDriverCompletion );

SQLRETURN ODBC_API SQLBrowseConnectW(
	SQLHDBC            	hdbc,
	SQLWCHAR *		szConnStrIn,
	SQLSMALLINT        	cbConnStrIn,
	SQLWCHAR *		szConnStrOut,
	SQLSMALLINT        	cbConnStrOutMax,
	SQLSMALLINT *		pcbConnStrOut );

SQLRETURN ODBC_API SQLColumnPrivilegesW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName,
	SQLWCHAR *		szColumnName,
	SQLSMALLINT        	cbColumnName );

SQLRETURN ODBC_API SQLGetStmtAttrW(
	SQLHSTMT           	hstmt,
	SQLINTEGER         	fAttribute,
	SQLPOINTER         	rgbValue,
	SQLINTEGER         	cbValueMax,
	SQLINTEGER *		pcbValue );

SQLRETURN ODBC_API SQLSetStmtAttrW(
	SQLHSTMT           	hstmt,
	SQLINTEGER         	fAttribute,
	SQLPOINTER         	rgbValue,
	SQLINTEGER         	cbValueMax );

SQLRETURN ODBC_API SQLForeignKeysW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szPkCatalogName,
	SQLSMALLINT        	cbPkCatalogName,
	SQLWCHAR *		szPkSchemaName,
	SQLSMALLINT        	cbPkSchemaName,
	SQLWCHAR *		szPkTableName,
	SQLSMALLINT        	cbPkTableName,
	SQLWCHAR *		szFkCatalogName,
	SQLSMALLINT        	cbFkCatalogName,
	SQLWCHAR *		szFkSchemaName,
	SQLSMALLINT        	cbFkSchemaName,
	SQLWCHAR *		szFkTableName,
	SQLSMALLINT        	cbFkTableName );

SQLRETURN ODBC_API SQLNativeSqlW(
	SQLHDBC            	hdbc,
	SQLWCHAR *		szSqlStrIn,
	SQLINTEGER         	cbSqlStrIn,
	SQLWCHAR *		szSqlStr,
	SQLINTEGER         	cbSqlStrMax,
	SQLINTEGER *		pcbSqlStr );

SQLRETURN ODBC_API SQLPrimaryKeysW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName );

SQLRETURN ODBC_API SQLProcedureColumnsW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szProcName,
	SQLSMALLINT        	cbProcName,
	SQLWCHAR *		szColumnName,
	SQLSMALLINT        	cbColumnName );

SQLRETURN ODBC_API SQLProceduresW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szProcName,
	SQLSMALLINT        	cbProcName );

SQLRETURN ODBC_API SQLTablePrivilegesW(
	SQLHSTMT           	hstmt,
	SQLWCHAR *		szCatalogName,
	SQLSMALLINT        	cbCatalogName,
	SQLWCHAR *		szSchemaName,
	SQLSMALLINT        	cbSchemaName,
	SQLWCHAR *		szTableName,
	SQLSMALLINT        	cbTableName );
    
SQLRETURN ODBC_API SQLDriversW(
	SQLHENV            	henv,
	SQLUSMALLINT       	fDirection,
	SQLWCHAR *		szDriverDesc,
	SQLSMALLINT        	cbDriverDescMax,
	SQLSMALLINT *		pcbDriverDesc,
	SQLWCHAR *		szDriverAttributes,
	SQLSMALLINT        	cbDrvrAttrMax,
	SQLSMALLINT *		pcbDrvrAttr );


// ANSI versions

SQLRETURN ODBC_API SQLColAttributeA(
	SQLHSTMT		hstmt,
	SQLSMALLINT		iCol,
	SQLSMALLINT		iField,
	SQLPOINTER		pCharAttr,
	SQLSMALLINT		cbCharAttrMax,	
	SQLSMALLINT  *		pcbCharAttr,
	SQLLEN *		pNumAttr);

SQLRETURN ODBC_API SQLColAttributesA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       icol,
    SQLUSMALLINT       fDescType,
    SQLPOINTER         rgbDesc,
    SQLSMALLINT        cbDescMax,
    SQLSMALLINT        *pcbDesc,
    SQLLEN     	       *pfDesc);

SQLRETURN ODBC_API SQLConnectA(
    SQLHDBC            hdbc,
    SQLCHAR         *szDSN,
    SQLSMALLINT        cbDSN,
    SQLCHAR         *szUID,
    SQLSMALLINT        cbUID,
    SQLCHAR         *szAuthStr,
    SQLSMALLINT        cbAuthStr);


SQLRETURN ODBC_API SQLDescribeColA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       icol,
    SQLCHAR         *szColName,
    SQLSMALLINT        cbColNameMax,
    SQLSMALLINT    *pcbColName,
    SQLSMALLINT    *pfSqlType,
    SQLULEN    	   *pcbColDef,
    SQLSMALLINT    *pibScale,
    SQLSMALLINT    *pfNullable);


SQLRETURN ODBC_API SQLErrorA(
    SQLHENV            henv,
    SQLHDBC            hdbc,
    SQLHSTMT           hstmt,
    SQLCHAR        *szSqlState,
    SQLINTEGER     *pfNativeError,
    SQLCHAR        *szErrorMsg,
    SQLSMALLINT        cbErrorMsgMax,
    SQLSMALLINT    *pcbErrorMsg);

SQLRETURN ODBC_API SQLExecDirectA(
    SQLHSTMT           hstmt,
    SQLCHAR           *szSqlStr,
    SQLINTEGER         cbSqlStr);

SQLRETURN ODBC_API SQLGetConnectAttrA(
    SQLHDBC            hdbc,
    SQLINTEGER         fAttribute,
    SQLPOINTER         rgbValue,
    SQLINTEGER         cbValueMax,
    SQLINTEGER     *pcbValue);

SQLRETURN ODBC_API SQLGetCursorNameA(
    SQLHSTMT           hstmt,
    SQLCHAR        	*szCursor,
    SQLSMALLINT        cbCursorMax,
    SQLSMALLINT    *pcbCursor);

#if (ODBCVER >= 0x0300)
SQLRETURN ODBC_API SQLGetDescFieldA(
    SQLHDESC           hdesc,
    SQLSMALLINT        iRecord,
    SQLSMALLINT        iField,
    SQLPOINTER         rgbValue,
    SQLINTEGER		   cbValueMax,
    SQLINTEGER     *pcbValue);

SQLRETURN ODBC_API SQLGetDescRecA(
    SQLHDESC           hdesc,
    SQLSMALLINT        iRecord,
    SQLCHAR        *szName,
    SQLSMALLINT        cbNameMax,
    SQLSMALLINT    *pcbName,
    SQLSMALLINT    *pfType,
    SQLSMALLINT    *pfSubType,
    SQLLEN         *pLength,
    SQLSMALLINT    *pPrecision, 
    SQLSMALLINT    *pScale,
    SQLSMALLINT    *pNullable);

SQLRETURN ODBC_API SQLGetDiagFieldA(
    SQLSMALLINT        fHandleType,
    SQLHANDLE          handle,
    SQLSMALLINT        iRecord,
    SQLSMALLINT        fDiagField,
    SQLPOINTER         rgbDiagInfo,
    SQLSMALLINT        cbDiagInfoMax,
    SQLSMALLINT    *pcbDiagInfo);

SQLRETURN ODBC_API SQLGetDiagRecA(
    SQLSMALLINT        fHandleType,
    SQLHANDLE          handle,
    SQLSMALLINT        iRecord,
    SQLCHAR        *szSqlState,
    SQLINTEGER     *pfNativeError,
    SQLCHAR        *szErrorMsg,
    SQLSMALLINT        cbErrorMsgMax,
    SQLSMALLINT    *pcbErrorMsg);


SQLRETURN ODBC_API SQLGetStmtAttrA(
    SQLHSTMT           hstmt,
    SQLINTEGER         fAttribute,
    SQLPOINTER         rgbValue,
    SQLINTEGER         cbValueMax,
    SQLINTEGER     *pcbValue);

#endif

SQLRETURN ODBC_API	SQLGetTypeInfoA(
	SQLHSTMT			StatementHandle,
	SQLSMALLINT			DataType);

SQLRETURN ODBC_API SQLPrepareA(
    SQLHSTMT           hstmt,
    SQLCHAR        	*szSqlStr,
    SQLINTEGER         cbSqlStr);

SQLRETURN ODBC_API SQLSetConnectAttrA(
    SQLHDBC            hdbc,
    SQLINTEGER         fAttribute,
    SQLPOINTER         rgbValue,
    SQLINTEGER         cbValue);

SQLRETURN ODBC_API SQLSetCursorNameA(
    SQLHSTMT           hstmt,
    SQLCHAR           *szCursor,
    SQLSMALLINT        cbCursor);



    



SQLRETURN ODBC_API SQLColumnsA(
    SQLHSTMT           hstmt,
    SQLCHAR        	*szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        	*szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        	*szTableName,
    SQLSMALLINT        cbTableName,
    SQLCHAR        	*szColumnName,
    SQLSMALLINT        cbColumnName);

SQLRETURN ODBC_API SQLGetConnectOptionA(
    SQLHDBC            hdbc,
    SQLUSMALLINT       fOption,
    SQLPOINTER         pvParam);



SQLRETURN ODBC_API SQLGetInfoA(
    SQLHDBC            hdbc,
    SQLUSMALLINT       fInfoType,
    SQLPOINTER         rgbInfoValue,
    SQLSMALLINT        cbInfoValueMax,
    SQLSMALLINT    *pcbInfoValue);

SQLRETURN ODBC_API SQLGetStmtOptionA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       fOption,
    SQLPOINTER         pvParam);

SQLRETURN ODBC_API SQLSetConnectOptionA(
    SQLHDBC            hdbc,
    SQLUSMALLINT       fOption,
    SQLULEN	       vParam);

SQLRETURN ODBC_API SQLSetStmtOptionA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       fOption,
    SQLULEN            vParam);

SQLRETURN ODBC_API SQLSpecialColumnsA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       fColType,
    SQLCHAR        	*szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        	*szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        	*szTableName,
    SQLSMALLINT        cbTableName,
    SQLUSMALLINT       fScope,
    SQLUSMALLINT       fNullable);

SQLRETURN ODBC_API SQLStatisticsA(
    SQLHSTMT           hstmt,

    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szTableName,
    SQLSMALLINT        cbTableName,
    SQLUSMALLINT       fUnique,
    SQLUSMALLINT       fAccuracy);

SQLRETURN ODBC_API SQLTablesA(
    SQLHSTMT           hstmt,

    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szTableName,
    SQLSMALLINT        cbTableName,
    SQLCHAR        *szTableType,

    SQLSMALLINT        cbTableType);



SQLRETURN ODBC_API SQLDataSourcesA(
    SQLHENV            henv,
    SQLUSMALLINT       fDirection,
    SQLCHAR        *szDSN,
    SQLSMALLINT        cbDSNMax,
    SQLSMALLINT    *pcbDSN,
    SQLCHAR        *szDescription,
    SQLSMALLINT        cbDescriptionMax,
    SQLSMALLINT    *pcbDescription);




SQLRETURN ODBC_API SQLDriverConnectA(
    SQLHDBC            hdbc,
    SQLHWND            hwnd,
    SQLCHAR        *szConnStrIn,
    SQLSMALLINT        cbConnStrIn,
    SQLCHAR        *szConnStrOut,
    SQLSMALLINT        cbConnStrOutMax,
    SQLSMALLINT    *pcbConnStrOut,
    SQLUSMALLINT       fDriverCompletion);


SQLRETURN ODBC_API SQLBrowseConnectA(
    SQLHDBC            hdbc,
    SQLCHAR        *szConnStrIn,
    SQLSMALLINT        cbConnStrIn,
    SQLCHAR        *szConnStrOut,
    SQLSMALLINT        cbConnStrOutMax,
    SQLSMALLINT    *pcbConnStrOut);

SQLRETURN ODBC_API SQLColumnPrivilegesA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szTableName,
    SQLSMALLINT        cbTableName,
    SQLCHAR        *szColumnName,
    SQLSMALLINT        cbColumnName);

SQLRETURN ODBC_API SQLDescribeParamA(
    SQLHSTMT           hstmt,
    SQLUSMALLINT       ipar,
    SQLSMALLINT    *pfSqlType,
    SQLULEN    	   *pcbParamDef,
    SQLSMALLINT    *pibScale,
    SQLSMALLINT    *pfNullable);


SQLRETURN ODBC_API SQLForeignKeysA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szPkCatalogName,
    SQLSMALLINT        cbPkCatalogName,
    SQLCHAR        *szPkSchemaName,
    SQLSMALLINT        cbPkSchemaName,
    SQLCHAR        *szPkTableName,
    SQLSMALLINT        cbPkTableName,
    SQLCHAR        *szFkCatalogName,
    SQLSMALLINT        cbFkCatalogName,
    SQLCHAR        *szFkSchemaName,
    SQLSMALLINT        cbFkSchemaName,
    SQLCHAR        *szFkTableName,
    SQLSMALLINT        cbFkTableName);


SQLRETURN ODBC_API SQLNativeSqlA(
    SQLHDBC            hdbc,
    SQLCHAR        *szSqlStrIn,
    SQLINTEGER         cbSqlStrIn,
    SQLCHAR        *szSqlStr,
    SQLINTEGER         cbSqlStrMax,
    SQLINTEGER     *pcbSqlStr);


SQLRETURN ODBC_API SQLPrimaryKeysA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szTableName,
    SQLSMALLINT        cbTableName);

SQLRETURN ODBC_API SQLProcedureColumnsA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szProcName,
    SQLSMALLINT        cbProcName,
    SQLCHAR        *szColumnName,
    SQLSMALLINT        cbColumnName);

SQLRETURN ODBC_API SQLProceduresA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szProcName,
    SQLSMALLINT        cbProcName);


SQLRETURN ODBC_API SQLTablePrivilegesA(
    SQLHSTMT           hstmt,
    SQLCHAR        *szCatalogName,
    SQLSMALLINT        cbCatalogName,
    SQLCHAR        *szSchemaName,
    SQLSMALLINT        cbSchemaName,
    SQLCHAR        *szTableName,
    SQLSMALLINT        cbTableName);

SQLRETURN ODBC_API SQLDriversA(
    SQLHENV            henv,
    SQLUSMALLINT       fDirection,
    SQLCHAR        *szDriverDesc,
    SQLSMALLINT        cbDriverDescMax,
    SQLSMALLINT    *pcbDriverDesc,
    SQLCHAR        *szDriverAttributes,
    SQLSMALLINT        cbDrvrAttrMax,
    SQLSMALLINT    *pcbDrvrAttr);
#endif // UL_ODBC


// Map functions calls to the Unicode version of the
// functions unless SQL_NOUNICODEMAP is defined.

#ifndef	SQL_NOUNICODEMAP	// define this to disable the mapping
#ifdef UNICODE

#define	SQLColAttribute		SQLColAttributeW
#define	SQLColAttributes	SQLColAttributesW
#define	SQLConnect			SQLConnectW
#define	SQLDescribeCol		SQLDescribeColW
#define	SQLError			SQLErrorW
#define	SQLExecDirect		SQLExecDirectW
#define	SQLGetConnectAttr	SQLGetConnectAttrW
#define	SQLGetCursorName	SQLGetCursorNameW
#define	SQLGetDescField		SQLGetDescFieldW
#define	SQLGetDescRec		SQLGetDescRecW
#define	SQLGetDiagField		SQLGetDiagFieldW
#define	SQLGetDiagRec		SQLGetDiagRecW
#define	SQLPrepare			SQLPrepareW
#define	SQLSetConnectAttr	SQLSetConnectAttrW
#define	SQLSetCursorName	SQLSetCursorNameW
#define	SQLSetDescField		SQLSetDescFieldW
#define SQLSetStmtAttr		SQLSetStmtAttrW
#define SQLGetStmtAttr		SQLGetStmtAttrW
#define	SQLColumns			SQLColumnsW
#define	SQLGetConnectOption	SQLGetConnectOptionW
#define	SQLGetInfo			SQLGetInfoW
#define SQLGetTypeInfo		SQLGetTypeInfoW
#define	SQLSetConnectOption	SQLSetConnectOptionW
#define	SQLSpecialColumns	SQLSpecialColumnsW
#define	SQLStatistics		SQLStatisticsW
#define	SQLTables			SQLTablesW
#define	SQLDataSources		SQLDataSourcesW
#define	SQLDriverConnect	SQLDriverConnectW
#define	SQLBrowseConnect	SQLBrowseConnectW
#define	SQLColumnPrivileges	SQLColumnPrivilegesW
#define	SQLForeignKeys		SQLForeignKeysW
#define	SQLNativeSql		SQLNativeSqlW
#define	SQLPrimaryKeys		SQLPrimaryKeysW
#define	SQLProcedureColumns	SQLProcedureColumnsW
#define	SQLProcedures		SQLProceduresW
#define	SQLTablePrivileges	SQLTablePrivilegesW
#define	SQLDrivers			SQLDriversW

#endif	/* UNICODE */
#endif	/* SQL_NOUNICODEMAP */


#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* _ODBC_H_INCLUDED */
