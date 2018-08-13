// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/** \file ulprotos.h
    UltraLite function declarations.
*/

#ifndef __UL_PROTOS_H__
#define __UL_PROTOS_H__

#ifndef __stdarg_h
#include <stdarg.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef DOXYGEN_IGNORE
#if defined( UL_BUILD_DLL )
        #define UL_FN_SPEC		extern __declspec(dllexport)
    	#define UL_FN_MOD 		__stdcall
        #define UL_VAR_SPEC 		UL_FN_SPEC
	#define UL_CLS_SPEC		__declspec(dllexport)
	#define UL_METHOD_SPEC
#elif defined( UL_USE_DLL )
        #define UL_FN_SPEC 		extern __declspec(dllimport)
    	#define UL_FN_MOD 		__stdcall
        #define UL_VAR_SPEC 		UL_FN_SPEC
	#define UL_CLS_SPEC		__declspec(dllimport)
	#define UL_METHOD_SPEC
#else
    #define UL_FN_SPEC 		extern
    #if defined( UNDER_CE )
        #define UL_FN_MOD	__cdecl
    #else
        #define UL_FN_MOD
    #endif
    #define UL_VAR_SPEC 	UL_FN_SPEC
    #define UL_CLS_SPEC		
    #define UL_METHOD_SPEC
#endif

// decorators for functions in static library (ulbase10)
#define UL_LIB_SPEC extern
#if defined( UNDER_CE )
    #define UL_LIB_MOD __cdecl
#else
    #define UL_LIB_MOD
#endif

#define UL_TIMESTAMP // used by jdate.h
#define UL_STORE_PARMS		UL_NULL
#endif

/** Specifies possible database properties that users can retrieve.
 *
 * These properties are used with the ULConnection.GetDatabaseProperty
 * method.
 *
 * \apilink{ULConnection::GetDatabaseProperty, "ulc", "ulc-ulcpp-ulconnection-cla-getdatabaseproperty-met"}
 *
 * \hideinitializers
 */
enum ul_database_property_id {
    /** Date format. (date_format) */
    ul_property_date_format = 1,
    /** Date order. (date_order) */
    ul_property_date_order,
    /** Nearest century. (nearest_century) */
    ul_property_nearest_century,
    /** Precision. (precision)  */
    ul_property_precision,
    /** Scale. (scale) */
    ul_property_scale,
    /** Time format. (time_format) */
    ul_property_time_format,
    /** Timestamp format. (timestamp_format) */
    ul_property_timestamp_format,
    /** Timestamp increment. (timestamp_increment) */
    ul_property_timestamp_increment,
    /** Name. (Name) */
    ul_property_name,
    /** File. (File) */
    ul_property_file,
    /** Encryption. (Encryption) */
    ul_property_encryption,
    /** Global database ID. (global_database_id) */
    ul_property_global_database_id,
    /** Remote ID. (ml_remote_id) */
    ul_property_ml_remote_id,
    /** Character set. (CharSet) */
    ul_property_char_set,
    /** collation sequence. (Collation) */
    ul_property_collation,
    /** Page size. (PageSize) */
    ul_property_page_size,
    /** CaseSensitive. (CaseSensitive) */
    ul_property_case_sensitive,
    /** Connection count. (ConnCount) */
    ul_property_conn_count,
    /** Default maximum index hash. (MaxHashSize) */
    ul_property_max_hash_size,
    /** Database checksum level. (ChecksumLevel) */
    ul_property_checksum_level,
    /** Database checkpoint count. (CheckpointCount) */
    ul_property_checkpoint_count,
    /** Database commit flush timeout. (commit_flush_timeout) */
    ul_property_commit_flush_timeout,
    /** Database commit flush count. (commit_flush_count) */
    ul_property_commit_flush_count,
    /** Connection isolation level. (isolation_level) */
    ul_property_isolation_level,
    /** Timestamp with time zone format. (timestamp_with_time_zone_format) */
    ul_property_timestamp_with_time_zone_format,
    /** The current database file cache size, as a percentage value of the
	minimum to maximum range.
    */
    ul_property_cache_allocation,
    /// \internal
    ul_property_database_file_version,
};

/** Specifies possible database options that users can set.
 *
 * These database options are used with the ULConnection.SetDatabaseOption
 * method.
 *
 * \apilink{ULConnection::SetDatabaseOption, "ulc", "ulc-ulcpp-ulconnection-cla-setdatabaseoption-met"}
 * \hideinitializers
*/
enum ul_database_option_id {
    /** The global database ID is set using an unsigned long integer. */
    ul_option_global_database_id = 1,
    /** The remote ID is set using a string. */
    ul_option_ml_remote_id,
    /** The database commit flush timeout is set as an integer, representing
     * a time threshold measured in milliseconds. */
    ul_option_commit_flush_timeout,
    /** The database commit flush count is set as integer, representing a commit
     * count threshold. */
    ul_option_commit_flush_count,
    /** The connection isolation level is set as string.
     * (read_committed/read_uncommitted)*/
    ul_option_isolation_level,
    /** Set to resize the database file cache. The value is an integer in the
	range 0 to 100, representing the amount of cache allocated of the
	minimum to maximum size range.
    */
    ul_option_cache_allocation,
};

/// \internal
#define ul_option__first    ul_option_global_database_id
/// \internal
#define ul_option__last	    ul_option_cache_allocation

/** Performs a checkpoint operation, flushing any pending committed transactions
 * to the database.
 *
 * Any current transaction is not committed by calling this method.  This method
 * is used in conjunction with deferring automatic transaction 
 * checkpoints as a performance enhancement.
 *
 * This method ensures that all pending committed transactions have been written
 * to the database. 
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULCheckpoint( SQLCA * sqlca );

/** Sets the database identification number.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param value A positive integer that uniquely identifies a particular
 *              database in a replication or synchronization setup.
 *
 * \see ULGlobalAutoincUsage 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULSetDatabaseID(
    SQLCA *	sqlca,
    ul_u_long	value );

/** Gets the current database ID used for global autoincrement.
 *
 * \param sqlca	A pointer to the SQLCA. 
 * \return The value set by the last call to the SetDatabaseID method, or
 *         UL_INVALID_DATABASE_ID if the ID was never set.
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULGetDatabaseID(
    SQLCA *	sqlca );

/** Obtains the percent of the default values used in all the columns that have 
 * global autoincrement defaults.
 *
 * If the database contains more than one column with this default, this value 
 * is calculated for all columns and the maximum is returned. For example, a 
 * return value of 99 indicates that very few default values remain for at least
 * one of the columns. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \return The percent of the global autoincrement values used by the counter.
 *
 * \see ULSetDatabaseID
 */
UL_FN_SPEC ul_u_short UL_FN_MOD ULGlobalAutoincUsage(
    SQLCA *	sqlca );

/** Gets the @@identity value.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \return The last value inserted into an autoincrement or global autoincrement 
 *         column.
 */
UL_FN_SPEC ul_u_big UL_FN_MOD ULGetIdentity( SQLCA * sqlca);


/** Obtains the value of a database property.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param id The identifier for the database property. 
 * \param dst A character array to store the value of the property. 
 * \param buffer_size The size of the character array dst. 
 * \param null_indicator An indicator that the database parameter is null. 
 */
UL_FN_SPEC void UL_FN_MOD ULGetDatabasePropertyA(
    SQLCA * sqlca,
    ul_database_property_id id,
    char * dst,
    size_t buffer_size,
    ul_bool * null_indicator );

#ifdef UL_WCHAR_API
/** Obtains the value of a database property.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULGetDatabaseProperty method and \#define the UNICODE macro on Win32 
 * platforms. Typically, you would not reference this method directly when
 * creating an UltraLite application.
 * 
 * \param sqlca	A pointer to the SQLCA.
 * \param id The identifier for the database property. 
 * \param dst A character array to store the value of the property. 
 * \param buffer_size The size of the character array dst. 
 * \param null_indicator An indicator that the database parameter is null. 
 */
UL_FN_SPEC void UL_FN_MOD ULGetDatabasePropertyW(
    SQLCA * sqlca,
    ul_database_property_id id,
    ul_wchar * dst,
    size_t buffer_size,
    ul_bool * null_indicator );
#endif

/** Sets a database option from a string value.
 *
 * \param sqlca	A pointer to the SQLCA. 
 * \param id The identifier for the database option to be set. 
 * \param value The value of the database option. 
 */
UL_FN_SPEC void UL_FN_MOD ULSetDatabaseOptionStringA( SQLCA * sqlca, ul_database_option_id id, char const * value );

#ifdef UL_WCHAR_API
/** Sets a database option from a string value.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSetDatabaseOptionString method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when
 * creating an UltraLite application.
 * 
 * \param sqlca	A pointer to the SQLCA. 
 * \param id The identifier for the database option to be set. 
 * \param value The value of the database option. 
 */
UL_FN_SPEC void UL_FN_MOD ULSetDatabaseOptionStringW( SQLCA * sqlca, ul_database_option_id id, ul_wchar const * value );
#endif

/** Sets a numeric database option.
 *
 * \param sqlca	A pointer to the SQLCA. 
 * \param id The identifier for the database option to be set. 
 * \param value The value of the database option. 
 */
UL_FN_SPEC void UL_FN_MOD ULSetDatabaseOptionULong( SQLCA * sqlca, ul_database_option_id id, ul_u_long value );

