// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef _SAODBC_H_INCLUDED
#define _SAODBC_H_INCLUDED
#define SAODBC_H


/*	SAODBC.H
	SQL Anywhere driver-specific connection and statement attribute values
*/


#define SA_UNUSED_OPTION			1900
#define SA_GET_SQLCA				1901	// historical
#define SA_GET_STATEMENT_HANDLE			1902
#define SA_SQL_COLUMN_ISKEY			1903
#define SA_REGISTER_MESSAGE_CALLBACK		1904
#define SA_CONVERT_TO_UNICODE			1905
#define SA_GET_MESSAGE_CALLBACK_PARM		1906
#define SA_USE_ISOLATION_ON_OPEN		1907
#define SA_SQL_DESC_ISKEY			SA_SQL_COLUMN_ISKEY
#define SA_SQL_ATTR_TXN_ISOLATION		1908
#define SA_CLIENT_API_NAME			1909
#define SA_REGISTER_VALIDATE_FILE_TRANSFER_CALLBACK	1910
#define SA_INTERNAL_TOOLID			1911
#define SA_REGISTER_MESSAGE_CALLBACK_W		1912
#define UL_FILENAME_PROPERTY			1913	    // Used in the UL ODBC driver

/* Extended SQL_TXN_ISOLATION_OPTION bitmasks */
#define SA_SQL_TXN_SNAPSHOT			0x00000020L
#define SA_SQL_TXN_STATEMENT_SNAPSHOT		0x00000040L
#define SA_SQL_TXN_READONLY_STATEMENT_SNAPSHOT	0x00000080L

/* Historical constants using ASA instead of SA */
#define ASA_UNUSED_OPTION			SA_UNUSED_OPTION
#define ASA_GET_SQLCA				SA_GET_SQLCA
#define ASA_GET_STATEMENT_HANDLE		SA_GET_STATEMENT_HANDLE
#define ASA_SQL_COLUMN_ISKEY			SA_SQL_COLUMN_ISKEY
#define ASA_REGISTER_MESSAGE_CALLBACK		SA_REGISTER_MESSAGE_CALLBACK
#define ASA_CONVERT_TO_UNICODE			SA_CONVERT_TO_UNICODE
#define ASA_GET_MESSAGE_CALLBACK_PARM		SA_GET_MESSAGE_CALLBACK_PARM
#define ASA_USE_ISOLATION_ON_OPEN		SA_USE_ISOLATION_ON_OPEN
#define ASA_SQL_DESC_ISKEY			SA_SQL_DESC_ISKEY

/* Extra Information requested by OLEDB of SQLGetInfo() */

#define SQL_OLEDB_GET_CHARSET_ID		10101
#define SQL_OLEDB_GET_CHARSET_WIDTH		10102

#endif
