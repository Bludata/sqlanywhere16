// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _SQLDT_H_INCLUDED
#define _SQLDT_H_INCLUDED
#define II_SQLDT

/**********************************/
/* host language type definitions */
/**********************************/

typedef unsigned short  a_sql_data_type;

#define DT_TYPES        0x03fe
#define DT_FLAGS        0xfc01

#define DT_NULLS_ALLOWED        0x0001

/* The following flags are used in the */
/* indicator variable on a describe */

#define DT_PROCEDURE_OUT	0x8000
#define DT_PROCEDURE_IN		0x4000
#define DT_UPDATABLE            0x2000
#define DT_DESCRIBE_INPUT       0x1000
#define DT_AUTO_INCREMENT	0x0800
#define DT_KEY_COLUMN		0x0400
#define DT_HIDDEN_COLUMN	0x0200
#define DT_HAS_USERTYPE_INFO	0x0100


#define DT_NOTYPE       0
#define DT_SMALLINT     500
#define DT_INT          496
#define DT_DECIMAL      484
#define DT_FLOAT        482
#define DT_DOUBLE       480
#define DT_DATE         384
#define DT_STRING       460
#define DT_FIXCHAR      452
#define DT_VARCHAR      448
#define DT_LONGVARCHAR  456
#define DT_TIME         388
#define DT_TIMESTAMP    392
#define DT_TIMESTAMP_STRUCT 390
#define DT_BINARY       524
#define DT_LONGBINARY   528
#define DT_VARIABLE     600
#define DT_TINYINT	604
#define DT_BIGINT	608
#define DT_UNSINT	612
#define DT_UNSSMALLINT	616
#define DT_UNSBIGINT	620
#define DT_BIT		624
#define DT_NSTRING	628
#define DT_NFIXCHAR	632
#define DT_NVARCHAR	636
#define DT_LONGNVARCHAR	640
#if defined( UNDER_UL_SQLPP )
    // two byte WCHAR string (only supported by Ultralite)
    #define DT_W2STRING	700
    // two byte WCHAR FIXCHAR (only supported by Ultralite)
    #define DT_W2FIXCHAR 702
    // streamed blob special case ( Ultralite only )  
    #define DT_STREAMED_BLOB 704
    // column default
    #define DT_DEFAULT	706
#else
    #define DT_W2STRING	DT_W2STRING_NOT_IMPLEMENTED_FOR_ASA
    #define DT_W2FIXCHAR DT_W2FIXCHAR_NOT_IMPLEMENTED_FOR_ASA
    #define DT_STREAMED_BLOB DT_STREAMED_BLOB_NOT_IMPLEMENTED_FOR_ASA
    #define DT_DEFAULT	DT_DEFAUTL_NOT_IMPLEMENTED_FOR_ASA
#endif
#if defined( UNICODE )
    #define DT_T2STRING DT_W2STRING
    #define DT_T2FIXCHAR DT_W2FIXCHAR
#else
    #define DT_T2STRING DT_STRING
    #define DT_T2FIXCHAR DT_FIXCHAR
#endif

#define DT_EXTFN_TABLE  1000
#define DT_ROWTYPE  1001
#define DT_VARRAY  1002


#endif