/** Creates an UltraLite database.
 *
 * The database is created with information provided in two sets of parameters.
 * 
 * The connect_parms parameter is a list of connection parameters that are
 * applicable whenever the database is accessed.  Some examples include file
 * name, user ID, password, or optional encryption key.
 * 
 * The create_parms parameter is a list of parameters that are only relevant
 * when creating a database.  Some examples include obfuscation, page-size, and
 * time and date format).
 * 
 * Applications can call this method after initializing the SQLCA.
 * 
 * The following code illustrates how to use the ULCreateDatabase method to
 * create an UltraLite database as the file <dfn>C:\\myfile.udb</dfn>:
 *
 * <pre>
 * if( ULCreateDatabase(&sqlca 
 *     ,UL_TEXT("DBF=C:\myfile.udb;uid=DBA;pwd=sql")
 *     ,ULGetCollation_1250LATIN2() 
 *     ,UL_TEXT("obfuscate=1;page_size=8192")
 *     ,NULL)
 * {
 *     // success
 * };
 * </pre>
 *
 * \param sqlca	A pointer to the initialized SQLCA. 
 * \param connect_parms A semicolon-separated string of connection parameters, 
 *                      which are set as keyword=value pairs. The connection
 *                      string must include the name of the database. These
 *                      parameters are the same set of parameters that can be
 *                      specified when you connect to a database.
 * \param create_parms A semicolon-separated string of creation parameters,
 *                     a set as keyword=value pairs, such as
 *                     page_size=2048;obfuscate=yes.
 * \param reserved This parameter is reserved for future use. 
 * \return ul_true if database was successfully created; otherwise, returns
 *         ul_false.  Typically ul_false is caused by an invalid file name or
 *         denied access. 
 *
 * \seealso{UltraLite connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-connparms.html", "uladmin", "fo-connparms"}
 * \seealso{UltraLite creation parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-creationparms.html", "uladmin", "fo-creationparms"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULCreateDatabaseA(
    SQLCA *		sqlca,
    char const *	connect_parms,
    char const *	create_parms,
    void *		reserved );

#ifdef UL_WCHAR_API
/** Creates an UltraLite database.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULCreateDatabase method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 * 
 * The database is created with information provided in two sets of parameters.
 * 
 * The connect_parms parameter is a list of connection parameters that are
 * applicable whenever the database is accessed.  Some examples include file
 * name, user ID, password, or optional encryption key.
 * 
 * The create_parms parameter is a list of parameters that are only relevant
 * when creating a database.  Some examples include obfuscation, page-size, and
 * time and date format).
 * 
 * Applications can call this method after initializing the SQLCA.
 * 
 * The following code illustrates how to use the ULCreateDatabase method to
 * create an UltraLite database as the file <dfn>C:\\myfile.udb</dfn>:
 *
 * <pre>
 * if( ULCreateDatabase(&sqlca 
 *     ,UL_TEXT("DBF=C:\myfile.udb;uid=DBA;pwd=sql")
 *     ,ULGetCollation_1250LATIN2() 
 *     ,UL_TEXT("obfuscate=1;page_size=8192")
 *     ,NULL)
 * {
 *     // success
 * };
 * </pre>
 *
 * \param sqlca	A pointer to the initialized SQLCA. 
 * \param connect_parms A semicolon-separated string of connection parameters, 
 *                      which are set as keyword=value pairs. The connection
 *                      string must include the name of the database. These
 *                      parameters are the same set of parameters that can be
 *                      specified when you connect to a database.
 * \param create_parms A semicolon-separated string of creation parameters,
 *                     a set as keyword=value pairs, such as
 *                     page_size=2048;obfuscate=yes.
 * \param reserved This parameter is reserved for future use. 
 * \return ul_true if database was successfully created; otherwise, returns
 *         ul_false.  Typically ul_false is caused by an invalid file name or
 *         denied access. 
 *
 * \seealso{UltraLite connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-connparms.html", "uladmin", "fo-connparms"}
 * \seealso{UltraLite creation parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-creationparms.html", "uladmin", "fo-creationparms"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULCreateDatabaseW(
    SQLCA *		sqlca,
    ul_wchar const *	connect_parms,
    ul_wchar const *	create_parms,
    void *		reserved );
#endif

#ifdef USE_CHARSET_WRAPPERS
#if defined( UNICODE )
#   define ULGetDatabaseProperty	ULGetDatabasePropertyW
#   define ULSetDatabaseOptionString	ULSetDatabaseOptionStringW
#   define ULCreateDatabase		ULCreateDatabaseW
#else
#   define ULGetDatabaseProperty	ULGetDatabasePropertyA
#   define ULSetDatabaseOptionString	ULSetDatabaseOptionStringA
#   define ULCreateDatabase		ULCreateDatabaseA
#endif
#endif

// Synchronization functions

/** Initializes the synchronization information structure.
 *
 * \param info A synchronization structure.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULInitSyncInfoA(
    ul_sync_info_a *	info );

#ifdef UL_WCHAR_API
/** Initializes the synchronization information structure.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULInitSyncInfo method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param info A synchronization structure.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULInitSyncInfoW(
    ul_sync_info_w2 *	info );
#endif

/** Creates a synchronization profile using the given name based on the given
 * ul_sync_info structure.
 * 
 * The synchronization profile replaces any previous profile with the same 
 * name. The named profile is deleted by specifying a null pointer for the
 * structure.
 *
 * \param sqlca A pointer to the SQLCA.
 * \param profile_name The name of the synchronization profile.
 * \param sync_info A pointer to the ul_sync_info structure that holds the
 *                  synchronization parameters.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULSetSyncInfoA(
    SQLCA * sqlca,
    char const * profile_name,
    ul_sync_info_a * sync_info );

#ifdef UL_WCHAR_API
/** Creates a synchronization profile using the given name based on the given
 * ul_sync_info structure.
 * 
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSetSyncInfo method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * This sync profile replaces any previous sync profile with the same name.
 * Specifying a null pointer for the ul_sync_info deletes the named profile.
 *
 * \param sqlca A pointer to the SQLCA.
 * \param profile_name The name of the synchronization profile.
 * \param sync_info A pointer to the ul_sync_info structure that holds the
 *                  synchronization parameters.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULSetSyncInfoW(
    SQLCA * sqlca,
    ul_wchar const * profile_name,
    ul_sync_info_w2 * sync_info );
#endif

/** Sets START SYNCHRONIZATION DELETE for this connection.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_ret_void  UL_FN_MOD ULStartSynchronizationDelete( SQLCA * sqlca);

/** Sets STOP SYNCHRONIZATION DELETE for this connection.
 *
 * \param sqlca	A pointer to the SQLCA
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool	UL_FN_MOD ULStopSynchronizationDelete( SQLCA * sqlca);

/** Obtains the last time a specified publication was downloaded.
 * 
 * The following call populates the dt structure with the date and time that
 * the UL_PUB_PUB1 publication was downloaded:
 *
 * <pre>
 * DECL_DATETIME dt;
 * ret = ULGetLastDownloadTime( &sqlca, UL_TEXT("UL_PUB_PUB1"), &dt );
 * </pre>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param pub_name A string containing a publication name for which the last 
 *                 download time is retrieved. 
 * \param value A pointer to the DECL_DATETIME structure to be populated. For
 *              example, the value of January 1, 1990 indicates that the
 *              publication has yet to be synchronized.
 * \return True when the value is successfully populated by the last download
 *         time of the publication specified by the pub_name value; Otherwise, 
 *         returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetLastDownloadTimeA(
    SQLCA *		sqlca,
    char const *	pub_name,
    DECL_DATETIME *	value
);

#ifdef UL_WCHAR_API
/** Obtains the last time a specified publication was downloaded.
 * 
 * <em>Note:</em>This method prototype is used internally when you refer to
 * ULGetLastDownloadTime and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * The following call populates the dt structure with the date and time that
 * the UL_PUB_PUB1 publication was downloaded:
 *
 * <pre>
 * DECL_DATETIME dt;
 * ret = ULGetLastDownloadTime( &sqlca, UL_TEXT("UL_PUB_PUB1"), &dt );
 * </pre>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param pub_name A string containing a publication name for which the last 
 *                 download time is retrieved. 
 * \param value A pointer to the DECL_DATETIME structure to be populated. For
 *              example, the value of January 1, 1990 indicates that the
 *              publication has yet to be synchronized.
 * \return True when the value is successfully populated by the last download
 *         time of the publication specified by the pub_name value; Otherwise, 
 *         returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetLastDownloadTimeW(
    SQLCA *		sqlca,
    ul_wchar const *	pub_name,
    DECL_DATETIME *	value
);
#endif

/** Resets the last download time of a publication so that the application
 * resynchronizes previously downloaded data.
 *
 * The following method call resets the last download time for all tables:
 *
 * <pre>
 * ULResetLastDownloadTime( &sqlca, UL_TEXT("*") );
 * </pre>
 *
 * \param sqlca	A pointer to the SQLCA
 * \param pub_list A string containing a comma-separated list of publications
 *                 to reset. An empty string assigns all tables except tables 
 *                 marked as "no sync".  A string containing just an asterisk
 *                 ("*") assigns all publications. Some tables may not be part
 *                 of any publication and are not included if the pub_list 
 *                 string is "*". 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULResetLastDownloadTimeA(
    SQLCA *		sqlca,
    char const *	pub_list
);

#ifdef UL_WCHAR_API
/** Resets the last download time of a publication so that the application
 * resynchronizes previously downloaded data.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULResetLastDownloadTime method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when
 * creating an UltraLite application.
 *
 * The following method call resets the last download time for all tables:
 *
 * <pre>
 * ULResetLastDownloadTime( &sqlca, UL_TEXT("*") );
 * </pre>
 *
 * \param sqlca	A pointer to the SQLCA
 * \param pub_list A string containing a comma-separated list of publications
 *                 to reset. An empty string assigns all tables except tables 
 *                 marked as "no sync".  A string containing just an asterisk
 *                 ("*") assligns all publications. Some tables may not be part
 *                 of any publication and are not included if the pub_list 
 *                 string is "*". 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULResetLastDownloadTimeW(
    SQLCA *		sqlca,
    ul_wchar const *	pub_list
);
#endif

/** Counts the number of rows that need to be uploaded for synchronization.
 *
 * Use this method to prompt users to synchronize, or determine when
 * automatic background synchronization should take place.
 *
 * The following call checks the entire database for the total number of
 * rows to be synchronized:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_SYNC_ALL, 0 );
 * </pre>
 *
 * The following call checks the PUB1 and PUB2 publications for a maximum of
 * 1000 rows:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_TEXT("PUB1,PUB2"), 1000 );
 * </pre>
 *
 * The following call checks if any rows need to be synchronized in the
 * PUB1 and PUB2 publications:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_TEXT("PUB1,PUB2"), 1 );
 * </pre>
 *
 * \param sqlca	A pointer to the SQL.
 * \param pub_list A string containing a comma-separated list of publications to
 *                 check. An empty string (the UL_SYNC_ALL macro) implies all
 *                 tables except tables marked as "no sync". A string containing
 *                 just an asterisk (the UL_SYNC_ALL_PUBS macro) implies all
 *                 tables referred to in any publication. Some tables may not be
 *                 part of any publication and are not included if the pub_list
 *                 string is "*". 
 * \param threshold Determines the maximum number of rows to count, thereby 
 *                  limiting the amount of time taken by the call. A threshold
 *                  of 0 corresponds to no limit (that is, the method counts all
 *                  the rows that need to be synchronized), and  a threshold of 
 *                  1 can be used to quickly determine if any rows need to be
 *                  synchronized.
 * \return The number of rows that need to be synchronized, either in a
 *         specified set of publications or in the whole database.
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULCountUploadRowsA(
    SQLCA *		sqlca,
    char const *	pub_list,
    ul_u_long		threshold
);

#ifdef UL_WCHAR_API
/** Counts the number of rows that need to be uploaded for synchronization.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULCountUploadRows method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * Use this method to prompt users to synchronize, or determine when
 * automatic background synchronization should take place.
 *
 * The following call checks the entire database for the total number of
 * rows to be synchronized:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_SYNC_ALL, 0 );
 * </pre>
 *
 * The following call checks the PUB1 and PUB2 publications for a maximum of
 * 1000 rows:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_TEXT("PUB1,PUB2"), 1000 );
 * </pre>
 *
 * The following call checks if any rows need to be synchronized in the
 * PUB1 and PUB2 publications:
 *
 * <pre>
 * count = ULCountUploadRows( sqlca, UL_TEXT("PUB1,PUB2"), 1 );
 * </pre>
 *
 * \param sqlca	A pointer to the SQL.
 * \param pub_list A string containing a comma-separated list of publications to
 *                 check. An empty string (the UL_SYNC_ALL macro) implies all
 *                 tables except tables marked as "no sync". A string containing
 *                 just an asterisk (the UL_SYNC_ALL_PUBS macro) implies all
 *                 tables referred to in any publication. Some tables may not be
 *                 part of any publication and are not included if the pub_list
 *                 string is "*". 
 * \param threshold Determines the maximum number of rows to count, thereby 
 *                  limiting the amount of time taken by the call. A threshold
 *                  of 0 corresponds to no limit (that is, the method counts all
 *                  the rows that need to be synchronized), and  a threshold of 
 *                  1 can be used to quickly determine if any rows need to be
 *                  synchronized.
 * \return The number of rows that need to be synchronized, either in a
 *         specified set of publications or in the whole database.
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULCountUploadRowsW(
    SQLCA *		sqlca,
    ul_wchar const *	pub_list,
    ul_u_long		threshold
);
#endif

#ifdef USE_CHARSET_WRAPPERS
#if defined( UNICODE )
#   define ULGetLastDownloadTime    ULGetLastDownloadTimeW
#   define ULResetLastDownloadTime  ULResetLastDownloadTimeW
#   define ULCountUploadRows	    ULCountUploadRowsW
#else
#   define ULGetLastDownloadTime    ULGetLastDownloadTimeA
#   define ULResetLastDownloadTime  ULResetLastDownloadTimeA
#   define ULCountUploadRows	    ULCountUploadRowsA
#endif
#endif

/** Sets the callback to be invoked while performing a synchronization.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param callback The callback. 
 * \param user_data User context information that is passed to the callback. 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULSetSynchronizationCallback(
    SQLCA *		sqlca,
    ul_sync_observer_fn callback,
    ul_void *		user_data );

/** Initiates synchronization in an UltraLite application.
 *
 * For TCP/IP or HTTP synchronization, the ULSynchronize method initiates 
 * synchronization. Errors during synchronization that are not handled by the 
 * handle_error script are reported as SQL errors. Application programs should
 * test the SQLCODE return value of this method. 
 *
 * The following example demonstrates database synchronization:
 *
 * <pre>
 * ul_sync_info info;
 * ULInitSyncInfo( &info );
 * info.user_name = UL_TEXT( "user_name" );
 * info.version = UL_TEXT( "test" );
 * ULSynchronize( &sqlca, &info );
 * </pre>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param info A pointer to the ul_sync_info structure that holds the
 *             synchronization parameters.
 */
