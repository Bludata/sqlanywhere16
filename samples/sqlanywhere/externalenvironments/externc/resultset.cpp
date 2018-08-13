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

// Demonstrate how a result set can be returned from a C_ESQL or C_ODBC
// external environment function

#include "testsrc.h"

_VOID_ENTRY GetResultSet1( an_extfn_api *api, void *arg_handle )
/**************************************************************/
{
    // Return a result set with two columns (c1 int, c2 char(128))

    an_extfn_result_set_info	rs_info;

    // mark that there are 2 columns
    rs_info.number_of_columns = 2;

    // need to describe each column
    an_extfn_result_set_column_info *col_info =
        (an_extfn_result_set_column_info *)malloc( 2 * sizeof(an_extfn_result_set_column_info) );
    an_extfn_result_set_column_data *col_data =
        (an_extfn_result_set_column_data *)malloc( 2 * sizeof(an_extfn_result_set_column_data) );
    
    // column 1 description
    col_info[0].column_name	    = "c1";
    col_info[0].column_type	    = DT_INT;
    col_info[0].column_width	    = 0;
    col_info[0].column_index	    = 1; // column indexes are 1 based
    col_info[0].column_can_be_null  = 1; // yes

    // column 2 description
    col_info[1].column_name	    = "c2";
    col_info[1].column_type	    = DT_FIXCHAR;
    col_info[1].column_width	    = 128; // char(128)
    col_info[1].column_index	    = 2; // column indexes are 1 based
    col_info[1].column_can_be_null  = 1; // yes

    // send the result set description
    rs_info.column_infos	= col_info;
    rs_info.column_data_values	= col_data;

    if( api->set_value(	arg_handle,
			EXTFN_RESULT_SET_ARG_NUM,
			(an_extfn_value *)&rs_info,
			EXTFN_RESULT_SET_DESCRIBE ) == 0 ) {
	// failed
	free( col_info );
	free( col_data );
	return;
    }

    // now send rows for the result set
    for( a_sql_int32 i = 1; i <= 1000; ++i ) {
	char str[128];
	sprintf( str, "This is row #%d", i );

	col_data[0].column_index    = 1;
	col_data[0].column_data	    = &i;
	col_data[0].data_length	    = sizeof( a_sql_int32 );
	col_data[0].append	    = 0;

	col_data[1].column_index    = 2;
	col_data[1].column_data	    = str;
	col_data[1].data_length	    = (a_sql_uint32)strlen(str);
	col_data[1].append	    = 0;

	if( api->set_value(  arg_handle,
			    EXTFN_RESULT_SET_ARG_NUM,
			    (an_extfn_value *)&rs_info,
			    EXTFN_RESULT_SET_NEW_ROW_FLUSH ) == 0 ) {
	    // failed
	    free( col_info );
	    free( col_data );
	    return;
	}
    }

    free( col_info );
    free( col_data );
}

_VOID_ENTRY GetResultSet2( an_extfn_api *api, void *arg_handle )
/**************************************************************/
{
    // Return a result set with two columns (c3 int, c4 char(128))

    an_extfn_result_set_info	rs_info;

    // mark that there are 2 columns
    rs_info.number_of_columns = 2;

    // need to describe each column
    an_extfn_result_set_column_info *col_info =
        (an_extfn_result_set_column_info *)malloc( 2 * sizeof(an_extfn_result_set_column_info) );
    an_extfn_result_set_column_data *col_data =
        (an_extfn_result_set_column_data *)malloc( 2 * sizeof(an_extfn_result_set_column_data) );
    
    // column 1 description
    col_info[0].column_name	    = "c3";
    col_info[0].column_type	    = DT_INT;
    col_info[0].column_width	    = 0;
    col_info[0].column_index	    = 1; // column indexes are 1 based
    col_info[0].column_can_be_null  = 1; // yes

    // column 2 description
    col_info[1].column_name	    = "c4";
    col_info[1].column_type	    = DT_FIXCHAR;
    col_info[1].column_width	    = 128; // char(128)
    col_info[1].column_index	    = 2; // column indexes are 1 based
    col_info[1].column_can_be_null  = 1; // yes

    // send the result set description
    rs_info.column_infos	= col_info;
    rs_info.column_data_values	= col_data;

    if( api->set_value(	arg_handle,
			EXTFN_RESULT_SET_ARG_NUM,
			(an_extfn_value *)&rs_info,
			EXTFN_RESULT_SET_DESCRIBE ) == 0 ) {
	// failed
	free( col_info );
	free( col_data );
	return;
    }

    // now send rows for the result set
    for( a_sql_int32 i = 1; i <= 1000; ++i ) {
	a_sql_int32 val = i * 1001;
	char str[128];
	sprintf( str, "This is value %d", val );

	col_data[0].column_index    = 1;
	col_data[0].column_data	    = &val;
	col_data[0].data_length	    = sizeof( a_sql_int32 );
	col_data[0].append	    = 0;

	col_data[1].column_index    = 2;
	col_data[1].column_data	    = str;
	col_data[1].data_length	    = (a_sql_uint32)strlen(str);
	col_data[1].append	    = 0;

	if( api->set_value(  arg_handle,
			    EXTFN_RESULT_SET_ARG_NUM,
			    (an_extfn_value *)&rs_info,
			    EXTFN_RESULT_SET_NEW_ROW_FLUSH ) == 0 ) {
	    // failed
	    free( col_info );
	    free( col_data );
	    return;
	}
    }

    free( col_info );
    free( col_data );
}

