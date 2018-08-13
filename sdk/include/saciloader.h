// ***************************************************************************
// Copyright (c) 2014 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef _SACILOADER_H_INCLUDED
#define _SACILOADER_H_INCLUDED

#include "saci.h"

#if defined( __cplusplus )
extern "C" {
#endif

typedef a_saci_version (SACI_FN *saci_version_func)( void );

struct saci_env_iface {
    SACIEnvironmentH	(SACI_FN *create_func)( const a_saci_callbacks *, void *,
						a_saci_user_option *,
						const char *, a_saci_error * );
    void		(SACI_FN *destroy_func)( SACIEnvironmentH );
    a_saci_bool		(SACI_FN *stream_alg_func)(
	SACIEnvironmentH, const char * );
    a_saci_bool		(SACI_FN *stream_alg_id_func)(
	SACIEnvironmentH, a_saci_byte );
    a_saci_bool		(SACI_FN *block_enc_alg_func)(
	SACIEnvironmentH, const char * );
    a_saci_bool		(SACI_FN *block_enc_alg_id_func)(
	SACIEnvironmentH, a_saci_byte );
    a_saci_bool		(SACI_FN *block_hash_alg_func)(
	SACIEnvironmentH, const char * );
    a_saci_bool		(SACI_FN *block_hash_alg_id_func)(
	SACIEnvironmentH, a_saci_byte );
    a_saci_bool		(SACI_FN *pw_hash_alg_func)(
	SACIEnvironmentH, const char * );
    a_saci_bool		(SACI_FN *pw_hash_alg_id_func)(
	SACIEnvironmentH, a_saci_byte );
};

struct saci_error_iface {
    void		(SACI_FN *destroy_func)( SACIEnvironmentH, a_saci_error * );
};

struct saci_stream_iface {
    SACIStreamH		(SACI_FN *create_func)( SACIEnvironmentH,
                                	        const a_saci_stream_callbacks *,
						void *, const char *,
						a_saci_error * );
    SACIStreamH		(SACI_FN *create_with_id_func)( SACIEnvironmentH,
							const a_saci_stream_callbacks *,
							void *, a_saci_byte,
							a_saci_error * );
    a_saci_status	(SACI_FN *init_func)( SACIStreamH, a_saci_side,
					      a_saci_user_option * );
    a_saci_byte		(SACI_FN *get_algorithm_id_func)( SACIStreamH );
    void		(SACI_FN *fini_func)( SACIStreamH );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACIStreamH );
    void		(SACI_FN *destroy_func)( SACIStreamH );
    a_saci_bool		(SACI_FN *is_synchronous_func)( SACIStreamH );
};

struct saci_stream_conn_iface {
    SACIStreamConnH	(SACI_FN *create_func)( SACIStreamH,
						const a_saci_conn_callbacks *,
                                 	        void *, a_saci_user_option *,
						a_saci_error * );
    a_saci_io_status	(SACI_FN *read_func)( SACIStreamConnH, a_saci_byte *, size_t, size_t * );
    a_saci_io_status	(SACI_FN *write_func)( SACIStreamConnH, const a_saci_byte *, size_t );
    a_saci_io_status	(SACI_FN *flush_writes_func)( SACIStreamConnH );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACIStreamConnH );
    void		(SACI_FN *destroy_func)( SACIStreamConnH );
};

struct saci_password_hasher_iface {
    SACIPasswordHasherH	(SACI_FN *create_func)( SACIEnvironmentH, a_saci_error * );
    SACIPasswordHasherH	(SACI_FN *create_with_id_func)( SACIEnvironmentH,
							a_saci_byte,
							a_saci_error * );
    a_saci_byte		(SACI_FN *get_algorithm_id_func)( SACIPasswordHasherH );
    size_t		(SACI_FN *get_max_hash_size_func)( SACIPasswordHasherH );
    a_saci_status	(SACI_FN *hash_func)( SACIPasswordHasherH, const a_saci_byte *, size_t, a_saci_byte *, size_t );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACIPasswordHasherH );
    void		(SACI_FN *destroy_func)( SACIPasswordHasherH );
};

