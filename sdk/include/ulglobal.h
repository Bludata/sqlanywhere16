// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// 0001
/** \file ulglobal.h
    UltraLite Global Definitions.
*/

#ifndef _ULGLOBAL_H_INCLUDED
#define _ULGLOBAL_H_INCLUDED

/// \internal
#define UNDER_UL_SQLPP
#ifndef SQLCAPTR
/// \internal
    #define SQLCAPTR		(&sqlca)
#endif
#include "uldef.h"
#include "sqldef.h"
#include "sqltype.h"

/// \internal
#define UL_VERSION		16000
/// \internal
#define UL_MAJOR_VERSION	16
/// \internal
#define UL_VERSION_STR		UL_TEXT("16000")

#ifdef _MSC_VER
// --- code warnings ---
#if _MSC_VER < 1300
// This error does not exist in Vc7
//// - C4761: integral size mismatch in argument; conversion supplied
#pragma warning(disable:4761)
#endif
// --- header warnings --- (these warning settings will be restored)
#pragma warning(push)
// - C4103: 'filename': used #pragma pack to change alignment
#pragma warning(disable:4103)
// - C4214: nonstandard extension used : bit field types other than int
#pragma warning(disable:4214)
#endif

#if defined(UNDER_CE) && _WIN32_WCE < 300
    #error "UltraLite applications for Windows CE must target Windows CE 3.0 or later"
#endif

#ifdef _WIN32
    #ifndef WIN32
	#define WIN32
    #endif
    #if ! defined(UNDER_CE) && !defined(UNDER_NT)
	#define UNDER_NT
    #endif
#endif

// Platforms that support 2 byte wide char Unicode entrypoints
#if defined(UNDER_CE) || defined(UNDER_NT)
    /// \internal
    #define UL_WCHAR_API
#endif
#if defined(ULPLAT_UNIXBASE) || defined(UNIX)
    #define UL_WCHAR_DATA_API
#endif

#if defined(_MSC_VER) || defined(_PUSHPOP_SUPPORTED)
#pragma pack(push,8)
#endif

/// \internal
#define UL_OFFSETOF( t, f )	offsetof(t,f)
/// \internal
#define UL_NULL			NULL

#if defined(_MSC_VER)  ||  defined(ULPLAT_GNU)  || defined(UNIX)
/// \internal
    #define UL_CONST const
#else
/// \internal
    #define UL_CONST
#endif

// use: extern UL_EXTERN_C <decl>;
#if defined( __cplusplus )
#define UL_EXTERN_C	"C"
#else
/// \internal
#define UL_EXTERN_C
#endif

#if defined(__WATCOMC__) || defined(_MSC_VER)
/// \internal
#define UL_CALLBACK_FN		__stdcall
#else
/// \internal
#define UL_CALLBACK_FN
#endif
/// \internal
#define UL_GENNED_FN_MOD UL_CALLBACK_FN // For compatibility with 9.0 and earlier code

#ifndef _ULRUN_H_INCLUDED
/// \internal
#define USE_CHARSET_WRAPPERS
#endif

/// \internal
#define UL_USE_PARM( a )	(a=a)
/// \internal
#define UL_ARRAY_SIZE( a )	(sizeof(a)/sizeof(a[0]))

/// \internal
#define UL_IS_BIT_SET( e, m )	(((e)&(m))!=0)
/// \internal
#define UL_BIT_SET( e, m )	((e) = (e)|(m))
/// \internal
#define UL_BIT_SET_T( e, m, t )	((e) = (t)((e)|(m)))
/// \internal
#define UL_BIT_RESET( e, m )	((e) = (e)&(~(m)))
/// \internal
#define UL_BIT_RESET_T( e, m, t ) ((e) = (t)((e)&(~(m))))
/// \internal
#define _UL_ABSOLUTE( l, d, s )	{ if( s < 0 ) { d = -s; } else { d = s; } }

/// \internal
#define MAX_UL_STRING		0x7ff0
/// \internal
#define MAX_UL_BINARY		0x7fff

/// \internal
#define UL_WGS84		4326
/// \internal
#define UL_DEFAULT_SRID		0
/// \internal
#define UL_UNDEF_SRID		-1
/// \internal
#define UL_UNDEF_COL_SRID	(ul_length)32767
/// \internal
#define UL_WGS84_MAJOR		6378137.0
/// \internal
#define UL_WGS84_MINOR		6356752.3142
/// \internal
#define UL_MAX_PLANAR_COORD	50000000.0
/// \internal
#define UL_MIN_PLANAR_COORD	-50000000.0
/// \internal
#define UL_MAX_LAT		90.0
/// \internal
#define UL_MIN_LAT		-90.0
/// \internal
#define UL_MAX_LON		180.0
/// \internal
#define UL_MIN_LON		-180.0
/// \internal
#define UL_MAX_GEOM_STRING	75

typedef asa_uint8		ul_bool;
/// \internal
#define ul_true			1
/// \internal
#define ul_false		0
/// \internal
#define ul_yes			ul_true
/// \internal
#define ul_no			ul_false

/// \internal
#define MAX_ULTRALITE_STRING	    2000
/// \internal
#define MAX_ULTRALITE_BINARY	    2000
// MAX_ULTRALITE_ROW is dependent on the store page size

typedef asa_uint16		ul_length;
typedef asa_uint8		ul_prec;
typedef asa_uint8		ul_scale;
typedef asa_uint32		ul_rs_offset;	// offset into result set

typedef char			ul_achar;
#if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //ul_wchar type
    #if defined( ULPLAT_UNIXBASE ) || defined( UNIX )
	typedef asa_uint16	ul_wchar;
    #else
	typedef wchar_t		ul_wchar;
    #endif
#endif
/// \internal
#define UL_WTEXT( s )		L##s
#ifdef UNICODE
    typedef ul_wchar		ul_char;
    /// \internal
    #define UL_TEXT( s )	L##s
#else
    typedef ul_achar		ul_char;
    /** Prepares constant strings to be compiled as single-byte strings or
     * wide-character strings.
     *
     * Use this macro to enclose all constant strings if you plan to compile the
     * application to use Unicode and non-Unicode representations of strings.
     * This macro properly defines strings in all environments and platforms.
     */
    #define UL_TEXT( s )	s
#endif