UL_FN_SPEC ul_ret_void	UL_FN_MOD ULSynchronizeA(
    SQLCA * 		sqlca,
    ul_sync_info_a *	info );

#ifdef UL_WCHAR_API
/** Initiates synchronization in an UltraLite application.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSynchronize method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * For TCP/IP or HTTP synchronization, the ULSynchronize function initiates 
 * synchronization. Errors during synchronization that are not handled by the 
 * handle_error script are reported as SQL errors. Application programs should
 * test the SQLCODE return value of this function. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param info A pointer to the ul_sync_info structure that holds the
 *             synchronization parameters.
 */
UL_FN_SPEC ul_ret_void	UL_FN_MOD ULSynchronizeW(
    SQLCA * 		sqlca,
    ul_sync_info_w2 *	info );
#endif

/** Synchronizes the database using the given profile and merge parameters.
 *
 * This method is identical to executing the SYNCHRONIZE statement.
 *
 * \seealso{SYNCHRONIZE statement [UltraLite], "http://dcx.sybase.com/goto?page=sa160/en/uladmin/ul-synchronize-statement.html", "uladmin", "ul-synchronize-statement"}
 *
 * \param sqlca A pointer to the SQLCA.
 * \param profile_name The name of the profile to synchronize.
 * \param merge_parms Merge parameters for the synchronization.
 * \param observer Observer callback to send status updates to.
 * \param user_data User context data passed to callback.
 */
UL_FN_SPEC ul_ret_void	UL_FN_MOD ULSynchronizeFromProfileA(
    SQLCA *		sqlca,
    char const *	profile_name,
    char const *	merge_parms,
    ul_sync_observer_fn observer,
    ul_void *		user_data );

#ifdef UL_WCHAR_API
/** Synchronize the database using the given profile and merge parameters.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSynchronizeFromProfile method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * \param sqlca A pointer to the SQLCA.
 * \param profile_name Name of the profile to synchronize.
 * \param merge_parms Merge parameters for the synchronization.
 * \param observer Observer callback to send status updates to.
 * \param user_data	User context data passed to callback.
 */
UL_FN_SPEC ul_ret_void	UL_FN_MOD ULSynchronizeFromProfileW(
    SQLCA *		sqlca,
    ul_wchar const *	profile_name,
    ul_wchar const *	merge_parms,
    ul_sync_observer_fn observer,
    ul_void *		user_data );
#endif