_VOID_ENTRY GetResultSet3( an_extfn_api *api, void *arg_handle )
/**************************************************************/
{
    // Return a result set with four columns (c1 int, c2 char(128), c3 int, c4 char(128))

    an_extfn_result_set_info	rs_info;

    // mark that there are 4 columns
    rs_info.number_of_columns = 4;

    // describe the result set
    an_extfn_result_set_column_info *col_info =
        (an_extfn_result_set_column_info *)malloc( 4 * sizeof(an_extfn_result_set_column_info) );
    an_extfn_result_set_column_data *col_data =
        (an_extfn_result_set_column_data *)malloc( 4 * sizeof(an_extfn_result_set_column_data) );
    
    col_info[0].column_name	    = "c1";
    col_info[0].column_type	    = DT_INT;
    col_info[0].column_width	    = 0;
    col_info[0].column_index	    = 1; // column indexes are 1 based
    col_info[0].column_can_be_null  = 1; // yes

    col_info[1].column_name	    = "c2";
    col_info[1].column_type	    = DT_FIXCHAR;
    col_info[1].column_width	    = 128; // char(128)
    col_info[1].column_index	    = 2; // column indexes are 1 based
    col_info[1].column_can_be_null  = 1; // yes

    col_info[2].column_name	    = "c3";
    col_info[2].column_type	    = DT_INT;
    col_info[2].column_width	    = 0;
    col_info[2].column_index	    = 3; // column indexes are 1 based
    col_info[2].column_can_be_null  = 1; // yes

    col_info[3].column_name	    = "c4";
    col_info[3].column_type	    = DT_FIXCHAR;
    col_info[3].column_width	    = 128; // char(128)
    col_info[3].column_index	    = 4; // column indexes are 1 based
    col_info[3].column_can_be_null  = 1; // yes

    // send the result set description
    rs_info.column_infos	= col_info;
    rs_info.column_data_values	= col_data;

    if( api->set_value(	arg_handle,
			EXTFN_RESULT_SET_ARG_NUM,
			(an_extfn_value *)&rs_info,
			EXTFN_RESULT_SET_DESCRIBE ) == 0 ) {
	// failed
	free( col_info );
	free( col_data );
	return;
    }

    // now send rows for the result set
    for( a_sql_int32 i = 1; i <= 1000; ++i ) {
	char str[128];
	sprintf( str, "This is row #%d", i );

	col_data[0].column_index    = 1;
	col_data[0].column_data	    = &i;
	col_data[0].data_length	    = sizeof( a_sql_int32 );
	col_data[0].append	    = 0;

	col_data[1].column_index    = 2;
	col_data[1].column_data	    = str;
	col_data[1].data_length	    = (a_sql_uint32)strlen(str);
	col_data[1].append	    = 0;

	a_sql_int32 val = i * 1001;
	char str2[128];
	sprintf( str2, "This is value %d", val );

	col_data[2].column_index    = 3;
	col_data[2].column_data	    = &val;
	col_data[2].data_length	    = sizeof( a_sql_int32 );
	col_data[2].append	    = 0;

	col_data[3].column_index    = 4;
	col_data[3].column_data	    = str2;
	col_data[3].data_length	    = (a_sql_uint32)strlen(str2);
	col_data[3].append	    = 0;

	if( api->set_value(  arg_handle,
			    EXTFN_RESULT_SET_ARG_NUM,
			    (an_extfn_value *)&rs_info,
			    EXTFN_RESULT_SET_NEW_ROW_FLUSH ) == 0 ) {
	    // failed
	    free( col_info );
	    free( col_data );
	    return;
	}
    }

    free( col_info );
    free( col_data );
}