typedef asa_uint8		ul_byte;	// general byte

typedef void			(* ul_pfv)( void );

typedef asa_uint8		ul_col_domain;
typedef asa_uint16		ul_col_domain_info;
typedef asa_int32		ul_collation_no;

/// \internal
typedef struct ul_astring {
    ul_length		len;
    ul_achar		data[ MAX_UL_STRING ];
} ul_astring, * p_ul_astring;

#ifdef UL_WCHAR_API
/// \internal
typedef struct ul_wstring {
    ul_length		len;
    ul_wchar		data[ MAX_UL_STRING ];
} ul_wstring, * p_ul_wstring;
#endif

#ifdef UNICODE
    typedef ul_wstring		ul_string;
    typedef p_ul_wstring	p_ul_string;
#else
    typedef ul_astring		ul_string;
    typedef p_ul_astring	p_ul_string;
#endif

/// Sets and fetches binary values from a table in the database.
typedef struct ul_binary {
    /// The number of bytes in the value.
    ul_length		len;
    /// The actual data to be set (for insert) or that was fetched (for select).
    ul_byte		data[ MAX_UL_BINARY ];
} ul_binary, * p_ul_binary;

typedef void * p_ul_numeric;

/// \internal 
#define UL_DECL_ASTRING( size )		\
    struct {				\
	ul_length	len;		\
	ul_achar	data[ size ];	\
    }
    
/// \internal 
#define UL_DECL_WSTRING( size )		\
    struct {				\
	ul_length	len;		\
	ul_achar	data[ size ];	\
    }

/// \internal 
#define UL_DECL_STRING( size )		\
    struct {				\
	ul_length	len;		\
	ul_char		data[ size ];	\
    }

/// \internal 
#define UL_DECL_BINARY( size )		\
    struct {				\
	ul_length	len;		\
	ul_byte		data[ size ];	\
    }

/// \internal 
#define UL_DECL_NUMERIC( size )			\
    struct {					\
	ul_byte		data[ 3 + size / 2 ];	\
    }

/// \internal 
typedef struct ul_datetime {
    asa_uint32		date;		// years through minutes
    asa_uint32		seconds;	// seconds and microseconds
    asa_int16		offset;		// minutes from UTC
} ul_datetime, * p_ul_datetime;

/// \internal 
#define ul_void		void
/// \internal 
#define ul_ret_void	void			// functions returning nothing
/// \internal 
#define ul_arg_void	void			// functions with no arguments

typedef asa_int8	ul_compare;		// result of a comparison
typedef asa_uint16	ul_table_num;		// table number in database
typedef asa_uint16	ul_column_num;		// column number in database
typedef asa_uint16	ul_cursor_num;		// cursor number
typedef asa_uint16	ul_index_num;		// index number in table
typedef asa_uint16	ul_object_id;		// unique object id for systables
typedef asa_int32	ul_fetch_offset;	// EXEC SQL FETCH offset
typedef asa_uint32	ul_fetch_count;		// unsigned fetch offset
typedef asa_int8	ul_direction;		// fetch and index direction
typedef asa_uint8	ul_foreign_columns;	// return for copy_to_primary
typedef asa_uint32	ul_row_length;		// length of row
typedef ul_length	ul_value_length;	// length of value
typedef asa_uint8	ul_connection_num;	// connection number
typedef asa_uint8	ul_publication_count;	// total number of publications

// value for ul_column_num
/// \internal 
#define UL_MAX_NCOLS		0x7fff

typedef asa_uint32	ul_row_id;		// identify row within a table (3-byte rowid)

typedef asa_uint32	ul_mem_handle;		// memory handle (legacy; same as ul_stor_handle)
typedef ul_mem_handle	h_ul_index_root;	// to index root
typedef ul_mem_handle	h_ul_row;		// to row handle

typedef asa_uint8	ul_u_bit;		// 1-bit unsigned integer
typedef asa_uint8	ul_u_tiny;		// 1-byte unsigned integer
typedef asa_int16	ul_s_short;		// 2-byte signed integer
typedef asa_uint16	ul_u_short;		// 2-byte unsigned integer
typedef asa_int32	ul_s_long;		// 4-byte signed integer
typedef asa_uint32	ul_u_long;		// 4-byte unsigned integer
typedef asa_int64	ul_s_big;		// 8-byte signed integer
typedef asa_uint64	ul_u_big;		// 8-byte unsigned integer
typedef float		ul_real;		// 4-byte floating-point
typedef double		ul_double;		// 8-byte floating-point

typedef ul_u_long	ul_buffer_length;
// String length to indicate it is null-terminated.
/// \internal
#define UL_NULL_TERMINATED_STRING ((ul_buffer_length)(-1))

#if !defined(GUID_DEFINED)
/// \internal
    #define GUID_DEFINED
/// \internal
    typedef struct _GUID {
	ul_u_long	Data1;
	ul_u_short	Data2;
	ul_u_short	Data3;
	ul_byte		Data4[ 8 ];
    } GUID;
#endif

/** Represents the host variable types for a column.
 *
 * These values are used to identify the host variable type required for a
 * column, and to indicate how UltraLite should fetch values.
 */
enum ul_column_storage_type {
    UL_TYPE_BAD_INDEX,		///< Represents an invalid value
    UL_TYPE_S_LONG,		///< Represents a ul_s_long (32 bit signed int).
    UL_TYPE_U_LONG,		///< Represents a ul_u_long (32 bit unsigned int).
    UL_TYPE_S_SHORT,		///< Represents a ul_s_short (16 bit signed int).
    UL_TYPE_U_SHORT,		///< Represents a ul_u_short (16 bit unsigned int).
    UL_TYPE_S_BIG,		///< Represents a ul_s_big (64 bit signed int).
    UL_TYPE_U_BIG,		///< Represents a ul_u_big (64 bit unsigned int).
    UL_TYPE_TINY,		///< Represents a ul_byte (8 bit unsigned).
    UL_TYPE_BIT,		///< Represents a ul_byte (8 bit unsigned, 1 bit used).
    UL_TYPE_DOUBLE,		///< Represents a ul_double (double).
    UL_TYPE_REAL,		///< Represents a ul_real (float).
    UL_TYPE_BINARY,		///< Represents a ul_binary (2 byte length followed by byte array).
    UL_TYPE_TIMESTAMP_STRUCT,	///< Represents a DECL_DATETIME.
    UL_TYPE_TCHAR,		///< Represents a character array (string buffer).
    UL_TYPE_CHAR,		///< Represents a char array (string buffer).
    UL_TYPE_WCHAR,		///< Represents a ul_wchar (UTF16) array.
    UL_TYPE_GUID,		///< Represents a GUID structure.
    UL_TYPE_NULL,		///< \internal
    UL_TYPE_SIZED_BINARY,	///< \internal
    UL_TYPE_MAX_INDEX		///< \internal
};