/** Gets the result of the last synchronization.
 *
 * \apilink{ul_sync_result, "ulc", "ulc-ulcom-ul-sync-result-str"}
 * 	
 * \param sqlca A pointer to the SQLCA.
 * \param sync_result A pointer to the ul_sync_result structure that holds the
 *                    synchronization results.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool	UL_FN_MOD ULGetSyncResult(
    SQLCA *		sqlca,
    ul_sync_result * sync_result );

/** Rolls back the changes from a failed synchronization.
 *
 * When a communication error occurs during the download phase of 
 * synchronization, UltraLite can apply the downloaded changes, so that the 
 * application can resume the synchronization from the place it was interrupted.
 * If the download changes are not needed (the user or application does not want
 * to resume the download at this point), the ULRollbackPartialDownload method 
 * rolls back the failed download transaction. 
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void	UL_FN_MOD ULRollbackPartialDownload(
    SQLCA *		sqlca );

#ifdef USE_CHARSET_WRAPPERS
  #ifdef UNICODE
    #define ULSynchronize		ULSynchronizeW
    #define ULSynchronizeFromProfile	ULSynchronizeFromProfileW
    #define ULInitSyncInfo		ULInitSyncInfoW
    #define ULSetSyncInfo		ULSetSyncInfoW
  #else
    #define ULSynchronize		ULSynchronizeA
    #define ULSynchronizeFromProfile	ULSynchronizeFromProfileA
    #define ULInitSyncInfo		ULInitSyncInfoA
    #define ULSetSyncInfo		ULSetSyncInfoA
  #endif
#endif

// old stream names
/// \internal
#define ULSocketStream()			"tcpip"
/// \internal
#define ULHTTPStream()				"http"
/// \internal
#define ULHTTPSStream()				"https"
// security streams cannot be converted

#ifdef UNDER_CE
// Apps which are registered with the ActiveSync provider need to call this
// method in their WNDPROC to determine if the message is a synchronize
// message...

/** Checks a message to see if it is a synchronization message from the MobiLink
 * provider for ActiveSync, so that code to handle such a message can be called.
 * When the processing of a synchronization message is complete, the 
 * ULSignalSyncIsComplete method should be called. 
 * 
 * You should include a call to this method in the WindowProc function of your
 * application. This applies to Windows Mobile for ActiveSync.
 *
 * The following code snippet illustrates how to use the ULIsSynchronizeMessage
 * method to handle a synchronization message:
 *
 * <pre>
 * LRESULT CALLBACK WindowProc( HWND hwnd,
 *          UINT uMsg,
 *          WPARAM wParam,
 *          LPARAM lParam )
 * {
 *   if( ULIsSynchronizeMessage( uMsg ) ) {
 *     // execute synchronization code
 *     if( wParam == 1 ) DestroyWindow( hWnd );
 *     return 0;
 *   }
 * 
 *   switch( uMsg ) {
 * 
 *   // code to handle other windows messages
 * 
 *   default:
 *     return DefWindowProc( hwnd, uMsg, wParam, lParam );
 *   }
 *   return 0;
 * }
 * </pre>
 *
 * \see ULSignalSyncIsComplete 
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULIsSynchronizeMessage( ul_u_long number );
// ...and call this method when they are done.

/** Indicates that processing a synchronization message is complete.
 *
 * Applications that are registered with the ActiveSync provider need to call
 * this method in their WNDPROC when processing a synchronization message is 
 * complete. 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULSignalSyncIsComplete();
#endif

// error handling

/** Sets the callback to be invoked when an error occurs.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param callback The callback function.
 * \param user_data User context information passed to the callback. 
 * \param buffer A user-supplied buffer that contains the error parameters when 
 *               the callback is invoked. 
 * \param len The size, in bytes, of the buffer.
 *
 * \seealso{Handling errors, "http://dcx.sybase.com/goto?page=sa160/en/ulc/error-af-development.html", "ulc", "error-af-development"}
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULSetErrorCallbackA(
    SQLCA *			sqlca,
    ul_error_callback_fn_a	callback,
    ul_void *			user_data,  // passed to callback
    char *			buffer,	    // filled with error info and passed to callback
    size_t			len );	    // size of buffer in chars

#ifdef UL_WCHAR_API
/** Sets the callback to be invoked when an error occurs.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSetErrorCallback method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param callback The callback function.
 * \param user_data User context information passed to the callback. 
 * \param buffer A user-supplied buffer that contains the error parameters when 
 *               the callback is invoked. 
 * \param len The size, in bytes, of the buffer.
 *
 * \seealso{Handling errors, "http://dcx.sybase.com/goto?page=sa160/en/ulc/error-af-development.html", "ulc", "error-af-development"}
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULSetErrorCallbackW(
    SQLCA *			sqlca,
    ul_error_callback_fn_w2	callback,
    ul_void *			user_data,  // passed to callback
    ul_wchar *			buffer,	    // filled with error info and passed to callback
    size_t			len );	    // size of buffer in ul_wchars
#endif

/** Obtains a count of the number of error parameters.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \return The number of error parameters. Unless the result is zero, values 
 *         from 1 through this result can be used to call the
 *         ULGetErrorParameter method to retrieve the corresponding error 
 *         parameter value.
 *
 * \see ULGetErrorParameter 
 */
UL_FN_SPEC ul_u_long    UL_FN_MOD ULGetErrorParameterCount( SQLCA const * sqlca );

/** Retrieve error parameter via an ordinal parameter number.
 * 
 * \param sqlca	A pointer to the SQLCA.
 * \param parm_num The ordinal parameter number. 
 * \param buffer A pointer to a buffer that contains the error parameter. 
 * \param size The size, in bytes, of the buffer. 
 * \return This method returns the number of characters copied to the supplied
 *         buffer.
 *
 * \see ULGetErrorParameterCount
 */
UL_FN_SPEC size_t 	UL_FN_MOD ULGetErrorParameterA( SQLCA const * sqlca,
						       ul_u_long parm_num,
						       char * buffer,
						       size_t size );

#ifdef UL_WCHAR_API
/** Retrieve error parameter via ordinal.
 * 
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULGetErrorParameter method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param parm_num The ordinal parameter number. 
 * \param buffer Pointer to a buffer to contain the error parameter. 
 * \param size The size in bytes of the buffer. 
 * \return This method returns the number of characters copied to the supplied
 *         buffer.
 *
 * \see ULGetErrorParameterCount
 */
UL_FN_SPEC size_t 	UL_FN_MOD ULGetErrorParameterW( SQLCA const * sqlca,
						       ul_u_long parm_num,
						       ul_wchar * buffer,
						       size_t size );
#endif

#ifdef USE_CHARSET_WRAPPERS
  #ifdef UNICODE
    #define ULSetErrorCallback	ULSetErrorCallbackW
    #define ULGetErrorParameter	ULGetErrorParameterW
  #else
    #define ULSetErrorCallback	ULSetErrorCallbackA
    #define ULGetErrorParameter	ULGetErrorParameterA
  #endif
#endif

// Error-info functions

/// \internal
UL_FN_SPEC void UL_FN_MOD ULErrorInfoPushToSqlca( ul_error_info const * errinf, SQLCA * sqlca );

/** Copies the error information from the SQLCA to the ul_error_info object.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param errinf The ul_error_info object.
 */
UL_FN_SPEC void UL_FN_MOD	ULErrorInfoInitFromSqlca(
    ul_error_info *	errinf,
    SQLCA const *	sqlca
    );

/** Retrieves a description of the error.
 *
 * \param errinf The ul_error_info object.
 * \param buffer The buffer to receive the error description.
 * \param bufferSize The size, in bytes, of the buffer.
 * \return The size, in bytes, required to store the string. If the return value
 *	       is larger than the len value, the string was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoStringA(
    ul_error_info const * errinf,
    char *		buffer,
    size_t		bufferSize
    );
    
#ifdef UL_WCHAR_API
/** Retrieves a description of the error.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULErrorInfoString method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param errinf The ul_error_info object.
 * \param buffer The buffer to receive the error description.
 * \param bufferSize The size, in ul_wchars, of the buffer.
 * \return The size, in ul_wchars, required to store the string. If the return
 *         value is larger than the len value, the string was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoStringW(
    ul_error_info const * errinf,
    ul_wchar *		buffer,
    size_t		bufferSize
    );
#endif

/** Retrieves a URL to the documentation page for this error.
 *
 * \param errinf The ul_error_info object.
 * \param buffer The buffer to receive the URL.
 * \param bufferSize The size, in bytes, of the buffer.
 * \param reserved Reserved for future use.
 * \return The size, in bytes, required to store the URL. If the return value is
 *         larger than the len value, the URL was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoURLA(
    ul_error_info const * errinf,
    char *		buffer,
    size_t		bufferSize,
    char const *	reserved
    );
    
#ifdef UL_WCHAR_API
/** Retrieves a URL to the documentation page for this error.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULErrorInfoURL method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param errinf The ul_error_info object.
 * \param buffer The buffer to receive the URL.
 * \param bufferSize The size, in ul_wchars, of the buffer.
 * \param reserved Reserved for future use.
 * \return The size, in ul_wchars, required to store the URL. If the return 
 *	       value is larger than the len value, the URL was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoURLW(
    ul_error_info const * errinf,
    ul_wchar *		buffer,
    size_t		bufferSize,
    ul_wchar const *	reserved
    );
#endif

/** Retrieves the number of error parameters.
 *
 * \param errinf The ul_error_info object.
 * \return The number of error parameters.
 */
UL_FN_SPEC ul_u_short UL_FN_MOD	ULErrorInfoParameterCount(
    ul_error_info const * errinf
    );

/** Retrieves an error parameter by ordinal.
 * 
 * \param errinf The ul_error_info object.
 * \param parmNo The 1-based parameter ordinal.
 * \param buffer The buffer to receive parameter string.
 * \param bufferSize The size of the buffer.
 * \return The size, in bytes, required to store the parameter, or zero if the
 *         ordinal isn't valid. If the return value is larger than the 
 *         bufferSize value, the parameter was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoParameterAtA(
    ul_error_info const * errinf,
    ul_u_short		parmNo,
    char *		buffer,
    size_t		bufferSize
    );
    
#ifdef UL_WCHAR_API
/** Retrieves an error parameter by ordinal.
 * 
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULErrorInfoParameterAt method and \#define the UNICODE macro on Win32 
 * platforms.  Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * \param errinf The ul_error_info object.
 * \param parmNo The 1-based parameter ordinal.
 * \param buffer The buffer to receive parameter string.
 * \param bufferSize The size of the buffer.
 * \return The size, in bytes, required to store the parameter, or zero if the
 *         ordinal isn't valid. If the return value is larger than the 
 *         bufferSize value, the parameter was truncated.
 */
