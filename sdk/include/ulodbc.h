// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

// Ultralite ODBC.

#ifndef _ULODBC_H_
#define _ULODBC_H_

#include "ulglobal.h"

#define ODBCVER 0x0300		// needed to get right stuff
				// if GUIDs supported, need 0x0350

#define UL_ODBC YUP		// disables API in odbc.h

#include "odbc.h"

// *******************************************************************
// Ultralite ODBC Prototypes
// *******************************************************************

#ifdef __cplusplus
extern "C" {
#endif

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLAllocHandle(
    SQLSMALLINT			HandleType,
    SQLHANDLE			InputHandle,
    SQLHANDLE *			OutputHandle );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLBindCol(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,
    SQLSMALLINT			TargetType,
    SQLPOINTER			TargetValue,
    SQLLEN			BufferLength,
    SQLLEN *			StrLen_or_Ind );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLBindParameter(
    SQLHSTMT			hstmt,
    SQLUSMALLINT		ipar,
    SQLSMALLINT			fParamType,
    SQLSMALLINT			fCType,
    SQLSMALLINT			fSqlType,
    SQLULEN			cbColDef,
    SQLSMALLINT			ibScale,
    SQLPOINTER			rgbValue,
    SQLLEN			cbValueMax,
    SQLLEN *			pcbValue );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLConnectA(
    SQLHDBC			ConnectionHandle,
    SQLCHAR *			ServerName,
    SQLSMALLINT			NameLength1,
    SQLCHAR *			UserName,
    SQLSMALLINT			NameLength2,
    SQLCHAR *			Authentication,
    SQLSMALLINT			NameLength3 );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLConnectW(
    SQLHDBC			ConnectionHandle,
    SQLWCHAR *			ServerName,
    SQLSMALLINT			NameLength1,
    SQLWCHAR *			UserName,
    SQLSMALLINT			NameLength2,
    SQLWCHAR *			Authentication,
    SQLSMALLINT			NameLength3 );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLDescribeColA(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,
    SQLCHAR *			ColumnName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		NameLength,
    SQLSMALLINT *		DataType,
    SQLULEN *			ColumnSize,
    SQLSMALLINT *		DecimalDigits,
    SQLSMALLINT *		Nullable );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLDescribeColW(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,
    SQLWCHAR *			ColumnName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		NameLength,
    SQLSMALLINT *		DataType,
    SQLULEN *			ColumnSize,
    SQLSMALLINT *		DecimalDigits,
    SQLSMALLINT *		Nullable );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLDisconnect(
    SQLHDBC			ConnectionHandle );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLEndTran(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle,
    SQLSMALLINT			CompletionType );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLExecDirectA(
    SQLHSTMT			StatementHandle,
    SQLCHAR *			StatementText,
    SQLINTEGER			TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLExecDirectW(
    SQLHSTMT			StatementHandle,
    SQLWCHAR *			StatementText,
    SQLINTEGER			TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLExecute(
    SQLHSTMT			StatementHandle );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetParam(		// deprecated, needed for dbtest
    SQLHSTMT		stmtHandle,
    SQLUSMALLINT	ipar,
    SQLSMALLINT		fCType,
    SQLSMALLINT		fSqlType,
    SQLULEN		cbColDef,
    SQLSMALLINT		ibScale,
    SQLPOINTER		rgbValue,
    SQLLEN *		pcbValue );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLExtendedFetch(	// deprecated, needed for dbtest
    SQLHSTMT			StatementHandle,
    SQLSMALLINT			FetchOrientation,
    SQLLEN			FetchOffset,
    SQLUINTEGER			*RowCountPtr,
    SQLUSMALLINT		*RowStatusArray );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLFetch(
    SQLHSTMT			StatementHandle );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLFetchScroll(
    SQLHSTMT			StatementHandle,
    SQLSMALLINT			FetchOrientation,
    SQLLEN			FetchOffset );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLFreeHandle(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetCursorNameA(
    SQLHSTMT			StatementHandle,
    SQLCHAR *			CursorName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		NameLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetCursorNameW(
    SQLHSTMT			StatementHandle,
    SQLWCHAR *			CursorName,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		NameLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetData(
    SQLHSTMT			StatementHandle,
    SQLUSMALLINT		ColumnNumber,
    SQLSMALLINT			TargetType,
    SQLPOINTER			TargetValue,
    SQLLEN			BufferLength,
    SQLLEN *			StrLen_or_Ind );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetDiagRecA(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle,
    SQLSMALLINT			RecNumber,
    SQLCHAR *			Sqlstate,
    SQLINTEGER *		NativeError,
    SQLCHAR *			MessageText,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetDiagRecW(
    SQLSMALLINT			HandleType,
    SQLHANDLE			Handle,
    SQLSMALLINT			RecNumber,
    SQLWCHAR *			Sqlstate,
    SQLINTEGER *		NativeError,
    SQLWCHAR *			MessageText,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT *		TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetInfoA(
    SQLHDBC			ConnectionHandle,
    SQLUSMALLINT		InfoType,
    SQLPOINTER			InfoValue,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLGetInfoW(
    SQLHDBC			ConnectionHandle,
    SQLUSMALLINT		InfoType,
    SQLPOINTER			InfoValue,
    SQLSMALLINT			BufferLength,
    SQLSMALLINT ODBCFAR *	StringLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLNumResultCols(
    SQLHSTMT			StatementHandle,
    SQLSMALLINT *		ColumnCount );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLPrepareA(
    SQLHSTMT			StatementHandle,
    SQLCHAR *			StatementText,
    SQLINTEGER			TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLPrepareW(
    SQLHSTMT			StatementHandle,
    SQLWCHAR *			StatementText,
    SQLINTEGER			TextLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLRowCount(
    SQLHSTMT			StatementHandle,
    SQLLEN *			RowCount );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetCursorNameA(
    SQLHSTMT			StatementHandle,
    SQLCHAR *			CursorName,
    SQLSMALLINT			NameLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetCursorNameW(
    SQLHSTMT			StatementHandle,
    SQLWCHAR *			CursorName,
    SQLSMALLINT			NameLength );

// *******************************************************************
// Ultralite ODBC Prototypes -- extensions
// *******************************************************************

//struct ul_synch_info;

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetConnectionNameA(
    SQLHSTMT			StatementHandle,
    SQLCHAR *			CursorName,
    SQLSMALLINT			NameLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetConnectionNameW(
    SQLHSTMT			StatementHandle,
    SQLWCHAR *			CursorName,
    SQLSMALLINT			NameLength );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSynchronizeA(
    SQLHDBC			ConnectionHandle,
    ul_synch_info_a *		SynchInfo );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSynchronizeW(
    SQLHDBC			ConnectionHandle,
    ul_synch_info_w2 *		SynchInfo );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLSetParam(		// deprecated, needed for dbtest
    SQLHSTMT		stmtHandle,
    SQLUSMALLINT	ipar,
    SQLSMALLINT		fCType,
    SQLSMALLINT		fSqlType,
    SQLULEN		cbColDef,
    SQLSMALLINT		ibScale,
    SQLPOINTER		rgbValue,
    SQLLEN *		pcbValue );

UL_FN_SPEC SQLRETURN UL_FN_MOD SQLExtendedFetch(	// deprecated, needed for dbtest
    SQLHSTMT			StatementHandle,
    SQLSMALLINT			FetchOrientation,
    SQLLEN			FetchOffset,
    SQLUINTEGER			*RowCountPtr,
    SQLUSMALLINT		*RowStatusArray );

#if defined( UNICODE ) && ! defined( SQL_NOUNICODEMAP )
#define SQLConnect		SQLConnectW
#define SQLDescribeCol		SQLDescribeColW
#define SQLExecDirect		SQLExecDirectW
#define SQLGetCursorName	SQLGetCursorNameW
#define SQLGetDiagRec		SQLGetDiagRecW
#define SQLGetInfo		SQLGetInfoW
#define SQLPrepare		SQLPrepareW
#define SQLSetCursorName	SQLSetCursorNameW
#define SQLSetConnectionName	SQLSetConnectionNameW
#define SQLSynchronize		SQLSynchronizeW
#else
#define SQLConnect		SQLConnectA
#define SQLDescribeCol		SQLDescribeColA
#define SQLExecDirect		SQLExecDirectA
#define SQLGetCursorName	SQLGetCursorNameA
#define SQLGetDiagRec		SQLGetDiagRecA
#define SQLGetInfo		SQLGetInfoA
#define SQLPrepare		SQLPrepareA
#define SQLSetCursorName	SQLSetCursorNameA
#define SQLSetConnectionName	SQLSetConnectionNameA
#define SQLSynchronize		SQLSynchronizeA
#endif

#ifdef __cplusplus
}
#endif

#endif // _ULODBC_H_