/** Represents the SQL types for a column.
 * 
 * These values correspond to SQL column types.
 */
enum ul_column_sql_type {
    /// Represents that the column at the specified index does not exist.
    UL_SQLTYPE_BAD_INDEX,
    /// Represents that the column contains a signed long.
    UL_SQLTYPE_S_LONG,
    /// Represents that the column contains an unsigned long.
    UL_SQLTYPE_U_LONG,
    /// Represents that the column contains a signed short.
    UL_SQLTYPE_S_SHORT,
    /// Represents that the column contains an unsigned short.
    UL_SQLTYPE_U_SHORT,
    /// Represents that the column contains a signed 64-bit integer.
    UL_SQLTYPE_S_BIG,
    /// Represents that the column contains an unsigned 64-bit integer.
    UL_SQLTYPE_U_BIG,
    /// Represents that the column contains an unsigned 8-bit integer.
    UL_SQLTYPE_TINY,
    /// Represents that the column contains a 1-bit flag.
    UL_SQLTYPE_BIT,
    /// Represents that the column contains timestamp information.
    UL_SQLTYPE_TIMESTAMP,
    /// Represents that the column contains date information.
    UL_SQLTYPE_DATE,
    /// Represents that the column contains time information.
    UL_SQLTYPE_TIME,
    /// Represents that the column contains a double precision floating-point
    /// number (8 bytes).
    UL_SQLTYPE_DOUBLE,
    /// Represents that the column contains a single precision floating-point
    /// number (4 bytes).
    UL_SQLTYPE_REAL,
    /// Represents that the column contains exact numerical data, with specified
    /// precision and scale.
    UL_SQLTYPE_NUMERIC,
    /// Represents that the column contains binary data with a specified maximum
    /// length.
    UL_SQLTYPE_BINARY,
    /// Represents that the column contains character data with a specified
    /// length.
    UL_SQLTYPE_CHAR,
    /// Represents that the column contains character data with variable length.
    UL_SQLTYPE_LONGVARCHAR,
    /// Represents that the column contains binary data with variable length.
    UL_SQLTYPE_LONGBINARY,
    /// Represents that the column contains a UUID.
    UL_SQLTYPE_UUID,
    /// Represents that the column contains spatial data in the form of points.
    UL_SQLTYPE_ST_GEOMETRY,
    /// Represents that the column contains timestamp and time zone information.
    UL_SQLTYPE_TIMESTAMP_WITH_TIME_ZONE,
    /// \internal
    UL_SQLTYPE_MAX_INDEX
};

// Invalid database id for global autoincrement
/// \internal
#define UL_INVALID_DATABASE_ID	2147483647

// value for ul_mem_handle
/// \internal
#define UL_NO_MEM_HANDLE	((ul_mem_handle) 0)

// values for ul_direction
/// \internal
#define UL_FORWARD	    	1
/// \internal
#define UL_BACKWARD	   	(-1)

/// \internal
#define UL_INVALID_CURSOR_NUM   	(0xFFFF)
/// \internal
#define UL_INVALID_INDEX_NUM	   	(0xFFFF)

/** Synchronizes all tables in the database that are not marked as "no sync",
 * including tables that are not in any publication.
 *  
 * \see ul_sync_info
 * \see UL_SYNC_ALL_PUBS
 */
#define UL_SYNC_ALL      UL_TEXT("")

/** Synchronizes all tables in a publication.
 *
 * \see ul_sync_info
 * \see UL_SYNC_ALL
 */
#define UL_SYNC_ALL_PUBS UL_TEXT("*")

#ifndef UL_DISABLE_MULTITHREADING
    #if defined( WIN32 ) || defined( UNDER_VXW ) || defined( ULPLAT_UNIXBASE ) || defined( UNIX ) 
	#define UL_ENABLE_MULTITHREADING
    #endif
#endif

/** Stores complete information about an UltraLite error.
 * 
 * \apilink{ULErrorInfoString, "ulc", "ulc-ulesql-ulprotos-h-fil-ulerrorinfostring-met"}
 * \apilink{ULErrorInfoURL, "ulc", "ulc-ulesql-ulprotos-h-fil-ulerrorinfourl-met"}
 * \apilink{ULErrorInfoInitFromSqlca, "ulc", "ulc-ulesql-ulprotos-h-fil-ulerrorinfoinitfromsqlca-met"}
 * \apilink{ULErrorInfoParameterCount, "ulc", "ulc-ulesql-ulprotos-h-fil-ulerrorinfoparametercount-met"}
 * \apilink{ULErrorInfoParameterAt, "ulc", "ulc-ulesql-ulprotos-h-fil-ulerrorinfoparameterat-met"}
 */
struct ul_error_info {
    an_sql_code		sqlcode;	///< The SQLCODE value.
    ul_s_short		parms_len;	///< \internal Number of bytes stored in parms.
    char		parms[70];	///< \internal Null terminator-separated error parameters.
    ul_s_long		sqlcount;	///< The SQLCOUNT value.
};

// Error callback

/** Specifies possible error actions returned from callback.
 *
 *  Not all actions apply to all error codes.
 */ 
enum ul_error_action {
    /// Behave as if there is no error callback.
    UL_ERROR_ACTION_DEFAULT,
	/// Cancel the operation that raised the error.
    UL_ERROR_ACTION_CANCEL,
	/// Retry the operation that raised the error.
    UL_ERROR_ACTION_TRY_AGAIN,
	/// Continue execution, ignoring the operation that raised the error.
    UL_ERROR_ACTION_CONTINUE
};

