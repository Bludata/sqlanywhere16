#include "sqlda.h"
#include "langload.h"
#include "extenv.h"
#include "sqldef.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static void*         EeHandle; 
static SV*	        Exec;
static PerlInterpreter* Interpreter; 

static void* EXTENVCALL create_loader( void* ee_handle )
/**********************************************************/
{
    EeHandle = ee_handle;
    return (void*) 1;
}

static long EXTENVCALL free_loader( void* ll_handle )
/******************************************************/
{
    return EXTENV_OK;
}

static long EXTENVCALL execute( void* ll_handle, const char* method_sig )
/***********************************************************************/
{
    long ret;
    
    PERL_SET_CONTEXT( Interpreter );
    {
	dSP;
    
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( method_sig, 0 ) ) );
	PUTBACK;
	dbg_print( "going into perl." );
	ret = call_sv( Exec, G_SCALAR );
	dbg_print( "back from perl" );
	SPAGAIN;
	if( ret != 0 ) {
	    ret = POPi;
	} else {
	    ret = EXTENV_ERROR;
	}
	FREETMPS;
	LEAVE;
	PUTBACK;
    }

    return ret;
}

static long EXTENVCALL interrupt( void* ll_handle )
/****************************************************/
{
    return 0;
}

static long EXTENVCALL set_thread( void* ll_handle, void* thread_handle )
/**************************************************************************/
{
    return 0;
}

MODULE = SAPerlGlue  		PACKAGE = SAPerlGlue

I32
constant()
    PROTOTYPE:
    ALIAS:
    	IDS_EE_PERL_BAD_BODY                    = 17405
	IDS_EE_PERL_BAD_OPTION                  = 17406
	IDS_EE_PERL_BAD_ARG_LIST                = 17407
	IDS_EE_PERL_UKNOWN_KEY                  = 17408
    CODE:
    	if( !ix ) {
	    char *what = GvNAME( CvGV(cv) );
	    croak( "Unknown SAPerlGlue constant '%s'", what );
	} else {
	    RETVAL = ix;
	}
    OUTPUT:
    	RETVAL


long
start( SV* sv_exec, char* eng, char* dbn, char* uid, char* pwd )

    INIT:
	long ret;
	struct a_language_loader loader;

    CODE:
	Exec = sv_exec;
	Interpreter = PERL_GET_INTERP;
    
	loader.create_loader = create_loader;
	loader.free_loader = free_loader;
	loader.execute = execute;
	loader.interrupt = interrupt;
	loader.set_thread = set_thread;
    
	ret = ee_init( loader, DBLIB );
	if( ret < 0 ) {
	    ee_fini();
	    XSRETURN_UNDEF;
	}
	
	ret = ee_set_type_map( DT_BINARY, "@" );
	if( ret >= 0 ) {
	    ret = ee_set_type_map( DT_LONGBINARY, "@" );
	}
	if( ret >= 0 ) {
	    ret = ee_set_type_map( DT_NOTYPE, "$" ); // map all other datatypes to $
	}
	if( ret < 0 ) {
	    ee_fini();
	    XSRETURN_UNDEF;
	}
	ee_set_return_separator( '/' );
	ee_set_arg_separator( 0 );
    
	ret = ee_connect( eng, dbn, uid, pwd );
	if( ret < 0 ) {
	    ee_fini();
	    XSRETURN_UNDEF;
	}
    
	ret = ee_mainloop();
	if( ret < 0 ) {
	    ee_fini();
	    XSRETURN_UNDEF;
	}
    
	ret = ee_fini();
	if( ret < 0 ) {
	    ee_fini();
	    XSRETURN_UNDEF;
	}
	RETVAL = ret;
    OUTPUT:
    	RETVAL

SV*
get_sqlca()

    CODE:
	char buff[50];
    	void* sqlca = (void*) ee_get_conn( EeHandle );
	
	memset( buff, 0, sizeof( buff ) );
	sprintf( buff, "%p", sqlca );
	RETVAL = newSVpvn( buff, strlen( buff ) );
	
    OUTPUT:
    	RETVAL

