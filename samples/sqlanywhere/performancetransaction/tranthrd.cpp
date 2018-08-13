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

/****************************************************************************
 *									    *
 *	Sybase SQL Anywhere Transaction Test Utility			    *
 *									    *
 ****************************************************************************/

// Platform-specific threading and locking code

#include "tranthrd.hpp"

#if defined( __NT__ )

HANDLE			    OutputSem;

unsigned int StartThread(
    void		(*func)( void *),
    void *		arg )
/**************************************/
{
#if defined( _MSC_VER )
    DWORD		thread_id;
    
    // NOTE: thread handle created is never closed, resulting in a handle leak.
    return( CreateThread( NULL,
    			  THREAD_STACK_SIZE,
			  (LPTHREAD_START_ROUTINE)func,
			  arg,
			  0,
			  &thread_id )
            != NULL );
#elif __WATCOMC__ >= 1100
    return( _beginthread( func, THREAD_STACK_SIZE, arg ) != -1 );
#else
    return( _beginthread( func, NULL, THREAD_STACK_SIZE, arg ) != -1 );
#endif
}

void EndThread( void )
/********************/
{
    ExitThread( 0 );
}

#elif defined( POSIX4 )

unsigned int StartThread(
    void (*func)( void *),
    void *		arg )
/*********************************/
{
    pthread_attr_t 	attrs;
    pthread_t 		tid; 
    
    pthread_attr_init( &attrs );
    pthread_attr_setdetachstate( &attrs, PTHREAD_CREATE_DETACHED );
    pthread_attr_setscope( &attrs, PTHREAD_SCOPE_SYSTEM );
    return( pthread_create( &tid, &attrs, (void *(*)(void *))func, (void *)arg ) != 0 );
}

void EndThread( void )
/********************/
{
    int			status = 0;
    
    pthread_exit( &status );
}

#endif

void IncrThreadCount()
/********************/
{
    ActiveThreadCountMutex.get();
    ++ThreadsActive;
    ActiveThreadCountMutex.give();
}

void DecrThreadCount()
/********************/
{
    ActiveThreadCountMutex.get();
    --ThreadsActive;
    ActiveThreadCountMutex.give();
}

void Terminate( int exitcode )
/****************************/
{
    DecrThreadCount();
    EndThread();
    exit( exitcode );
}