/** Defines a method that is called whenever an error is signalled by the 
 * runtime.
 *
 * \param sqlca The active sqlca for the error.
 * \param user_data The user data as passed to register function.
 * \param buffer The buffer that was passed to the register function, which
 *               contains error information.
 * \return A ul_error_action value that instructs the runtime how to proceed.
 *
 * \apilink{ul_error_action, "ulc", "ulc-ulcom-ul-error-action-str"}
 * \see ULSetErrorCallbackA
 */
typedef ul_error_action (UL_CALLBACK_FN *ul_error_callback_fn_a )(
    SQLCA *		sqlca,
    ul_void *		user_data,
    char *		buffer );

#ifdef UL_WCHAR_API
/** Defines a method that is called whenever an error is signalled by the 
 * runtime.
 *
 * \param sqlca The active sqlca for the error.
 * \param user_data The user data as passed to the register function.
 * \param buffer The buffer that was passed to the register function, which
 *               contains error information.
 * \return A ul_error_action value that instructs the runtime how to proceed.
 *
 * \apilink{ul_error_action, "ulc", "ulc-ulcom-ul-error-action-str"}
 * \see ULSetErrorCallbackW
 */
typedef ul_error_action (UL_CALLBACK_FN *ul_error_callback_fn_w2 )(
    SQLCA *		sqlca,	    // active sqlca for error
    ul_void *		user_data,  // as passed to register function
    ul_wchar *		buffer );   // as passed to register function, contains error info
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
    typedef ul_error_callback_fn_w2 ul_error_callback_fn;
    #else
    typedef ul_error_callback_fn_a ul_error_callback_fn;
    #endif
#endif

// Synchronization definitions
#include "sserror.h"

/// \internal 
#define UL_STREAM_ERROR_STRING_SIZE	80

/** Stores synchronization communication stream error information.
 */
typedef struct {
    /// The specific stream error.  See the ss_error_code enumeration for
    /// possible values.
    ss_error_code	stream_error_code;
    /// A system-specific error code.  For more information about error codes,
    /// see your platform documentation.
    asa_int32		system_error_code;
    /// A string with additional information, if available, for the
    /// stream_error_code value.
    char		error_string[UL_STREAM_ERROR_STRING_SIZE];
} ul_stream_error, * p_ul_stream_error;

/** Indicates the current stage of synchronization.
 *
 * You should not assume that the synchronization states occur in the order
 * listed below.
 */
enum ul_sync_state {
    /// The synchronization is starting; initial parameter validation is
    /// complete and synchronization result will be saved.
    UL_SYNC_STATE_STARTING,
    /// Connecting to the MobiLink server.
    UL_SYNC_STATE_CONNECTING,
    /// The synchronization connection is established and initial data is about 
    /// to be sent.
    UL_SYNC_STATE_SENDING_HEADER,
    /// A table is about to be sent.
    UL_SYNC_STATE_SENDING_TABLE,
    /// Schema information or row data is being sent.
    UL_SYNC_STATE_SENDING_DATA,
    /// The upload stage is complete and state information is about to be
    /// committed.
    UL_SYNC_STATE_FINISHING_UPLOAD,
    /// About to read data from the server, starting with the upload
    /// acknowledgement.
    UL_SYNC_STATE_RECEIVING_UPLOAD_ACK,
    /// A table is about to be received.
    UL_SYNC_STATE_RECEIVING_TABLE,
    /// Data for the most recently identified table is being received.
    UL_SYNC_STATE_RECEIVING_DATA,
    /// The download stage is complete and downloaded rows are about to be
    /// committed.
    UL_SYNC_STATE_COMMITTING_DOWNLOAD,
    /// An error occurred during download and the download is being rolled back.
    UL_SYNC_STATE_ROLLING_BACK_DOWNLOAD,
    /// An acknowledgement that the download is complete is being sent.
    UL_SYNC_STATE_SENDING_DOWNLOAD_ACK,
    /// About to disconnect from the server.
    UL_SYNC_STATE_DISCONNECTING,
    /// Synchronization has completed successfully.
    UL_SYNC_STATE_DONE,
    /// Synchronization has completed, but with an error.
    UL_SYNC_STATE_ERROR
};
/// \internal
enum { UL_SYNC_STATE__COUNT = UL_SYNC_STATE_ERROR+1 };

typedef asa_uint16  ul_auth_status;
/// \internal 
#define UL_AUTH_STATUS_UNKNOWN			0
/// \internal 
#define UL_AUTH_STATUS_VALID			1
/// \internal 
#define UL_AUTH_STATUS_VALID_BUT_EXPIRES_SOON	2
/// \internal 
#define UL_AUTH_STATUS_EXPIRED			3
/// \internal 
#define UL_AUTH_STATUS_INVALID			4	// Bad userid or password
/// \internal 
#define UL_AUTH_STATUS_IN_USE			5	// userid already in use

// forward decl
struct ul_sync_status;

/** The definition for a user-provided method that is called at various
 * stages of synchronization.
 *
 * By implementing a method of this type, it's possible to receive progress
 * information while a synchronization is happening.  Notify UltraLite of this
 * method by calling the ULSetSynchronizationCallback method.
 *
 * \apilink{ULSetSynchronizationCallback, "ulc", "ulc-ulesql-ulprotos-h-fil-ulsetsynchronizationcallback-met"}
 */
typedef void(UL_CALLBACK_FN *ul_sync_observer_fn)( ul_sync_status * status );

/** Stores synchronization data.
 * 
 * Synchronization parameters control the synchronization behavior between an
 * UltraLite database and the MobiLink server. The Stream Type synchronization
 * parameter, User Name synchronization parameter, and Version synchronization
 * parameter are required. If you do not set them, the synchronization
 * method returns an error (SQLE_SYNC_INFO_INVALID or its equivalent).
 * You can only specify one of Download Only, Ping, or Upload Only at a time.
 * If you set more than one of these parameters to true, the synchronization
 * method returns an error (SQLE_SYNC_INFO_INVALID or its equivalent).
 *
 * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
 */
