// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef EXTENV_H
#define EXTENV_H

#include "consts.h"
#include "sqltype.h"

#if defined( UNIX )
    #include <stddef.h>
#endif

// uncomment to enable tracing
//#define DEBUG_TRACE_FILE "d:\\tmp\\ctrace.txt"

#ifdef DEBUG_TRACE_FILE

#include "dbgtrace.h"
#define dbg_init() _dbg_init( DEBUG_TRACE_FILE )
#define dbg_fini() _dbg_fini()
#define dbg_print( msg ) _dbg_print( __FILE__, __LINE__, msg )
#define dbg_print_d( msg, intval ) _dbg_print_d( __FILE__, __LINE__, msg, intval )

#else

#define dbg_init() 
#define dbg_fini()
#define dbg_print( msg ) 
#define dbg_print_d( msg, intval )

#endif

#ifndef NULL
#define NULL (0)
#endif

struct a_col_desc {
    short	type;
    short	len;
    int      	nullable;
    char	name[256];
};

#ifdef __cplusplus
extern "C" {
#endif

void *EXTENVCALL ee_malloc( size_t sz );
void *EXTENVCALL ee_realloc( void *, size_t sz );
void  EXTENVCALL ee_free( void *p );

struct a_language_loader;

EXTENVRET EXTENVCALL ee_initADO( struct a_language_loader loader, enum DataAccessApi api, void *cb );
EXTENVRET EXTENVCALL ee_init( struct a_language_loader loader, enum DataAccessApi api );
EXTENVRET EXTENVCALL ee_fini();
EXTENVRET EXTENVCALL ee_exit();
EXTENVRET EXTENVCALL ee_connect( const char *eng, const char *dbn, const char *uid, const char *pwd );
EXTENVRET EXTENVCALL ee_mainloop();
EXTENVRET EXTENVCALL ee_get_string( asa_uint32 err_code, char *output, size_t len );

EXTENVRET EXTENVCALL ee_set_error( void *eevm, const char *err );
EXTENVRET EXTENVCALL ee_set_sqlstate( void *eevm, const char *sqlstate );
EXTENVRET EXTENVCALL ee_set_error_id( void *eevm, long id, char *buffer, size_t buflen, const char *arg_str, const char *arg_str2, const char *sqlstate );
EXTENVRET EXTENVCALL ee_set_type_map( int dt, const char *mapped_str );
EXTENVRET EXTENVCALL ee_set_return_separator( char c );
EXTENVRET EXTENVCALL ee_set_arg_separator( char c );
EXTENVRET EXTENVCALL ee_get_arg_chunk( void  *eevm, int argnum, long offset );
EXTENVRET EXTENVCALL ee_get_args( void	*eevm,
				  void	**sqlvars,
				  int	num_args,
				  int	has_return,
				  short	*arg_types );
EXTENVRET EXTENVCALL ee_get_args_chunk( void	*eevm,
					void	**sqlvars,
					int	num_args,
					int	has_return,
					int	chunk_on,
					short	*arg_types );
void *EXTENVCALL ee_get_descriptor( void *eevm );
EXTENVRET EXTENVCALL ee_set_output( void *eevm );
char *EXTENVCALL ee_get_class( void *pi_eevm, const char *class_name );
EXTENVRET EXTENVCALL ee_write_string( void *eevm, const char *str, size_t len );
EXTENVRET EXTENVCALL ee_execute( void *eevm, const char *stmt_text );
EXTENVRET EXTENVCALL ee_execute_any( void *eevm, const char *stmt_text, int num_out_values, char **out_values, size_t *buflens );
void *EXTENVCALL ee_get_conn( void *eevm );
void EXTENVCALL ee_force_exit( void *eevm );
void *EXTENVCALL ee_create_result_set( void *eevm, struct a_col_desc *columns, int num_columns );
void *EXTENVCALL ee_get_result_set_desc( void *rs );
EXTENVRET EXTENVCALL ee_flush_result_set_row( void *rs );

#ifdef __cplusplus
}
#endif
#endif