UL_FN_SPEC size_t UL_FN_MOD	ULErrorInfoParameterAtW(
    ul_error_info const * errinf,
    ul_u_short		parmNo,
    ul_wchar *		buffer,
    size_t		bufferSize
    );
#endif

#ifdef USE_CHARSET_WRAPPERS
  #ifdef UNICODE
    #define ULErrorInfoString	    ULErrorInfoStringW
    #define ULErrorInfoURL	    ULErrorInfoURLW
    #define ULErrorInfoParameterAt  ULErrorInfoParameterAtW
  #else
    #define ULErrorInfoString	    ULErrorInfoStringA
    #define ULErrorInfoURL	    ULErrorInfoURLA
    #define ULErrorInfoParameterAt  ULErrorInfoParameterAtA
  #endif
#endif

// Enable Functions:

/** Enables TCP/IP synchronization.
 *
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before the Synchronize method. 
 * If you attempt to synchronize without a preceding call to enable the 
 * synchronization type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs.
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableTcpipSynchronization( SQLCA *sqlca );

/** Enables HTTP synchronization.
 *
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before the Synchronize method. 
 * If you attempt to synchronize without a preceding call to enable the 
 * synchronization type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs.
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableHttpSynchronization( SQLCA *sqlca );

/// \internal
#define ULEnableTlsSynchronization	ULEnableTcpipSynchronization
/// \internal
#define ULEnableHttpsSynchronization	ULEnableHttpSynchronization
// currently this is enough to enable all sync types:
/// \internal
#define ULEnableAllSync			ULEnableHttpSynchronization

/** Enables RSA encryption for SSL or TLS streams.
 *
 * This is required when setting a stream parameter to TLS or HTTPS. 
 *
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before the Synchronize method. 
 * If you attempt to synchronize without a preceding call to enable the 
 * synchronization type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs. 
 *
 * \param sqlca	A pointer to the SQLCA.
 *
 * \see ULEnableRsaFipsSyncEncryption 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableRsaSyncEncryption( SQLCA *sqlca );

/** Enables RSA FIPS encryption for SSL or TLS streams.
 *
 * This is required when setting a stream parameter to TLS or HTTPS.
 *
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before the Synchronize method. If you
 * attempt to synchronize without a preceding call to enable the synchronization
 * type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs.
 *
 * \param sqlca	A pointer to the SQLCA.
 *
 * \see ULEnableRsaSyncEncryption
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableRsaFipsSyncEncryption( SQLCA *sqlca );

/** Enables ZLIB compression for a synchronization stream.
 *
 * You can use this method in C++ API applications and embedded SQL
 * applications. You must call this method before calling the Synchronize
 * method. If you attempt to synchronize without a preceding call to enable
 * the synchronization type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs.
 *
 * \param sqlca A pointer to the initialized SQLCA. 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableZlibSyncCompression( SQLCA *sqlca );

/** Enables RSA end-to-end encryption.
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableRsaE2ee( SQLCA *sqlca );

/** Enables FIPS 140-2 certified RSA end-to-end encryption.
 *
 * \param sqlca	A pointer to the SQLCA.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableRsaFipsE2ee( SQLCA *sqlca );

// General methods:

/** Performs initialization of the UltraLite runtime for embedded SQL
 * applications.
 * 
 * This method should be called once and only once per application, before any
 * other UltraLite methods have been called.
 */
UL_FN_SPEC void UL_FN_MOD ULStaticInit();

/** Performs finalization of the UltraLite runtime for embedded SQL
 * applications.
 * 
 * This method should be called once and only once per application, after which
 * no other UltraLite method should be called.
 * 
 */
UL_FN_SPEC void UL_FN_MOD ULStaticFini();

/** Returns the version number of the UltraLite runtime library.
 *
 *  \return The version number of the UltraLite runtime library.
 */
UL_FN_SPEC char const * UL_FN_MOD ULLibraryVersion( ul_arg_void );

/** Returns the version number of the RSA encryption library.
 *
 *  \return The version number of the RSA encryption library.
 */
UL_FN_SPEC char const * UL_FN_MOD ULRSALibraryVersion( ul_arg_void );


/** Truncates the table and temporarily activates the STOP SYNCHRONIZATION 
 * DELETE statement.
 *
 * \param sqlca A pointer to the SQLCA.
 * \param number The ID of the table to truncate.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_ret_void  UL_FN_MOD ULTruncateTable( SQLCA * sqlca, ul_table_num number );

/** Deletes all rows from a table.
 *
 * In some applications, you may want to delete all rows from a table before 
 * downloading a new set of data into the table. If you set the stop  
 * synchronization property on the connection, the deleted rows are not 
 * synchronized.
 *
 * <em>Note:</em> Any uncommitted inserts from other connections are not 
 * deleted. Also, any uncommitted deletes from other connections are not 
 * deleted, if the other connection does a rollback after it calls the 
 * DeleteAllRows method.
 *
 * If this table has been opened without an index, then it is considered 
 * read-only and data cannot be deleted.
 *
 * \param sqlca A pointer to the SQLCA.
 * \param number The ID of the table to truncate.
 * \return True on success; otherwise, returns False. For example, the table is
 *         not open, or there was a SQL error, and so on.
 */
UL_FN_SPEC ul_ret_void  UL_FN_MOD ULDeleteAllRows( SQLCA * sqlca, ul_table_num number );