struct ul_sync_info_a {			// Synchronization Information
    const char *	user_name;	///< A string that the MobiLink server uses to identify a unique MobiLink user.
    const char *	password;	///< A string specifying the existing MobiLink password associated with the user name. This parameter is optional.
    const char *	new_password;	///< A string specifying a new MobiLink password associated with the user name. This parameter is optional.
    const char *	version;	///< The version string allows an UltraLite application to choose from a set of synchronization scripts. 
    const char *	stream;		///< The MobiLink network protocol to use for synchronization. 
    const char *	stream_parms;	///< The options to configure the network protocol you selected.
    ul_sync_observer_fn observer;	///< A pointer to a callback function or event handler that monitors synchronization. This parameter is optional.
    ul_void *		user_data;	///< Make application-specific information available to the synchronization observer. This parameter is optional.
    ul_bool		upload_only;	///< Do not download any changes from the consolidated database during the current synchronization. This can save communication time, especially over slow communication links.
    ul_bool		download_only;	///< Do not upload any changes from the UltraLite database during the current synchronization.
    ul_bool		send_download_ack;	///< Instructs the MobiLink server whether or not the client provides download acknowledgements.
    ul_bool		send_column_names;	///< @internal
    ul_bool		ping;		///< Confirm communications between the UltraLite client and the MobiLink server. When this parameter is set to true, no synchronization takes place.
    ul_byte		num_auth_parms; ///< The number of authentication parameters being passed to authentication parameters in MobiLink events.
    const char * *	auth_parms;	///< An array of authentication parameters in MobiLink events.
    ul_bool		keep_partial_download;	///< When a download fails because of a communications error during synchronization, this parameter controls whether UltraLite holds on to the partial download rather than rolling back the changes.
    ul_bool		resume_partial_download;///< Resume a failed download. The synchronization does not upload changes; it only downloads those changes that were to be downloaded in the failed download.
    const char *	publications;	///< A comma separated list of publications indicating what data to include in the synchronization.
    const char *	additional_parms;	///< A string of name value pairs "name=value;" with extra parameters

    // fields set on output
    ul_stream_error	stream_error;   ///< The structure to hold communications error reporting information.
    ul_bool		upload_ok;	///< The status of data uploaded to the MobiLink server. This field reports true if upload succeeded.
    ul_bool		ignored_rows;	///< The status of ignored rows. This read-only field reports true if any rows were ignored by the MobiLink server during synchronization because of absent scripts. 
    ul_auth_status	auth_status;	///< The status of MobiLink user authentication. The MobiLink server provides this information to the client.
    ul_s_long		auth_value;	///< The results of a custom MobiLink user authentication script. The MobiLink server provides this information to the client to determine the authentication status.
    ul_bool		partial_download_retained; ///< When a download fails because of a communications error during synchronization, this parameter indicates whether UltraLite applied those changes that were downloaded rather than rolling back the changes.

    // keep last:
    ul_sync_info_a *	init_verify;	///< Initialize verification.
};

#ifdef UL_WCHAR_API
/** Stores synchronization data.
 *
 * <em>Note:</em> This structure prototype is used internally when you refer to
 * ul_sync_info and \#define the UNICODE macro on Win32 platforms.
 * Typically, you would not reference this method directly when creating an
 * UltraLite application.
 * 
 * Synchronization parameters control the synchronization behavior between an
 * UltraLite database and the MobiLink server. The Stream Type synchronization
 * parameter, User Name synchronization parameter, and Version synchronization
 * parameter are required. If you do not set them, the synchronization method
 * returns an error (SQLE_SYNC_INFO_INVALID or its equivalent).  You can only
 * specify one of Download Only, Ping, or Upload Only at a time.  If you set
 * more than one of these parameters to true, the synchronization method returns
 * an error (SQLE_SYNC_INFO_INVALID or its equivalent).
 *
 * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
 *
 * \see ul_sync_info
 * \internal
 */
struct ul_sync_info_w2 {		// Synchronization Information
    const ul_wchar *	user_name;	///< A string that the MobiLink server uses to identify a unique MobiLink user.
    const ul_wchar *	password;	///< A string specifying the existing MobiLink password associated with the user name. This parameter is optional.
    const ul_wchar *	new_password;	///< A string specifying a new MobiLink password associated with the user name. This parameter is optional.
    const ul_wchar *	version;	///< The version string allows an UltraLite application to choose from a set of synchronization scripts.
    const char *	stream;		///< The MobiLink network protocol to use for synchronization.
    const ul_wchar *	stream_parms;	///< The options to configure the network protocol you selected.
    ul_sync_observer_fn observer;	///< A pointer to a callback function or event handler that monitors synchronization. This parameter is optional.
    ul_void *		user_data;	///< Make application-specific information available to the synchronization observer. This parameter is optional.
    ul_bool		upload_only;	///< Do not download any changes from the consolidated database during the current synchronization. This can save communication time, especially over slow communication links.
    ul_bool		download_only;	///< Do not upload any changes from the UltraLite database during the current synchronization.
    ul_bool		send_download_ack;	///< Instructs the MobiLink server whether or not the client provides download acknowledgements.
    ul_bool		send_column_names;	///< Deprecated.  Column names are always sent to the MobiLink server in the upload.
    ul_bool		ping;		///< Confirm communications between the UltraLite client and the MobiLink server. When this parameter is set to true, no synchronization takes place.
    ul_byte		num_auth_parms; ///< The number of authentication parameters being passed to authentication parameters in MobiLink events.
    const ul_wchar * *	auth_parms;	///< An array of authentication parameters in MobiLink events.
    ul_bool		keep_partial_download;	///< When a download fails because of a communications error during synchronization, this parameter controls whether UltraLite holds on to the partial download rather than rolling back the changes.
    ul_bool		resume_partial_download;///< Resume a failed download. The synchronization does not upload changes; it only downloads those changes that were to be downloaded in the failed download.
    const ul_wchar *	publications;	///< A comma separated list of publications indicating what data to include in the synchronization.
    const ul_wchar *	additional_parms;	///< A string of name value pairs "name=value;" with extra parameters

    // fields set on output
    ul_stream_error	stream_error;   ///< The structure to hold communications error reporting information.
    ul_bool		upload_ok;	///< The status of data uploaded to the MobiLink server. This field reports true if upload succeeded.
    ul_bool		ignored_rows;	///< The status of ignored rows. This read-only field reports true if any rows were ignored by the MobiLink server during synchronization because of absent scripts.
    ul_auth_status	auth_status;	///< The status of MobiLink user authentication. The MobiLink server provides this information to the client.
    ul_s_long		auth_value;	///< The MobiLink server provides this information to the client to determine the authentication status.
    ul_bool		partial_download_retained; ///< When a download fails because of a communications error during synchronization, this parameter indicates whether UltraLite applied those changes that were downloaded rather than rolling back the changes.

