// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/** \file ulcpp.h
 * UltraLite C++ interface declaration.
 */

#ifndef _ULCPP_H_INCLUDED
#define _ULCPP_H_INCLUDED

#include "ulglobal.h"
#ifndef __stdarg_h
#include <stdarg.h>
#endif

class ULDatabaseManager;
class ULConnection;
class ULPreparedStatement;
class ULResultSet;
class ULTable;
class ULResultSetSchema;
class ULDatabaseSchema;
class ULTableSchema;
class ULIndexSchema;
struct ul_receive_deploy_file_session;

/** Used when reading data with the ULResultSet.GetStringChunk or
 * ULResultSet.GetByteChunk methods.
 *
 * This value indicates that the chunk of data to be read should continue from
 * where the last chunk was read.
 *
 * \see ULResultSet::GetStringChunk, ULResultSet::GetByteChunk
 * \hideinitializers
 */
#define UL_BLOB_CONTINUE	(size_t)(-1)

/** Manages the errors returned from the UltraLite runtime.
 */
class UL_CLS_SPEC ULError {
  public:
    /** Constructs a ULError object.
     */
    ULError();
    
    /** Tests the error code.
     *
     * \return True if the current code is SQLE_NOERROR or a warning; otherwise,
     *         returns false if the current code indicates an error.
     */
    inline bool IsOK() const {
        return _info.sqlcode >= SQLE_NOERROR;
    }
    
    /** Returns the SQLCODE error code for the last operation.
     * 
     * \return The sqlcode value.
     */
    inline an_sql_code GetSQLCode() const {
	return _info.sqlcode;
    }
    
    /** Returns the description of the current error.
     * 
     * The string includes the error code and all parameters.  A full 
     * description of the error can be obtained by loading the URL returned
     * by the ULError.GetURL method.
     *
     * The output string is always null-terminated, even if the buffer is too
     * small and the string is truncated.
     *
     * \param	dst	The buffer to receive the error description.
     * \param	len	The size, in array elements, of the buffer.
     * \return The size required to store the string. The string is
     *         truncated when the return value is larger than the len value.
     *
     * \see GetURL
     */
    inline size_t GetString( char * dst, size_t len ) const {
	return ULErrorInfoStringA( &_info, dst, len );
    }

    #ifdef UL_WCHAR_API
    /** \copydoc GetString
     */
    inline size_t GetString( ul_wchar * dst, size_t len ) const {
	return ULErrorInfoStringW( &_info, dst, len );
    }
    #endif

    /** Returns a value that depends on the last operation, and the result of
     * that operation.
     *
     * The following list outlines the possible operations, and their returned 
     * results:
     *
     * <dl>
     * <dt>INSERT, UPDATE, or DELETE operation executed successfully</dt>
     * <dd>Returns the number of rows that were affected by the statement.</dd>
     * <dt>SQL statement syntax error (SQLE_SYNTAX_ERROR)</dt>
     * <dd>Returns the approximate character position within the statement where
     * the error was detected.</dd>
     * </dl>
     *
     * \return The value for the last operation, if applicable; otherwise,
     *         returns -1 if not applicable.
     */
    inline ul_s_long GetSQLCount() const {
	return _info.sqlcount;
    }

    /** Clears the current error.
     * 
     * The current error is cleared automatically on most calls, so this is not
     * normally called by applications.
     */
    void Clear();

    /** Returns the number of error parameters.
     * 
     * \return The number of error parameters.
     */
    inline ul_u_short GetParameterCount() const {
	return ULErrorInfoParameterCount( &_info );
    }

    /** Copies the specified error parameter into the provided buffer.
     *
     * The output string is always null-terminated, even when the buffer is too
     * small and the string is truncated.
     * 
     * \param parmNo A 1-based parameter number.
     * \param dst The buffer to receive the parameter.
     * \param len The size of the buffer.
     * \return The size required to store the parameter, or zero if the ordinal
     *         is not valid. The parameter is truncated if the return value is 
     *         larger than the len value.
     */
    inline size_t GetParameter( ul_u_short parmNo, char * dst, size_t len ) const {
	return ULErrorInfoParameterAtA( &_info, parmNo, dst, len );
    }
    
    #ifdef UL_WCHAR_API
    /** Copies the specified error parameter into the provided buffer.
     *
     * \copydetails GetParameter
     */
    inline size_t GetParameter( ul_u_short parmNo, ul_wchar * dst, size_t len ) const {
	return ULErrorInfoParameterAtW( &_info, parmNo, dst, len );
    }
    #endif

    /** Returns a URL to the documentation page for this error.
     *
     * \param buffer  The buffer to receive the URL.
     * \param len The size of the buffer.
     * \param reserved Reserved for future use; you must pass NULL, the default.
     * \return The size required to store the URL. The URL is truncated if the 
     *         return value is larger is larger than the len value.
    */
    inline size_t GetURL( char * buffer, size_t len, const char * reserved = UL_NULL ) const {
	return ULErrorInfoURLA( &_info, buffer, len, reserved );
    }

    #ifdef UL_WCHAR_API
    /** Returns a URL to the documentation page for this error.
     *
     * \copydetails GetURL
     */
    inline size_t GetURL( ul_wchar * buffer, size_t len, const ul_wchar * reserved = UL_NULL ) const {
	return ULErrorInfoURLW( &_info, buffer, len, reserved );
    }
    #endif

    /** Returns a pointer to the underlying ul_error_info object.
     *
     * \return A pointer to the underlying ul_error_info object.
     * 
     * \apilink{ul_error_info, "ulc", "ulc-ulcom-ul-error-info-str"}
     */
    inline const ul_error_info * GetErrorInfo() const {
	return &_info;
    }
    
    /** Returns a pointer to the underlying ul_error_info object.
     *
     * \return A pointer to the underlying ul_error_info object.
     *
     * \apilink{ul_error_info, "ulc", "ulc-ulcom-ul-error-info-str"}
     */
    inline ul_error_info * GetErrorInfo() {
	return &_info;
    }
    
  private:
    ul_error_info	_info;
};

/** Defines a method that is called whenever an error is signalled by the 
 * runtime.
 *
 * The following example is a typical error callback implementation for use
 * during application development:
 * <p>
 * <pre>
 * static ul_error_action UL_CALLBACK_FN my_error_callback(
 *     const ULError *     error,
 *     void *              userData )
 * {
 *     char                buf[256];
 *
 *     (void)userData;
 *     // always ignore some errors
 *     switch( error->GetSQLCode() ) {
 *         case SQLE_NOTFOUND:
 *             return UL_ERROR_ACTION_DEFAULT;
 *         default:
 *             break;
 *     }
 *     // output error message and URL
 *     error->GetString( buf, sizeof(buf) );
 *     printf( "%s\n", buf );
 *     error->GetURL( buf, sizeof(buf) );
 *     printf( "%s\n", buf );
 *     return UL_ERROR_ACTION_DEFAULT;
 * }           
 * </pre>
 * </p>
 *
 * \param  error	A ULError object containing the error information.
 * \param  userData	The user data supplied to ULDatabaseManager::SetErrorCallback.
 * \return A ul_error_action value that instructs the runtime how to proceed.
 *
 * \apilink{ul_error_action, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-error-action-enu"}
 * \see ULDatabaseManager::SetErrorCallback
 */
typedef ul_error_action (UL_CALLBACK_FN *ul_cpp_error_callback_fn )(
    const ULError *	error,
    void *		userData );

/** Manages connections and databases.
 *
 * The Init method must be called in a thread-safe environment before any other
 * calls can be made.  The Fini method must be called in a similarly thread-safe
 * environment when finished.
 *   
 * <em>Note:</em> This class is static.  Do not create an instance of it.
 */
class UL_CLS_SPEC ULDatabaseManager {
  public:
    /** Initializes the UltraLite runtime.
     *
     * This method must be called only once by a single thread before any
     * other calls can be made.  This method is not thread-safe.
     *
     * This method does not usually fail unless memory is unavailable.
     *
     * \return True on success; otherwise, returns false.  False can also 
     *         be returned if the method is called more than once.
     */
    static bool Init();

    /** Finalizes the UltraLite runtime.
     * 
     * This method must be called only once by a single thread when the
     * application is finished.  This method is not thread-safe.
     */
    static void Fini();

    /** Sets the callback to be invoked when an error occurs.
     * 
     * This method is not thread-safe.
     *
     * \param callback The callback function.
     * \param userData User context information passed to the callback.
     */
    static void SetErrorCallback(
	ul_cpp_error_callback_fn callback,
	void *			 userData );

    /** Enables AES database encryption.
     *
     * Call this method to use AES database encryption. Use the DBKEY
     * connection parameter to specify the encryption passphrase.
     * You must call this method before opening the database connection.
     *
     * \seealso{UltraLite DBKEY connection parameter, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/key-database-connparms.html", "uladmin", "key-database-connparms"}
     */
    static void EnableAesDBEncryption();

    /** Enables FIPS 140-2 certified AES database encryption.
     *
     * Call this method to use FIPS AES database encryption. Use the DBKEY
     * connection parameter to specify the encryption passphrase.
     *
     * You must specify 'fips=yes' in the database creation parameters string.
     * You must call this method before opening the database connection.
     *
     * \xmlonly
     * <xinclude href="../common/seplicense.xml"
     *     xmlns:xi="http://www.w3.org/2001/XInclude"></xinclude>
     * \endxmlonly
     *
     * \see EnableAesDBEncryption
     * \seealso{UltraLite DBKEY connection parameter, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/key-database-connparms.html", "uladmin", "key-database-connparms"}
     */
    static void EnableAesFipsDBEncryption();

    /** Enables TCP/IP synchronization.
     *
     * You must call this method before the Synchronize method.
     *
     * When initiating synchronization, set the <b>stream</b> parameter to
     * "TCPIP".
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableTcpipSynchronization();

    /** Enables HTTP synchronization.
     *
     * You must call this method before the Synchronize method.
     *
     * When initiating synchronization, set the <b>stream</b> parameter to
     * "HTTP".
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableHttpSynchronization();

    /** Enables TLS synchronization.
     *
     * You must call this method before the Synchronize method.
     *
     * When initiating synchronization, set the <b>stream</b> parameter to
     * "TLS". Also set the network protocol certificate options.
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableTlsSynchronization();

    /** Enables HTTPS synchronization.
     *
     * You must call this method before the Synchronize method.
     *
     * When initiating synchronization, set the <b>stream</b> parameter to
     * "HTTPS". Also set the network protocol certificate options.
     * 
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableHttpsSynchronization();

    /** Enables all four types of synchronization: TCPIP, HTTP, TLS, and HTTPS.
     *
     * You must call this method before the Synchronize method.
     *
     * When initiating synchronization, set the <b>stream</b> parameter to
     * "TCPIP", "HTTP", "TLS", or "HTTPS". Also set the network protocol
     * certificate options if using TLS or HTTPS
     * 
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableAllSynchronization();

    /** Enables RSA synchronization encryption.
     *
     * You must call this method before the Synchronize method.
     *
     * This is required when setting the <b>stream</b> parameter to "TLS" or
     * "HTTPS" for RSA encryption.
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableRsaSyncEncryption();

    /** Enables FIPS 140-2 certified RSA synchronization encryption for SSL or
     * TLS streams.
     *
     * You must call this method before the Synchronize method.
     *
     * This is required when setting the <b>stream</b> parameter to "TLS" or
     * "HTTPS" for FIPS RSA encryption. In this case, the <b>fips</b> option
     * must be set to "yes".
     *
     * \see EnableRsaSyncEncryption
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableRsaFipsSyncEncryption();

    /** Enables Zlib compression for a synchronization stream.
     * 
     * You must call this method before the Synchronize method.
     *
     * To use compression, set the <b>compression</b> network protocol option
     * to "zlib".
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableZlibSyncCompression();

    /** Enables RSA end-to-end encryption.
     *
     * You must call this method before the Synchronize method.
     *
     * To use end-to-end encryption, set the <b>e2ee_public_key</b> network
     * protocol option.
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableRsaE2ee();

    /** Enables FIPS 140-2 certified RSA end-to-end encryption.
     *
     * You must call this method before the Synchronize method.
     *
     * To use end-to-end encryption, set the <b>e2ee_public_key</b> network
     * protocol option.  In this case, the <b>fips</b> option must be set to
     * "yes".
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     */
    static void EnableRsaFipsE2ee();

    /** Opens a new connection to an existing database.
     *
     * The connection string is a set of option=value connection parameters
     * (semicolon separated) that indicates which database to connect to, and
     * options to use for the connection. For example, after securely
     * obtaining your encryption passphrase, the resulting connection string
     * might be: "DBF=mydb.udb;DBKEY=iyntTZld9OEa#&G".
     *
     * To get error information, pass in a pointer to a ULError object. The
     * following is a list of possible errors:
     *
     * <dl>
     * <dt>SQLE_INVALID_PARSE_PARAMETER</dt>
     *  <dd><b>connParms</b> was not formatted properly.</dd>
     * <dt>SQLE_UNRECOGNIZED_OPTION</dt>
     *     <dd>A connection option name was likely misspelled.</dd>
     * <dt>SQLE_INVALID_OPTION_VALUE</dt>
     *     <dd>A connection option value was not specified properly.</dd>
     * <dt>SQLE_ULTRALITE_DATABASE_NOT_FOUND</dt>
     *     <dd>The specified database could not be found.</dd>
     * <dt>SQLE_INVALID_LOGON</dt>
     *     <dd>You supplied an invalid user ID or an incorrect password.</dd>
     * <dt>SQLE_TOO_MANY_CONNECTIONS</dt>
     *     <dd>You exceeded the maximum number of concurrent database
     *     connections.</dd>
     * </dl>
     *
     * \param connParms	The connection string.
     * \param error An optional ULError object to return error information.
     * \param reserved Reserved for internal use.  Omit or set to null.
     * \return A new ULConnection object if the method succeeds; otherwise,
     * returns NULL.
     *
     * \seealso{UltraLite connection strings and parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/connparms-s-3590908.html", "uladmin", "connparms-s-3590908"}
     * \seealso{UltraLite connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-connparms.html", "uladmin", "fo-connparms"}
     */
    static ULConnection * OpenConnection(
        const char *	connParms,
	ULError *	error = UL_NULL,
	void *		reserved = UL_NULL );

    #ifdef UL_WCHAR_API
    /** Opens a new connection to an existing database.
     *
     * \copydetails OpenConnection
     */
    static ULConnection * OpenConnection(
        const ul_wchar *	connParms,
	ULError *		error = UL_NULL,
	void *			reserved = UL_NULL );
    #endif

    /** Erases an existing database that is not currently running.
     * 
     * \param parms The database identification parameters. (a connection
     *              string)
     * \param error An optional ULError object to receive error information.
     * \return True if the database was successfully deleted; otherwise, returns
     *         false.
    */
    static bool DropDatabase( const char * parms, ULError * error = UL_NULL );
	
