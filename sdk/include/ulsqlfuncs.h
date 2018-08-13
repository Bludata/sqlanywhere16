// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef __UL_SQLFUNCS_H__
#define __UL_SQLFUNCS_H__

#ifndef UNDER_ASA_SQLPP

#ifdef __cplusplus
extern "C" {
#endif

// ESQL entry points
#define db_init( sqlca )	dbpp_dbinit( sqlca )
#define db_fini( sqlca )	dbpp_dbfini( sqlca )
#define db_start_database( sqlca, parms )	\
    ulpp_start_database( sqlca, parms )
#define db_stop_database( sqlca, parms )	\
    ulpp_stop_database( sqlca, parms )
#define ULDropDatabase( sqlca, parms )	\
    ulpp_drop( sqlca, parms )

UL_FN_SPEC a_sqlpp_version_number	UL_FN_MOD db_verify_version_16( void );

UL_FN_SPEC ul_bool	UL_FN_MOD dbpp_dbinit( SQLCA * sqlca );
UL_FN_SPEC ul_bool	UL_FN_MOD dbpp_dbfini( SQLCA * sqlca );

UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_start_database_a( SQLCA *, char const * );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_stop_database_a( SQLCA *, char const * );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_create_database_a(
    SQLCA *		sqlca,
    char const *	connect_parms,
    char const *	create_parms,
    void *		ssl,
    ul_connection_num *	p_gbl_conn_id );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_drop_a( SQLCA *, char const * );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_start_database_w2( SQLCA *, ul_wchar const * );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_stop_database_w2( SQLCA *, ul_wchar const * );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_create_database_w2(
    SQLCA *		sqlca,
    ul_wchar const *	connect_parms,
    ul_wchar const *	create_parms,
    void *		ssl,
    ul_connection_num *	p_gbl_conn_id );
UL_FN_SPEC ul_bool	UL_FN_MOD ulpp_drop_w2( SQLCA *, ul_wchar const * );
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
    #define ulpp_start_database( sqlca, parms ) ulpp_start_database_w2( sqlca, parms )
    #define ulpp_stop_database( sqlca, parms ) ulpp_stop_database_w2( sqlca, parms )
    #define ulpp_drop( sqlca, parms ) ulpp_drop_w2( sqlca, parms )
    #else
    #define ulpp_start_database( sqlca, parms ) ulpp_start_database_a( sqlca, parms )
    #define ulpp_stop_database( sqlca, parms ) ulpp_stop_database_a( sqlca, parms )
    #define ulpp_drop( sqlca, parms ) ulpp_drop_a( sqlca, parms )
    #endif
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_close( SQLCA *, const char * );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_commit( SQLCA *,unsigned int );

UL_FN_SPEC ul_bool UL_FN_MOD dbpp_connect_40( SQLCA *, const char *, const char *, char *, const char *, char * );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_bool UL_FN_MOD dbpp_connect_40_w2( SQLCA *, const ul_wchar *, const ul_wchar *, char *, const ul_wchar *, char * );
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_delete(SQLCA *,const char *,char *,char *);

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_disconnect( SQLCA *, const char * );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_disconnect_w2( SQLCA *, const ul_wchar * );
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_dropstmt( SQLCA *,char const *,char const *,short int * );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_execute_into( SQLCA *,char const *,char const *,short *,SQLDA *,SQLDA *);

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_fetch( SQLCA *,const char *,unsigned short int,a_sql_int32,SQLDA *,short int,a_sql_uint32 );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_open( SQLCA *,char const *,char const *,char const *,short int *,SQLDA *, short int, short int, a_sql_uint32 );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_prepare_describe_16( SQLCA *,char const *,char const *,short int *,const char *,SQLDA *,SQLDA *,unsigned int, unsigned short int, a_sql_uint32 );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_prepare_describe_16_w2( SQLCA *,char const *,char const *,short int *,const ul_wchar *,SQLDA *,SQLDA *,unsigned int, unsigned short int, a_sql_uint32 );
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_declare( SQLCA *,char const *,char const *,char const *,short int *, a_sql_uint32 );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_prepare_exec_drop( SQLCA *,const char *,SQLDA *,SQLDA *);
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_prepare_exec_drop_w2( SQLCA *,const ul_wchar *,SQLDA *,SQLDA *);
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_put_into( SQLCA *,const char *,SQLDA *,SQLDA *);

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_rollback( SQLCA *,unsigned int );

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_setconnect( SQLCA *, const char * );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_setconnect_w2( SQLCA *, const ul_wchar * );
#endif
UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_setconnect_by_num( SQLCA *, ul_connection_num );
UL_FN_SPEC ul_bool UL_FN_MOD dbpp_getconnect( SQLCA *, const char *, ul_connection_num * );

UL_FN_SPEC ul_bool UL_FN_MOD db_string_connect( SQLCA *, const char * );
#ifdef UL_WCHAR_API
UL_FN_SPEC ul_bool UL_FN_MOD db_string_connect_w2( SQLCA *, const ul_wchar * );
#endif

UL_FN_SPEC ul_ret_void UL_FN_MOD dbpp_update( SQLCA *,const char *,SQLDA *);

// dynamic SQL utility routines
UL_FN_SPEC SQLDA * 	UL_FN_MOD alloc_descriptor( SQLCA *, unsigned int );
UL_FN_SPEC SQLDA * 	UL_FN_MOD alloc_sqlda(unsigned int );
UL_FN_SPEC SQLDA * 	UL_FN_MOD alloc_sqlda_noind(unsigned int );
UL_FN_SPEC ul_ret_void	UL_FN_MOD check_descriptor_null_value( SQLCA *, struct sqlda *, unsigned short );
UL_FN_SPEC SQLDA *	UL_FN_MOD dealloc_descriptor( SQLCA *, SQLDA * );
UL_FN_SPEC ul_ret_void 	UL_FN_MOD dbpp_describe( SQLCA *,char const *,char const *,short int *,SQLDA *,unsigned int );
UL_FN_SPEC SQLDA * 	UL_FN_MOD fill_sqlda(SQLDA *);
UL_FN_SPEC SQLDA *	UL_FN_MOD fill_s_sqlda(SQLDA *, unsigned int);
UL_FN_SPEC ul_ret_void 	UL_FN_MOD free_sqlda(SQLDA *);
UL_FN_SPEC ul_ret_void	UL_FN_MOD free_sqlda_noind(SQLDA *);
UL_FN_SPEC ul_ret_void	UL_FN_MOD free_filled_sqlda(SQLDA *);
UL_FN_SPEC ul_u_short	UL_FN_MOD get_descriptor_count( SQLCA * sqlca, SQLDA * sqlda );
UL_FN_SPEC ul_ret_void	UL_FN_MOD get_descriptor_data( SQLCA *, struct sqlda *, unsigned short, unsigned short, void *, unsigned short, a_descriptor_behaviour, a_descriptor_behaviour );
UL_FN_SPEC ul_u_short	UL_FN_MOD get_descriptor_field( SQLCA *, struct sqlda *, ul_u_short, a_descriptor_field
						      , a_descriptor_behaviour, a_descriptor_behaviour );
UL_FN_SPEC ul_ret_void	UL_FN_MOD set_descriptor_count( SQLCA * sqlca, struct sqlda * sqlda, int count );
UL_FN_SPEC ul_ret_void	UL_FN_MOD set_descriptor_data( SQLCA * sqlca, struct sqlda * sqlda, ul_u_short index
						     , a_sql_data_type host_type, void * host_var, ul_u_short length
						     , a_descriptor_behaviour handle_warning
						     , a_descriptor_behaviour handle_error );
UL_FN_SPEC ul_u_short	UL_FN_MOD set_descriptor_field( SQLCA * sqlca, struct sqlda * sqlda, ul_u_short index
    						      , a_descriptor_field field_type, ul_s_short value
						      , a_descriptor_behaviour handle_warning
						      , a_descriptor_behaviour handle_error );
UL_FN_SPEC ul_u_long	UL_FN_MOD sqlda_string_length( SQLDA *sqlda, int offset );
UL_FN_SPEC ul_u_long	UL_FN_MOD sqlda_storage( SQLDA *sqlda, int offset );

	
// tchar support
#ifdef UNICODE
#define dbpp_connect_40_t2(a, b, c, d, e, f)			dbpp_connect_40_w2(a, b, c, d, e, f)
#define dbpp_disconnect_t2(a, b)				dbpp_disconnect_w2(a, b)
#define dbpp_prepare_describe_16_t2(a, b, c, d, e, f, g, h, i)	dbpp_prepare_describe_16_w2(a, b, c, d, e, f, g, h, i)
#define dbpp_prepare_exec_drop_t2(a, b, c, d)			dbpp_prepare_exec_drop_w2(a, b, c, d)
#define dbpp_setconnect_t2(a, b)				dbpp_setconnect_w2(a, b)
#define db_string_connect_t2(a, b)				db_string_connect_w2(a, b)
#else
#define dbpp_connect_40_t2(a, b, c, d, e, f)			dbpp_connect_40(a, b, c, d, e, f)
#define dbpp_disconnect_t2(a, b)				dbpp_disconnect(a, b)
#define dbpp_prepare_describe_16_t2(a, b, c, d, e, f, g, h, i)	dbpp_prepare_describe_16(a, b, c, d, e, f, g, h, i)
#define dbpp_prepare_exec_drop_t2(a, b, c, d)			dbpp_prepare_exec_drop(a, b, c, d)
#define dbpp_setconnect_t2(a, b)				dbpp_setconnect(a, b)
#define db_string_connect_t2(a, b)				db_string_connect(a, b)
#endif

// extended streaming api

struct db_blob_t;
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_get_data_start_a( SQLCA * psqlca, short int statnum, ul_column_num column );
#if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //db_get_data_start_w2()
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_get_data_start_w2( SQLCA * psqlca, short int statnum, ul_column_num column );
#endif
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_get_data_start_binary( SQLCA * psqlca, short int statnum, ul_column_num column );
#define DB_GET_DATA_CONTINUE ((ul_buffer_length)-1)
UL_FN_SPEC ul_buffer_length UL_FN_MOD db_get_data_a( SQLCA * psqlca, db_blob_t * blob_in, char * dst, ul_buffer_length len, ul_buffer_length offset = DB_GET_DATA_CONTINUE );
#if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //db_get_data_w2()
UL_FN_SPEC ul_buffer_length UL_FN_MOD db_get_data_w2( SQLCA * psqlca, db_blob_t * blob_in, ul_wchar * dst, ul_buffer_length len, ul_buffer_length offset = DB_GET_DATA_CONTINUE  );
#endif
UL_FN_SPEC ul_buffer_length UL_FN_MOD db_get_data_binary( SQLCA * psqlca, db_blob_t * blob_in, ul_byte * dst, ul_buffer_length len, ul_buffer_length offset = DB_GET_DATA_CONTINUE );
UL_FN_SPEC ul_ret_void	UL_FN_MOD db_get_data_finish( SQLCA * psqlca, db_blob_t * blob_in );
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_put_data_start_a( SQLCA * psqlca, short int statnum, ul_column_num column );
#if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //db_put_data_start_w2()
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_put_data_start_w2( SQLCA * psqlca, short int statnum, ul_column_num column );
#endif
UL_FN_SPEC db_blob_t *	UL_FN_MOD db_put_data_start_binary( SQLCA * psqlca, short int statnum, ul_column_num column );
UL_FN_SPEC ul_bool	UL_FN_MOD db_put_data_a( SQLCA * psqlca, db_blob_t * blob_in, const char * src, ul_buffer_length len );
#if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //db_put_data_w2()
UL_FN_SPEC ul_bool	UL_FN_MOD db_put_data_w2( SQLCA * psqlca, db_blob_t * blob_in, const ul_wchar * src, ul_buffer_length len );
#endif
UL_FN_SPEC ul_bool	UL_FN_MOD db_put_data_binary( SQLCA * psqlca, db_blob_t * blob_in, const ul_byte * src, ul_buffer_length len );
UL_FN_SPEC ul_ret_void	UL_FN_MOD db_put_data_finish( SQLCA * psqlca, db_blob_t * blob_in );

#ifdef __cplusplus
}
#endif

#endif // UNDER_ASA_SQLPP

#endif // __UL_SQLFUNCS_H__