    // keep last:
    ul_sync_info_w2 *	init_verify;	///< Initialize verification.
};
#endif

#ifdef USE_CHARSET_WRAPPERS
    #ifdef UNICODE
    typedef struct ul_sync_info_w2 ul_sync_info, * p_ul_sync_info;
    #else
    typedef struct ul_sync_info_a ul_sync_info, * p_ul_sync_info;
    #endif
#endif

/** Defines a bit set in the ul_sync_status.flags field to indicate that the
 * synchronization is blocked awaiting a response from the MobiLink server.
 *
 * Identical synchronization progress messages are generated periodically while
 * this is the case.
 */
#define UL_SYNC_STATUS_FLAG_IS_BLOCKING		1

/** Reports the upload statistics of the synchronization stream.
 */
typedef struct ul_sync_stats_upload {
    ul_u_long	bytes;			///< The number of bytes currently sent.
    ul_u_long	inserts;		///< The number of rows currently inserted.
    ul_u_long	updates;		///< The number of updated rows currently sent.
    ul_u_long	deletes;		///< The number of deleted rows currently sent.
} ul_sync_stats_upload;

/** Reports the download statistics of the synchronization stream.
 */
typedef struct ul_sync_stats_download {
    ul_u_long	bytes;			///< The number of bytes currently received.
    ul_u_long	inserts;		///< The number of rows currently inserted.
    ul_u_long	updates;		///< The number of rows currently received that have been updated.
    ul_u_long	ignored_updates;	///< The number of rows in the current download that have been received and are duplicates of rows that already exist in the table.
    ul_u_long	deletes;		///< The number of rows currently received that have been deleted.
    ul_u_long	ignored_deletes;	///< The number of rows in the current download that have been received and do not exist in the table.
    ul_u_long	truncate_deletes;	///< The number of rows that have been deleted by a truncate operation.
} ul_sync_stats_download;

/** Returns synchronization progress monitoring data. 
 *
 * \see ul_sync_info_a
 * \see ul_sync_state
 */
struct ul_sync_status {				// Synchronization Progress
    ul_sync_stats_upload	sent;		///< Upload statistics.
    ul_sync_stats_download	received;	///< Download statistics.
    ul_sync_info_a *		info;		///< A pointer to the ul_sync_info_a structure.
    ul_u_short			db_table_count;	///< The number of tables in database.
    ul_u_short			table_id;	///< The current table ID that is being uploaded or downloaded (1-based). This number may skip values when not all tables are being synchronized, and is not necessarily increasing.
    char			table_name[DB_MAX_IDENTIFIER_LEN+4]; ///< The name of the current table.
    #ifdef UL_WCHAR_API
    ul_wchar			table_name_w2[DB_MAX_IDENTIFIER_LEN+2]; ///< The name of the current table.
    #endif
    ul_u_short			sync_table_count;	///< The number of tables being synchronized.
    ul_u_short			sync_table_index; ///< 1 .. sync_table_count
    ul_sync_state		state;		///< One of the many supported states.
    ul_bool			stop;		///< A boolean that cancels synchronization. A value of true means that synchronization is canceled.
    ul_u_short			flags;		///< The current synchronization flags indicating additional information relating to the current state.
    ul_void *			user_data;	///< User data passed in to the ULSetSynchronizationCallback method or set in the ul_sync_info structure.
    SQLCA *			sqlca;		///< The connection's active SQLCA.
    ul_u_long			current_download_row_count;///< The number of rows that have been downloaded so far.  This number includes duplicate rows that aren't included in received.inserts, received.updates, or received.deletes.
    ul_u_long			total_download_row_count;///< The total number of rows to be received in the download.  This number includes duplicate rows that aren't included in received.inserts, received.updates, or received.deletes.  This field is not set until the synchronization enters the UL_SYNC_STATE_RECEIVING_TABLE state for the first table.
};

/** Stores the synchronization result so that appropriate action can be taken
 * in the application.
 */
typedef struct ul_sync_result {
    ul_error_info	error_status;	///< The error status from the last synchronization. 
    ul_stream_error	stream_error;	///< The communication stream error information.
    ul_bool		upload_ok;	///< True if the upload was successful; false otherwise.
    ul_bool		ignored_rows;	///< True if uploaded rows were ignored; false otherwise.
    ul_auth_status	auth_status;	///< The synchronization authentication status.
    ul_s_long		auth_value;	///< The value used by the MobiLink server to determine the auth_status result.
    ul_bool		partial_download_retained;  ///< The value that tells you that a partial download was retained. See keep_partial_download.
    SQLDATETIME		timestamp;	///< The time and date of the last synchronization.
    ul_sync_stats_upload	sent;		///< Upload statistics.
    ul_sync_stats_download	received;	///< Download statistics.
} ul_sync_result, *p_ul_sync_result;

/// \internal -- no longer used in the new C++ interface
enum ul_table_open_type {
    /* Open the table using the primary key.  Row order is dictated by the primary key.
        No additional parameters are necessary.  */
    ul_table_open_primary_key = 1,
    /* Open the table without using an index.  The row order is arbitrary, data cannot
        be altered, and value lookup cannot be performed.  No additional parameters are
	necessary. */
    ul_table_open_no_index,
    /* Open the table using a specific index.  Row order is dictated by the named index.
        Specify the name of the index in the parameters passed to OpenTableEx(). */
    ul_table_open_with_index
};

/** Specifies possible result set or cursor states.
    \hideinitializers
*/
enum UL_RS_STATE {
    UL_RS_STATE_ERROR = -1,	///< Error.
    UL_RS_STATE_UNPREPARED = 0,	///< Not prepared.
    UL_RS_STATE_ON_ROW,		///< On a valid row.
    UL_RS_STATE_BEFORE_FIRST,	///< Before the first row.
    UL_RS_STATE_AFTER_LAST,	///< After the last row.
    UL_RS_STATE_COMPLETED	///< Closed.
};

/** Specifies possible status IDs for the UltraLite validation tool. 
 */