SV*
get_args( char* args, int num_args, int has_return )

    CODE:
	int i;
	unsigned int j;
	long ret;
	struct sqlda*  da = NULL;
	struct sqlvar* sqlvars = NULL;
	AV* results;
	int real_num_args;
	short* types;
	
	dbg_print( "entering get_args" );
	
	real_num_args = num_args;
	if( has_return ) {
	    real_num_args++;
	}
	types = (short*) ee_malloc( sizeof(short) * real_num_args );
        for( i = 0; i < real_num_args; i++ ) {
	    types[i] = (args[i] == '$'? DT_LONGVARCHAR : DT_LONGBINARY);
	}
	
	ret = ee_get_args( EeHandle, &da, num_args, has_return, types );
	sqlvars = da->sqlvar;
	ee_free( types );
	if( ret < 0 ) {
	    XSRETURN_UNDEF;
	    dbg_print( "leaving get_args bad" );
	    return;
	}

    	results = (AV*) sv_2mortal( (SV*) newAV() );
    
	for( i = 0; i < num_args; i++ ) {
	    SV* str;

	    if( *sqlvars[i].sqlind >= 0 ) {
		if( args[i] == '$' ) {
		    LONGVARCHAR* longdata = (LONGVARCHAR*) sqlvars[i].sqldata;
		    
		    str = newSVpv( longdata->array, longdata->stored_len );
		} else {
		    LONGBINARY * longdata = (LONGBINARY*) sqlvars[i].sqldata;
		    AV*          data = (AV*) sv_2mortal( (SV*) newAV() );
		    
		    // av_unshift( data, longdata->stored_len );
		    
		    for( j = 0; j < longdata->stored_len; j++ ) {
		    	//av_push( data, newSVnv( longdata->array[j] ) );
			av_store( data, j, newSVnv( longdata->array[j] ) );
		    }
		    str = (SV*) newRV( (SV*) data ); 
		}
		av_push( results, str );
	    } else {
	    	av_push( results, &PL_sv_undef );
	    }
	}
	
	RETVAL = newRV( (SV*) results );
	dbg_print( "leaving get_args ok" );
    OUTPUT:
    	RETVAL
	
long
set_output( SV* out_vals )

    INIT:
    	I32 num_args = 0;
	long ret;
	int i;
	struct sqlda*  da;
	struct sqlvar* sqlvars;

	if( !SvROK( out_vals ) ||
	    SvTYPE( SvRV( out_vals ) ) != SVt_PVAV ) {
	    dbg_print( "bad parameter to set_output" );
	    XSRETURN_UNDEF;
	}
	num_args = 1 + av_len( (AV*) SvRV( out_vals ) ); 	    
    CODE:
    	da = ee_get_descriptor( EeHandle );
	if( da == NULL ) {
	    RETVAL = 0;
	    XSRETURN_IV( 0 );
	}
	sqlvars = da->sqlvar;
	for( i = 0; i < num_args; i++ ) {
	    STRLEN l;
	    SV* sv_parm = *av_fetch( (AV*) SvRV( out_vals ), i, 0 );
	    struct sqlvar* sv = &sqlvars[i];
	    
	    if( sv_parm == &PL_sv_undef ) {
	    	*sv->sqlind = -1;
	    } else if( (sv->sqltype & 0xFFFE) == DT_LONGVARCHAR ) {
		char* parm = SvPV( sv_parm, l );
		LONGVARCHAR* longdata = (LONGVARCHAR*) sv->sqldata;
    
		if( longdata == NULL || longdata->array_len < l ) {
		    ee_free( sv->sqldata );
		    longdata = (LONGVARCHAR*) ee_malloc( 
		    	LONGVARCHARSIZE( l ) );
		    if( longdata == NULL ) {
		    	XSRETURN_UNDEF;
		    }
		    longdata->array_len = l; 		    
		    sv->sqldata = longdata;
		}
		
		longdata->stored_len = l;
		memcpy( longdata->array, parm, l ); 	    
		*sv->sqlind = 0;
	    } else {
	    	unsigned int bin_len = 0;
		AV* arr;
		LONGVARCHAR* longdata;
		unsigned int j;
		
	    	arr = (AV*) SvRV( sv_parm );
		bin_len = av_len( arr ) + 1;
		longdata = (LONGVARCHAR*) sv->sqldata;
		
		if( longdata == NULL || longdata->array_len < bin_len ) {
		    ee_free( sv->sqldata );
		    longdata = (LONGVARCHAR*) ee_malloc( 
		    	LONGVARCHARSIZE( bin_len ) );
		    if( longdata == NULL ) {
		    	XSRETURN_UNDEF;
		    }
		    longdata->array_len = bin_len;
		    sv->sqldata = longdata; 		
		}
		
		longdata->stored_len = bin_len;

		for( j = 0; j < bin_len; j++ ) {
		    longdata->array[j] = (char) SvIVX( *av_fetch( arr, j, 0 ) );
		}
		*sv->sqlind = 0;
	    }
	}
    	ret = ee_set_output( EeHandle );
	if( ret < 0 ) {
	    XSRETURN_UNDEF;
	}
	RETVAL = ret;
    OUTPUT:
	RETVAL

char*
get_code( char* class_name )

    CODE:
	char* ret = (char*) ee_get_class( EeHandle, class_name );
	if( ret == NULL ) {
	    XSRETURN_UNDEF;
	}
	RETVAL = ret;
    OUTPUT:
    	RETVAL

long
write_string( char* str, int len )

    CODE:
    	RETVAL = ee_write_string( EeHandle, str, len );
    OUTPUT:
    	RETVAL


void
set_error( char* str )

    CODE:
    	ee_set_error( EeHandle, str );


SV*
get_error( int err_code )

    CODE:
    	char buff[1024];
	
	int len = ee_get_string( err_code, buff, sizeof( buff ) );

	RETVAL = newSVpv( buff, len );
    OUTPUT:
    	RETVAL