/** Validates the database on this connection.
 *
 * Depending on the flags passed to this routine, the low level store and/or the
 * indexes can be validated. To receive information during the validation, 
 * implement a callback function and pass the address to this routine. To limit 
 * the validation to a specific table, pass in the table name or ID as the last 
 * parameter. 
 *
 * The flags parameter is combination of the following values:
 *
 * <ul>
 * <li>ULVF_TABLE
 * <li>ULVF_INDEX
 * <li>ULVF_DATABASE
 * <li>ULVF_EXPRESS
 * <li>ULVF_FULL_VALIDATE
 * </ul>
 *
 * \param sqlca A pointer to the SQLCA.
 * \param start_parms The parameter used to start the database.
 * \param table_id The ID of a specific table to validate.
 * \param flags Flags controlling the type of validation.
 * \param callback_fn The function to receive validation progress information.
 * \param user_data	User data to send back to the caller via the callback.
 * \return True on success; otherwise, returns false.
 *
 * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
 * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
 * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
 * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
 * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULValidateDatabaseA(
    SQLCA *			sqlca
    , char const *		start_parms
    , ul_table_num		table_id
    , ul_u_short		flags
    , ul_validate_callback_fn	callback_fn
    , void *			user_data );

#ifdef UL_WCHAR_API
/** Validates the database on this connection.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULValidateDatabase method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * Depending on the flags passed to this routine, the low level store and/or the
 * indexes can be validated. To receive information during the validation, 
 * implement a callback function and pass the address to this routine. To limit 
 * the validation to a specific table, pass in the table name or ID as the last 
 * parameter. 
 *
 * The flags parameter is combination of the following values:
 *
 * <ul>
 * <li>ULVF_TABLE
 * <li>ULVF_INDEX
 * <li>ULVF_DATABASE
 * <li>ULVF_EXPRESS
 * <li>ULVF_FULL_VALIDATE
 * </ul>
 *
 * \param sqlca A pointer to the SQLCA.
 * \param start_parms The parameter used to start the database.
 * \param table_id The ID of a specific table to validate.
 * \param flags Flags controlling the type of validation.
 * \param callback_fn The function to receive validation progress information.
 * \param user_data User data to send back to the caller via the callback.
 * \return True on success; otherwise, returns false.
 *
 * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
 * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
 * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
 * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
 * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULValidateDatabaseW(
    SQLCA *			sqlca
    , ul_wchar const *		start_parms
    , ul_table_num		table_id
    , ul_u_short		flags
    , ul_validate_callback_fn	callback_fn
    , void *			user_data );
#endif

/** Validates the database on this connection.
 *
 * Depending on the flags passed to this routine, the low level store and/or the
 * indexes can be validated. To receive information during the validation, 
 * implement a callback function and pass the address to this routine. To limit 
 * the validation to a specific table, pass in the table name or ID as the last 
 * parameter. 
 *
 * The flags parameter is combination of the following values:
 *
 * <ul>
 * <li>ULVF_TABLE
 * <li>ULVF_INDEX
 * <li>ULVF_DATABASE
 * <li>ULVF_EXPRESS
 * <li>ULVF_FULL_VALIDATE
 * </ul>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param start_parms The parameter used to start the database.
 * \param table_name The name of a specific table to validate.
 * \param flags Flags controlling the type of validation.
 * \param callback_fn The function to receive validation progress information.
 * \param user_data User data to send back to the caller via the callback.
 * \return True on success; otherwise, returns false.
 *
 * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
 * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
 * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
 * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
 * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULValidateDatabaseTableNameA(
    SQLCA *			sqlca
    , char const *		start_parms
    , char const *		table_name
    , ul_u_short		flags
    , ul_validate_callback_fn	callback_fn
    , void *			user_data );

#ifdef UL_WCHAR_API
/** Validates the database on this connection.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULValidateDatabaseTableName method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when
 * creating an UltraLite application.
 *
 * Depending on the flags passed to this routine, the low level store and/or the
 * indexes can be validated. To receive information during the validation, 
 * implement a callback function and pass the address to this routine. To limit 
 * the validation to a specific table, pass in the table name or ID as the last 
 * parameter. 
 *
 * The flags parameter is combination of the following values:
 *
 * <ul>
 * <li>ULVF_TABLE
 * <li>ULVF_INDEX
 * <li>ULVF_DATABASE
 * <li>ULVF_EXPRESS
 * <li>ULVF_FULL_VALIDATE
 * </ul>
 *
 * \param sqlca A pointer to the SQLCA.
 * \param start_parms The parameter used to start the database.
 * \param table_name The name of a specific table to validate.
 * \param flags Flags controlling the type of validation.
 * \param callback_fn The function to receive validation progress information.
 * \param user_data User data to send back to the caller via the callback.
 * \return True on success; otherwise, returns false.
 *
 * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
 * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
 * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
 * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
 * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULValidateDatabaseTableNameW(
    SQLCA *			sqlca
    , ul_wchar const *		start_parms
    , ul_wchar const *		table_name
    , ul_u_short		flags
    , ul_validate_callback_fn	callback_fn
    , void *			user_data );
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
        #define ULValidateDatabase	ULValidateDatabaseW
    #else
        #define ULValidateDatabase	ULValidateDatabaseA
    #endif
#endif

// Events

/** Creates an event notification queue for this connection.
 *
 * Queue names are scoped per-connection, so different connections can create 
 * queues with the same name. When an event notification is sent, all queues in 
 * the database with a matching name receive (a separate instance of) the 
 * notification. Names are case insensitive. A default queue is created on 
 * demand for each connection when calling the ULRegisterForEvent method if no
 * queue is specified. This call fails with an error if the name already exists
 * or isn't valid. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param name The name for the new queue. 
 * \param parameters Currently unused. Set to NULL. 
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULCreateNotificationQueueA(
    SQLCA *		sqlca,
    char const *	name,
    char const *	parameters );

/** Destroys the given event notification queue.
 *
 * A warning is signaled if unread notifications remain in the queue. Unread
 * notifications are discarded. A connection's default event queue, if created,
 * is destroyed when the connection is closed.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param name The name of the queue to destroy.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULDestroyNotificationQueueA(
    SQLCA *		sqlca,
    char const *	name );

/** Declares an event which can then be registered for and triggered.
 *
 * UltraLite predefines some system events triggered by operations on the
 * database or the environment. This function declares user-defined events.
 * User-defined events are triggered with ULTriggerEvent method. The event name
 * must be unique. Names are case insensitive.
 * 
 * \param sqlca	A pointer to the SQLCA.
 * \param event_name The name for the new user-defined event. 
 * \return True if the event was declared successfully; otherwise, returns false
 *         if the name is already used or not valid.
 *
 * \see ULTriggerEvent
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULDeclareEventA(
    SQLCA *		sqlca,
    char const *	event_name );

/** Registers or unregisters a queue to receive notifications of an event.
 *
 * If no queue name is supplied, the default connection queue is implied, and 
 * created if required. Certain system events allow you to specify an object 
 * name to which the event applies. For example, the TableModified event can 
 * specify the table name. Unlike the ULSendNotification method, only the
 * specific queue registered receives notifications of the event. Other queues
 * with the same name on different connections do not receive notifications,
 * unless they are also explicitly registered. 
 *
 * The predefined system events are:
 * 
 * <dl>
 * <dt>TableModified</dt>
 * <dd>Triggered when rows in a table are inserted, updated, or deleted.
 * One notification is sent per request, no matter how many rows were
 * affected by the request. The object_name parameter specifies the 
 * table to monitor. A value of "*" means all tables in the database. This 
 * event has a parameter named table_name whose value is the name of the
 * modified table.</dd>
 * <dt>Commit</dt>
 * <dd>Triggered after any commit completes. This event has no parameters.
 * </dd>
 * <dt>SyncComplete</dt>
 * <dd>Triggered after synchronization completes. This event has no
 * parameters.</dd>
 * </dl>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param event_name The system- or user-defined event to register for. 
 * \param object_name The object to which the event applies, such as a table
 *                    name.
 * \param queue_name The connection queue name. NULL denotes the default
 *                   connection queue.
 * \param register_not_unreg True to register; false to unregister. 
 * \return True if the registration succeeded; false if the queue or event does 
 *         not exist.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULRegisterForEventA(
    SQLCA *		sqlca,
    char const *	event_name,
    char const *	object_name,
    char const *	queue_name,
    ul_bool		register_not_unreg );

/** Sends a notification to all queues matching the given name.
 *
 * This includes any such queue on the current connection. This call does not 
 * block. Use the special queue name "*" to send to all queues. The given event 
 * name does not need to correspond to any system or user-defined event; it is 
 * simply passed through to identify the notification when read and has meaning 
 * only to the sender and receiver.
 *
 * The parameters value specifies a semicolon delimited name=value 
 * pairs option list. After the notification is read, the parameter values 
 * are read with the ULGetNotificationParameter method. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The connection queue name.  NULL indicates the default
 *                   connection queue.
 * \param event_name The system or user-defined event to register for.
 * \param parameters Currently unused.  Set to NULL.
 * \return The number of notifications sent (the number of matching queues).
 *
 * \see ULGetNotificationParameter
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULSendNotificationA(
    SQLCA *		sqlca,
    char const *	queue_name,
    char const *	event_name,
    char const *	parameters );

/** Trigger a user-defined event (and send notification to all registered 
 * queues).
 *
 * The parameters value specifies a semicolon delimited name=value pairs 
 * option list. After the notification is read, the parameter values are read 
 * with the ULGetNotificationParameter method.
 *
 * \param sqlca	A pointer for the SQLCA.
 * \param event_name The system or user-defined event to register for.
 * \param parameters Currently unused. Set to NULL.
 * \return The number of event notifications sent.
 *
 * \see ULGetNotificationParameter
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULTriggerEventA(
    SQLCA *		sqlca,
    char const *	event_name,
    char const *	parameters );

/** Reads an event notification.
 *
 * This call blocks until a notification is received or until the given wait 
 * period expires. Pass UL_READ_WAIT_INFINITE to the wait_ms parameter to wait
 * indefinitely.  To cancel a wait, send another notification to the given queue
 * or use the ULCancelGetNotification method. After reading a notification, use
 * the ULGetNotificationParameter method to retrieve additional parameters by
 * name.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The queue to read or NULL for the default connection queue. 
 * \param event_name_buf A buffer to hold the name of the event.
 * \param event_name_buf_len The size of the buffer in bytes.
 * \param wait_ms The time, in milliseconds, to wait (block) before returning.
 * \return True on success; otherwise, returns false.
 *
 * \see ULCancelGetNotification
 * \see ULGetNotificationParameter
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetNotificationA(
    SQLCA *		sqlca,
    char const *	queue_name,
    char *		event_name_buf,
    ul_length		event_name_buf_len,
    ul_u_long		wait_ms );

/// \internal
#define UL_READ_WAIT_INFINITE	((ul_u_long)-1)

/** Gets a parameter for the event notification just read by the 
 * ULGetNotification method.
 *
 * Only the parameters from the most recently read notification on the given 
 * queue are available. Parameters are retrieved by name. A parameter name of 
 * "*" retrieves the entire parameter string.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The queue to read or NULL for default connection queue.
 * \param parameter_name The name of the parameter to read (or "*").
 * \param value_buf A buffer to hold the parameter value.
 * \param value_buf_len  The size of the buffer in bytes.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetNotificationParameterA(
    SQLCA *		sqlca,
    char const *	queue_name,
    char const *	parameter_name,
    char *		value_buf,
    ul_length		value_buf_len );

/** Cancels any pending get-notification calls on all queues matching the given 
 * name.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The name of the queue.
 * \return The number of affected queues (not the number of blocked reads 
 * necessarily).
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULCancelGetNotificationA(
    SQLCA *		sqlca,
    char const *	queue_name );

#ifdef UL_WCHAR_API
/** Creates an event notification queue for this connection.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULCreateNotificationQueue method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * Queue names are scoped per-connection, so different connections can create 
 * queues with the same name. When an event notification is sent, all queues in 
 * the database with a matching name receive (a separate instance of) the 
 * notification. Names are case insensitive. A default queue is created on 
 * demand for each connection when calling the ULConnection.RegisterForEvent 
 * method if no queue is specified. This call fails with an error if the name
 * already exists or is not valid. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param name Name for the new queue. 
 * \param parameters Currently unused. Set to NULL. 
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULCreateNotificationQueueW(
    SQLCA *		sqlca,
    ul_wchar const *	name,
    ul_wchar const *	parameters );

/** Destroys the given event notification queue.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULDestroyNotificationQueue method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when
 * creating an UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param name The name of the queue to destroy.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULDestroyNotificationQueueW(
    SQLCA *		sqlca,
    ul_wchar const *	name );

/** Declares an event which can then be registered for and triggered.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULDeclareEvent method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param event_name The name for the new user-defined event. 
 * \return True if the event was declared successfully; false if the name is 
 *         already used or not valid.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULDeclareEventW(
    SQLCA *		sqlca,
    ul_wchar const *	event_name );

/** Registers or unregisters a queue to receive notifications of an event.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULRegisterForEvent method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * If no queue name is supplied, the default connection queue is implied, and 
 * created if required. Certain system events allow specification of an object 
 * name to which the event applies. For example, the TableModified event can 
 * specify the table name. Unlike the SendNotification method, only the specific
 * queue registered receives notifications of the event. Other queues with the
 * same name on different connections do not, unless they are also explicit 
 * registered.
 *
 * The predefined system events are:
 * 
 * <dl>
 * <dt>TableModified</td>
 * <dd>Triggered when rows in a table are inserted, updated, or deleted.  One
 * notification is sent per request, no matter how many rows were affected by
 * the request. The object_name parameter specifies the table to monitor. A 
 * value of "*" means all tables in the database. This event has a parameter
 * named table_name, whose value is the name of the modified table.</dd>
 * <dt>Commit</td>
 * <dd>Triggered after any commit completes. This event has no parameters.</dd>
 * <dt>SyncComplete</td>
 * <dd>Triggered after synchronization completes. This event has no parameters.
 * </dd>
 * </dl>
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param event_name The system or user-defined event to register for. 
 * \param object_name The object to which the event applies (like table name).
 * \param queue_name The connection queue name.  NULL means default connection
 *                   queue.
 * \param register_not_unreg True to register; false to unregister. 
 * \return True if the registration succeeded; false if the queue or event does 
 *         not exist.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULRegisterForEventW(
    SQLCA *		sqlca,
    ul_wchar const *	event_name,
    ul_wchar const *	object_name,
    ul_wchar const *	queue_name,
    ul_bool		register_not_unreg );

/** Sends a notification to all queues matching the given name.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULSendNotification method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * This includes any such queue on the current connection. This call does not 
 * block. Use the special queue name "*" to send to all queues. The given event 
 * name does not need to correspond to any system or user-defined event; it is 
 * simply passed through to identify the notification when read and has meaning 
 * only to the sender and receiver.
 *
 * The parameters value specifies a semicolon delimited name=value pairs option
 * list. After the notification is read, the parameter values are read with the
 * ULConnection.GetNotificationParameter method.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name NULL means default connection queue.
 * \param event_name The system or user-defined event to register for.
 * \param parameters Currently unused.  Set to NULL.
 * \return The number of notifications sent (the number of matching queues).
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULSendNotificationW(
    SQLCA *		sqlca,
    ul_wchar const *	queue_name,
    ul_wchar const *	event_name,
    ul_wchar const *	parameters );

/** Trigger a user-defined event (and send notification to all registered 
 * queues).
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULTriggerEvent method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * The parameters value specifies a semicolon delimited name=value pairs option
 * list. After the notification is read, the parameter values are read with the
 * GetNotificationParameter method.
 *
 * \param sqlca	A pointer for the SQLCA.
 * \param event_name The system or user-defined event to register for.
 * \param parameters Currently unused. Set to NULL.
 * \return The number of event notifications sent.
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULTriggerEventW(
    SQLCA *		sqlca,
    ul_wchar const *	event_name,
    ul_wchar const *	parameters );

/** Reads an event notification.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULGetNotification method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * This call blocks until a notification is received or until the given wait 
 * period expires. To wait indefinitely, pass UL_READ_WAIT_INFINITE to the
 * wait_ms parameter. To cancel a wait, send another notification to the given
 * queue or use the ULConnection.CancelGetNotification method. After reading a
 * notification, use the ULConnection.GetNotificationParameter method to
 * retrieve additional parameters by name.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The queue to read or NULL for default connection queue. 
 * \param event_name_buf A buffer to hold the name of the event.
 * \param event_name_buf_len The size of the buffer in ul_wchars.
 * \param wait_ms The time to wait (block) before returning.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetNotificationW(
    SQLCA *		sqlca,
    ul_wchar const *	queue_name,
    ul_wchar *		event_name_buf,
    ul_length		event_name_buf_len,
    ul_u_long		wait_ms );

/// \internal
#define UL_READ_WAIT_INFINITE	((ul_u_long)-1)


/** Gets a parameter for the event notification just read by the 
 * ULConnection.GetNotification method.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULGetNotificationParameter method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * Only the parameters from the most-recently read notification on the given 
 * queue are available. Parameters are retrieved by name. A parameter name of 
 * "*" retrieves the entire parameter string.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The queue to read or NULL for default connection queue.
 * \param parameter_name The name of the parameter to read (or "*").
 * \param value_buf A buffer to hold the parameter value.
 * \param value_buf_len  The size of the buffer in ul_wchars.
 * \return True on success; otherwise, returns false.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULGetNotificationParameterW(
    SQLCA *		sqlca,
    ul_wchar const *	queue_name,
    ul_wchar const *	parameter_name,
    ul_wchar *		value_buf,
    ul_length		value_buf_len );

/** Cancels any pending get-notification calls on all queues matching the given 
 * name.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULCancelGetNotification method and \#define the UNICODE macro on Win32
 * platforms. Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param queue_name The name of the queue.
 * \return The number of affected queues (not the number of blocked reads 
 *         necessarily).
 */
