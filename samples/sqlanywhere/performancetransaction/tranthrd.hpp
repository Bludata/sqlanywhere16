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

#include "sqlos.h"

#if defined( __NT__ )
    #include <windows.h>
#elif defined( UNIX )
    #define POSIX4
#endif
 
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <time.h>
#include <string.h>

#if defined( UNIX )
    #include <unistd.h>
    #include <pthread.h>
#else
    #include <dos.h>
#endif

#include <sys/stat.h>
#ifndef UNIX
    #include <process.h>
#endif


#if defined( __NT__ )
    #define THREAD_STACK_SIZE	8096

    class Mutex {
      public:
	Mutex()	    { _mutex = CreateMutex( NULL, FALSE, NULL ); }
	~Mutex()    { CloseHandle( _mutex ); }
	void get()  { WaitForSingleObject( _mutex, INFINITE ); }
	void give() { ReleaseMutex( _mutex ); }
      private:
	HANDLE	    _mutex;
    };
    
#elif defined( POSIX4 )
    class Mutex {
      public:
	Mutex()	    { pthread_mutex_init( &_mutex, NULL ); }
	~Mutex()    {}
	void get()  { pthread_mutex_lock( &_mutex ); }
	void give() { pthread_mutex_unlock( &_mutex ); }
      private:
	pthread_mutex_t	_mutex;
    };

#else
    #error Platform not defined
#endif


extern Mutex		    OutputMutex;
extern Mutex		    ActiveThreadCountMutex;
extern long		    ThreadsActive;
    
extern unsigned int StartThread(
    void		(*func)( void *),
    void *		arg );
extern void EndThread( void );
extern void Terminate( int exitcode );
extern void IncrThreadCount();
extern void DecrThreadCount();