    #ifdef UL_WCHAR_API
    /** Erases an existing database that is not currently running.
     *
     * \copydetails DropDatabase()
     */
    static bool DropDatabase( const ul_wchar * parms, ULError * error = UL_NULL );
    #endif

    /** Creates a new database.
     *
     * The database is created with information provided in two sets of 
     * parameters.
     *
     * The connParms parameter is a set of standard connection parameters that 
     * are applicable whenever the database is accessed, such as the file name
     * or the  encryption key.
     *
     * The createParms parameter is a set of parameters that are only relevant
     * when creating a database, such as checksum-level, page-size, collation,
     * and time and date format.
     *
     * The following code illustrates how to use the CreateDatabase method to
     * create an UltraLite database as the file <dfn>mydb.udb</dfn>:
     *
     * <pre>
     * ULConnection * conn;
     * conn = ULDatabaseManager::CreateDatabase( "DBF=mydb.udb", "checksum_level=2" );
     * if( conn != NULL ) {
     *     // success
     * } else {
     *     // unable to create
     * }
     * </pre>
     *
     * \param connParms A semicolon separated string of connection parameters, 
     *                  which are set as keyword=value pairs. The connection
     *                  string must include the name of the database. These
     *                  parameters are the same set of parameters that can be
     *                  specified when you connect to a database.
     * \param createParms A semicolon separated string of database creation 
     *                    parameters, which are set as keyword value pairs. For
     *                    example: page_size=2048;obfuscate=yes.
     * \param error An optional ULError object to receive error information.
     * \return A ULConnection object to the new database is returned if the
     *         database was created successfully.  NULL is returned if the
     *         method fails. Failure is usually caused by an invalid file name
     *         or denied access.
     *
     * \seealso{UltraLite connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-connparms.html", "uladmin", "fo-connparms"}
     * \seealso{UltraLite creation parameters, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-creationparms.html", "uladmin", "fo-creationparms"}
     */	
    static ULConnection * CreateDatabase(
        const char *	connParms,
	const char *	createParms,
	ULError *	error = UL_NULL );
	
    #ifdef UL_WCHAR_API
    /** Creates a new database.
     *
     * \copydetails CreateDatabase()
     */	
    static ULConnection * CreateDatabase(
        const ul_wchar *	connParms,
	const ul_wchar *	createParms,
	ULError *		error = UL_NULL );
    #endif

    /// \internal
    static bool CreateDatabaseFromDeployFile(
	char const *	databaseFilename, 
	char const *	encryptionPassword,
	char const *	deployFilename,
	ULError *	error,
	char const *	options = UL_NULL );

    /** Performs low level and index validation on a database.
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
     * \param connParms The parameters used to connect to the database.
     * \param flags The flags controlling the type of validation; see the 
     *              example below.
     * \param fn A function to receive validation progress information.
     * \param userData The user data to send back to the caller via the
     *                 callback.
     * \param error An optional ULError object to receive error information.
     * \return True if the validation succeeds; otherwise, returns false.
     *
     * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
     * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
     * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
     * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
     * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
     *
     * \examples
     * The following example demonstrates table and index validation in express
     * mode:
     *
     * <pre>
     * flags = ULVF_TABLE | ULVF_INDEX | ULVF_EXPRESS;
     * </pre>
     * 
     */
    static bool ValidateDatabase(
        const char *		connParms,
	ul_u_short		flags,
	ul_validate_callback_fn	fn,	
	void *			userData,
	ULError *		error = UL_NULL );
	
    #ifdef UL_WCHAR_API
    /** Performs low level and index validation on a database.
     *
     * \copydetails ValidateDatabase()
     */
    static bool ValidateDatabase(
        const ul_wchar *	connParms,
	ul_u_short		flags,
	ul_validate_callback_fn	fn,
	void *			userData,
	ULError *		error = UL_NULL );
    #endif

    /// \internal
    static ul_receive_deploy_file_session * ReceiveDeployFileBegin(
	char const *	filename,
	char const *	encryptionPassword,
	bool		resume,
	ULError *	error );

    /// \internal
    static bool ReceiveDeployFileAddData(
	ul_receive_deploy_file_session * session,
	size_t		offset, // of this chunk within the full deploy file
	void const *	buf,
	size_t		size,
	ULError *	error );

    /// \internal
    static bool ReceiveDeployFileFinish(
	ul_receive_deploy_file_session * session,
	bool		data_complete,
	ULError *	error );
};

/** Represents a connection to an UltraLite database.
 */
class ULConnection {
  public:
    /** Destroys this connection and any remaining associated objects.
     *
     * \param error An optional ULError object to receive error information.
     */
    virtual void Close( ULError * error = UL_NULL ) = 0;

    /** Gets the number of currently open child objects on the connection.
     *
     * This method can be used to detect object leaks.
     * 
     * \return The number of currently open child objects.
     */
    virtual ul_u_long GetChildObjectCount() = 0;

    /** Gets the communication area associated with this connection.
     *
     * \return A pointer to the SQLCA object for this connection.
     */
    virtual SQLCA * GetSqlca() = 0;

    /** Returns the error information associated with the last call.
     *
     * The error object whose address is returned remains valid while the
     * connection is open, but not updated automatically on subsequent calls.
     * You must call GetLastError to retrieve updated status information.
     * 
     * \return A pointer to the ULError object with information associated
     *         with the last call.
     *
     * \see ULError
     */
    virtual const ULError * GetLastError() = 0;