UL_FN_SPEC ul_u_long UL_FN_MOD ULCancelGetNotificationW(
    SQLCA *		sqlca,
    ul_wchar const *	queue_name );
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
        #define ULCreateNotificationQueue	ULCreateNotificationQueueW
	#define ULDestroyNotificationQueue	ULDestroyNotificationQueueW
	#define ULDeclareEvent			ULDeclareEventW
	#define ULRegisterForEvent		ULRegisterForEventW
	#define ULSendNotification		ULSendNotificationW
	#define ULTriggerEvent			ULTriggerEventW
	#define ULGetNotification		ULGetNotificationW
	#define ULGetNotificationParameter	ULGetNotificationParameterW
	#define ULCancelGetNotification		ULCancelGetNotificationW
    #else
        #define ULCreateNotificationQueue	ULCreateNotificationQueueA
	#define ULDestroyNotificationQueue	ULDestroyNotificationQueueA
	#define ULDeclareEvent			ULDeclareEventA
	#define ULRegisterForEvent		ULRegisterForEventA
	#define ULSendNotification		ULSendNotificationA
	#define ULTriggerEvent			ULTriggerEventA
	#define ULGetNotification		ULGetNotificationA
	#define ULGetNotificationParameter	ULGetNotificationParameterA
	#define ULCancelGetNotification		ULCancelGetNotificationA
    #endif
#endif

/// \internal
#define ULEnableUserAuthentication( s )

/** Grants access to an UltraLite database for a new or existing user ID with 
 * the given password.
 *
 * This method updates the password for an existing user when you specify an
 * existing user ID.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param uid A character array that holds the user ID.
 * \param pwd A character array that holds the password for the user ID.
 *
 * \see ULRevokeConnectFrom
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULGrantConnectToA(
    SQLCA * 		sqlca,
    char const *	uid,
    char const *	pwd );

#ifdef UL_WCHAR_API
/** Grants access to an UltraLite database for a new or existing user ID with 
 * the given password.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULGrantConnectTo method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * If you specify an existing user ID, this function then updates the password 
 * for the user.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param uid A character array that holds the user ID.
 * \param pwd A character array that holds the password for the user ID.
 *
 * \see ULRevokeConnectFrom
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULGrantConnectToW(
    SQLCA * 		sqlca,
    ul_wchar const *	uid,
    ul_wchar const *	pwd );
#endif

/** Revokes access from an UltraLite database for a user ID.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param uid A character array holding the user ID to be excluded from database
 *            access.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULRevokeConnectFromA(
    SQLCA * 		sqlca,
    char const *	uid );

#ifdef UL_WCHAR_API
/** Revokes access from an UltraLite database for a user ID.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULRevokeConnectFrom method and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param uid A character array holding the user ID to be excluded from database
 *            access.
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULRevokeConnectFromW(
    SQLCA * 		sqlca,
    ul_wchar const *	uid );
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
    #define ULGrantConnectTo	ULGrantConnectToW
    #define ULRevokeConnectFrom	ULRevokeConnectFromW
    #else
    #define ULGrantConnectTo	ULGrantConnectToA
    #define ULRevokeConnectFrom	ULRevokeConnectFromA
    #endif
#endif

// Persistent Store Strong Encryption
/// \internal
#define ULEnableStrongEncryption	ULEnableAesDBEncryption
/// \internal
#define ULEnableFIPSStrongEncryption	ULEnableAesFipsDBEncryption

/** Enables AES database encryption.
 *
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before calling the
 * ULInitDatabaseManager method. 
 *
 * <em>Note:</em> Calling this method causes the encryption routines to be
 * included in the application and increases the size of the application code. 
 * 
 * \param sqlca	A pointer to the initialized SQLCA. 
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableAesDBEncryption(
    SQLCA * 		sqlca );

/** Enables FIPS 140-2 certified AES database encryption.
 *
 * <em>Note:</em> Calling this method causes the appropriate routines to be 
 * included in the application and increases the size of the application code. 
 * 
 * You can use this method in C++ API applications and embedded SQL 
 * applications. You must call this method before the Synchronize method. 
 * If you attempt to synchronize without a preceding call to enable the 
 * synchronization type, the SQLE_METHOD_CANNOT_BE_CALLED error occurs. 
 *
 * \xmlonly
 * <xinclude href="../common/seplicense.xml"
 *     xmlns:xi="http://www.w3.org/2001/XInclude"></xinclude>
 * \endxmlonly
 *
 * \param sqlca	A pointer to the initialized SQLCA.
 *
 * \see ULEnableAesDBEncryption
 */
UL_FN_SPEC ul_ret_void UL_FN_MOD ULEnableAesFipsDBEncryption(
    SQLCA * 		sqlca );

