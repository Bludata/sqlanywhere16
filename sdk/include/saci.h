// ***************************************************************************
// Copyright (c) 2014 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/*
 * saci.h - API to help 3rd-parties (eg. customers) add their own crypto
 * layer to our software.
 */

#ifndef _SACI_H_INCLUDED
#define _SACI_H_INCLUDED

#if defined( UNDER_PALM_OS ) && !defined( _SIZE_T_DEFINED )
    #define _SIZE_T_DEFINED_
    #define _SIZE_T
    typedef unsigned long	size_t;
#endif

#if defined( UNIX )
    #include <sys/types.h>
#endif

#if defined( UNDER_CE )
#include <windef.h> // for __stdcall
#endif
#ifdef WIN32
    #define SACI_FN	__stdcall
#else
    #define SACI_FN
#endif

#if defined( __cplusplus )
extern "C" {
#endif

typedef unsigned char a_saci_byte;
typedef unsigned char a_saci_bool;
typedef unsigned int a_saci_uint32;

#define SACI_HASH_SHA256	1
#define SACI_HASH_SHA256_FIPS	2
#define SACI_HASH_SHA1		3
#define SACI_HASH_SHA1_FIPS	4
#define SACI_HASH_MD5		5
#define SACI_HASH_CRC32		6

// Client or Server?
typedef enum {
    SACI_CLIENT,
    SACI_SERVER
} a_saci_side;

// Status returned by most methods.
typedef enum {
    SACI_OK,
    SACI_ERROR
} a_saci_status;

// For asynchronous encryption/decryption requirement, we might have
// used a new return, eg. SACI_IO_BLOCKED, but instead we have done
// the following:
//  - Writes and flushes return WOULD_BLOCK on internal async blockage
//	- Works because the server-side WriteCB never returns WOULD_BLOCK itself
//  - Reads return WOULD_BLOCK for both external (eg. our ReadCB)
//    and internal async blockage
//	- Works because the server-side SACI block can distinguish an internal
//	  blockage from external blockage as follows:
//	    - INTERNAL if the last ReadCB call for this connection returned bytes
//	    - EXTERNAL if the last ReadCB call for this connection returned no bytes

// Status returned by most I/O methods.
typedef enum {
    SACI_IO_OK,
    SACI_IO_ERROR,
    SACI_IO_WOULD_BLOCK,    // The underlying I/O would have to block to satisfy the request.
    SACI_IO_GRACEFUL_CLOSE  // The other side has closed the connection
} a_saci_io_status;

/* Callback typedefs
 */
typedef void * (*a_saci_alloc_cb)(
    void *			global_context,
    size_t			length );
typedef void * (*a_saci_realloc_cb)(
    void *			global_context,
    void *			ptr,
    size_t			new_length );
typedef void   (*a_saci_free_cb)(
    void *			global_context,
    void *			ptr );
typedef unsigned long (*a_saci_threadid_cb)(
    void *			global_context );
typedef void * (*a_saci_mutex_create_cb)(
    void *			global_context );
typedef void   (*a_saci_mutex_destroy_cb)(
    void *			global_context,
    void *			mutex );
typedef void   (*a_saci_mutex_get_cb)(
    void *			global_context,
    void *			mutex );
typedef void   (*a_saci_mutex_give_cb)(
    void *			global_context,
    void *			mutex );

typedef void (*a_saci_thread_proc)( void *thread_context );

typedef a_saci_status (*a_saci_create_thread_cb)(
    void *			global_context,
    a_saci_thread_proc	        proc,
    void *			thread_context );

// log_level: 
//  0   ==> always log
//  1-9 ==> log in debug mode only
#define SACI_LOG_MESSAGE	  0
typedef a_saci_status (*a_saci_log_cb)(
    void *			context,
    int				log_level,
    const char *		text,
    const a_saci_byte *		data,
    size_t			data_len );

// Callback struct.
typedef struct {
    a_saci_alloc_cb		alloc_cb;
    a_saci_realloc_cb		realloc_cb;
    a_saci_free_cb		free_cb;
    a_saci_log_cb		log_cb;
    a_saci_threadid_cb		threadid_cb;
    a_saci_mutex_create_cb	mutex_create_cb;
    a_saci_mutex_destroy_cb	mutex_destroy_cb;
    a_saci_mutex_get_cb		mutex_get_cb;
    a_saci_mutex_give_cb	mutex_give_cb;
    a_saci_create_thread_cb	create_thread_cb;
} a_saci_callbacks;

typedef struct {
    a_saci_log_cb     log_cb;
} a_saci_stream_callbacks;

// Can return any status
typedef a_saci_io_status (*a_saci_read_cb)(
    void *			conn_context,
    a_saci_byte *		buffer,
    size_t			buffer_len,
    size_t *			read_len );

// Can return any status
typedef a_saci_io_status (*a_saci_write_cb)(
    void *			conn_context,
    const a_saci_byte *		buffer,
    size_t			buffer_len );

typedef a_saci_status (*a_saci_blocked_io_complete_cb)(
    void *			conn_context );

typedef a_saci_status (*a_saci_check_client_cert_cb)(
    void *			conn_context,
    const a_saci_byte *		cert,
    size_t			cert_len );

typedef struct {
    a_saci_read_cb		    read_cb;
    a_saci_write_cb		    write_cb;
    a_saci_log_cb		    log_cb;
    a_saci_blocked_io_complete_cb   blocked_io_complete_cb;
    a_saci_check_client_cert_cb	    check_client_cert_cb;
} a_saci_conn_callbacks;

// Option struct.
// Any function that takes a_saci_user_option * should set the "used"
// field to TRUE if that function uses the given option.
// The caller is responsible for setting "used" to FALSE before the call.
typedef struct _a_saci_user_option {
    const char  *			opt_name;
    const char  *			opt_value;
    a_saci_bool				used;
    struct _a_saci_user_option *	next;
} a_saci_user_option;

/* Typedefs for handles */
typedef struct SACIEnvironment *	SACIEnvironmentH;
typedef struct SACIStream *		SACIStreamH;
typedef struct SACIStreamConn *		SACIStreamConnH;
typedef struct SACIPasswordHasher *	SACIPasswordHasherH;
typedef struct SACIBlockHasher *	SACIBlockHasherH;
typedef struct SACIBlockEncrypter *	SACIBlockEncrypterH;
typedef struct SACIBlockEncrypterSession *  SACIBlockEncrypterSessionH;
typedef struct SACISignatureHandler *	SACISignatureHandlerH;
typedef struct SACILicenseEncrypter *	SACILicenseEncrypterH;
typedef struct SACICertificateHandler * SACICertificateHandlerH;

// ***************************************************/
// *        Error structure and functions            */
// ***************************************************/

typedef struct {
#ifndef EASTPORT
    // these members are used internally by SA
    unsigned long	code;
    unsigned long	system_code;
    char **		parm_list;
#endif
    // these members are used for custom encryption
    a_saci_bool		is_set;
    a_saci_bool		is_allocated;
    char *		description;
} a_saci_error;

// Frees the _parm_list, but does not destroy the object itself. You only
// need to call this if the object you are trying to create is not created.
void SACI_FN SACIError_Destroy( SACIEnvironmentH env, a_saci_error *err );

// ***************************************************/
// *            Protocol version                     */
// ***************************************************/

// The API version
#define SACI_VERSION_MAJOR		1
// minor version 1: original implementation
// minor version 2: added SignatureHandler functions
// minor version 3: added Is*AlgorithmSupported functions
// minor version 4: added LicenseEncrypter functions
// minor version 5: added a_saci_blocked_io_complete_cb, reworked error struct
// minor version 6: added CertificateHandler functions
// minor version 7: added a_saci_check_client_cert_cb
// minor version 8: added encrypt_with_iv/decrypt_with_iv
// minor version 10: changed the definition of a_saci_error and added SACIBlockEncrypterSession

#define SACI_VERSION_MINOR		10

// The impl_id is the implementation id. Implementors must use the value assigned
// to them by iAnywhere Solutions. The impl_ver field can be used to distinguish
// between different implementation versions for the same vendor.

typedef struct {
    unsigned short	api_major;
    unsigned short	api_minor;
    unsigned short	impl_id;
    unsigned short	impl_ver;
} a_saci_version;

a_saci_version SACI_FN SACIGetVersion( void );

// ***************************************************/
// *             Environment functions               */
// ***************************************************/

#define SACI_COMP_UNSPECIFIED		"Unspecified"
#define SACI_COMP_SA_SERVER		"SA Server"
#define SACI_COMP_SA_CLIENT		"SA Client"
#define SACI_COMP_ML_SERVER		"ML Server"
#define SACI_COMP_MLSYNC		"MLSync"
#define SACI_COMP_ULTRALITE		"UltraLite"
#define SACI_COMP_IQ_SERVER		"IQ Server"

/* If this function returns NULL, the error object is populated. The _code
   field is set, and the _parm_list will contain one or more strings related
   to the error code. Each of these strings will be allocated using the
   alloc_cb callback function -- the caller must free the strings using the
   free_cb.
*/
SACIEnvironmentH SACI_FN SACIEnvironment_Create(
    const a_saci_callbacks *		callbacks,
    void *				global_context,
    a_saci_user_option *		options,
    const char *			component,
    a_saci_error *			error );
void SACI_FN SACIEnvironment_Destroy(
    SACIEnvironmentH			env );

a_saci_bool SACI_FN SACI_IsStreamAlgorithmSupported(
    SACIEnvironmentH	env,
    const char *	alg );
a_saci_bool SACI_FN SACI_IsStreamAlgorithmIDSupported(
    SACIEnvironmentH	env,
    a_saci_byte		alg_id );
a_saci_bool SACI_FN SACI_IsBlockEncrypterAlgorithmSupported(
    SACIEnvironmentH	env,
    const char *	alg );
a_saci_bool SACI_FN SACI_IsBlockEncrypterAlgorithmIDSupported(
    SACIEnvironmentH	env,
    a_saci_byte		alg_id );
a_saci_bool SACI_FN SACI_IsBlockHasherAlgorithmSupported(
    SACIEnvironmentH	env,
    const char *	alg );
a_saci_bool SACI_FN SACI_IsBlockHasherAlgorithmIDSupported(
    SACIEnvironmentH	env,
    a_saci_byte		alg_id );
a_saci_bool SACI_FN SACI_IsPasswordHasherAlgorithmSupported(
    SACIEnvironmentH	env,
    const char *	alg );
a_saci_bool SACI_FN SACI_IsPasswordHasherAlgorithmIDSupported(
    SACIEnvironmentH	env,
    a_saci_byte		alg_id );

// ***************************************************/
// *               Stream functions                  */
// ***************************************************/

/* On the server side, an SACIStreamH is instantiated once per port to listen
 * on.
 * On the client side, an SACIStreamH may be instantiated once per client
 * instance, but doesn't have to be.
 */
/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.
*/
SACIStreamH SACI_FN SACIStream_Create(
    SACIEnvironmentH			env,
    const a_saci_stream_callbacks *	callbacks,
    void *				stream_context,
    const char *			stream_name,
    a_saci_error *			error );

SACIStreamH SACI_FN SACIStream_CreateWithID(
    SACIEnvironmentH			env,
    const a_saci_stream_callbacks *	callbacks,
    void *				stream_context,
    a_saci_byte				stream_id,
    a_saci_error *			error );

a_saci_status SACI_FN SACIStream_Init(
    SACIStreamH				stream,
    a_saci_side				side,
    a_saci_user_option *		options );
			       
a_saci_byte SACI_FN SACIStream_GetAlgorithmID(
    SACIStreamH				stream );
a_saci_bool SACI_FN SACIStream_IsSynchronous(
    SACIStreamH				stream );
void SACI_FN SACIStream_Fini(
    SACIStreamH				stream );
const a_saci_error * SACI_FN SACIStream_GetLastError(
    SACIStreamH				stream );
void SACI_FN SACIStream_Destroy(
    SACIStreamH				stream );

// ***************************************************/
// *          Stream Connection functions            */
// ***************************************************/

/* Open one SACIStreamConnH for each connection.
 */

SACIStreamConnH SACI_FN SACIStreamConn_Create(
    SACIStreamH		     		stream,
    const a_saci_conn_callbacks * 	callbacks,
    void *				conn_context,
    a_saci_user_option *		options,
    a_saci_error *	     		error );

// Can return any status.
a_saci_io_status SACI_FN SACIStreamConn_Read(
    SACIStreamConnH			conn,
    a_saci_byte *			buffer,
    size_t				buffer_len,
    size_t *				read_len );

// Can return any status.
a_saci_io_status SACI_FN SACIStreamConn_Write(
    SACIStreamConnH	    		conn,
    const a_saci_byte *			buffer,
    size_t				buffer_len );

// Can return any status.
a_saci_io_status SACI_FN SACIStreamConn_FlushWrites(
    SACIStreamConnH			conn );
const a_saci_error * SACI_FN SACIStreamConn_GetLastError(
    SACIStreamConnH			conn );
void SACI_FN SACIStreamConn_Destroy(
    SACIStreamConnH			conn );

// ***************************************************/
// *            Password Hasher functions            */
// ***************************************************/

/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.
*/
SACIPasswordHasherH SACI_FN SACIPasswordHasher_Create(
    SACIEnvironmentH			env,
    a_saci_error *			err );
SACIPasswordHasherH SACI_FN SACIPasswordHasher_CreateWithID(
    SACIEnvironmentH			env,
    a_saci_byte				alg_id,
    a_saci_error *			err );

a_saci_byte SACI_FN SACIPasswordHasher_GetAlgorithmID(
    SACIPasswordHasherH			hasher );

// Returns the maximum number of bytes in the output (ie. the hash).
size_t SACI_FN SACIPasswordHasher_GetMaxHashSize(
    SACIPasswordHasherH			hasher );

a_saci_status SACI_FN SACIPasswordHasher_Hash(
    SACIPasswordHasherH			hasher,
    const a_saci_byte *			input,
    size_t				input_len,
    a_saci_byte *			output,
    size_t				output_len );
const a_saci_error * SACI_FN SACIPasswordHasher_GetLastError(
    SACIPasswordHasherH			hasher );
void SACI_FN SACIPasswordHasher_Destroy(
    SACIPasswordHasherH			hasher );


// ***************************************************/
// *             Block Hasher functions              */
// ***************************************************/

/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.
*/
SACIBlockHasherH SACI_FN SACIBlockHasher_Create(
    SACIEnvironmentH			env,
    const char *			algorithm,
    a_saci_error *			error );
SACIBlockHasherH SACI_FN SACIBlockHasher_CreateWithID(
    SACIEnvironmentH			env,
    a_saci_byte				alg_id,
    a_saci_error *			error );

a_saci_byte SACI_FN SACIBlockHasher_GetAlgorithmID(
    SACIBlockHasherH			hasher );

// Returns the maximum number of bytes in the output (ie. the hash).
unsigned int SACI_FN SACIBlockHasher_GetMaxHashSize(
    SACIBlockHasherH			hasher );

// Returns the input block size (if non-zero, input must be a multiple of
// this value in length)
size_t SACI_FN SACIBlockHasher_GetBlockSize(
    SACIBlockHasherH			hasher );
a_saci_status SACI_FN SACIBlockHasher_BeginHash(
    SACIBlockHasherH			hasher );
a_saci_status SACI_FN SACIBlockHasher_AddData(
    SACIBlockHasherH			hasher,
    const a_saci_byte *			input,
    size_t				input_len );
a_saci_status SACI_FN SACIBlockHasher_EndHash(
    SACIBlockHasherH			hasher,
    a_saci_byte *			output,
    size_t				output_len );
const a_saci_error * SACI_FN SACIBlockHasher_GetLastError(
    SACIBlockHasherH			hasher );
void SACI_FN SACIBlockHasher_Destroy(
    SACIBlockHasherH			hasher );

// ***************************************************/
// *           Block Encrypter functions             */
// ***************************************************/
   
/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.

   If the key is NULL, the implementation must generate a random key.
*/
SACIBlockEncrypterH SACI_FN SACIBlockEncrypter_Create(
    SACIEnvironmentH			env,
    const char *			algorithm,
    const a_saci_byte *			key,
    size_t				keylen,
    a_saci_user_option *		options,
    a_saci_error *			error );
SACIBlockEncrypterH SACI_FN SACIBlockEncrypter_CreateWithID(
    SACIEnvironmentH			env,
    a_saci_byte				alg_id,
    const a_saci_byte *			key,
    size_t				keylen,
    a_saci_user_option *		options,
    a_saci_error *			error );

a_saci_byte SACI_FN SACIBlockEncrypter_GetAlgorithmID(
    SACIBlockEncrypterH			encrypter );
// data is encrypted in place
a_saci_status SACI_FN SACIBlockEncrypter_Encrypt(
    SACIBlockEncrypterH 		encrypter,
    a_saci_byte *			data,
    size_t				data_length,
    unsigned				salt );
// data is decrypted in place
a_saci_status SACI_FN SACIBlockEncrypter_Decrypt(
    SACIBlockEncrypterH 		encrypter,
    a_saci_byte *			data,
    size_t				data_length,
    unsigned				salt );
// data is encrypted in place
a_saci_status SACI_FN SACIBlockEncrypter_EncryptWithIV(
    SACIBlockEncrypterH 		encrypter,
    a_saci_byte *			data,
    size_t				data_length,
    a_saci_byte *			iv,
    size_t				iv_length );
// data is decrypted in place
a_saci_status SACI_FN SACIBlockEncrypter_DecryptWithIV(
    SACIBlockEncrypterH 		encrypter,
    a_saci_byte *			data,
    size_t				data_length,
    a_saci_byte *			iv,
    size_t				iv_length );
// Returns the size of each block (i.e. input must be a multiple of this
// value in length)
size_t SACI_FN SACIBlockEncrypter_GetBlockSize(
    SACIBlockEncrypterH			encrypter );
const a_saci_error * SACI_FN SACIBlockEncrypter_GetLastError(
    SACIBlockEncrypterH			encrypter );
void SACI_FN SACIBlockEncrypter_Destroy(
    SACIBlockEncrypterH			encrypter );

SACIBlockEncrypterSessionH SACI_FN SACIBlockEncrypterSession_Create(
    SACIBlockEncrypterH			encrypter,
    a_saci_error *			error );
a_saci_status SACI_FN SACIBlockEncrypterSession_Init(	// can be called multiple times to reuse the session
    SACIBlockEncrypterSessionH		session,
    a_saci_bool				encrypt,	// true to encrypt, false to decrypt
    a_saci_byte *			iv,
    size_t				iv_length );
a_saci_status SACI_FN SACIBlockEncrypterSession_DoCrypt(
    SACIBlockEncrypterSessionH		session,
    a_saci_byte *			data,
    size_t				data_length );
void SACI_FN SACIBlockEncrypterSession_Destroy(
    SACIBlockEncrypterSessionH		session );
const a_saci_error * SACI_FN SACIBlockEncrypterSession_GetLastError(
    SACIBlockEncrypterSessionH		session );

// ***************************************************/
// *         Signature Handler functions             */
// ***************************************************/
   
/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.
*/
SACISignatureHandlerH SACI_FN SACISignatureHandler_Create(
    SACIEnvironmentH			env,
    a_saci_user_option *		options,
    a_saci_error *			error );

a_saci_status SACI_FN SACISignatureHandler_CreateDBSig(
    SACISignatureHandlerH 	handler,
    const char *		company,
    const char *		application,
    const char *		type_str,
    char *			sig,
    size_t			sig_len );
a_saci_status SACI_FN SACISignatureHandler_CreateConnSig(
    SACISignatureHandlerH 	handler,
    const char *		company,
    const char *		application,
    char *			sig,
    size_t			sig_len );
a_saci_status SACI_FN SACISignatureHandler_VerifyDBSig(
    SACISignatureHandlerH 	handler,
    const char *		company,
    const char *		application,
    const char *		type_str,
    const char *		sig,
    a_saci_bool *		verified );
a_saci_status SACI_FN SACISignatureHandler_VerifyConnSig(
    SACISignatureHandlerH 	handler,
    const char *		company,
    const char *		application,
    const char *		sig,
    a_saci_bool *		verified );

const a_saci_error * SACI_FN SACISignatureHandler_GetLastError(
    SACISignatureHandlerH		handler );
void SACI_FN SACISignatureHandler_Destroy(
    SACISignatureHandlerH		handler );

// ***************************************************/
// *         License Encrypter functions             */
// ***************************************************/
   
/* If this function returns NULL, the error object is populated. In this case,
   you must call SACIError_Destroy() to free the parameters.
*/
SACILicenseEncrypterH SACI_FN SACILicenseEncrypter_Create(
    SACIEnvironmentH			env,
    a_saci_user_option *		options,
    a_saci_error *			error );

a_saci_status SACI_FN SACILicenseEncrypter_Encrypt(
    SACILicenseEncrypterH 	handler,
    a_saci_byte *		buffer,
    size_t			buffer_size );
a_saci_status SACI_FN SACILicenseEncrypter_Decrypt(
    SACILicenseEncrypterH 	handler,
    a_saci_byte *		buffer,
    size_t			buffer_len );

const a_saci_error * SACI_FN SACILicenseEncrypter_GetLastError(
    SACILicenseEncrypterH		handler );
void SACI_FN SACILicenseEncrypter_Destroy(
    SACILicenseEncrypterH		handler );

typedef struct _a_saci_certificate_field {
    a_saci_uint32			name_id;
    const char *			value;
    struct _a_saci_certificate_field *	next;
} a_saci_certificate_field;

SACICertificateHandlerH SACI_FN SACICertificateHandler_Create(
    SACIEnvironmentH	env,
    a_saci_byte *	certificate,
    size_t		certificate_len,
    a_saci_error *	error  );
a_saci_certificate_field * SACI_FN SACICertificateHandler_Describe(
    SACICertificateHandlerH	handler );
void SACI_FN SACICertificateHandler_FreeFields(
    SACICertificateHandlerH	handler,
    a_saci_certificate_field *	fields );
const a_saci_error * SACI_FN SACICertificateHandler_GetLastError(
    SACICertificateHandlerH		handler );
void SACI_FN SACICertificateHandler_Destroy(
    SACICertificateHandlerH handler );

#if defined( __cplusplus )
} // extern "C"
#endif

#endif