enum ul_validate_status_id {
    /*---------------- info ---------------------*/
    /// \internal
    UL_VALID_INFO_FIRST			= 0,
    /** No error occurred.
     */
    UL_VALID_NO_ERROR			= 0,
    /** Start validation.
    */
    UL_VALID_START			= 1,
    /** End validation.
	Parm1 tracks the resulting sqlcode, which indicates success or failure.
    */
    UL_VALID_END			= 2,
    /** Send a periodic status message while checking database pages.
	Parm1 tracks a number associated with the page.  The order is not defined.
    */
    UL_VALID_CHECKING_PAGE		= 10,
    /** Checking a table.
	Parm1 tracks the table name.
    */
    UL_VALID_CHECKING_TABLE		= 20,
    /** Checking an index.
	Parm1 stores the table name and
	parm2 stores the index name.
    */
    UL_VALID_CHECKING_INDEX		= 21,
    /** Reporting on the index hash use. (development version only)
	Parm1 tracks the table name, 
	parm2 tracks the index name,
	parm3 tracks the number of visible rows,
	parm4 tracks the number of unique hash values, and
	parm5 tracks the  maximum number of times a hash entry appears.
    */
    UL_VALID_HASH_REPORT		= 30,
    /** A redundant index was found. (development version only)
	Parm1 tracks the table name,
	parm2 tracks the redundant index name, and
	parm3 tracks the name of index that makes it redundant.
    */
    UL_VALID_REDUNDANT_INDEX		= 31,
    /** Two indexes are the same. (development version only)
	Parm1 tracks the table name,
	parm2 tracks the name of first index, and
	parm3 tracks the name of second index.
    */
    UL_VALID_DUPLICATE_INDEX		= 32,
    /// \internal
    UL_VALID_INFO_LAST			= 99,

    /*---------------- errors -------------------*/
    /// \internal
    UL_VALID_ERROR_FIRST		= 100,
    /** An error occurred accessing the database. Check the SQLCODE for more information. */
    UL_VALID_DATABASE_ERROR		= 100,
    /** Error starting the database. (for low-level access) */
    UL_VALID_STARTUP_ERROR		= 101,
    /** Error connecting to the database. */
    UL_VALID_CONNECT_ERROR		= 102,
    /** Validation process interrupted. */
    UL_VALID_INTERRUPTED		= 103,
    /** Page table is corrupt. */
    UL_VALID_CORRUPT_PAGE_TABLE		= 110,
    /** Page checksum failed.
	Parm1 tracks a number associated with the page
    */
    UL_VALID_FAILED_CHECKSUM		= 111,
    /** A page is corrupt.
	Parm1 tracks a number associated with the page.
    */
    UL_VALID_CORRUPT_PAGE		= 112,
    /** The number of rows in the index is different from the table row count.
	Parm1 tracks the table name, and
	parm2 tracks index name.
    */
    UL_VALID_ROWCOUNT_MISMATCH		= 120,
    /** There is an invalid row identifier in the index.
	Parm1 tracks the table name, and
	parm2 tracks the index name.
    */
    UL_VALID_BAD_ROWID	       		= 121,
    /// \internal
    UL_VALID_ERROR_LAST			= 199
};

/** Evaluates true if a given ul_validate_status_id is an informational status.
 *
 * \hideinitializers
 */
#define UL_VALID_IS_INFO( sid )		(/*((sid) >= UL_VALID_INFO_FIRST) &&*/ ((sid) <= UL_VALID_INFO_LAST))

/** Evaluates true if a given ul_validate_status_id is an error status.
 *
 * \hideinitializers
 */
#define UL_VALID_IS_ERROR( sid )	(((sid) >= UL_VALID_ERROR_FIRST) && ((sid) <= UL_VALID_ERROR_LAST))

/** Stores validation status information for the callback.
 */
struct ul_validate_data {
    ul_validate_status_id   status_id;		///< Indicates what is being reported in the validation process.
    ul_bool		    stop;		///< A boolean that cancels the validation.  A value of true means that validation is canceled.
    ul_u_short		    parm_count;		///< The number of parameters in the structure.

    /// \internal
    enum { MAX_DB_IDEN = DB_MAX_IDENTIFIER_LEN };

    /// \internal
    enum { MAX_PARMS = 5 };

    /// The possible parameter types.
    enum parm_type { 
	INT,		//< parameter is an integer
	STR		//< parameter is a string
    };
    /** Parameters for this validation status.
    */
    struct {
	parm_type	type;			///< Type of parameter stored
	union {
	    ul_u_long	i;			///< Parameter as an integer
	    char	s[MAX_DB_IDEN + 1];	///< Parameter as a string (this is not a wide char)
	};
    }			    parms[ MAX_PARMS ];	///< Array of parameters
    ul_void *		    user_data;		///< User-defined data pointer passed into validation routine
};

// Callback typedef for validation feedback
typedef void(UL_CALLBACK_FN *ul_validate_callback_fn)( ul_validate_data * vdata );

// Validation input flags
//
/** Used to validate table(s).
 *
 * Check that table and index row counts match.
 *
 * \apilink{ULDatabaseManager::ValidateDatabase, "ulc", "ulc-ulcpp-uldatabasemanager-cla-validatedatabase-met"}
 * \apilink{ULConnection::ValidateDatabase, "ulc", "ulc-ulcpp-ulconnection-cla-validatedatabase-met"}
 */
#define ULVF_TABLE		0x0001
/** Used to validate indexes.
 *
 * Check the integrity of the index.
 *
 * \apilink{ULDatabaseManager::ValidateDatabase, "ulc", "ulc-ulcpp-uldatabasemanager-cla-validatedatabase-met"}
 * \apilink{ULConnection::ValidateDatabase, "ulc", "ulc-ulcpp-ulconnection-cla-validatedatabase-met"}
*/
#define ULVF_INDEX		0x0002
/** Used to validate database.
 *
 * Verify all database pages using page checksums and additional checks.
 *
 * \apilink{ULDatabaseManager::ValidateDatabase, "ulc", "ulc-ulcpp-uldatabasemanager-cla-validatedatabase-met"}
 * \apilink{ULConnection::ValidateDatabase, "ulc", "ulc-ulcpp-ulconnection-cla-validatedatabase-met"}
 */