struct saci_block_hasher_iface {
    SACIBlockHasherH	(SACI_FN *create_func)( SACIEnvironmentH, const char *,
						a_saci_error * );
    SACIBlockHasherH	(SACI_FN *create_with_id_func)( SACIEnvironmentH,
							a_saci_byte,
							a_saci_error * );
    a_saci_byte		(SACI_FN *get_algorithm_id_func)( SACIBlockHasherH );
    unsigned int	(SACI_FN *get_max_hash_size_func)( SACIBlockHasherH );
    size_t		(SACI_FN *get_block_size_func)( SACIBlockHasherH );
    a_saci_status	(SACI_FN *begin_hash_func)( SACIBlockHasherH );
    a_saci_status	(SACI_FN *add_data_func)( SACIBlockHasherH, const a_saci_byte *,
						  size_t );
    a_saci_status	(SACI_FN *end_hash_func)( SACIBlockHasherH, a_saci_byte *, size_t );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACIBlockHasherH );
    void		(SACI_FN *destroy_func)( SACIBlockHasherH );
};

struct saci_block_encrypter_iface {
    SACIBlockEncrypterH	(SACI_FN *create_func)( SACIEnvironmentH, const char *,
						const a_saci_byte *, size_t,
						a_saci_user_option *,
						a_saci_error * );
    SACIBlockEncrypterH	(SACI_FN *create_with_id_func)( SACIEnvironmentH,
							a_saci_byte,
							const a_saci_byte *,
							size_t,
							a_saci_user_option *,
							a_saci_error * );
    a_saci_byte		(SACI_FN *get_algorithm_id_func)( SACIBlockEncrypterH );
    a_saci_status	(SACI_FN *encrypt_func)( SACIBlockEncrypterH, a_saci_byte *,
						 size_t, unsigned );
    a_saci_status	(SACI_FN *decrypt_func)( SACIBlockEncrypterH, a_saci_byte *,
						 size_t, unsigned );
    a_saci_status	(SACI_FN *encrypt_with_iv_func)( SACIBlockEncrypterH,
							 a_saci_byte *,
							 size_t,
							 a_saci_byte *,
							 size_t );
    a_saci_status	(SACI_FN *decrypt_with_iv_func)( SACIBlockEncrypterH,
							 a_saci_byte *,
							 size_t,
							 a_saci_byte *,
							 size_t );
    size_t		(SACI_FN *get_block_size_func)( SACIBlockEncrypterH );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACIBlockEncrypterH );
    void		(SACI_FN *destroy_func)( SACIBlockEncrypterH );
};

struct saci_block_encrypter_session_iface {
    SACIBlockEncrypterSessionH	(SACI_FN *create_func)( SACIBlockEncrypterH, a_saci_error * );
    a_saci_status		(SACI_FN *init_func)( SACIBlockEncrypterSessionH, a_saci_bool, a_saci_byte *, size_t );
    a_saci_status		(SACI_FN *do_crypt_func)( SACIBlockEncrypterSessionH, a_saci_byte *, size_t );
    const a_saci_error *	(SACI_FN *get_last_error_func)( SACIBlockEncrypterSessionH );
    void			(SACI_FN *destroy_func)( SACIBlockEncrypterSessionH );
};

struct saci_signature_handler_iface {
    SACISignatureHandlerH	(SACI_FN *create_func)( SACIEnvironmentH,
							a_saci_user_option *,
							a_saci_error * );
    a_saci_status	(SACI_FN *create_dbsig_func)( SACISignatureHandlerH,
						      const char *,
						      const char *,
						      const char *,
						      char *, size_t );
    a_saci_status	(SACI_FN *create_connsig_func)( SACISignatureHandlerH,
							const char *,
							const char *,
							char *, size_t );
    a_saci_status	(SACI_FN *verify_dbsig_func)( SACISignatureHandlerH,
						      const char *,
						      const char *,
						      const char *,
						      const char *,
						      a_saci_bool * );
    a_saci_status	(SACI_FN *verify_connsig_func)( SACISignatureHandlerH,
							const char *,
							const char *,
							const char *,
							a_saci_bool * );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACISignatureHandlerH );
    void		(SACI_FN *destroy_func)( SACISignatureHandlerH );
};

