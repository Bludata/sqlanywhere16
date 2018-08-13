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

// Work list

#include "trantest.hpp"

class ScriptFromFile : public UnitOfWork {
  public:
    ScriptFromFile()
    {
	script_read = FALSE;
    }
    ~ScriptFromFile()
    {
    }
    a_bool InitWork( TransactionThread * thread )
    {
	a_bool		result = TRUE;
	
	// first thread reads in file
	thread->my_script = NULL;
	_mutex.get();
	if( !script_read ) {
	    FILE *	fp;
	    int		len;
	    
	    fp = fopen( BMark->script_file, "r" );
	    if( fp == NULL ) {
		printf( "Unable to read script file\n" );
		sql_script[0] = '\0';
	    } else {
		len = (int)fread( sql_script, sizeof(char), sizeof(sql_script), fp );
		sql_script[len] = '\0';
		fclose( fp );
	    }
	    script_read = TRUE;
	}
	_mutex.give();
	if( sql_script[0] != '\0' ) {
	    char *	src;
	    char *	dst;
	    char *	rep;
	    char	id[10];
	    size_t	preceding;
	    
	    // Replace any instances of "{thread}" in the string with the
	    // thread number of the current thread.
	    sprintf( id, "%d", thread->id );
	    thread->my_script = (char *) malloc( strlen( sql_script ) + 100 );
	    src = sql_script;
	    dst = thread->my_script;
	    for( ;; ) {
		rep = strstr( src, "{thread}" );
		if( rep == NULL ) {
		    strcpy( dst, src ); 
		    break;
		}
		preceding = (rep - src);
		strncpy( dst, src, preceding ); 
		dst += preceding;
		strcpy( dst, id );
		dst += strlen( id );
		src = rep + strlen( "{thread}" );
	    }
	    if( BMark->prepare_once ) {
		result = thread->Prepare( thread->my_script );
		free( thread->my_script );
		thread->my_script = NULL;
	    }
	}
	return( result );
    }
    a_bool DoWork( TransactionThread * thread )
    {
	a_bool		result;
	if( BMark->prepare_once ) {
	    result = thread->Execute();
	} else {
	    result = thread->Prepare( thread->my_script );
	    if( result ) {
		result = thread->Execute();
		thread->Drop();
	    }
	}
	return( result );
    }
    void FiniWork( TransactionThread * thread )
    {
	if( BMark->prepare_once ) {
	    thread->Drop();
	} else {
	    free( thread->my_script );
	    thread->my_script = NULL;
	}
    }
  private:
    Mutex	    _mutex;
    a_bool	    script_read;
    char	    sql_script[10000];
};

// The following example assumes that three procedures (p1, p2 and p3) exist
// in the database. p1 takes one input parameter, p2 takes one input and one
// output parameter, and p3 takes one input parameter and results a result set.
// The test randomly calls one of the procedures and generates parameters
// to be passed. Parameters are passed as strings.
//
// Notes:
// 1) Calls to SetParm must appear only inside DoWork and must pass a pointer
//    to memory that will still exist when the Execute call is performed.
// 2) A random value between 0 and 1 is used to weight the execution of
//    several tests (i.e. so that some are executed more frequently than
//    others).
// 3) A similar test could execute several statements for each invocation of
//    DoWork.
class MyTest : public UnitOfWork {
  public:
    a_bool InitWork( TransactionThread * thread )
    {
	if( !thread->Prepare( "call p1(?)", 0 ) ) {
	    return( FALSE );
	}
	if( !thread->Prepare( "call p2(?,?)", 1 ) ) {
	    return( FALSE );
	}
	if( !thread->Prepare( "call p3(?)", 2 ) ) {
	    return( FALSE );
	}
	return( TRUE );
    }
    a_bool DoWork( TransactionThread * thread )
    {
	double	    drand = ((double) Random( thread )) / ((double) ULONG_MAX);
	a_bool	    result;
	char	    input1[11];
	char	    inout2[11];

	// Randomly execute one of these procedures.
	sprintf( input1, "%lu", Random( thread ) );
	if( drand < 0.25 ) {		    // execute p1 25% of time
	    thread->SetParm( 0, input1, 0 );
	    result = thread->Execute( 0 );
	} else if( drand < 0.5 ) {	    // execute p2 25% of time
	    thread->SetParm( 0, input1, 1 );
	    strcpy( inout2, "55" );
	    thread->SetParm( 1, inout2, 1 );
	    result = thread->Execute( 1 );
	} else {			    // execute p3 remainder of time
	    thread->SetParm( 0, input1, 2 );
	    result = thread->Execute( 2 );
	}
	return( result );
    }
    void FiniWork( TransactionThread * thread )
    {
	thread->Drop( 0 );
	thread->Drop( 1 );
	thread->Drop( 2 );
    }
};

// ***************************************************************************

// Insert your tests here (using above as models).
// Tests must also be added to WorkList below.

// ***************************************************************************

ScriptFromFile	    ScriptFromFile_inst;
MyTest		    MyTest_inst;


typedef struct WorkList {
    char *	    name;
    UnitOfWork *    job;
} WorkList;

WorkList Jobs[] = {
    { "script",	    (UnitOfWork *) &ScriptFromFile_inst },
    { "mytest",	    (UnitOfWork *) &MyTest_inst },
    { NULL,	    NULL }
};


UnitOfWork * FindWork( char * test_name )
/***************************************/
{
    int		    i;

    for( i = 0; Jobs[i].name != NULL; ++i ) {
	if( stricmp( Jobs[i].name, test_name ) == 0 ) {
	    return( Jobs[i].job );
	}
    }
    return( NULL );
}

