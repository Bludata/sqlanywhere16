// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/* *********************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// ****************************************************************** */

#include "sqlos.h"

#if defined( WIN32 ) || defined( WIN64 )
    #include <windows.h>
    #include <io.h>
#elif defined( UNIX )
    #include <unistd.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#include "sqldef.h"

// define some error codes returned by extract_oem_string
#define OEM_OK       0
#define OEM_ER_OPEN  1
#define OEM_ER_READ  2
#define OEM_ER_NOSTR 3

#define _debug( x )

#if defined( WIN32 ) || defined( WIN64 )
    #define OPEN_FLAGS  ( O_RDONLY | O_BINARY )
#elif defined( UNIX )
    #define OPEN_FLAGS  O_RDONLY
#endif

int extract_oem_string( char * fname, int max_len, char * oem_string, int * oem_len )
{
    int  fd;
    int  len;
    char buf[2048];
    int  n;
    int  i;
    int  start;

    fd = open( fname, OPEN_FLAGS );
    if( fd < 0 ) {
	// some error, maybe no found or could be a permission problem?
	return OEM_ER_OPEN;
    }
    len = read( fd, buf, sizeof( buf ) );
    close( fd );
    if( len < 0 ) {
	return OEM_ER_READ;
    }
    _debug( printf( "nbytes read = %d\n", len ); )

    // Now search for the oem prefix
    for( start=-1,n=DB_OEM_STRING_PSXLEN,i=0; i<len-n; i++ ) {
	if( memcmp( buf+i, DB_OEM_STRING_PREFIX, n ) == 0 ) {
	    // found beginning
	    start = i + n;
	    break;
	}
    } //for
    if( start < 0 ) {
	return OEM_ER_NOSTR;
    }
    _debug( printf( "start at = %d\n", start ); )

    // And then find the end of the oem string
    for( n=DB_OEM_STRING_PSXLEN,i=start; i<len-n; i++ ) {
	if( memcmp( buf+i, DB_OEM_STRING_SUFFIX, n ) == 0 ) {
	    // found end
	   break;
	}
    } //for
    if( i>=len-n ) {
	return OEM_ER_NOSTR;
    }
    _debug( printf( "end at = %d\n", i ); )

    // Found it ... all the bytes between start and i-1
    len = i - start;  // number of bytes found
    if( len > max_len ) {
	len = max_len;
    }
    _debug( printf( "length = %d\n", len ); )

    *oem_len = len;
    for( i=0; len>0; len-- ) {
	oem_string[i++] = buf[start++];
    }
    return OEM_OK;
}

int main( int argc, char * argv[] )
{
    int  verbose = 0;
    int  argi;
    char oem_string[ 256 ];
    int  oem_len;
    
    for( argi=1; argi<argc; argi++ ) {
	if( strcmp( argv[argi], "-v" ) == 0 ) {
	    verbose ++;
	} else {
	    break;
	}
    }
    if( argi >= argc ) {
	if( verbose ) {
	    fprintf( stderr, "*** Error: Missing filename\n" );
	}
	return( 1 );   // failed
    }
    _debug( printf( "Filename is argv[%d] = %s\n" , argi, argv[argi] ); )

    switch( extract_oem_string( argv[argi], sizeof(oem_string)-1, oem_string, &oem_len ) ) {
    case OEM_OK:
	if( verbose ) {
	    fprintf( stderr, "*** OK: Found OEM string - number of bytes = %d\n", oem_len );
	}
	break;
    case OEM_ER_OPEN:
	if( verbose ) {
	    fprintf( stderr, "*** Error: Open error: %s\n", argv[argi] );
	}
	return( 2 );
    case OEM_ER_READ:
	if( verbose ) {
	    fprintf( stderr, "*** Error: Read error: %s\n", argv[argi] );
	}
	return( 3 );
    case OEM_ER_NOSTR:
	if( verbose ) {
	    fprintf( stderr, "*** Error: No OEM string found: %s\n", argv[argi] );
	}
	return( 4 );
    default:
	// Oops, unknown return code
	if( verbose ) {
	    fprintf( stderr, "*** Error: Oops: %s\n", argv[argi] );
	}
	return( 9 );
    } //switch

    // Ok, found the string, print it out
    // but first trim trailing zeros
    for( ; oem_len>0 && oem_string[oem_len-1] == '\0'; oem_len-- );
    oem_string[ oem_len ] = '\0'; // make sure null terminated before printing it
    puts( oem_string );
    return( 0 );
}