#define ULVF_DATABASE		0x0004
/** Used to perform a faster, though less thorough, validation.
 *
 * This flag modifies others specified.
 *
 * \apilink{ULDatabaseManager::ValidateDatabase, "ulc", "ulc-ulcpp-uldatabasemanager-cla-validatedatabase-met"}
 * \apilink{ULConnection::ValidateDatabase, "ulc", "ulc-ulcpp-ulconnection-cla-validatedatabase-met"}
*/
#define ULVF_EXPRESS		0x8000
/** Performs all types of validation on the database.
 *
 * \apilink{ULDatabaseManager::ValidateDatabase, "ulc", "ulc-ulcpp-uldatabasemanager-cla-validatedatabase-met"}
 * \apilink{ULConnection::ValidateDatabase, "ulc", "ulc-ulcpp-ulconnection-cla-validatedatabase-met"}
 */
#define ULVF_FULL_VALIDATE	(ULVF_TABLE|ULVF_INDEX|ULVF_DATABASE)
// Additional development version flags
/** Checks redundant indexes (development version only).
 *
 * \copydetails ULVF_TABLE
 */
#define ULVF_IDX_REDUNDANT	0x0100
/** Reports effectiveness of the index hashes (development version only).
 *
 * \copydetails ULVF_TABLE
 */
#define ULVF_IDX_HASH		0x0200

#if 0
/// \internal
enum ul_sql_passthrough_state {
    UL_SQL_PASSTHROUGH_STATE_STARTING,
    UL_SQL_PASSTHROUGH_STATE_RUNNING_SCRIPT,
    UL_SQL_PASSTHROUGH_STATE_DONE,
    UL_SQL_PASSTHROUGH_STATE_ERROR,

    UL_SQL_PASSTHROUGH_STATE_COUNT
};

/** \internal
 * SQL Passthrough status information.
 */
typedef struct {
    ul_sql_passthrough_state	state;		// current state
    ul_u_long			script_count;	// total number of scripts that will be executed
    ul_u_long			cur_script;	// current script being executed (1-based)
    ul_bool			stop;		// set to true to stop script execution
    						// can only be set in the starting state
    ul_void *			user_data;	// user data provided in register call
    SQLCA *			sqlca;
} ul_sql_passthrough_status;

/// \internal
typedef void(UL_CALLBACK_FN *ul_sql_passthrough_observer_fn)
    ( ul_sql_passthrough_status * status );
#endif

#ifdef UNDER_CE
/** Provides the name of the callback message used to indicate an ActiveSync
 * synchronization.
 * 
 * This applies to Windows Mobile applications that use ActiveSync only.
 *
 * \seealso{Adding ActiveSync synchronization to your application, "http://dcx.sybase.com/goto?page=sa160/en/ulc/activesync-synchronization-windowsce.html", "ulc", "activesync-synchronization-windowsce"}
 */
#define UL_AS_SYNCHRONIZE	UL_TEXT( "dbas_synchronize" )
#endif

#if defined(_MSC_VER) || defined(_PUSHPOP_SUPPORTED)
#pragma pack(pop)
#endif

#ifdef _MSC_VER
#pragma warning(pop)
#endif

// UltraLite uses the ASA version of SQLDAs
#include "ulprotos.h"
#include "ulsqlfuncs.h"

// synch was changed to sync for many methods, structs, and defines.  The
// following covers will ensure code using the old names will still compile.

typedef struct ul_sync_info_a	ul_synch_info_a;
#ifdef UL_WCHAR_API
typedef struct ul_sync_info_w2	ul_synch_info_w2;
#endif
#ifdef UNICODE
typedef struct ul_sync_info_w2	ul_synch_info, * p_ul_synch_info;
#else
typedef struct ul_sync_info_a	ul_synch_info, * p_ul_synch_info;
#endif
typedef struct ul_sync_result	ul_synch_result, * p_ul_synch_result;
typedef ul_sync_observer_fn	ul_synch_observer_fn;
typedef struct ul_sync_status	ul_synch_status, * p_ul_synch_status;
typedef struct ul_sync_stats	ul_synch_stats;
/// \internal
typedef ul_sync_state		ul_synch_state;

/// \internal
#define UL_SYNCH_STATE_STARTING			UL_SYNC_STATE_STARTING
/// \internal
#define UL_SYNCH_STATE_CONNECTING		UL_SYNC_STATE_CONNECTING
/// \internal
#define UL_SYNCH_STATE_SENDING_HEADER		UL_SYNC_STATE_SENDING_HEADER
/// \internal
#define UL_SYNCH_STATE_SENDING_TABLE		UL_SYNC_STATE_SENDING_TABLE
/// \internal
#define UL_SYNCH_STATE_SENDING_DATA		UL_SYNC_STATE_SENDING_DATA
/// \internal
#define UL_SYNCH_STATE_FINISHING_UPLOAD		UL_SYNC_STATE_FINISHING_UPLOAD
/// \internal
#define UL_SYNCH_STATE_RECEIVING_UPLOAD_ACK	UL_SYNC_STATE_RECEIVING_UPLOAD_ACK
/// \internal
#define UL_SYNCH_STATE_RECEIVING_TABLE		UL_SYNC_STATE_RECEIVING_TABLE
/// \internal
#define UL_SYNCH_STATE_RECEIVING_DATA		UL_SYNC_STATE_RECEIVING_DATA
/// \internal
#define UL_SYNCH_STATE_COMMITTING_DOWNLOAD	UL_SYNC_STATE_COMMITTING_DOWNLOAD
/// \internal
#define UL_SYNCH_STATE_SENDING_DOWNLOAD_ACK	UL_SYNC_STATE_SENDING_DOWNLOAD_ACK
/// \internal
#define UL_SYNCH_STATE_DISCONNECTING		UL_SYNC_STATE_DISCONNECTING
/// \internal
#define UL_SYNCH_STATE_DONE			UL_SYNC_STATE_DONE
/// \internal
#define UL_SYNCH_STATE_ERROR			UL_SYNC_STATE_ERROR
/// \internal
#define UL_SYNCH_STATE_ROLLING_BACK_DOWNLOAD	UL_SYNC_STATE_ROLLING_BACK_DOWNLOAD

/// \internal
#define UL_SYNCH_STATUS_FLAG_IS_BLOCKING	1

#endif
