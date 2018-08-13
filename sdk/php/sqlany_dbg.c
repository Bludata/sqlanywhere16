/*-----------------------------------------------------------------------------+
 * Copyright 2013 SAP AG or an SAP affiliate company.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *                                                                                
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * While not a requirement of the license, if you do modify this file, we
 * would appreciate hearing about it. Please email sqlany_interfaces@sybase.com
 *-----------------------------------------------------------------------------+
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#if defined( _WIN32 ) 
#include <windows.h>
#else
#include <unistd.h>
#include <pthread.h>
#endif

#include "sqlany_dbg.h"
#include "php_sqlany_ver.h"

#if defined( _WIN32 )
int getpid()
{
    return GetCurrentProcessId();
}
#define PATH_SEP "\\"
#else
#define PATH_SEP "/"
#endif
char * get_temp_dir()
/********************/
{
    char * env;

    env = getenv( "TEMP" );
    if( env != NULL ) {
	return env;
    }
    env = getenv( "TMP" );
    if( env != NULL ) {
	return env;
    }
    return NULL;
}


static FILE * logfd = NULL;

void SQLAnyDebug( char * filename, int line, char * msg, ... )
/**************************************************************/
{
    char * format;
    va_list ap;

    if( logfd == NULL ) {
    	char buffer[40];
	char * env = get_temp_dir();
	if( env != NULL ) {
	    sprintf( buffer, "%s" PATH_SEP "sa_php.trace.%d", getpid() );
	} else {
	    sprintf( buffer, "sa_php.trace.%d", getpid() );
	}
        logfd = fopen( buffer, "a" );
        if( logfd == NULL ) return;
	fprintf( logfd, "[%d] %s:%d : STARTING LOG [%s]\n", 
		getpid(), filename, line, PHP_SQLANYWHERE_VERSION );
    }

    format = (char *)malloc( strlen( filename ) + 100 + strlen( msg ) );
#if defined( _WIN32 )
    sprintf( format, "[%x] %s:%d : %s\n", 
	    GetCurrentThreadId(), filename, line, msg );
#else
    sprintf( format, "[%d:%x] %s:%d : %s\n", 
	    getpid(), (unsigned int)pthread_self(), filename, line, msg );
#endif
    va_start( ap, msg );
    vfprintf( logfd, format, ap );
    va_end( ap );

    fflush( logfd );
    free( format );
}