struct saci_license_encrypter_iface {
    SACILicenseEncrypterH	(SACI_FN *create_func)( SACIEnvironmentH,
							a_saci_user_option *,
							a_saci_error * );
    a_saci_status	(SACI_FN *encrypt_func)( SACILicenseEncrypterH,
						 a_saci_byte *, size_t );
    a_saci_status	(SACI_FN *decrypt_func)( SACILicenseEncrypterH,
						 a_saci_byte *, size_t );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACILicenseEncrypterH );
    void		(SACI_FN *destroy_func)( SACILicenseEncrypterH );
};

struct saci_certificate_handler_iface {
    SACICertificateHandlerH	(SACI_FN *create_func)( SACIEnvironmentH,
							a_saci_byte *, size_t,
							a_saci_error * );
    a_saci_certificate_field *	(SACI_FN *describe_func)( SACICertificateHandlerH );
    void			(SACI_FN *free_fields_func)( SACICertificateHandlerH,
							     a_saci_certificate_field * );
    const a_saci_error * (SACI_FN *get_last_error_func)( SACICertificateHandlerH );
    void		(SACI_FN *destroy_func)( SACICertificateHandlerH );
};

typedef a_saci_status (SACI_FN *get_saci_iface_func)( void * iface );

extern a_saci_status SACI_FN SACIGetEnvIface( saci_env_iface * iface );
extern a_saci_status SACI_FN SACIGetErrorIface( saci_error_iface * iface );
extern a_saci_status SACI_FN SACIGetStreamIface( saci_stream_iface * iface );
extern a_saci_status SACI_FN SACIGetStreamConnIface( saci_stream_conn_iface * iface );
extern a_saci_status SACI_FN SACIGetPasswordHasherIface( saci_password_hasher_iface * iface );
extern a_saci_status SACI_FN SACIGetBlockHasherIface( saci_block_hasher_iface * iface );
extern a_saci_status SACI_FN SACIGetBlockEncrypterIface( saci_block_encrypter_iface * iface );
extern a_saci_status SACI_FN SACIGetBlockEncrypterSessionIface( saci_block_encrypter_session_iface * iface );
extern a_saci_status SACI_FN SACIGetSignatureHandlerIface( saci_signature_handler_iface * iface );
extern a_saci_status SACI_FN SACIGetLicenseEncrypterIface( saci_license_encrypter_iface * iface );
extern a_saci_status SACI_FN SACIGetCertificateHandlerIface( saci_certificate_handler_iface * iface );

typedef a_saci_status (SACI_FN *SACIGetEnvIface_t)( saci_env_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetErrorIface_t)( saci_error_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetStreamIface_t)( saci_stream_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetStreamConnIface_t)( saci_stream_conn_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetPasswordHasherIface_t)( saci_password_hasher_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetBlockHasherIface_t)( saci_block_hasher_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetBlockEncrypterIface_t)( saci_block_encrypter_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetBlockEncrypterSessionIface_t)( saci_block_encrypter_session_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetSignatureHandlerIface_t)( saci_signature_handler_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetLicenseEncrypterIface_t)( saci_license_encrypter_iface * iface );
typedef a_saci_status (SACI_FN *SACIGetCertificateHandlerIface_t)( saci_certificate_handler_iface * iface );
typedef a_saci_version (SACI_FN *SACIGetVersion_t)( void );

struct saci_loader_iface {
    SACIGetVersion_t			get_version;
    SACIGetEnvIface_t			get_env_iface;
    SACIGetErrorIface_t			get_error_iface;
    SACIGetStreamIface_t		get_stream_iface;
    SACIGetStreamConnIface_t		get_stream_conn_iface;
    SACIGetPasswordHasherIface_t	get_password_hasher_iface;
    SACIGetBlockHasherIface_t		get_block_hasher_iface;
    SACIGetBlockEncrypterIface_t	get_block_encrypter_iface;
    SACIGetBlockEncrypterSessionIface_t	get_block_encrypter_session_iface;
    SACIGetSignatureHandlerIface_t	get_signature_handler_iface;
    SACIGetLicenseEncrypterIface_t	get_license_encrypter_iface;
    SACIGetCertificateHandlerIface_t	get_certificate_handler_iface;
};

#if defined( __cplusplus )
} // extern "C"
#endif

#endif