    /** Prepares a SQL statement.
     *
     * \param sql The SQL statement to prepare.
     * \return The ULPreparedStatement object on success; otherwise, returns 
     * NULL.
     */
    virtual ULPreparedStatement * PrepareStatement( const char * sql ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Prepares a SQL statement.
     *
     * \copydetails PrepareStatement()
     */
    virtual ULPreparedStatement * PrepareStatement( const ul_wchar * sql ) = 0;
    #endif

    /**	Opens a table.
     * 
     * The cursor position is set before the first row when the application
     * first opens a table.
     * 
     * \param tableName The name of the table to open.
     * \param indexName The name of the index to open the table on.  Pass NULL
     *                  to open on the primary key and the empty string to open
     *                  the table unordered.
     * \return The ULTable object when the call is successful; otherwise,
     *         returns NULL.
     */
    virtual ULTable * OpenTable(
        const char *	tableName,
	const char *	indexName = UL_NULL ) = 0;

    #ifdef UL_WCHAR_API
    /**	Opens a table.
     *
     * \copydetails OpenTable()
     */
    virtual ULTable * OpenTable(
        const ul_wchar * tableName,
	const ul_wchar * indexName = UL_NULL ) = 0;
    #endif

    /** Executes a SQL statement string directly.
     *
     * Use this method to execute a SELECT statement directly and retrieve a
     * single result.
     * 
     * Use the PrepareStatement method to execute a statement repeatedly with
     * variable parameters, or to fetch multiple results.
     *
     * \param sql The SQL script to execute.
     * \return True on success; otherwise, returns false.
     *
     * \see PrepareStatement
     */
    virtual bool ExecuteStatement( const char * sql ) = 0;

    #ifdef UL_WCHAR_API
    /** Executes a SQL statement directly.
     *
     * \copydetails ExecuteStatement()
     */
    virtual bool ExecuteStatement( const ul_wchar * sql ) = 0;
    #endif

    /** Executes a SQL SELECT statement directly, returning a single result.
     *
     * The dstPtr value must point to a variable of the correct type, 
     * matching the dstType value.  The dstSize parameter is only required for
     * variable-sized values, such as strings and binaries, and is otherwise
     * ignored. The variable list of parameter values must correspond to
     * parameters in the statement, and all values are assumed to be strings.
     * (internally, UltraLite casts the parameter values as required for the
     * statement)
     *
     * The following types are supported:
     * 
     * <dl>
     * <dt>UL_TYPE_BIT/UL_TYPE_TINY</dt>
     * <dd>Use variable type ul_byte (8 bit, unsigned).</dd>
     * <dt>UL_TYPE_U_SHORT/UL_TYPE_S_SHORT</dt>
     * <dd>Use variable type ul_u_short/ul_s_short (16 bit).</dd>
     * <dt>UL_TYPE_U_LONG/UL_TYPE_S_LONG</dt>
     * <dd>Use variable type ul_u_long/ul_s_long (32 bit).</dd>
     * <dt>UL_TYPE_U_BIG/UL_TYPE_S_BIG</dt>
     * <dd>Use variable type ul_u_big/ul_s_big (64 bit).</dd>
     * <dt>UL_TYPE_DOUBLE</dt>
     * <dd>Use variable type ul_double (double).</dd>
     * <dt>UL_TYPE_REAL</dt>
     * <dd>Use variable type ul_real (float).</dd>
     * <dt>UL_TYPE_BINARY</dt>
     * <dd>Use variable type ul_binary and specify <b>dstSize</b> (as in
     * GetBinary()).</dd>
     * <dt>UL_TYPE_TIMESTAMP_STRUCT</dt>
     * <dd>Use variable type DECL_DATETIME.</dd>
     * <dt>UL_TYPE_CHAR</dt>
     * <dd>Use variable type char [] (a character buffer), and set
     * <b>dstSize</b> to the size of the buffer (as in GetString()).</dd>
     * <dt>UL_TYPE_WCHAR</dt>
     * <dd>Use variable type ul_wchar [] (a wide character buffer), and
     * set <b>dstSize</b> to the size of the buffer (as in GetString()).</dd>
     * <dt>UL_TYPE_TCHAR</dt>
     * <dd>Same as UL_TYPE_CHAR or UL_TYPE_WCHAR, depending on which
     * version of the method is called.</dd>
     * </dl>
     *
     * The following example demonstrates integer fetching:
     *
     * <pre>
     * ul_u_long	val;
     * ok = conn->ExecuteScalar( &val, 0, UL_TYPE_U_LONG,
     *     "SELECT count(*) FROM t WHERE col LIKE ?", "ABC%" );
     * </pre>
     * 
     * The following example demonstrates string fetching:
     *
     * <pre>
     * char	val[40];
     * ok = conn->ExecuteScalar( &val, sizeof(val), UL_TYPE_CHAR,
     *     "SELECT uuidtostr( newid() )" );
     * </pre>
     *
     * \param dstPtr A pointer to a variable of the required type to receive the
     *               value.
     * \param dstSize The size of variable to receive value, if applicable.
     * \param dstType The type of value to retrieve.  This value must match
     *                the variable type.
     * \param sql The SELECT statement, optionally containing '?' parameters.
     * \param ... String (char *) parameter values to substitute.
     * \return True if the query is successfully executed and a value is
     *         successfully retrieved; otherwise, returns false when a value is
     *         not fetched.  Check the SQLCODE error code to determine why false
     *         is returned. The selected value is NULL if no warning or error
     *         (SQLE_NOERROR) is indicated.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual bool ExecuteScalar(
	void *			dstPtr,
	size_t			dstSize,
	ul_column_storage_type	dstType,
	const char *		sql,
	... ) = 0;

    /** Executes a SQL SELECT statement string, along with a list of
     * substitution values.
     *
     * The dstPtr value must point to a variable of the correct type, 
     * matching the dstType value.  The dstSize parameter is only required for
     * variable-sized values, such as strings and binaries, and is otherwise
     * ignored. The variable list of parameter values must correspond to
     * parameters in the statement, and all values are assumed to be strings.
     * (internally, UltraLite casts the parameter values as required for the
     * statement)
     *
     * The following types are supported:
     * 
     * <dl>
     * <dt>UL_TYPE_BIT/UL_TYPE_TINY</dt>
     * <dd>Use variable type ul_byte (8 bit, unsigned).</dd>
     * <dt>UL_TYPE_U_SHORT/UL_TYPE_S_SHORT</dt>
     * <dd>Use variable type ul_u_short/ul_s_short (16 bit).</dd>
     * <dt>UL_TYPE_U_LONG/UL_TYPE_S_LONG</dt>
     * <dd>Use variable type ul_u_long/ul_s_long (32 bit).</dd>
     * <dt>UL_TYPE_U_BIG/UL_TYPE_S_BIG</dt>
     * <dd>Use variable type ul_u_big/ul_s_big (64 bit).</dd>
     * <dt>UL_TYPE_DOUBLE</dt>
     * <dd>Use variable type ul_double (double).</dd>
     * <dt>UL_TYPE_REAL</dt>
     * <dd>Use variable type ul_real (float).</dd>
     * <dt>UL_TYPE_BINARY</dt>
     * <dd>Use variable type ul_binary and specify <b>dstSize</b> (as in
     * GetBinary()).</dd>
     * <dt>UL_TYPE_TIMESTAMP_STRUCT</dt>
     * <dd>Use variable type DECL_DATETIME.</dd>
     * <dt>UL_TYPE_CHAR</dt>
     * <dd>Use variable type char [] (a character buffer), and set
     * <b>dstSize</b> to the size of the buffer (as in GetString()).</dd>
     * <dt>UL_TYPE_WCHAR</dt>
     * <dd>Use variable type ul_wchar [] (a wide character buffer), and
     * set <b>dstSize</b> to the size of the buffer (as in GetString()).</dd>
     * <dt>UL_TYPE_TCHAR</dt>
     * <dd>Same as UL_TYPE_CHAR or UL_TYPE_WCHAR, depending on which
     * version of the method is called.</dd>
     * </dl>
     *
     * \param dstPtr A pointer to a variable of the required type to receive the
     *               value.
     * \param dstSize The size of variable to receive value, if applicable.
     * \param dstType The type of value to retrieve.  This value must match
     *                the variable type.
     * \param sql The SELECT statement, optionally containing '?' parameters.
     * \param args A list of string (char *) values to substitute.
     * \return True if the query is successfully executed and a value is
     *         successfully retrieved; otherwise, returns false when a value is
     *         not fetched.  Check the SQLCODE error code to determine why false
     *         is returned. The selected value is NULL if no warning or error
     *         (SQLE_NOERROR) is indicated.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual bool ExecuteScalarV(
	void *			dstPtr,
	size_t			dstSize,
	ul_column_storage_type	dstType,
	const char *		sql,
	va_list			args ) = 0;

    #ifdef UL_WCHAR_API
    /** Executes a SQL SELECT statement.
     *
     * \copydetails ExecuteScalar()
     */
    virtual bool ExecuteScalar(
	void *			dstPtr,
	size_t			dstSize,
	ul_column_storage_type	dstType,
	const ul_wchar *	sql,
	... ) = 0;

    /**	Executes a SQL SELECT statement, along with a list of substitution
     * values.
     *
     * \copydetails ExecuteScalarV()
     */
    virtual bool ExecuteScalarV(
	void *			dstPtr,
	size_t			dstSize,
	ul_column_storage_type	dstType,
	const ul_wchar *	sql,
	va_list			args ) = 0;
    #endif

    /** Commits the current transaction.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool Commit() = 0;

    /** Rolls back the current transaction.
     *
     * \return True on success, otherwise false.
     */
    virtual bool Rollback() = 0;
    
    /** Performs a checkpoint operation, flushing any pending committed
     * transactions to the database.
     *
     * Any current transaction is not committed by calling the Checkpoint
     *  method.  This method is used in conjunction with deferring automatic 
     * transaction checkpoints (using the <b>commit_flush</b> connection
     * parameter) as a performance enhancement.
     *
     * The Checkpoint method ensures that all pending committed transactions 
     * have been written to the database. 
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool Checkpoint() = 0;

    /** Returns an object pointer used to query the schema of the database.
     *
     * \return A ULDatabaseSchema object used to query the schema of the
     * database.
     */
    virtual ULDatabaseSchema * GetDatabaseSchema() = 0;
    
    /** Grants access to an UltraLite database for a new or existing user ID
     * with the given password.
     *
     * This method updates the password for an existing user when you specify an
     * existing user ID.
     *
     * \param uid A character array that holds the user ID. The maximum length 
     *            is 31 characters. 
     * \param pwd A character array that holds the password for the user ID.
     * \return True on success; otherwise, returns false.
     *
     * \see RevokeConnectFrom
     */
    virtual bool GrantConnectTo( const char * uid, const char * pwd ) = 0;

    #ifdef UL_WCHAR_API
    /** Grants access to an UltraLite database for a new or existing user ID
     * with the given password.
     * 
     * \copydetails GrantConnectTo()
     */
    virtual bool GrantConnectTo( const ul_wchar * uid, const ul_wchar * pwd ) = 0;
    #endif

    /** Revokes access from an UltraLite database for a user ID.
     * 
     * \param uid A character array holding the user ID to be excluded from 
     *            database access.
     * \return True on success, otherwise false.
     */
    virtual bool RevokeConnectFrom( const char * uid ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Deletes an existing user.
     *
     * \copydetails RevokeConnectFrom()
     */
    virtual bool RevokeConnectFrom( const ul_wchar * uid ) = 0;
    #endif

    /** Sets START SYNCHRONIZATION DELETE for this connection.
     *
     * \return True on success, otherwise false.
     */
    virtual bool StartSynchronizationDelete() = 0;
    
    /** Sets STOP SYNCHRONIZATION DELETE for this connection.
     *
     * \return True on success, otherwise false.
     */
    virtual bool StopSynchronizationDelete() = 0;

    /** Changes the database encryption key for an UltraLite database.
     *
     * Applications that call this method must first ensure that the user has
     * either synchronized the database or created a reliable backup copy of the 
     * database. It is important to have a reliable backup of the database
     * because the ChangeEncryptionKey method is an operation that must run to
     * completion. When the database encryption key is changed, every row in the
     * database is first decrypted with the old key and then encrypted with the
     * new key and rewritten. This operation is not recoverable. If the 
     * encryption change operation does not complete, the database is left in an
     * invalid state and you cannot access it again. 
     *
     * \param newKey The new encryption key for the database.
     * \return True on success; otherwise, returns false.
     */
    virtual bool ChangeEncryptionKey( const char * newKey ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Changes the database encryption key for an UltraLite database.
     *
     * \copydetails ChangeEncryptionKey()
     */
    virtual bool ChangeEncryptionKey( const ul_wchar * newKey ) = 0;
    #endif

    /** Obtains the value of a database property.
     *
     * The returned value points to a static buffer whose contents may be 
     * changed by any subsequent UltraLite call, so you must make a copy of the
     * value if you need to save it.
     *
     * \param propName The name of the property being requested.
     * \return A pointer to a string buffer containing the database property
     *         value is returned when run successfully; otherwise, returns NULL.
     *
     * \seealso{UltraLite database properties, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-dbprops.html", "uladmin", "fo-dbprops"}
     * \see ul_database_property_id
     *
     * \examples
     * The following example illustrates how to get the value of the CharSet
     * database property.
     *
     * <p><pre>
     * const char * charset = GetDatabaseProperty( "CharSet" );
     * </pre></p>
     */
    virtual const char * GetDatabaseProperty( const char * propName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Obtains the value of a database property.
     *
     * \copydetails GetDatabaseProperty()
     */
    virtual const ul_wchar * GetDatabaseProperty( const ul_wchar * propName ) = 0;
    #endif

    /** Obtains the integer value of a database property.
     *
     * \param propName The name of the property being requested.
     * \return If successful, the integer value of the property; otherwise,
     *         returns 0.
     *
     * \seealso{UltraLite database properties, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-dbprops.html", "uladmin", "fo-dbprops"}
     * \see ul_database_property_id
     *
     * \examples
     * The following example illustrates how to get the value of the ConnCount
     * database property.
     *
     * <p><pre>
     * unsigned connectionCount = GetDatabasePropertyInt( "ConnCount" );
     * </pre></p>
     */
    virtual ul_u_long GetDatabasePropertyInt( const char * propName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets the database property specified by the provided ul_wchars.
     *
     * \copydetails GetDatabasePropertyInt()
     */
    virtual ul_u_long GetDatabasePropertyInt( const ul_wchar * propName ) = 0;
    #endif

    /** Sets the specified database option.
     *
     * \seealso{UltraLite database options, "http://dcx.sybase.com/goto?page=sa160/en/uladmin/fo-options.html", "uladmin", "fo-options"}
     *
     * \param optName The name of the option being set.
     * \param value The new value of the option.
     * \return True on success, otherwise false.
     */
    virtual bool SetDatabaseOption(
        const char *		optName,
	const char *		value ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Sets the specified database option.
     *
     * \copydetails SetDatabaseOption()
     */
    virtual bool SetDatabaseOption(
        const ul_wchar *	optName,
	const ul_wchar *	value ) = 0;
    #endif
	
    /** Sets a database option.
     *
     * \param optName The name of the option being set.
     * \param value The new value of the option.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetDatabaseOptionInt(
        const char *		optName,
	ul_u_long		value ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Sets a database option.
     *
     * \copydetails SetDatabaseOptionInt()
     */
    virtual bool SetDatabaseOptionInt(
        const ul_wchar *	optName,
	ul_u_long		value ) = 0;
    #endif

    /** Initializes the synchronization information structure.
     *
     * Call this method before setting the values of fields in the ul_sync_info
     * structure.
     *
     * \param info A pointer to the ul_sync_info structure that holds the
     *             synchronization parameters.
     */
    virtual void InitSyncInfo( ul_sync_info_a * info ) = 0;

    #ifdef UL_WCHAR_API
    /** Initializes the synchronization information structure.
     *
     * \copydetails InitSyncInfo()
     */
    virtual void InitSyncInfo( ul_sync_info_w2 * info ) = 0;
    #endif

    /** Creates a synchronization profile using the given name based on the 
     * given ul_sync_info structure.
     * 
     * The synchronization profile replaces any previous profile with the same 
     * name. The named profile is deleted by specifying a null pointer for the
     * structure.
     *
     * \param profileName The name of the synchronization profile.
     * \param info A pointer to the ul_sync_info structure that holds
     *             the synchronization parameters.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetSyncInfo( char const * profileName, ul_sync_info_a * info ) = 0;

    #ifdef UL_WCHAR_API
    /** Creates a synchronization profile.
     *
     * \copydetails SetSyncInfo()
     */
    virtual bool SetSyncInfo( const ul_wchar * profileName, ul_sync_info_w2 * info ) = 0;
    #endif

    /** Initiates synchronization in an UltraLite application.
     *
     * This method initiates synchronization with the MobiLink server.
     * This method does not return until synchronization is complete, however
     * additional threads on separate connections may continue to access the
     * database during synchronization.
     *
     * Before calling this method, enable the protocol and encryption you are
     * using with methods in the ULDatabaseManager class. For example, when
     * using "HTTP", call the ULDatabaseManager.EnableHttpSynchronization
     * method.
     *
     * \seealso{MobiLink client network protocol options, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-conparm.html", "mlclient", "mc-conparm"}
     *
     * The following example demonstrates database synchronization:
     *
     * <pre>
     * ul_sync_info info;
     * conn->InitSyncInfo( &info );
     * info.user_name = "my_user";
     * info.version = "myapp_1_2";
     * info.stream = "HTTP";
     * info.stream_parms = "host=myserver.com";
     * conn->Synchronize( &info );
     * </pre>
     *
     * \param info A pointer to the ul_sync_info structure that holds the
     *             synchronization parameters.
     * \return True on success; otherwise, returns false.
     *
     * \see ULDatabaseManager::EnableHttpSynchronization
     */
    virtual bool Synchronize( ul_sync_info_a * info ) = 0;

    #ifdef UL_WCHAR_API
    /** Synchronizes the database.
     *
     * \copydetails Synchronize()
     */
    virtual bool Synchronize( ul_sync_info_w2 * info ) = 0;
    #endif

    /** Synchronizes the database using the given profile and merge parameters.
     * 
     * This method is identical to executing the SYNCHRONIZE statement.
     *
     * \see Synchronize()
     * \seealso{SYNCHRONIZE statement [UltraLite], "http://dcx.sybase.com/goto?page=sa160/en/uladmin/ul-synchronize-statement.html", "uladmin", "ul-synchronize-statement"}
     *
     * \param profileName The name of the profile to synchronize.
     * \param mergeParms Merge parameters for the synchronization.
     * \param observer The observer callback to send status updates to.
     * \param userData User context data passed to callback.
     * \return True on success; otherwise, returns false.
    */
    virtual bool SynchronizeFromProfile(
        const char *		profileName,
	const char *		mergeParms,
	ul_sync_observer_fn	observer = UL_NULL,
	void *			userData = UL_NULL ) = 0;

    #ifdef UL_WCHAR_API
    /** Synchronize the database using the given profile and merge parameters.
     * 	
     * \copydetails SynchronizeFromProfile()
     */
    virtual bool SynchronizeFromProfile(
        const ul_wchar *	profileName,
	const ul_wchar *	mergeParms,
	ul_sync_observer_fn	observer = UL_NULL,
	void *			userData = UL_NULL ) = 0;
    #endif

    /** Rolls back the changes from a failed synchronization.
     *
     * When using resumable downloads (synchronizing with the
     * keep-partial-download option turned on), and a communication error
     * occurs during the download phase of synchronization, UltraLite retains
     * the changes which were downloaded (so the synchronization can resume from
     * the place it was interrupted).  Use this method to discard
     * this partial download when you no longer wish to attempt resuming.
     *
     * This method has effect only when using resumable downloads.
     *
     * \return True on success, otherwise false.
     */
    virtual bool RollbackPartialDownload() = 0;

    /** Gets the result of the last synchronization.
     *
     * \apilink{ul_sync_result, "ulc", "ulc-ulcom-ul-sync-result-str"}
     * 	
     * \param syncResult A pointer to the ul_sync_result structure to be
     *                   populated.
     * \return True on success, otherwise false.
     */
    virtual bool GetSyncResult( ul_sync_result * syncResult ) = 0;

    /** Gets the @@@@identity value.
     *
     * This value is the last value inserted into an autoincrement or global
     * autoincrement column for the database.  This value is not recorded when
     * the database is shutdown, so calling this method before any autoincrement
     * values have been inserted returns 0.
     *
     * <em>Note:</em> The last value inserted may have been on another
     * connection.
     * 
     * \return The last value inserted into an autoincrement or global
     *         autoincrement column
     */
    virtual ul_u_big GetLastIdentity() = 0;

    /** Obtains the percent of the default values used in all the columns that 
     * have global autoincrement defaults.
     *
     * If the database contains more than one column with this default, this
     * value is calculated for all columns and the maximum is returned. For
     * example, a return value of 99 indicates that very few default values
     * remain for at least one of the columns. 
     *
     * \return The percent of the global autoincrement values used by the
     *         counter.
     */
    virtual ul_u_short GlobalAutoincUsage() = 0;

    /** Counts the number of rows that need to be uploaded for synchronization.
     *
     * Use this method to prompt users to synchronize, or determine when
     * automatic background synchronization should take place.
     *
     * The following call checks the entire database for the total number of
     * rows to be synchronized:
     *
     * <pre>
     * count = conn->CountUploadRows( UL_SYNC_ALL, 0 );
     * </pre>
     *
     * The following call checks publications PUB1 and PUB2 for a maximum of
     * 1000 rows:
     *
     * <pre>
     * count = conn->CountUploadRows( "PUB1,PUB2", 1000 );
     * </pre>
     *
     * The following call checks to see if any rows need to be synchronized in 
     * publications PUB1 and PUB2:
     *
     * <pre>
     * anyToSync = conn->CountUploadRows( "PUB1,PUB2", 1 ) != 0;
     * </pre>
     *
     * \param pubList A string containing a comma-separated list of publications
     *                to check. An empty string (the UL_SYNC_ALL macro) implies 
     *                all tables except tables marked as "no sync". A string
     *                containing just an asterisk (the UL_SYNC_ALL_PUBS macro)
     *                implies all tables referred to in any  publication. Some
     *                tables may not be part of any publication and are not
     *                included if this value is "*". 
     * \param threshold Determines the maximum number of rows to count, thereby 
     *                  limiting the amount of time taken by the call. A
     *                  threshold of 0 corresponds to no limit (that is, count
     *                  all rows that need to be synchronized) and a threshold 
     *                  of 1 can be used to quickly determine if any rows need
     *                  to be synchronized.
     * \return The number of rows that need to be synchronized, either in a 
     *         specified set of publications or in the whole database.
     */
    virtual ul_u_long CountUploadRows( const char * pubList, ul_u_long threshold ) = 0;

    #ifdef UL_WCHAR_API
    /** Counts the number of rows that need to be uploaded for synchronization.
     *
     * \copydetails CountUploadRows()
     */
    virtual ul_u_long CountUploadRows( const ul_wchar * pubList, ul_u_long threshold ) = 0;
    #endif

    /** Obtains the last time a specified publication was downloaded.
     * 
     * The following call populates the dt structure with the date and time that
     * the 'pub1' publication was downloaded:
     *
     * <pre>
     * DECL_DATETIME dt;
     * ok = conn->GetLastDownloadTime( "pub1", &dt );
     * </pre>
     *
     * \param publication The publication name.
     * \param value A pointer to the DECL_DATETIME structure to be populated.
     *              The value of January 1, 1900 indicates that the publication
     *              has yet to be synchronized, or the time was reset.
     * \return True when the value is successfully populated by the last
     *         download time of the publication specified; otherwise, returns
     *         false.
     */
    virtual bool GetLastDownloadTime( const char * publication, DECL_DATETIME * value ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the time of the last download.
     *
     * \copydetails GetLastDownloadTime()
     */
    virtual bool GetLastDownloadTime( const ul_wchar * pubList, DECL_DATETIME * value ) = 0;
    #endif

    /** Resets the last download time of a publication so that the application
     * resynchronizes previously downloaded data.
     *
     * The following method call resets the last download time for all tables:
     *
     * <pre>
     * conn->ResetLastDownloadTime( "" );
     * </pre>
     *
     * \param pubList A string containing a comma-separated list of publications
     *                to reset. An empty string means all tables except tables
     *                marked as "no sync". A string containing just an asterisk
     *                ("*") denotes all publications. Some tables may not be
     *                part of any publication and are not included if this value
     *                is "*". 
     * \return True on success; otherwise, returns false.
     */
    virtual bool ResetLastDownloadTime( const char * pubList ) = 0;

    #ifdef UL_WCHAR_API
    /** Resets the time of the last download of the named publication.
     *
     * \copydetails ResetLastDownloadTime()
     */
    virtual bool ResetLastDownloadTime( const ul_wchar * pubList ) = 0;
    #endif

    /** Validates the database on this connection.
     * 
     * Tables, indexes, and database pages can be validated depending on the
     * flags passed to this routine.  To receive information during the
     * validation, implement a callback function and pass the address to this
     * routine.  To limit the validation to a specific table, pass in the table
     * name or ID as the last parameter.
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
     * \param flags Flags controlling the type of validation. See the example
     *              below.
     * \param fn Function to receive validation progress information.
     * \param user_data	User data to send back to the caller via the callback.
     * \param tableName	Optional.  A specific table to validate.
     * \return True on success; otherwise, returns false.
     *
     * \apilink{ULVF_TABLE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-table-var"}
     * \apilink{ULVF_INDEX, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-index-var"}
     * \apilink{ULVF_DATABASE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-database-var"}
     * \apilink{ULVF_EXPRESS, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-express-var"}
     * \apilink{ULVF_FULL_VALIDATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ulvf-full-validate-var"}
     *
     * \examples
     * The following example demonstrates table and index validation in
     * express mode:
     * <pre>
     * flags = ULVF_TABLE | ULVF_INDEX | ULVF_EXPRESS;
     * </pre>
     */
    virtual bool ValidateDatabase(
        ul_u_short		flags,
	ul_validate_callback_fn	fn,
	void *			user_data = UL_NULL,
	const char *		tableName = UL_NULL ) = 0;

    #ifdef UL_WCHAR_API
    /** Validates the database on this connection.
     *
     * \copydetails ValidateDatabase()
     */
    virtual bool ValidateDatabase(
        ul_u_short		flags,
	ul_validate_callback_fn	fn,
	void *			user_data,
	const ul_wchar *	tableName ) = 0;
    #endif

    /** Sets the callback to be invoked while performing a synchronization.
     *
     * \param callback The ul_sync_observer_fn callback.
     * \param userData User context information passed to the callback.
     */
    virtual void SetSynchronizationCallback(
        ul_sync_observer_fn	callback,
	void *			userData ) = 0;

    /** Creates an event notification queue for this connection.
     *
     * Queue names are scoped per-connection, so different connections can
     * create queues with the same name. When an event notification is sent,
     * all queues in the database with a matching name receive (a separate
     * instance of) the notification. Names are case insensitive. A default
     * queue is created on demand for each connection when calling the
     * RegisterForEvent method if no queue is specified. This call fails with an
     * error if the name already exists or isn't valid.
     * 
     * \param name The name for the new queue.
     * \param parameters Reserved.  Set to NULL.
     * \return True on success; otherwise, returns false.
     *
     * \see RegisterForEvent
     */
    virtual bool CreateNotificationQueue(
        const char *	 name,
	const char *	 parameters = UL_NULL ) = 0;

    #ifdef UL_WCHAR_API
    /** Creates an event notification queue for this connection.
     *
     * \copydetails CreateNotificationQueue()
     */
    virtual bool CreateNotificationQueue(
        const ul_wchar * name,
	const ul_wchar * parameters = UL_NULL ) = 0;
    #endif

    /** Destroys the given event notification queue.
     *
     * A warning is signaled if unread notifications remain in the queue.
     * Unread notifications are discarded. A connection's default event queue,
     * if created, is destroyed when the connection is closed.
     * 
     * \param name The name of the queue to destroy.
     * \return True on success; otherwise, returns false.
     */
    virtual bool DestroyNotificationQueue( const char *	 name ) = 0;

    #ifdef UL_WCHAR_API
    /** Destroys the given event notification queue.
     *
     * \copydetails DestroyNotificationQueue()
     */
    virtual bool DestroyNotificationQueue( const ul_wchar * name ) = 0;
    #endif
	
    /** Declares an event which can then be registered for and triggered.
     * 
     * UltraLite predefines some system events triggered by operations on the
     * database or the environment. This method declares user-defined events.
     * User-defined events are triggered with the TriggerEvent method.  The
     * event name must be unique. Names are case insensitive.
     * 
     * \param eventName The name for the new user-defined event.
     * \return True if the event was declared successfully; otherwise, returns
     *         false if the name is already used or not valid.
     *
     * \see TriggerEvent
     */
    virtual bool DeclareEvent( const char * eventName ) = 0;

    #ifdef UL_WCHAR_API
    /** Declares an event which can then be registered for and triggered.
     * 
     * \copydetails DeclareEvent()
     */
    virtual bool DeclareEvent( const ul_wchar * eventName ) = 0;
    #endif

    /** Registers or unregisters a queue to receive notifications of an event.
     * 
     * If no queue name is supplied, the default connection queue is implied,
     * and created if required. Certain system events allow you to specify an
     * object name to which the event applies. For example, the TableModified
     * event can specify the table name. Unlike the SendNotification method,
     * only the specific queue registered receives notifications of the event.
     * Other queues with the same name on different connections do not receive
     * notifications, unless they are also explicitly registered.
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
     * \param eventName The system- or user-defined event to register for.
     * \param objectName The object to which the event applies. (for example,
     *                   a table name).
     * \param queueName NULL means use the default connection queue.
     * \param register_not_unreg Set true to register, or false to unregister.
     * \return True if the registration succeeded; otherwise, returns false if
     *         the queue or event does not exist.
     */
    virtual bool RegisterForEvent(
        const char *		eventName,
	const char *		objectName,
	const char *		queueName,
	bool			register_not_unreg = true ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Registers or unregisters a queue to receive notifications of an event.
     *
     * \copydetails RegisterForEvent()
     */
    virtual bool RegisterForEvent(
        const ul_wchar *	eventName,
	const ul_wchar *	objectName,
	const ul_wchar *	queueName,
	bool			register_not_unreg = true ) = 0;
    #endif

    /** Sends a notification to all queues matching the given name.
     * 
     * This includes any such queue on the current connection. This call does
     * not block. Use the special queue name "*" to send to all queues. The
     * given event name does not need to correspond to any system or user-
     * defined event; it is simply passed through to identify the
     * notification when read and has meaning only to the sender and receiver.
     *
     * The <b>parameters</b> value specifies a semicolon delimited name=value
     * pairs option list. After the notification is read, the parameter values
     * are read with the GetNotificationParameter method.
     *
     * \param queueName The target queue name (or "*").
     * \param eventName The identity for notification.
     * \param parameters Optional parameters option list.	
     * \return The number of notifications sent. (the number of matching queues)
     *
     * \see GetNotificationParameter
     */
    virtual ul_u_long SendNotification(
        const char *		queueName,
	const char *		eventName,
	const char *		parameters ) = 0;

    #ifdef UL_WCHAR_API
    /** Send a notification to all queues matching the given name.
     * 
     * \copydetails SendNotification()
     */
    virtual ul_u_long SendNotification(
        const ul_wchar *	queueName,
	const ul_wchar *	eventName,
	const ul_wchar *	parameters ) = 0;
    #endif

    /** Triggers a user-defined event and sends notifications to all registered
     * queues.
     *
     * The <b>parameters</b> value specifies a semicolon delimited name=value
     * pairs option list. After the notification is read, the parameter values
     * are read with GetNotificationParameter().
     *
     * \param eventName The name of the system or user-defined event to trigger.
     * \param parameters Optional parameters option list.	
     * \return The number of event notifications sent.
     *
     * \see GetNotificationParameter
     */
    virtual ul_u_long TriggerEvent(
        const char *		eventName,
	const char *		parameters ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Triggers a user-defined event and sends notifications to all registered 
     * queues.
     *
     * \copydetails TriggerEvent()
     */
    virtual ul_u_long TriggerEvent(
        const ul_wchar *	eventName,
	const ul_wchar *	parameters ) = 0;
    #endif

    /** Reads an event notification.
     * 
     * This call blocks until a notification is received or until the given
     * wait period expires. To wait indefinitely, set the waitms parameter to 
     * UL_READ_WAIT_INFINITE. To cancel a wait, send another notification to the 
     * given queue or use the CancelGetNotification method.  Use the
     * GetNotificationParameter method after reading a notification to retrieve
     * additional parameters by name.
     * 
     * \param queueName The queue to read or NULL for the default connection
     *                  queue.
     * \param waitms The time, in milliseconds to wait (block) before returning.
     * \return The name of the event read or NULL on error.
     *
     * \see CancelGetNotification
     * \see GetNotificationParameter
     */
    virtual const char * GetNotification(
        const char *		queueName,
	ul_u_long		waitms ) = 0;

    #ifdef UL_WCHAR_API
    /** Reads an event notification.
     *
     * \copydetails GetNotification
     */
    virtual const ul_wchar * GetNotification(
    	const ul_wchar *	queueName,
	ul_u_long		waitms ) = 0;
    #endif
	
    /** Gets a parameter for the event notification just read by the
     * GetNotification method.
     *
     * Only the parameters from the most recently read notification on the
     * given queue are available.  Parameters are retrieved by name. A
     * parameter name of "*" retrieves the entire parameter string.
     *
     * \param queueName The queue to read or NULL for default connection queue.
     * \param parameterName The name of the parameter to read (or "*").
     * \return The parameter value or NULL on error.
     *
     * \see GetNotification
     */
    virtual const char * GetNotificationParameter(
        const char *		queueName,
	const char *		parameterName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets a parameter for the event notification just read by the
     * GetNotification method.
     *
     * \copydetails GetNotificationParameter()
     */
    virtual const ul_wchar * GetNotificationParameter(
        const ul_wchar *	queueName,
	const ul_wchar *	parameterName ) = 0;
    #endif
	
    /** Cancels any pending get-notification calls on all queues matching the
     * given name.
     * 
     * \param queueName The name of the queue.
     * \return The number of affected queues. (not the number of blocked reads
     *         necessarily)
     */
    virtual ul_u_long CancelGetNotification( const char * queueName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Cancels any pending get-notification calls on all queues matching the
     * given name.
     *
     * \copydetails CancelGetNotification()
     */
    virtual ul_u_long CancelGetNotification( const ul_wchar * queueName ) = 0;
    #endif

    /** Sets an arbitrary pointer value in the connection for use by the
     * calling application.
     *
     * This can be used to associate application data with the connection.
     *
     * \return The previously set pointer value.
     */
    virtual void * SetUserPointer( void * ptr ) = 0;

    /** Gets the pointer value last set by the SetUserPointer method.
     *
     * \see SetUserPointer
     */
    virtual void * GetUserPointer() = 0;
};

/** Represents a prepared SQL statement.
*/
class ULPreparedStatement {
  public:
    /** Destroys this object.
    */
    virtual void Close() = 0;

    /** Gets the connection object.
     *
     * \return The ULConnection object associated with this prepared statement.
     */
    virtual ULConnection * GetConnection() = 0;

    /** Gets the schema for the result set.
     *
     * \return A ULResultSetSchema object that can be used to get information
     * about the schema of the result set.
     */
    virtual const ULResultSetSchema & GetResultSetSchema() = 0;
    
    /** Executes a statement that does not return a result set, such as a SQL
     * INSERT, DELETE or UPDATE statement.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool ExecuteStatement() = 0;

    /** Executes a SQL SELECT statement as a query.
     *
     * \return The ULResultSet object that contains the results of the query,
     *         as a set of rows.
     */
    virtual ULResultSet * ExecuteQuery() = 0;

    /** Determines if the SQL statement has a result set.
     *
     * \return True if a result set is generated when this statement is
     *         executed; otherwise, returns false if no result set is generated.
     */
    virtual bool HasResultSet() = 0;

    /** Gets the number of rows affected by the last statement.
     *
     * \return The number of rows affected by the last statement.  If the
     *         number of rows is not available (for instance, the statement 
     *         alters the schema rather than data) the return value is -1.
     */
    virtual ul_s_long GetRowsAffectedCount() = 0;

    /** Gets the number of input parameters for this statement.
     *
     * \return The number of input parameters for this statement.
     */
    virtual ul_u_short GetParameterCount() = 0;

    /** Get the 1-based ordinal for a parameter name.
     *
     * \param name The name of the host variable.
     * \return The 1-based ordinal for a parameter name.
     */
    virtual ul_column_num GetParameterID( const char * name ) = 0;

    #ifdef UL_WCHAR_API
    /** Get the 1-based ordinal for a parameter name.
     *
     * \param name The name of the host variable.
     * \return The 1-based ordinal for a parameter name.
     */
    virtual ul_column_num GetParameterID( const ul_wchar * name ) = 0;
    #endif

    /** Gets the storage/host variable type of a parameter.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \return The type of the specified parameter.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual ul_column_storage_type GetParameterType( ul_column_num pid ) = 0;

    /** Sets a parameter to null.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \return True on success; otherwise, returns false.
     */    
    virtual bool SetParameterNull( ul_column_num pid ) = 0;

    /** Sets a parameter to an integer value.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \param value The integer value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterInt( ul_column_num pid, ul_s_long value ) = 0;

    /** Sets a parameter to an integer value of the specified integer type.
     *
     * The following is a list of integer values that can be used for the value
     * parameter:
     *
     * <ul>
     * <li>UL_TYPE_BIT
     * <li>UL_TYPE_TINY
     * <li>UL_TYPE_S_SHORT
     * <li>UL_TYPE_U_SHORT
     * <li>UL_TYPE_S_LONG
     * <li>UL_TYPE_U_LONG
     * <li>UL_TYPE_S_BIG
     * <li>UL_TYPE_U_BIG
     * </ul>
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value The integer value.
     * \param type The integer type to treat the value as.
     * \return True on success; otherwise, returns false.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */	
    virtual bool SetParameterIntWithType(
        ul_column_num		pid,
	ul_s_big		value,
	ul_column_storage_type	type ) = 0;

    /** Sets a parameter to a float value.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \param value The float value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterFloat( ul_column_num pid, ul_real value ) = 0;

    /** Sets a parameter to a double value.
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value	The double value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterDouble( ul_column_num pid, ul_double value ) = 0;

    /** Sets a parameter to a DECL_DATETIME value.
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value The DECL_DATETIME value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterDateTime( ul_column_num pid, DECL_DATETIME * value ) = 0;

    /** Sets a parameter to a GUID value.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \param value The GUID value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterGuid( ul_column_num pid, GUID * value ) = 0;

    /** Sets a parameter to a string value.
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value The string value.
     * \param len Optional.  Set to the length of the string in bytes or 
     *            UL_NULL_TERMINATED_STRING if the string in null-terminated. 
     *            SQLE_INVALID_PARAMETER is set if this parameter is greater 
     *            than 32K.  For large strings, call the
     *            AppendParameterStringChunk method instead.
     * \return True on success, otherwise false.
     *
     * \see AppendParameterStringChunk
     */
    virtual bool SetParameterString(
        ul_column_num		pid,
	const char *		value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a parameter to a wide string value.
     *
     * \copydetails SetParameterString
     */
    virtual bool SetParameterString(
        ul_column_num		pid,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
    #endif

    /** Sets a parameter to a ul_binary value.
     *
     * \param pid The 1-based ordinal of the parameter.
     * \param value The ul_binary value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetParameterBinary(
        ul_column_num		pid,
	const p_ul_binary	value ) = 0;

    /** Sets a large string parameter broken down into several chunks.
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value The string chunk to append.
     * \param len Optional. Set to the length of the string chunk in bytes or
     *            UL_NULL_TERMINATED_STRING if the string chunk is
     *            null-terminated.
     * \return True on success; otherwise, returns false.
     */
    virtual bool AppendParameterStringChunk(
        ul_column_num		pid,
	const char *		value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;

    #if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //AppendParameterStringChunk(wchar)
    /** Sets a large wide string parameter broken down into several chunks.
     * 
     * \copydetails AppendParameterStringChunk
     */
    virtual bool AppendParameterStringChunk(
        ul_column_num		pid,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
    #endif

    /** Sets a large binary parameter broken down into several chunks.
     * 
     * \param pid The 1-based ordinal of the parameter.
     * \param value The byte chunk to append.
     * \param valueSize The size of the buffer.
     * \return True on success; otherwise, returns false.
     */
    virtual bool AppendParameterByteChunk(
        ul_column_num		pid,
	const ul_byte *		value,
	size_t			valueSize ) = 0;
    
    /** Gets a text-based description of the query execution plan.
     *
     * This method is intended primarily for use during development.
     * 
     * An empty string is returned if there is no plan.  Plans exist when the
     * prepared statement is a SQL query.
     * 
     * When the plan is obtained before the associated query has been executed, 
     * the plan shows the operations used to execute the query.  The plan
     * additionally shows the number of rows each operation produced when the
     * plan is obtained after the query has been executed.  This plan can be 
     * used to gain insight about the execution of the query.
     * 
     * \param dst The destination buffer for the plan text. Pass NULL to 
     *            determine the size of the buffer required to hold the plan.
     * \param dstSize The size of the destination buffer.
     * \return The number of bytes copied to the buffer; otherwise, if the dst
     *         value is  NULL, returns the number of bytes required to store
     *         the plan, excluding the null-terminator.
     */
    virtual size_t GetPlan( char * dst, size_t dstSize ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets a text-based description of the query execution plan.
     *
     * \copydetails GetPlan
     */
    virtual size_t GetPlan( ul_wchar * dst, size_t dstSize ) = 0;
    #endif
};

/** Specifies values that control how a column name is retrieved when
 * describing a result set.
 *
 * \see ULResultSetSchema::GetColumnName
 */
enum ul_column_name_type {
    /** For SELECT statements, returns the alias or correlation name.
     * 
     * For tables, returns the column name.
     */
    ul_name_type_sql,
    /** For SELECT statements, returns the alias or correlation name and exclude
     * any table names that were specified.
     *
     * For tables, returns the column name.
     */
    ul_name_type_sql_column_only,
    /** Returns the underlying table name if it can be determined.
     *
     * If the table does not exist in the database schema, returns an empty
     * string.
     */
    ul_name_type_base_table,
    /** Returns the underlying column name if it can be determined.
     * 
     * If the column does not exist in the database schema, returns an empty
     * string.
     */
    ul_name_type_base_column,
    /** Returns the underlying qualified column name, if it can be determined,
     * when used in conjunction with the ULResultSetSchema.GetColumnName method.
     *
     * The returned name can be one of the following values, and is determined
     * in this order:
     *
     * <ol>
     * <li>The represented correlated table
     * <li>The name of the represented table column
     * <li>The alias name of the column
     * <li>An empty string
     * </ol>
     */
    ul_name_type_qualified,
    /** Indicates that a column name qualified with its table name should be 
     * returned when used with the GetColumnName method.
     *
     * If the column name being retrieved is associated with a base table in the
     * query, then the base table name is used as the column qualifier 
     * (that is, the base_table_name.column_name value is returned). If the 
     * column name being retrieved refers to a column in a correlated table in
     * the query, then the correlation name is used as the 
     * column qualifier (that is, the correl_table_name.col_name value is 
     * returned). If the column has an alias, then the qualified name of the 
     * column being aliased is returned; the alias is not part of the qualified
     * name. Otherwise, an empty string is returned.
     */
    ul_name_type_base
};

/** Represents a result set in an UltraLite database.
*/
class ULResultSet {
  public:
    /** Destroys this object.
    */
    virtual void Close() = 0;

    /** Gets the connection object.
     *
     * \return The ULConnection object associated with this result set.
     */
    virtual ULConnection * GetConnection() = 0;

    /** Returns an object that can be used to get information about the result
     * set.
     *
     * \return A ULResultSetSchema object that can be used to get information
     * about the result set.
     */
    virtual const ULResultSetSchema & GetResultSetSchema() = 0;
    
    /** Moves the cursor forward one row. 
     *
     * \return True, if the cursor successfully moves forward. Despite
     *         returning true, an error may be signaled even when the cursor
     *         moves successfully to the next row.  For example, there could be
     *         conversion errors while evaluating the SELECT expressions. In
     *         this case, errors are also returned when retrieving the column
     *         values. False is returned if it fails to move forward. For 
     *         example, there may not be a next row. In this case, the resulting
     *         cursor position is set after the last row.
     */
    virtual bool Next() = 0;

    /** Moves the cursor back one row.
     * 
     * \return True, if the cursor successfully moves back one row.  False, if 
     *         it fails to move backward. The resulting cursor position is
     *         set before the first row.
     */
    virtual bool Previous() = 0;

    /** Moves the cursor before the first row.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool BeforeFirst() = 0;

    /** Moves the cursor to the first row.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool First() = 0;

    /** Moves the cursor to the last row.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool Last() = 0;

    /** Moves the cursor after the last row.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool AfterLast() = 0;

    /** Moves the cursor by offset rows from the current cursor position.
     *
     * \param offset The number of rows to move.
     * \return True on success; otherwise, returns false.
     */
    virtual bool Relative( ul_fetch_offset offset ) = 0;

    //virtual bool Absolute( ul_fetch_offset offset ) = 0;

    /** Gets the internal state of the cursor.
     *
     * \return The state of the cursor.
     *
     * \apilink{UL_RS_STATE, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-rs-state-enu"}
     *
     */
    virtual UL_RS_STATE GetState() = 0;

    /** Gets the number of rows in the table.
     *
     * This method is equivalent to executing the "SELECT COUNT(*) FROM 
     * table" statement.
     * 
     * \param threshold The limit on the number of rows to count.  Set to 0 to
     *                  indicate no limit.
     * \return The number of rows in the table.
     */
    virtual ul_u_long GetRowCount( ul_u_long threshold = 0 ) = 0;

    /** Selects the update mode for setting columns.
     *
     * Columns in the primary key may not be modified when in update mode.
     * 
     * \return True on success, otherwise false.
     */
    virtual bool UpdateBegin() = 0;

    /**	Updates the current row.
     *
     * \return True on success, otherwise false.
     */
    virtual bool Update() = 0;

    /** Deletes the current row and moves it to the next valid row.
     *
     * \return True on success, otherwise false.
     */
    virtual bool Delete() = 0;

    /** Deletes the current row and moves it to the next valid row.
     *
     * \param tableName A table name or its correlation (required when the
     *                  database has multiple columns that share the same table
     *                  name).
     * \return True on success; otherwise, returns false.
    */
    virtual bool DeleteNamed( const char * tableName ) = 0;

    #ifdef UL_WCHAR_API
    /** Deletes the current row and moves it to the next valid row.
     *
     * \copydetails DeleteNamed()
     */
    virtual bool DeleteNamed( const ul_wchar * tableName ) = 0;
    #endif

    /** Checks if a column is NULL.
     *
     * \param cid The 1-based ordinal column number.
     * \return True if the value for the column is NULL.
     */
    virtual bool IsNull( ul_column_num cid ) = 0;

    /** Checks if a column is NULL.
     *
     * \param cname	The name of the column.
     * \return True if the value for the column is NULL.
     */
    virtual bool IsNull( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Checks if a column is NULL.
     *
     * \copydetails IsNull(const char *)
     */
    virtual bool IsNull( const ul_wchar * cname ) = 0;
    #endif

    /** Fetches a value from a column as an integer.
     *
     * \param cid	The 1-based ordinal column number.
     * \return The column value as an integer.
     */
    virtual ul_s_long GetInt( ul_column_num cid ) = 0;

    /** Fetches a value from a column as an integer.
     * 
     * \param cname	The name of the column.
     * \return The column value as an integer.
     */
    virtual ul_s_long GetInt( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as an integer.
     *
     * \copydetails GetInt(const char *)
     */
    virtual ul_s_long GetInt( const ul_wchar * cname ) = 0;
    #endif

    /** Fetches a value from a column as the specified integer type.
     *
     * The following is a list of integer values that can be used for the type
     * parameter:
     * 
     * <ul>
     * <li>UL_TYPE_BIT
     * <li>UL_TYPE_TINY
     * <li>UL_TYPE_S_SHORT
     * <li>UL_TYPE_U_SHORT
     * <li>UL_TYPE_S_LONG
     * <li>UL_TYPE_U_LONG
     * <li>UL_TYPE_S_BIG
     * <li>UL_TYPE_U_BIG
     * </ul>
     * 
     * \param cid The 1-based ordinal column number.
     * \param type The integer type to fetch as.
     * \return The column value as an integer.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual ul_s_big GetIntWithType(
        ul_column_num		cid,
	ul_column_storage_type	type ) = 0;

    /** Fetches a value from a column as the specified integer type.
     * 
     * The following is a list of integer values that can be used for the type
     * parameter:
     *
     * <ul>
     * <li>UL_TYPE_BIT
     * <li>UL_TYPE_TINY
     * <li>UL_TYPE_S_SHORT
     * <li>UL_TYPE_U_SHORT
     * <li>UL_TYPE_S_LONG
     * <li>UL_TYPE_U_LONG
     * <li>UL_TYPE_S_BIG
     * <li>UL_TYPE_U_BIG
     * </ul>
     * 
     * \param cname	The name of the column.
     * \param type	The integer type to fetch as.
     * \return The column value as an integer.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
    */
    virtual ul_s_big GetIntWithType(
        const char *		cname,
	ul_column_storage_type	type ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as the specified integer type.
     *
     * \copydetails GetIntWithType(const char *,ul_column_storage_type)
     */
    virtual ul_s_big GetIntWithType(
        const ul_wchar *	cname,
	ul_column_storage_type	type ) = 0;
    #endif

    /** Fetches a value from a column as a float.
     *
     * \param cid The 1-based ordinal column number.
     * \return The column value as a float.
     */
    virtual ul_real GetFloat( ul_column_num cid ) = 0;

    /** Fetches a value from a column as a float.
     * 
     * \param cname	The name of the column.
     * \return The column value as a float.
     */
    virtual ul_real GetFloat( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a float.
     *
     * \copydetails GetFloat(const char *)
     */
    virtual ul_real GetFloat( const ul_wchar * cname ) = 0;
    #endif

    /** Fetches a value from a column as a double.
     *
     * \param cid The 1-based ordinal column number.
     * \return The column value as a double.
     */
    virtual ul_double GetDouble( ul_column_num cid ) = 0;

    /** Fetches a value from a column as a double.
     * 
     * \param cname	The name of the column.
     * \return The column value as a double.
     */
    virtual ul_double GetDouble( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a double.
     *
     * \copydetails GetDouble(const char *)
     */
    virtual ul_double GetDouble( const ul_wchar * cname ) = 0;
    #endif

    /** Fetches a value from a column as a DECL_DATETIME.
     *
     * \param cid The 1-based ordinal column number.
     * \param dst The DECL_DATETIME value.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetDateTime( ul_column_num cid, DECL_DATETIME * dst ) = 0;

    /** Fetches a value from a column as a DECL_DATETIME.
     *
     * \param cname The name of the column.
     * \param dst The DECL_DATETIME value.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetDateTime( const char * cname, DECL_DATETIME * dst ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a DECL_DATETIME.
     *
     * \copydetails GetDateTime(const char *,DECL_DATETIME *)
     */
    virtual bool GetDateTime( const ul_wchar * cname, DECL_DATETIME * dst ) = 0;
    #endif

    /** Fetches a value from a column as a GUID.
     * 
     * \param	cid	The 1-based ordinal column number.
     * \param	dst	The GUID value.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetGuid( ul_column_num cid, GUID * dst ) = 0;

    /** Fetches a value from a column as a GUID.
     * 
     * \param cname The name of the column.
     * \param dst The GUID value.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetGuid( const char * cname, GUID * dst ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a GUID.
     * 
     * \copydetails GetGuid(const char *,GUID *)
     */
    virtual bool GetGuid( const ul_wchar * cname, GUID * dst ) = 0;
    #endif

    /** Fetches a value from a column as a null-terminated string.
     *
     * The string is truncated in the buffer when it isn't large enough to hold
     * the entire value.
     *
     * \param cid The 1-based ordinal column number.
     * \param dst The buffer to hold the string value.  The string is 
     *            null-terminated even if truncated.
     * \param len The size of the buffer in bytes.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetString(
        ul_column_num		cid,
	char *			dst,
	size_t			len ) = 0;

    /** Fetches a value from a column as a null-terminated string.
     *
     * The string is truncated in the buffer when it isn't large enough to hold
     * the entire value.
     *
     * \param cname The name of the column.
     * \param dst The buffer to hold the string value.  The string is 
     *            null-terminated even if truncated.
     * \param len The size of the buffer in bytes.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetString(
        const char *		cname,
	char *			dst,
	size_t			len ) = 0;
		
    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a null-terminated wide string.
     * 
     * The string is truncated in the buffer when it isn't large enough to hold
     * the entire value.
     *
     * \param cid The 1-based ordinal column number.
     * \param dst The buffer to hold the wide string value.  The string is
     *            null-terminated even if truncated.
     * \param len The size of the buffer in ul_wchars.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetString(
        ul_column_num		cid,
	ul_wchar *		dst,
	size_t			len ) = 0;

    /** Fetches a value from a column as a null-terminated wide string.
     *
     * The string is truncated in the buffer when it isn't large enough to hold
     * the entire value.
     *
     * \param cname The name of the column.
     * \param dst The buffer to hold the wide string value. The string is 
     *            null-terminated even if truncated.
     * \param len The size of the buffer in ul_wchars.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetString(
        const ul_wchar *	cname,
	ul_wchar *		dst,
	size_t			len ) = 0;
    #endif

    /** Fetches a value from a column as a ul_binary value.
     *
     * \param cid The 1-based ordinal column number.
     * \param dst The ul_binary result.
     * \param len The size of the ul_binary object.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetBinary(
        ul_column_num		cid,
	p_ul_binary		dst,
	size_t			len ) = 0;

    /** Fetches a value from a column as a ul_binary value.
     *
     * \param cname The name of the column.
     * \param dst The ul_binary result.
     * \param len The size of the ul_binary object.
     * \return True if the value was successfully fetched.
     */
    virtual bool GetBinary(
        const char *		cname,
	p_ul_binary		dst,
	size_t			len ) = 0;

    #ifdef UL_WCHAR_API
    /** Fetches a value from a column as a ul_binary.
     * 
     * \copydetails GetBinary(const char *, p_ul_binary, size_t)
     */
    virtual bool GetBinary(
        const ul_wchar *	cname,
	p_ul_binary		dst,
	size_t			len ) = 0;
    #endif

    /** Gets a string chunk from the column.
     * 
     * The end of the value has been reached if 0 is returned.
     * 
     * \param cid The 1-based ordinal column number.
     * \param dst The buffer to hold the string chunk.  The string is
     *            null-terminated even if truncated.
     * \param len	The size of the buffer in bytes.
     * \param offset Set to the offset into the value at which to start reading 
     *               or set to the UL_BLOB_CONTINUE constant to continue from 
     *               where the last read ended.
     * \return The number of bytes copied to the destination buffer excluding
     *         the null-terminator. If the dst value is set to NULL, then the
     *         number of bytes left in the string is returned.  An empty string
     *         is returned in the dst parameter when the column is null; use the
     *         IsNull method to differentiate between null and empty strings.
     * 
     * \see IsNull
     */
    virtual size_t GetStringChunk(
        ul_column_num		cid,
	char *			dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;

    /** Gets a string chunk from the column.
     * 
     * The end of the value has been reached if 0 is returned.
     *
     * \param cname The name of the column.
     * \param dst The buffer to hold the string chunk.  The string is 
     *            null-terminated even if truncated.
     * \param len The size of the buffer in bytes.
     * \param offset The offset into the value at which to start reading or the
     *               UL_BLOB_CONTINUE constant to continue from where the last
     *               read ended.
     * \return The number of bytes copied to the destination buffer excluding
     *         the null-terminator. If the dst value is set to NULL, then the 
     *         number of bytes left in the string is returned.  An empty string
     *         is returned in the dst parameter when the column is null; use the
     *         IsNull method to differentiate between null and empty strings.
     * 
     * \see IsNull
     */
    virtual size_t GetStringChunk(
        const char *		cname,
	char *			dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;
		
    #if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //GetStringChunk(id,wchar)
    /** Gets a wide string chunk from the column.
     *
     * The end of the value has been reached if 0 is returned.
     *
     * \param cid The 1-based ordinal column number.
     * \param dst The buffer to hold the string chunk.  The string is 
     *            null-terminated even if truncated.
     * \param len The size, in ul_wchars, of the buffer.
     * \param offset The offset into the value at which to start reading or the
     *               UL_BLOB_CONTINUE constant to continue from where the last
     *               read ended.
     * \return The number of ul_wchars copied to the destination buffer 
     *         excluding the null-terminator.  If the dst value is NULL, then
     *         the number of ul_wchars left in the string is returned.  An empty
     *         string is returned in the dst parameter when the column is null; 
     *         use the IsNull method to differentiate between null and empty 
     *         strings.
     * 
     * \see IsNull
     */
    virtual size_t GetStringChunk(
        ul_column_num		cid,
	ul_wchar *		dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;
    #endif

    #ifdef UL_WCHAR_API
    /** Gets a wide string chunk from the column.
     *
     * The end of the value has been reached if 0 is returned.
     *
     * \param cname The name of the column.
     * \param dst The buffer to hold the string chunk. The string is
     *            null-terminated even if truncated.
     * \param len The size, in ul_wchars, of the buffer.
     * \param offset The offset into the value at which to start reading or the
     *               UL_BLOB_CONTINUE constant to continue from where the last
     *               read ended.
     * \return The number of ul_wchars copied to the destination buffer
     *         excluding the null-terminator.  If the dst value is NULL, then
     *         the number of ul_wchars left in the string is returned.  An empty
     *         string is returned in the dst parameter when the column is null;
     *         use the IsNull method to differentiate between null and empty 
     *         strings.
     * 
     * \see IsNull
     */
    virtual size_t GetStringChunk(
        const ul_wchar *	cname,
	ul_wchar *		dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;
    #endif
	
    /** Gets a binary chunk from the column.
     *
     * The end of the value has been reached if 0 is returned.
     * 
     * \param cid The 1-based ordinal column number.
     * \param dst The buffer to hold the bytes.
     * \param len The size of the buffer in bytes.
     * \param offset The offset into the value at which to start reading or the
     *               UL_BLOB_CONTINUE constant to continue from where the last
     *               read ended.
     * \return The number of bytes copied to the destination buffer.  If the
     *         dst value is NULL, then the number of bytes left is returned.  An
     *         empty string is returned in the dst parameter when the column is
     *         null; use the IsNull method to differentiate between null and 
     *         empty strings.
     * 
     * \see IsNull
     */
    virtual size_t GetByteChunk(
        ul_column_num		cid,
	ul_byte *		dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;

    /** Gets a binary chunk from the column.
     *
     * The end of the value has been reached if 0 is returned.
     *
     * \param cname The name of the column.
     * \param dst The buffer to hold the bytes.
     * \param len The size of the buffer in bytes.
     * \param offset The offset into the value at which to start reading or the
     *               UL_BLOB_CONTINUE constant to continue from where the last
     *               read ended.
     * \return The number of bytes copied to the destination buffer.  If the
     *         dst value is NULL, then the number of bytes left is returned.  An
     *         empty string is returned in the dst parameter when the column is
     *         null; use the IsNull method to differentiate between null and 
     *         empty strings.
     * 
     * \see IsNull
     */
    virtual size_t GetByteChunk(
        const char *		cname,
	ul_byte *		dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets a binary chunk from the column.
     *
     * \copydetails GetByteChunk(const char *, ul_byte *, size_t, size_t)
     */
    virtual size_t GetByteChunk(
        const ul_wchar *	cname,
	ul_byte *		dst,
	size_t			len,
	size_t			offset = UL_BLOB_CONTINUE ) = 0;
    #endif

    /** Gets the string length of the value of a column.
     * 
     * The following example illustrates how to get the string length of a
     * column:
     *
     * <pre>
     * len = result_set->GetStringLength( cid );
     * dst = new char[ len + 1 ];
     * result_set->GetString( cid, dst, len + 1 );
     * </pre>
     *
     * For wide characters, the usage is as follows:
     * 
     * <pre>
     * len = result_set->GetStringLength( cid );
     * dst = new ul_wchar[ len + 1 ];
     * result_set->GetString( cid, dst, len + 1 );
     * </pre>
     *
     * \param cid The 1-based ordinal column number.
     * \return The number of bytes or characters required to hold the string
     *         returned by one of the GetString methods, not including the
     *         null-terminator.
     *
     * \see GetString
     */
    virtual size_t GetStringLength( ul_column_num cid ) = 0;

    /** Gets the string length of the value of a column.
     * 
     * The following example demonstrates how to get the string length of a
     * column:
     *
     * <pre>
     * len = result_set->GetStringLength( cid );
     * dst = new char[ len + 1 ];
     * result_set->GetString( cid, dst, len + 1 );
     * </pre>
     *
     * For wide characters, the usage is as follows:
     * 
     * <pre>
     * len = result_set->GetStringLength( cid );
     * dst = new ul_wchar[ len + 1 ];
     * result_set->GetString( cid, dst, len + 1 );
     * </pre>
     *
     * \param cname The name of the column.
     * \return The number of bytes or characters required to hold the string
     *         returned by one of the GetString methods, not including the 
     *         null-terminator.
     *
     * \see GetString
     */
    virtual size_t GetStringLength( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the string length of the value of a column.
     *
     * \copydetails GetStringLength(const char *)
     */
    virtual size_t GetStringLength( const ul_wchar * cname ) = 0;
    #endif

    /** Gets the binary length of the value of a column.
     *
     * \param cid The 1-based ordinal column number.
     * \return The size of the column value as a binary
     */
    virtual size_t GetBinaryLength( ul_column_num cid ) = 0;

    /** Gets the binary length of the value of a column.
     * 
     * \param cname The name of the column.
     * \return The size of the column value as a binary
     */
    virtual size_t GetBinaryLength( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the binary length of the value of a column.
     *
     * \copydetails GetBinaryLength(const char *)
     */
    virtual size_t GetBinaryLength( const ul_wchar * cname ) = 0;
    #endif

    /**	Sets a column to null.
     *
     * \param cid The 1-based ordinal column number.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetNull( ul_column_num cid ) = 0;

    /**	Sets a column to null.
     *
     * \param cname The name of the column.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetNull( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /**	Sets a column to null.
     *
     * \copydetails SetNull(const char *)
     */
    virtual bool SetNull( const ul_wchar * cname ) = 0;
    #endif

    /**	Sets a column to its default value.
     *
     * \param cid The 1-based ordinal column number.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetDefault( ul_column_num cid ) = 0;

    /**	Sets a column to its default value.
     *
     * \param cname The name of the column.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetDefault( const char * cname ) = 0;

    #ifdef UL_WCHAR_API
    /**	Sets a column to its default value.
     *
     * \copydetails SetDefault(const char *)
     */
    virtual bool SetDefault( const ul_wchar * cname ) = 0;
    #endif

    /** Sets a column to an integer value.
     *
     * \param cid The 1-based ordinal column number.
     * \param value The signed integer value.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetInt( ul_column_num cid, ul_s_long value ) = 0;

    /** Sets a column to an integer value.
     *
     * \param cname The name of the column.
     * \param value The signed integer value.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetInt( const char * cname, ul_s_long value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to an integer value.
     *
     * \copydetails SetInt(const char *, ul_s_long)
     */	
    virtual bool SetInt( const ul_wchar * cname, ul_s_long value ) = 0;
    #endif

    /** Sets a column to an integer value of the specified integer type.
     *
     * The following is a list of integer values that can be used for the value
     * parameter:
     *
     * <ul>
     * <li>UL_TYPE_BIT
     * <li>UL_TYPE_TINY
     * <li>UL_TYPE_S_SHORT
     * <li>UL_TYPE_U_SHORT
     * <li>UL_TYPE_S_LONG
     * <li>UL_TYPE_U_LONG
     * <li>UL_TYPE_S_BIG
     * <li>UL_TYPE_U_BIG
     * </ul>
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The integer value.
     * \param type The integer type to treat the value as.
     * \return True on success; otherwise, returns false.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual bool SetIntWithType(
        ul_column_num		cid,
	ul_s_big		value,
	ul_column_storage_type	type ) = 0;

    /** Sets a column to an integer value of the specified integer type.
     *
     * The following is a list of integer values that can be used for the value
     * parameter:
     *
     * <ul>
     * <li>UL_TYPE_BIT
     * <li>UL_TYPE_TINY
     * <li>UL_TYPE_S_SHORT
     * <li>UL_TYPE_U_SHORT
     * <li>UL_TYPE_S_LONG
     * <li>UL_TYPE_U_LONG
     * <li>UL_TYPE_S_BIG
     * <li>UL_TYPE_U_BIG
     * </ul>
     * 
     * \param cname The name of the column.
     * \param value The integer value.
     * \param type The integer type to treat the value as.
     * \return True on success; otherwise, returns false.
     *
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */	
    virtual bool SetIntWithType(
        const char *		cname,
	ul_s_big		value,
	ul_column_storage_type	type ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to an integer value of the specified integer type.
     * 
     * \copydetails SetIntWithType(const char *, ul_s_big, ul_column_storage_type)
     */
    virtual bool SetIntWithType(
        const ul_wchar *	cname,
	ul_s_big		value,
	ul_column_storage_type	type ) = 0;
    #endif

    /** Sets a column to a float value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value	The float value.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetFloat( ul_column_num cid, ul_real value ) = 0;

    /** Sets a column to a float value.
     * 
     * \param cname The name of the column.
     * \param value The float value.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetFloat( const char * cname, ul_real value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to a float value.
     *
     * \copydetails SetFloat(const char *, ul_real)
     */
    virtual bool SetFloat( const ul_wchar * cname, ul_real value ) = 0;
    #endif

    /** Sets a column to a double value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The double value.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetDouble( ul_column_num cid, ul_double value ) = 0;

    /** Sets a column to a double value.
     * 
     * \param cname The name of the column.
     * \param value The double value.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetDouble( const char * cname, ul_double value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to a double value.
     * 
     * \copydetails SetDouble(const char *, ul_double)
     */	
    virtual bool SetDouble( const ul_wchar * cname, ul_double value ) = 0;
    #endif

    /** Sets a column to a DECL_DATETIME value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The DECL_DATETIME value.  Passing NULL is equivalent to
     *              calling the SetNull method.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetDateTime( ul_column_num cid, DECL_DATETIME * value ) = 0;

    /** Sets a column to a DECL_DATETIME value.
     *
     * \param cname The name of the column.
     * \param value The DECL_DATETIME value.  Passing NULL is equivalent to
     *              calling the SetNull method.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetDateTime( const char * cname, DECL_DATETIME * value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to a DECL_DATETIME value.
     *
     * \copydetails SetDateTime(const char *, DECL_DATETIME *)
     */	
    virtual bool SetDateTime( const ul_wchar * cname, DECL_DATETIME * value ) = 0;
    #endif

    /** Sets a column to a GUID value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The GUID value.  Passing NULL is equivalent to calling the
     *              SetNull method.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetGuid( ul_column_num cid, GUID * value ) = 0;

    /** Sets a column to a GUID value.
     *
     * \param cname The name of the column.
     * \param value The GUID value.  Passing NULL is equivalent to calling the
     *              SetNull method.
     * \return True on success; otherwise, returns false.
     */	
    virtual bool SetGuid( const char * cname, GUID * value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to a GUID value.
     *
     * \copydetails SetGuid(const char *, GUID *)
     */	
    virtual bool SetGuid( const ul_wchar * cname, GUID * value ) = 0;
    #endif

    /** Sets a column to a string value.
     *
     * \param cid The 1-based ordinal column number.
     * \param value The string value.  Passing NULL is equivalent to calling the
     *              SetNull method.
     * \param len Optional.  The length of the string in bytes or the
     *            UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated.  The SQLE_INVALID_PARAMETER constant is set
     *            if the len value is set larger than 32K. For large strings, 
     *            call the AppendStringChunk method instead.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */	
    virtual bool SetString(
        ul_column_num		cid,
	const char *		value,
	size_t 			len = UL_NULL_TERMINATED_STRING ) = 0;

    /** Sets a column to a string value.
     *
     * \param cname The name of the column.
     * \param value The string value. Passing NULL is equivalent to calling the
     *              SetNull method.
     * \param len Optional.  The length of the string in bytes or the
     *            UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated.  The SQLE_INVALID_PARAMETER constant is set
     *            if the len value is set larger than 32K.  For large strings,
     *            call the AppendStringChunk method instead.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */	
    virtual bool SetString(
        const char *		cname,
	const char *		value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
		
    #ifdef UL_WCHAR_API
    /** Sets a column to a wide string value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The wide string value.  Passing NULL is equivalent to
     *              calling the SetNull method.
     * \param len Optional.  The length of the string in ul_wchars or the
     *            UL_NULL_TERMINATED_STRING constant if the string is 
     *            null-terminated.  The SQLE_INVALID_PARAMETER constant is set
     *            if the len value is set larger than 32K.  For large strings,
     *            call the AppendStringChunk method instead.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */	
    virtual bool SetString(
        ul_column_num		cid,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;

    /** Sets a column to a wide string value.
     *
     * \param cname The name of the column.
     * \param value The wide string value.  Passing NULL is equivalent to 
     *              calling the SetNull method.
     * \param len Optional.  The length of the string in ul_wchars or the
     *            UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated. The SQLE_INVALID_PARAMETER constant is set
     *            if the len value is set larger than 32K.  For large strings,
     *            call the AppendStringChunk method instead.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */	
    virtual bool SetString(
        const ul_wchar *	cname,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
    #endif

    /** Sets a column to a ul_binary value.
     * 
     * \param cid The 1-based ordinal column number.
     * \param value The ul_binary value.  Passing NULL is equivalent to calling
     *              the SetNull method.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetBinary( ul_column_num cid, p_ul_binary value ) = 0;

    /** Sets a column to a ul_binary value.
     *
     * \param cname The name of the column.
     * \param value The ul_binary value.  Passing NULL is equivalent to calling
     *              the SetNull method.
     * \return True on success; otherwise, returns false.
     */
    virtual bool SetBinary( const char * cname, p_ul_binary value ) = 0;

    #ifdef UL_WCHAR_API
    /** Sets a column to a ul_binary value.
     *
     * \copydetails SetBinary(const char *, p_ul_binary)
     */
    virtual bool SetBinary( const ul_wchar * cname, p_ul_binary value ) = 0;
    #endif

    /** Appends a string chunk to a column.
     *
     * This method appends the given string to the end of the string written so
     * far by AppendStringChunk method calls.
     *
     * \param cid The 1-based ordinal column number.
     * \param value The string chunk to append.
     * \param len Optional.  The length of the string chunk in bytes or 
     *            the UL_NULL_TERMINATED_STRING constant if the string is 
     *            null-terminated.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */
    virtual bool AppendStringChunk(
        ul_column_num		cid,
	const char *		value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;

    /** Appends a string chunk to a column.
     *
     * This method appends the given string to the end of the string written so
     * far by AppendStringChunk method calls.
     *
     * \param cname The name of the column.
     * \param value The string chunk to append.
     * \param len Optional.  The length of the string chunk in bytes or 
     *            the UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */
    virtual bool AppendStringChunk(
        const char *		cname,
	const char *		value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
		
    #if defined(UL_WCHAR_API) || defined(UL_WCHAR_DATA_API) //AppendStringChunk(id,wchar)
    /** Appends a wide string chunk to a column.
     *
     * This method appends the given string to the end of the string written so 
     * far by AppendStringChunk method calls.
     *
     * \param cid The 1-based ordinal column number.
     * \param value The wide string chunk to append.
     * \param len Optional.  The length of the string chunk in ul_wchars or 
     *            the UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendStringChunk
     */
    virtual bool AppendStringChunk(
        ul_column_num		cid,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
    #endif

    #ifdef UL_WCHAR_API
    /** Appends a wide string chunk to a column.
     *
     * This method appends the given string to the end of the string written so
     * far by AppendStringChunk method calls.
     *
     * \param cname The name of the column.
     * \param value The wide string chunk to append.
     * \param len Optional.  The length of the string chunk in ul_wchars or 
     *            the UL_NULL_TERMINATED_STRING constant if the string is
     *            null-terminated.
     * \return True on success; otherwise returns false.
     *
     * \see AppendStringChunk
     */
    virtual bool AppendStringChunk(
        const ul_wchar *	cname,
	const ul_wchar *	value,
	size_t			len = UL_NULL_TERMINATED_STRING ) = 0;
    #endif

    /** Appends bytes to a column.
     *
     * The given bytes are appended to the end of the column written so far by
     * AppendBinaryChunk method calls.
     *
     * \param cid The 1-based ordinal column number.
     * \param value The byte chunk to append.
     * \param valueSize The size of the byte chunk in bytes.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendByteChunk
     */
    virtual bool AppendByteChunk(
        ul_column_num		cid,
	const ul_byte *		value,
	size_t			valueSize ) = 0;

    /** Appends bytes to a column.
     *
     * The given bytes are appended to the end of the column written so far by
     * AppendBinaryChunk method calls.
     *
     * \param cname The name of the column.
     * \param value The byte chunk to append.
     * \param valueSize The size of the byte chunk in bytes.
     * \return True on success; otherwise, returns false.
     *
     * \see AppendByteChunk
     */
    virtual bool AppendByteChunk(
        const char *		cname,
	const ul_byte *		value,
	size_t			valueSize ) = 0;

    #ifdef UL_WCHAR_API
    /** Appends bytes to a column.
     *
     * \copydetails AppendByteChunk(const char*, const ul_byte *, size_t)
     */
    virtual bool AppendByteChunk(
        const ul_wchar *	cname,
	const ul_byte *		value,
	size_t			valueSize ) = 0;
    #endif
};

/** Represents a table in an UltraLite database.
 */
class ULTable : public ULResultSet
{
  public:
    /** Returns a ULTableSchema object that can be used to get schema 
     * information about the table.
     *
     * \return A ULTableSchema object that can be used to get schema information
     *         about the table.
     */
    virtual ULTableSchema * GetTableSchema() = 0;

    /** Selects the insert mode for setting columns.
     *
     * All columns are set to their default value during an insert unless
     * an alternative value is supplied via Set method calls.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool InsertBegin() = 0;
    
    /**	Inserts a new row into the table.
     *
     * \return True on success; otherwise returns false.
     */
    virtual bool Insert() = 0;

    /** Deletes all rows from a table.
     * 
     * In some applications, you may want to delete all rows from a table
     * before downloading a new set of data into the table. If you set
     * the stop synchronization property on the connection, the deleted rows
     * are not synchronized.
     * 
     * <em>Note:</em> Any uncommitted inserts from other connections are not
     * deleted. They are also not deleted if the other connection performs a 
     * rollback after it calls the DeleteAllRows method.
     *
     * If this table has been opened without an index, then it is considered 
     * read-only and data cannot be deleted.
     * 
     * \return True on success; otherwise, returns false. For example, false is
     *         returned when the table is not open, or a SQL error occurred.
     */
    virtual bool DeleteAllRows() = 0;
    
    /** Truncates the table and temporarily activates STOP SYNCHRONIZATION
     * DELETE.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool TruncateTable() = 0;

    /** Prepares to perform a new lookup on a table.
     *
     * You may only set columns in the index that the table was opened with.
     * If the table was opened without an index, this method cannot be called.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool LookupBegin() = 0;
    
    /** Performs a lookup based on the current index scanning forward through
     * the table.
     *
     * To specify the value to search for, set the column value for each column
     * in the index. The cursor is positioned on the last row that matches or
     * is less than the index value. For composite indexes, the ncols parameter
     * specifies the number of columns to use in the lookup.
     *
     * \param ncols For composite indexes, the number of columns to use in the
     *              lookup.
     * \return False if the resulting cursor position is set after the last row.
     */
    virtual bool Lookup( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Performs a lookup based on the current index scanning forward through
     * the table.
     *
     * \copydetails Lookup()
     */
    virtual bool LookupForward( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /**	Performs a lookup based on the current index scanning backward through
     * the table.
     *
     * To specify the value to search for, set the column value for each column
     * in the index. The cursor is positioned on the last row that matches or
     * is less than the index value. For composite indexes, the ncols parameter
     * specifies the number of columns to use in the lookup.
     *
     * \param ncols For composite indexes, the number of columns to use in the
     *              lookup.
     * \return False if the resulting cursor position is set before the first
     *         row.
     */
    virtual bool LookupBackward( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Prepares to perform a new Find call on a table by entering find mode.
     *
     * You may only set columns in the index that the table was opened with. 
     * This method cannot be called if the table was opened without an index.
     *
     * \return True on success; otherwise, returns false.
     */
    virtual bool FindBegin() = 0;

    /** Performs an exact match lookup based on the current index scanning
     * forward through the table.
     *
     * To specify the value to search for, set the column value for each column
     * in the index. The cursor is positioned on the first row that exactly
     * matches the index value.
     *
     * \param ncols For composite indexes, the number of columns to use
     *              during the search.
     * \return If no row matches the index value, the cursor position is 
     *         set after the last row and the method returns false.
     */
    virtual bool Find( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Performs an exact match lookup based on the current index scanning
     * forward through the table.
     *
     * \copydetails Find()
     */
    virtual bool FindFirst( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Performs an exact match lookup based on the current index scanning
     * backward through the table.
     *
     * To specify the value to search for, set the column value for each column
     * in the index. The cursor is positioned on the first row that exactly
     * matches the index value.
     *
     * \param ncols For composite indexes, the number of columns to use during 
     *              the search.
     * \return If no row matches the index value, the cursor position is set
     *         before the first row and the method returns false.
     */
    virtual bool FindLast( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Gets the next row that exactly matches the index.
     *
     * \param ncols For composite indexes, the number of columns to use during
     *              the search.
     * \return False if no more rows match the index.  In this case, the cursor
     *         is positioned after the last row.
     */
    virtual bool FindNext( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
	
    /** Gets the previous row that exactly matches the index.
     *
     * \param ncols For composite indexes, the number of columns to use
     *              during the search.
     * \return False if no more rows match the index.  In this case, the cursor
     *         is positioned before the first row.
     */
    virtual bool FindPrevious( ul_column_num ncols = UL_MAX_NCOLS ) = 0;
};

/** Represents the schema of an UltraLite result set.
 */
class ULResultSetSchema
{
  public:
    /** Gets the ULConnection object.
     *
     * \return The ULConnection object associated with this result set schema.
     */
    virtual ULConnection * GetConnection() const = 0;

    /** Gets the number of columns in the result set or table.
     *
     * \return The number of columns in the result set or table.
     */
    virtual ul_column_num GetColumnCount() const = 0;

    /** Gets the 1-based column ID from its name.
     *
     * \param columnName The column name.
     * \return 0 if the column does not exist; otherwise, returns 
     * SQLE_COLUMN_NOT_FOUND if the column name does not exist.
     */
    virtual ul_column_num GetColumnID( const char * columnName ) const = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets the 1-based column ID from its name.
     *
     * \copydetails GetColumnID()
     */
    virtual ul_column_num GetColumnID( const ul_wchar * columnName ) const = 0;
    #endif

    /** Gets the name of a column given its 1-based ID.
     * 
     * Depending on the type selected and how the column was declared in the 
     * SELECT statement, the column name may be returned in the form [table-
     * name].[column-name].
     *
     * The type parameter is used to specify what type of column
     * name to return.
     *
     * \param cid The 1-based ordinal column number.
     * \param type The desired column name type.
     * \return A pointer to a string buffer containing the column name, if
     *         found.  The pointer points to a static buffer whose contents may
     *         be changed by any subsequent UltraLite call, so you need to make
     *         a copy of the value if you need to keep it for a while.  If the 
     *         column does not exist, NULL is returned and SQLE_COLUMN_NOT_FOUND
     *         is set.
     *
     * \see ul_column_name_type
     */
    virtual const char * GetColumnName(
        ul_column_num		cid,
	ul_column_name_type	type = ul_name_type_sql ) const = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of a column given its 1-based ID.
     *
     * \copydetails GetColumnName()
     */
    virtual const ul_wchar * GetColumnNameW2(
        ul_column_num		cid,
	ul_column_name_type	type = ul_name_type_sql ) const = 0;
    #endif

    /** Gets the storage/host variable type of a column.
     *
     * \param cid The 1-based ordinal column number.
     * \return UL_TYPE_BAD_INDEX if the column does not exist.
     * 
     * \apilink{ul_column_storage_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-storage-type-enu"}
     */
    virtual ul_column_storage_type GetColumnType( ul_column_num cid ) const = 0;
	
    /** Gets the SQL type of a column.
     * 
     * \param cid The 1-based ordinal column number.
     * \return UL_SQLTYPE_BAD_INDEX if the column does not exist.
     *
     * \apilink{ul_column_sql_type, "ulc", "ulc-ulcom-ulglobal-h-fil-ul-column-sql-type-enu"}
     */
    virtual ul_column_sql_type GetColumnSQLType( ul_column_num cid ) const = 0;
	
    /** Gets the size of the column.
     * 
     * \param cid The 1-based ordinal column number.
     * \return 0 if the column does not exist or if the column type does not
     *         have a variable length.  SQLE_COLUMN_NOT_FOUND is set if the 
     *         column name  does not exist.  SQLE_DATATYPE_NOT_ALLOWED is set if
     *         the column type is not UL_SQLTYPE_CHAR or UL_SQLTYPE_BINARY.
     */
    virtual size_t GetColumnSize( ul_column_num cid ) const = 0;
	
    /** Gets the scale of a numeric column.
     *
     * \param cid The 1-based ordinal column number.
     * \return 0 if the column is not a numeric type or if the column does not
     *         exist.  SQLE_COLUMN_NOT_FOUND is set if the column name does not
     *         exist. SQLE_DATATYPE_NOT_ALLOWED is set if the column type is not 
     *         numeric.
     */
    virtual size_t GetColumnScale( ul_column_num cid ) const = 0;
	
    /** Gets the precision of a numeric column.
     *
     * \param cid The 1-based ordinal column number.
     * \return 0 if the column is not a numeric type or if the column does not
     *         exist. SQLE_COLUMN_NOT_FOUND is set if the column name does not
     *         exist. SQLE_DATATYPE_NOT_ALLOWED is set if the column type is not
     *         numeric.
     */
    virtual size_t GetColumnPrecision( ul_column_num cid ) const = 0;

    /** Indicates whether the column in a result set was given an alias.
     *
     * \param cid The 1-based ordinal column number.
     * \return True if the column is aliased; otherwise, returns false.
     */
    virtual bool IsAliased( ul_column_num cid ) const = 0;
};

typedef ul_u_long			ul_table_iter;

/** Used by the GetNextTable method to initialize table iteration in a database.
 *
 * \see ULDatabaseSchema::GetNextTable()
 */
#define ul_table_iter_start		1

typedef ul_u_long			ul_publication_iter;

/** Used by the GetNextPublication method to initialize publication iteration
 * in a database.
 * 
 * \see ULDatabaseSchema::GetNextPublication()
 */
#define ul_publication_iter_start	1

typedef ul_u_long			ul_index_iter;

/** Used by the GetNextIndex method to initialize index iteration in a table.
 * 
 * \see ULTableSchema::GetNextIndex()
 */
#define ul_index_iter_start		1

/** Represents the schema of an UltraLite database.
 */
class ULDatabaseSchema
{
  public:
    /** Destroys this object.
     */
    virtual void Close() = 0;

    /** Gets the ULConnection object.
     *
     * \return The ULConnection associated with this object.
     */
    virtual ULConnection * GetConnection() = 0;

    /** Returns the number of tables in the database.
     *
     * \return An integer that represents the number of tables.
     */
    virtual ul_table_num GetTableCount() = 0;

    /** Gets the next table (schema) in the database.
     *
     * Initialize the iter value to the ul_table_iter_start constant before the 
     * first call.
     *
     * \param iter A pointer to the iterator variable.
     * \return A ULTableSchema object or NULL when the iteration is complete.
     *
     * \see ul_table_iter_start
     */
    virtual ULTableSchema * GetNextTable( ul_table_iter * iter ) = 0;

    /** Returns the schema of the named table.
     *
     * \param tableName The name of the table.
     * \return A ULTableSchema object for the given table; otherwise, returns
     *         UL_NULL if the table does not exist.
     */
    virtual ULTableSchema * GetTableSchema( const char * tableName ) = 0;

    #ifdef UL_WCHAR_API
    /** Returns the schema of the named table.
     *
     * \copydetails GetTableSchema()
     */
    virtual ULTableSchema * GetTableSchema( const ul_wchar * tableName ) = 0;
    #endif

    /** Gets the number of publications in the database.
     *
     * Publication IDs range from 1 to the number returned by this method.
     *
     * \return The number of publications in the database.
     */
    virtual ul_publication_count GetPublicationCount() = 0;

    /** Gets the name of the next publication in the database.
     *
     * Initialize the iter value to the ul_publication_iter_start constant 
     * before the first call.
     *
     * \param iter A pointer to the iterator variable.
     * \return The name of the next publication.  This value points to a
     *         static buffer whose contents may be changed by any subsequent
     *         UltraLite call, so make a copy of the value if you need to retain
     *         it.  NULL is returned when the iteration is complete.
     *
     * \see ul_publication_iter_start
     */
    virtual const char * GetNextPublication( ul_publication_iter * iter ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of the next publication in the database.
     *
     * \copydetails GetNextPublication
     */
    virtual const ul_wchar * GetNextPublicationW2( ul_publication_iter * iter ) = 0;
    #endif
};

/** Identifies a column default type.
 *
 * \see ULTableSchema::GetColumnDefaultType
 * \hideinitializers
 */
enum ul_column_default_type {
    ul_column_default_none,		    ///< The column has no default value.
    ul_column_default_autoincrement,	    ///< The column default is AUTOINCREMENT.
    ul_column_default_global_autoincrement, ///< The column default is GLOBAL AUTOINCREMENT.
    ul_column_default_current_timestamp,    ///< The column default is CURRENT TIMESTAMP.
    ul_column_default_current_utc_timestamp,///< The column default is CURRENT UTC TIMESTAMP.
    ul_column_default_current_time,	    ///< The column default is CURRENT TIME.
    ul_column_default_current_date,	    ///< The column default is CURRENT DATE.
    ul_column_default_newid,		    ///< The column default is NEWID().
    ul_column_default_other		    ///< The column default is a user-specified constant.
};

/** Identifies a table synchronization type.
 *
 * \see ULTableSchema::GetTableSyncType
 * \hideinitializers
 */
enum ul_table_sync_type {
    /** All changed rows are synchronized, which is the default behavior.
     *
     * This initializer corresponds to the SYNCHRONIZE ON clause in a CREATE 
     * TABLE statement.
     */
    ul_table_sync_on,
    /** Table is never synchronized.
     *
     * This initializer corresponds to the SYNCHRONIZE OFF clause in a CREATE
     * TABLE statement.
     */
    ul_table_sync_off,
    /** Always upload every row, including unchanged rows.
     *
     * This initializer corresponds to the SYNCHRONIZE ALL clause in a CREATE
     * TABLE statement.
     */
    ul_table_sync_upload_all_rows,
    /** Changes are never uploaded.
     *
     * This initializer corresponds to the SYNCHRONIZE DOWNLOAD clause in a
     * CREATE TABLE statement.
     */
    ul_table_sync_download_only
};

/** Represents the schema of an UltraLite table.
 */
class ULTableSchema :
    public ULResultSetSchema
{
  public:
    /** Destroys this object.
    */
    virtual void Close() = 0;

    /** Gets the name of the table.
     *
     * \return The name of the table.  This value points to a static buffer
     *         whose contents may be changed by any subsequent UltraLite call, 
     *         so make a copy of the value if you need to retain it.
     */
    virtual const char * GetName() = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of the table.
     *
     * \copydetails GetName()
     */
    virtual const ul_wchar * GetNameW2() = 0;
    #endif

    /** Gets the default value for the column if it exists.
     *
     * \param cid A 1-based ordinal column number.
     * \return The default value.  An empty string is returned if the column has
     *         no default value.  This value points to a static buffer whose
     *         contents may be changed by any subsequent UltraLite call, so
     *         make a copy of the value if you need to retain it.
     */
    virtual const char * GetColumnDefault( ul_column_num cid ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the default value for the column if it exists.
     *
     * \copydetails GetColumnDefault()
     */
    virtual const ul_wchar * GetColumnDefaultW2( ul_column_num cid ) = 0;
    #endif

    /** Gets the type of column default.
     *
     * \param cid A 1-based ordinal column number.
     * \return The type of column default.
     *
     * \see ul_column_default_type
     */
    virtual ul_column_default_type GetColumnDefaultType( ul_column_num cid ) = 0;
	
    /** Checks whether the specified column is nullable.
     *
     * \param cid A 1-based ordinal column number.
     * \return True if the column is nullable; otherwise, returns false.
     */
    virtual bool IsColumnNullable( ul_column_num cid ) = 0;
	
    /** Determines the best index to use for searching for a column value.
     *
     * \param cid A 1-based ordinal column number.
     * \return The name of the index or NULL if the column isn't indexed.
     *         This value points to a static buffer whose contents may be 
     *         changed by any subsequent UltraLite call, so make a copy of the
     *         value if you need to keep it for a while.
     */
    virtual const char * GetOptimalIndex( ul_column_num cid ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Determines the best index to use for searching for a column value.
     *
     * \copydetails GetOptimalIndex()
     */
    virtual const ul_wchar * GetOptimalIndexW2( ul_column_num cid ) = 0;
    #endif

    /** Gets the partition size.
     *
     * \param cid A 1-based ordinal column number.
     * \param size An output parameter. The partition size for the column. All
     *             global autoincrement columns in a given table share the same
     *             global autoincrement partition.
     * \return True on success; otherwise, returns false.
     */
    virtual bool GetGlobalAutoincPartitionSize(
        ul_column_num		cid,
	ul_u_big *		size ) = 0;

    /** Gets the table synchronization type.
     *
     * This method indicates how the table participates in synchronization, and
     * is defined when the table is created with the SYNCHRONIZE constraint
     * clause of the CREATE TABLE statement.
     *
     * \return The table synchronization type.
     *
     * \see ul_table_sync_type.
     */
    virtual ul_table_sync_type GetTableSyncType() = 0;

    /** Checks whether the column is contained in the named index.
     *
     * \param cid A 1-based ordinal column number.
     * \param indexName The name of the index.
     * \return True if the column is contained in the index; otherwise, returns 
     *         false.
     */
    virtual bool IsColumnInIndex(
        ul_column_num		cid,
	const char *		indexName ) = 0;

    #ifdef UL_WCHAR_API
    /** Checks whether the column is contained in the named index.
     *
     * \copydetails IsColumnInIndex()
     */
    virtual bool IsColumnInIndex(
        ul_column_num		cid,
	const ul_wchar *	indexName ) = 0;
    #endif

    /** Gets the number of indexes in the table.
     *
     * Index IDs and counts may change during a schema upgrade. To correctly
     * identify an index, access it by name or refresh any cached IDs and
     * counts after a schema upgrade.
     *
     * \return The number of indexes in the table.
     */
    virtual ul_index_num GetIndexCount() = 0;

    /** Gets the next index (schema) in the table.
     *
     * Initialize the iter value to the ul_index_iter_start constant before the
     * first call.
     *
     * \param iter A pointer to the iterator variable.
     * \return A ULIndexSchema object, or NULL when the iteration is complete.
     *
     * \see ul_index_iter_start
     */
    virtual ULIndexSchema * GetNextIndex( ul_index_iter * iter ) = 0;

    /** Gets the schema of an index, given the name.
     * 
     * \param indexName The name of the index.
     * \return A ULIndexSchema object for the specified index, or NULL if the
     *         object does not exist.
     */
    virtual ULIndexSchema * GetIndexSchema( const char * indexName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets the schema of an index given its name.
     *
     * \copydetails GetIndexSchema()
     */
    virtual ULIndexSchema * GetIndexSchema( const ul_wchar * indexName ) = 0;
    #endif

    /** Gets the primary key for the table.
     *
     * \return a ULIndexSchema object for the table's primary key.
     */
    virtual ULIndexSchema * GetPrimaryKey() = 0;

    /** Checks whether the table is contained in the named publication.
     *
     * \param pubName The name of the publication.
     * \return True if the table is contained in the publication; otherwise, 
     *         returns false.
     */
    virtual bool InPublication( const char * pubName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Checks whether the table is contained in the named publication.
     *
     * \copydetails InPublication()
     */
    virtual bool InPublication( const ul_wchar * pubName ) = 0;
    #endif

    /** Gets the publication predicate as a string.
     *
     * \param pubName The name of the publication.
     * \return The publication predicate string for the specified publication.  
     *         This value points to a static buffer whose contents may be 
     *         changed by any subsequent UltraLite call, so make a copy of the
     *         value if you need to retain it.
     */
    virtual const char * GetPublicationPredicate( const char * pubName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets the publication predicate as a string.
     *
     * \copydetails GetPublicationPredicate()
     */
    virtual const ul_wchar * GetPublicationPredicate( const ul_wchar * pubName ) = 0;
    #endif
};

/** Flags (bit fields) which identify properties of an index.
 *
 * \see ULIndexSchema::GetIndexFlags()
 * \hideinitializers
 */
enum ul_index_flag {
    /// The index is a primary key.
    ul_index_flag_primary_key			= 0x0001,
    /// The index is a primary key or index created for a unique constraint
    /// (nulls not allowed).
    ul_index_flag_unique_key			= 0x0002,
    /// The index was created with the UNIQUE flag (or is a primary key).
    ul_index_flag_unique_index			= 0x0004,
    /// The index is a foreign key.
    ul_index_flag_foreign_key			= 0x0010,
    /// The foreign key allows nulls.
    ul_index_flag_foreign_key_nullable		= 0x0020,
    /// Referential integrity checks are performed on commit (rather than on
    /// insert/update).
    ul_index_flag_foreign_key_check_on_commit	= 0x0040
};

/** Represents the schema of an UltraLite table index.
 */
class ULIndexSchema
{
  public:
    /** Destroys this object.
    */
    virtual void Close() = 0;

    /** Gets the ULConnection object.
     * 
     * \return The connection associated with this object.
     */
    virtual ULConnection * GetConnection() = 0;

    /** Gets the name of the index.
     *
     * \return The name of the index.  This value points to a static buffer 
     *         whose contents may be changed by any subsequent UltraLite call,
     *         so make a copy of the value if you need to retain it.
     */
    virtual const char * GetName() = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of the index.
     *
     * \copydetails GetName()
     */
    virtual const ul_wchar * GetNameW2() = 0;
    #endif

    /** Gets the name of the table containing this index.
     *
     * \return The name of the table containing this index.  This value points
     *         to a static buffer whose contents may be changed by any 
     *         subsequent UltraLite call, so make a copy of the value if you
     *         need to retain it.
     */
    virtual const char * GetTableName() = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of the table containing this index.
     *
     * \copydetails GetTableName()
     */
    virtual const ul_wchar * GetTableNameW2() = 0;
    #endif

    /** Gets the number of columns in the index.
     *
     * \return The number of columns in the index.
     */
    virtual ul_column_num GetColumnCount() = 0;

    /** Gets the name of the column given the position of the column in the
     * index.
     *
     * \param col_id_in_index The 1-based ordinal number indicating the position
     *                        of the column in the index.
     * \return The name of the column.  This value points to a static buffer
     *         whose contents may be changed by any subsequent UltraLite call, 
     *         so make a copy of the value if you need to retain it.
     */
    virtual const char * GetColumnName( ul_column_num col_id_in_index ) = 0;

    #ifdef UL_WCHAR_API
    /** Gets the name of the column given the position of the column in the
     * index.
     *
     * \copydetails GetColumnName()
     */
    virtual const ul_wchar * GetColumnNameW2( ul_column_num col_id_in_index ) = 0;
    #endif

    /** Gets the 1-based index column ID from its name.
     *
     * \param columnName The column name.
     * \return 0, and sets SQLE_COLUMN_NOT_FOUND if the column name does not
     *         exist.
     */
    virtual ul_column_num GetIndexColumnID( const char * columnName ) = 0;
	
    #ifdef UL_WCHAR_API
    /** Gets the 1-based index column ID from its name.
     *
     * \copydetails GetIndexColumnID()
     */
    virtual ul_column_num GetIndexColumnID( const ul_wchar * columnName ) = 0;
    #endif

    /** Determines if the column is in descending order.
     *
     * \param cid The 1-based ordinal column number.
     * \return True if the column is in descending order; otherwise, returns
     *         false.
     */
    virtual bool IsColumnDescending( ul_column_num cid ) = 0;

    /** Gets the index property flags bit field.
     *
     * \see ul_index_flag
     */
    virtual ul_index_flag GetIndexFlags() = 0;

    /** Gets the associated primary index name.
     *
     * This method applies to foreign keys only.
     *
     * \return The name of the referenced index.  This value points to a static
     *         buffer whose contents may be changed by any subsequent UltraLite
     *         call, so make a copy of the value if you need to retain it.
     */
    virtual const char * GetReferencedIndexName() = 0;
    
    #ifdef UL_WCHAR_API
    /** Gets the associated primary index name.
     *
     * \copydetails GetReferencedIndexName()
     */
    virtual const ul_wchar * GetReferencedIndexNameW2() = 0;
    #endif

    /** Gets the associated primary table name.
     *
     * This method applies to foreign keys only.
     *
     * \return The name of the referenced table.  This value points to a static
     *         buffer whose contents may be changed by any subsequent UltraLite
     *         call, so make a copy of the value if you need to retain it.
     */
    virtual const char * GetReferencedTableName() = 0;
    
    #ifdef UL_WCHAR_API
    /** Gets the associated primary table name.
     *
     * \copydetails GetReferencedTableName()
     */
    virtual const ul_wchar * GetReferencedTableNameW2() = 0;
    #endif
};

#endif