/** Changes the encryption key for an UltraLite database.
 *
 * Applications that call this method must first ensure that the user has
 * either synchronized the database or created a reliable backup copy of the 
 * database. It is important to have a reliable backup of the database because 
 * this method is an operation that must run to completion. When the 
 * database encryption key is changed, every row in the database is first 
 * decrypted with the old key and then encrypted with the new key and rewritten.
 * This operation is not recoverable. If the encryption change operation does 
 * not complete, the database is left in an invalid state and you cannot access 
 * it again. 
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param new_key The new encryption key.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULChangeEncryptionKeyA(
    SQLCA *		sqlca,
    char const *	new_key );

#ifdef UL_WCHAR_API
/** Changes the encryption key for an UltraLite database.
 *
 * <em>Note:</em>This method prototype is used internally when you refer to the
 * ULChangeEncryptionKey method and \#define the UNICODE macro on Win32
 * platforms.  Typically, you would not reference this method directly when 
 * creating an UltraLite application.
 *
 * Applications that call this function must first ensure that the user has
 * either synchronized the database or created a reliable backup copy of the 
 * database. It is important to have a reliable backup of the database because 
 * this method is an operation that must run to completion. When the database
 * encryption key is changed, every row in the database is first decrypted with
 * the old key and then encrypted with the new key and rewritten. This operation
 * is not recoverable. If the encryption change operation does not complete, the
 * database is left in an invalid state and you cannot access it again.
 *
 * \param sqlca	A pointer to the SQLCA.
 * \param new_key The new encryption key.
 */
UL_FN_SPEC ul_bool UL_FN_MOD ULChangeEncryptionKeyW(
    SQLCA *		sqlca,
    ul_wchar const *	new_key );
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
	#define ULChangeEncryptionKey	ULChangeEncryptionKeyW
    #else
	#define ULChangeEncryptionKey	ULChangeEncryptionKeyA
    #endif
#endif

// Persistent Store Statistics
/// \internal
typedef enum {
    // cache statistics (value reset to zero on query):
    UL_STORE_STAT_PAGE_LOCKS,
    UL_STORE_STAT_PAGE_READS,
    UL_STORE_STAT_PAGE_WRITES,
    // cache size:
    UL_STORE_STAT_CACHE_PAGE_COUNT,
    UL_STORE_STAT_CACHE_MIN_PAGE_COUNT,
    UL_STORE_STAT_CACHE_MAX_PAGE_COUNT,
    // store page allocation:
    UL_STORE_STAT_ALLOCATED_BLOCKS,
    UL_STORE_STAT_TOTAL_PAGES,
    UL_STORE_STAT_ALLOCATED_PAGES,
    UL_STORE_STAT_FREE_PAGES,
    UL_STORE_STAT_SHADOW_PAGES,
    UL_STORE_STAT_PAGE_SIZE,
    // store properties:
    UL_STORE_STAT_CHECKSUM_LEVEL,
    // internal use only:
    UL_STORE_STAT_CACHE_CURR_LOCK_COUNT,
    UL_STORE_STAT_CACHE_DIRTY_PAGE_COUNT,
    UL_STORE_STAT_CACHE_MEM_FREE,
    //
    UL_STORE_STAT_CHECKPOINT_COUNT,
    UL_STORE_STAT_WORKING_SPACE_EXHAUSTED,
    UL_STORE_STAT_LOCKED_BLOCK_COUNT,
    UL_STORE_STAT_LOCKED_BLOCK_PAGES,
    UL_STORE_STAT_OUTSTANDING_LOCKS,
    UL_STORE_STAT_FILENAME,
    // internal system level:
    UL_STORE_STAT_CURR_EXTENT,
    // row cache stats
    UL_ROW_CACHE_STAT_HITS,
    UL_ROW_CACHE_STAT_MISSES,
    UL_ROW_CACHE_STAT_ROW_COUNT,
    UL_ROW_CACHE_STAT_BUCKET_COUNT,
    UL_ROW_CACHE_STAT_LARGEST_BUCKET_SIZE,
    UL_ROW_CACHE_STAT_TOTAL_MEMORY,
    UL_ROW_CACHE_STAT_USED_MEMORY,
    UL_ROW_CACHE_STAT_MEMORY_USAGE,
    // large memory allocator stats
    UL_MEM_ALLOC_STAT_SEGMENT_SIZE,
    UL_MEM_ALLOC_STAT_MIN_SEGMENT_COUNT,
    UL_MEM_ALLOC_STAT_MAX_SEGMENT_COUNT,
    UL_MEM_ALLOC_STAT_CUR_SEGMENT_COUNT
} ul_store_stat_type;

/// \internal
UL_FN_SPEC ul_u_big UL_FN_MOD ULStoreQueryStatistic(
    SQLCA *		sqlca,
    ul_store_stat_type	type );

/// \internal
typedef enum {
    UL_STORE_CTL_SET_CACHE_PAGE_COUNT, // return: resulting cache page count
    UL_STORE_CTL_CHECK_CACHE_SIZE, // return: resulting cache page count
} ul_store_ctl_cmd;

/// \internal
UL_FN_SPEC ul_u_long UL_FN_MOD ULStoreControl(
    SQLCA *		sqlca,
    ul_store_ctl_cmd	cmd,
    ul_u_long		v );

// Index statistics
/// \internal
typedef enum {
    UL_INDEX_STAT_LEAF_NEXT = 1
    , UL_INDEX_STAT_LEAF_COUNT
    , UL_INDEX_STAT_DEPTH
    , UL_INDEX_STAT_HASH
    , UL_INDEX_STAT_NODE_LIMIT
    , UL_INDEX_STAT_NODE_MIN
    , UL_INDEX_STAT_LEAF_LIMIT
    , UL_INDEX_STAT_LEAF_MIN
    , UL_INDEX_STAT_PAGE_ENTRIES
    , UL_INDEX_STAT_HASH_ROW_COUNT
    , UL_INDEX_STAT_UNIQUE_HASH_ENTRIES
    , UL_INDEX_STAT_MAX_DUPLICATE_HASH_ENTRIES
} ul_index_stat_type;


/// \internal
UL_FN_SPEC ul_u_long UL_FN_MOD ULIndexQueryStatistic(
    SQLCA *		sqlca,		// required to specify connection/db
    char const *	table_name,	// table name
    ul_index_num	iid,		// index id
    ul_index_stat_type	stat,		// stat to retrieve
    ul_u_long		data );		// stat-specific additional data (can be 0 for some)

/// \internal
UL_FN_SPEC ul_ret_void UL_FN_MOD ULIndexAnalyze(
    SQLCA *			sqlca,		// required for connection/db
    ul_u_short			flags,		// see ULVF_IDX_*
    char const *		table_name,	// table name or NULL for all tables
    char const *		index_name, 	// index name or NULL for all indexes in the table
    ul_validate_callback_fn	fn,		// callback function for results
    ul_void *			user_data );	// user-specified data

/// \internal
#define ULEnableFileDB( sqlca )

// string conversion methods

#ifdef UL_WCHAR_API
/// \internal
UL_FN_SPEC ul_buffer_length UL_FN_MOD ULConvertStringDBToWide(
    SQLCA *		sqlca,
    ul_wchar *		dst,
    ul_buffer_length	dstLen,
    const char *	src,
    ul_buffer_length	srcLen = UL_NULL_TERMINATED_STRING );
/// \internal
UL_FN_SPEC ul_buffer_length UL_FN_MOD ULConvertStringWideToDB(
    SQLCA *		sqlca,
    char *		dst,
    ul_buffer_length	dstLen,
    const ul_wchar *	src,
    ul_buffer_length	srcLen = UL_NULL_TERMINATED_STRING );
#endif
/// \internal
UL_FN_SPEC ul_compare UL_FN_MOD ULCompareStrings(
    SQLCA *		sqlca,
    const char *	str1,
    const char *	str2,
    ul_buffer_length	strLen1 = UL_NULL_TERMINATED_STRING,
    ul_buffer_length	strLen2 = UL_NULL_TERMINATED_STRING );

// Methods to set SQL errors that trigger the error callback.
/// \internal
UL_FN_SPEC void UL_FN_MOD ULSetSQLError( SQLCA * sqlca, an_sql_code code );
/// \internal
UL_FN_SPEC void UL_FN_MOD ULSetSQLErrorParm( SQLCA * sqlca, an_sql_code code, const char * fmt, ... );
/// \internal
UL_FN_SPEC void UL_FN_MOD ULSetSQLErrorParmV( SQLCA * sqlca, an_sql_code code, const char * fmt, va_list args );

// synch was changed to sync for many methods, structs, and defines.  The
// following covers will ensure code using the old names will still compile.

#ifndef DOXYGEN_IGNORE
#define ULInitSynchInfo			ULInitSyncInfo
#define ULInitSynchInfoA		ULInitSyncInfoA
#define ULInitSynchInfoW		ULInitSyncInfoW
#define ULSetSynchInfo			ULSetSyncInfo
#define ULSetSynchInfoA			ULSetSyncInfoA
#define ULSetSynchInfoW			ULSetSyncInfoW
#define ULGetSynchResult		ULGetSyncResult

// Several Register___ calls were changed to Set__.  The following covers
// will ensure code using the old names will still compile.

#define ULRegisterErrorCallback			ULSetErrorCallback
#define ULRegisterErrorCallbackA		ULSetErrorCallbackA
#define ULRegisterErrorCallbackW		ULSetErrorCallbackW
#define ULRegisterSynchronizationCallback	ULSetSynchronizationCallback
#define ULRegisterSynchronizationCallbackEx	ULSetSynchronizationCallbackEx
#endif

#ifdef __cplusplus
}
#endif

#endif // __UL_PROTOS_H__
