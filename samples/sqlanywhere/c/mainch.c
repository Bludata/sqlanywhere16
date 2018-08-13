// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer 
// as to the original code.  
// 
// *******************************************************************
/* MAINCH.C     Character mode specific routines for all example programs
*/
			
#include "sqlos.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#if !defined( UNIX )
    #include <conio.h>
#endif

#include "example.h"

int	PageSize	 = 16;

extern int Displaystringtext( int pos, int width, TCHAR *str )
/************************************************************/
{
    int  len;
    char buf[ MAX_SCREEN_WIDTH + 1 ];

    if( width > MAX_SCREEN_WIDTH ) {
        width = MAX_SCREEN_WIDTH;
    }
    len = strlen( str );
    if( len > width ) {
        len = width;
    }
    strncpy( buf, str, len );
    buf[len] = '\0';
    Displaytext( pos, TEXT( "%-*.*s" ), width, width, buf );
    return width;
}

extern int Displaytext( int pos, char *fmt, ... )
/***********************************************/
{
    va_list         arg_ptr;
    char            buffer[ MAX_SCREEN_WIDTH + 1 ];
    static int      curpos = 0;
    int             i;
    int             len;
    int             max_width = DEFAULT_SCREEN_WIDTH;

#ifdef UNIX
    char *env_buf = getenv( "COLUMNS" );
    if( env_buf != NULL ) {
        max_width = atoi( env_buf ) - 1;
        if( max_width <= 0 ) {
	    max_width = DEFAULT_SCREEN_WIDTH;
        } else if ( max_width > MAX_SCREEN_WIDTH ) {
	    max_width = MAX_SCREEN_WIDTH;
        }
    }
#endif

    va_start( arg_ptr, fmt );
    vsprintf( buffer, fmt, arg_ptr );
    va_end( arg_ptr );

    if( pos <= max_width ) {
    	for( i = 0; i < ( pos - curpos ); i++ ) {
	    putchar( ' ' );
	    curpos++;
    	}
    	len = strlen( buffer );
    	for( i = 0; i < len; i++, curpos++ ) {
	    if( buffer[ i ] == MY_NEWLINE_CHAR ) {
    		curpos = 0;
	    } 
	    if( curpos <= max_width ) {
		putchar( buffer[ i ] );
	    }
	}
    } else { 
        curpos = 0;
    }
    fflush( stdout );
    return( TRUE );
}

extern void Display_systemerror( char *message )
/**********************************************/
{
    fprintf( stderr, "%s\n", message );
}

extern void Display_refresh( void )
/*********************************/
{
}

static void prompt_for_string( char *prompt, char *buff, int len )
/****************************************************************/
{
    printf( "%s: ", prompt );
    fflush( stdout );
    fgets( buff, len, stdin );
    len = strlen( buff );
    if( buff[ len-1 ] == MY_NEWLINE_CHAR ) {
	buff[ len-1 ] = '\0';
    } else {
	fflush( stdin );	    /* entered line longer than len */
    }
}

extern void GetValue( char *prompt, char *buff, int len)
/******************************************************/
{
    prompt_for_string( prompt, buff, len );
}

extern void GetTableName( char *buff, int len )
/*********************************************/
{
    GetValue( "Enter table name", buff, len );
}


/* The GETCH_AVAIL macro is used below to indicate whether the getch()
   function is available from CLIB with your compiler
*/
#define GETCH_AVAIL	1
#ifdef __IBMC__
    #if __IBMC__ < 200
        #undef GETCH_AVAIL
    #endif
#endif

#if defined( UNIX )
    #undef GETCH_AVAIL
#endif


#if defined( UNIX )
int _argc;
char **_argv;

int main( int argc, char *argv[] )
/********************************/

#else

int main( void )
/**************/

#endif

{
    int 		ch;

#ifdef UNIX
    _argc = argc;
    _argv = argv;
#endif

    if( !WSQLEX_Init() ) {
    	return( 0 );
    }
    for( ; ; ) {
	fprintf( stdout, "==>" );
	fflush( stdout );
	#ifdef GETCH_AVAIL
	    ch = getche();
	#else
	    /* If your compiler does not support getche(), change
	       the definition of GETCH_AVAIL above */
	    while( (ch = getchar()) == MY_NEWLINE_CHAR );
	    while( getchar() != MY_NEWLINE_CHAR );
	#endif
	if( ch == EOF || ch == 'q') break;
	putchar( MY_NEWLINE_CHAR );
        WSQLEX_Process_Command( ch );
    }
    putchar( MY_NEWLINE_CHAR );
    WSQLEX_Finish();
    return( 0 );
}
