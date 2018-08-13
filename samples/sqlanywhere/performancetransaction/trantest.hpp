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

#ifndef _TRANSACT_HPP_INCLUDED
#define _TRANSACT_HPP_INCLUDED

#include "tranthrd.hpp"	    // for mutex in TransactionThread

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "sqlca.h"
#include "sqlda.h"
#if defined( __NT__ )
    #include "ntodbc.h"
#elif defined( UNIX )
    #include "unixodbc.h"
#else
    #error Platform not recognized
#endif

#if defined( _MSC_VER )
// Disable warning for deprecated string functions (e.g. stricmp, strdup, strnicmp).
#   pragma warning( disable : 4996 )
#endif

#define TRUE		    1
#define FALSE		    0

#if defined( __NT__ )
    #define MySleep( ms )   Sleep( ms )
#elif defined( UNIX )
    #define MySleep( ms )   sleep( ms/1000 )
#else
    #error Fix definition of MySleep!
    #define MySleep( ms )   sleep( ms/CLOCKS_PER_SEC )
    #define MAKELONG(low, high) ((unsigned long)(((unsigned int)(low)) | (((unsigned long)((unsigned int)(high))) << 16)))
#endif

#ifndef PATH_MAX
    #if defined( HP ) && OSVER >= 1131
	#define PATH_MAX        _POSIX_PATH_MAX
    #else
	#define PATH_MAX        1024
    #endif
#endif
#if defined( UNIX )
    #define _MAX_PATH PATH_MAX
    #define stricmp   strcasecmp
#endif

#define _ticks_to_ms( ticks )	((int) (((ticks) * 1000) / CLOCKS_PER_SEC))

// a_clock_counter is used to sum clock_t values, and needs to be large enough
// to avoid overflow on platforms where CLOCKS_PER_SEC is large.
typedef DECL_UNSIGNED_BIGINT    a_clock_counter;

typedef unsigned int	        a_bool;


extern class BenchMark *    BMark;
extern int		    ExitCode;
extern int		    DesiredResponse;
extern int		    WarmUpTime;

// Maximum number of statements per thread:
#define MAX_STATEMENTS	    20

// Maximum length for fetches
#define MAX_FETCH_SIZE	    32760

// ***************************************************************************

class ThreadResults {
  public:
    ThreadResults()
    {
	transactions	    = 0;
	trans_in_interval   = 0;
	under		    = 0;
	response	    = 0;
	max_response	    = 0;
	waiting		    = 0;
    }
    ~ThreadResults() {}
    void AddToTotals( clock_t _response, clock_t _waiting )
    {
	mutex.get();
	++transactions;
	++trans_in_interval;
	response += _response;
	if( _response < ( DesiredResponse * CLOCKS_PER_SEC ) ) {
	    under++;
	}
	if( _response > max_response ) {
	    max_response = _response;
	}
	waiting += _waiting;
	mutex.give();
    }
    void Calculate( clock_t duration )
    {
	tps = transactions / ((double) duration / CLOCKS_PER_SEC);
	if( transactions > 0 ) {
	    average_response	= _ticks_to_ms( response ) / transactions;
	    average_waiting	= _ticks_to_ms( waiting ) / transactions;
	    percent_under	= ((double) (under * 100)) / transactions;
	} else {
	    average_response	= 0;
	    average_waiting	= 0;
	    percent_under	= 100;
	}
    }
    void Copy( ThreadResults * dst )
    {
	mutex.get();
	dst->transactions	= transactions;
	dst->trans_in_interval	= trans_in_interval;
	dst->under		= under;
	dst->response		= response;
	dst->max_response	= max_response;
	dst->waiting		= waiting;
	trans_in_interval = 0;
	mutex.give();
    }
  public:
    a_clock_counter	    response;
    a_clock_counter	    waiting;
    int 		    transactions;
    int 		    trans_in_interval;
    int 		    under;
    clock_t		    max_response;

    // Following are calculated based on above values:
    double		    tps;
    double		    percent_under;
    int			    average_response;	// milliseconds
    int			    average_waiting;	// milliseconds
    Mutex		    mutex;
};


typedef class TransactionThread *   p_TransactionThread;

class UnitOfWork {
  public:
    virtual ~UnitOfWork() {}

    virtual a_bool InitWork( p_TransactionThread thread ) = 0;
    virtual a_bool DoWork( p_TransactionThread thread ) = 0;
    virtual void   FiniWork( p_TransactionThread thread ) = 0;
};


class DatabaseAPI {
  public:
    virtual ~DatabaseAPI() {}

    virtual a_bool Connect( p_TransactionThread thread ) = 0;
    virtual a_bool Disconnect( p_TransactionThread thread ) = 0;
    virtual a_bool Commit( p_TransactionThread thread ) = 0;
    virtual a_bool Rollback( p_TransactionThread thread ) = 0;
    virtual a_bool ExecSQLString( p_TransactionThread thread, char * str ) = 0;
    virtual a_bool Prepare( p_TransactionThread thread, char * str, int stnum ) = 0;
    virtual a_bool SetParm( p_TransactionThread thread, int parmnum, char * parmval, int stnum ) = 0;
    virtual a_bool Execute( p_TransactionThread thread, int stnum ) = 0;
    virtual a_bool Drop( p_TransactionThread thread, int stnum ) = 0;
    virtual a_bool GetIntQuery( p_TransactionThread thread, char * str, int * result ) = 0;
};

class ESQLAPI : public DatabaseAPI {
  public:
    a_bool Connect( p_TransactionThread thread );
    a_bool Disconnect( p_TransactionThread thread );
    a_bool Commit( p_TransactionThread thread );
    a_bool Rollback( p_TransactionThread thread );
    a_bool ExecSQLString( p_TransactionThread thread, char * str );
    a_bool Prepare( p_TransactionThread thread, char * str, int stnum );
    a_bool SetParm( p_TransactionThread thread, int parmnum, char * parmval, int stnum );
    a_bool Execute( p_TransactionThread thread, int stnum );
    a_bool Drop( p_TransactionThread thread, int stnum );
    a_bool GetIntQuery( p_TransactionThread thread, char * str, int * result );
    //
    char * GetSQLError( p_TransactionThread thread );
  public:
    a_bool		    has_result_set[MAX_STATEMENTS];
    SQLCA		    sqlca;
    SQLDA *		    sqlda[MAX_STATEMENTS];
    SQLDA *		    outsqlda[MAX_STATEMENTS];
    a_sql_statement_number  stmt[MAX_STATEMENTS];
};

class ODBCAPI : public DatabaseAPI {
  public:
    a_bool Connect( p_TransactionThread thread );
    a_bool Disconnect( p_TransactionThread thread );
    a_bool Commit( p_TransactionThread thread );
    a_bool Rollback( p_TransactionThread thread );
    a_bool ExecSQLString( p_TransactionThread thread, char * str );
    a_bool Prepare( p_TransactionThread thread, char * str, int stnum );
    a_bool SetParm( p_TransactionThread thread, int parmnum, char * parmval, int stnum );
    a_bool Execute( p_TransactionThread thread, int stnum );
    a_bool Drop( p_TransactionThread thread, int stnum );
    a_bool GetIntQuery( p_TransactionThread thread, char * str, int * result );
    void MakeOutput( p_TransactionThread thread, int stnum );
  public:
    a_bool		    has_result_set[MAX_STATEMENTS];
    HENV		    environment;
    HDBC		    connection;
    HSTMT		    statement[MAX_STATEMENTS];
    char **		    columns[MAX_STATEMENTS];
    int 		    num_cols[MAX_STATEMENTS];
    int 		    num_params[MAX_STATEMENTS];
    int *		    parm_types[MAX_STATEMENTS];
};

typedef enum {
    API_NONE = 0,
    API_ESQL,
    API_ODBC
} a_test_api;

extern a_test_api	APIType;


class TransactionThread {
  public:
    TransactionThread( int thread_id, int thread_group_id )
    {
	memset( &sqlca, 0, sizeof( sqlca ) );
	id = thread_id;
	connected = FALSE;
	if( APIType == API_ESQL ) {
	    api = new ESQLAPI();
	} else if( APIType == API_ODBC ) {
	    api = new ODBCAPI();
	}
	// give each thread a unique seed
	seed = (thread_group_id * 1000) + thread_id; 
	my_script = NULL;
    }
    ~TransactionThread()
    {
	delete api;
    }
    a_bool Connect()			{ return( api->Connect( this ) ); }
    a_bool Disconnect()			{ return( api->Disconnect( this ) ); }
    a_bool Commit()			{ return( api->Commit( this ) ); }
    a_bool Rollback()			{ return( api->Rollback( this ) ); }
    a_bool ExecSQLString( char * str )  { return( api->ExecSQLString( this, str ) ); }
    a_bool Prepare( char * str, int stnum = 0 )	{ return( api->Prepare( this, str, stnum ) ); }
    a_bool SetParm( int parmnum, char * parmval, int stnum = 0 )
					{ return( api->SetParm( this, parmnum, parmval, stnum ) ); }
    a_bool Execute( int stnum = 0 )	{ return( api->Execute( this, stnum ) ); }
    a_bool Drop( int stnum = 0 )	{ return( api->Drop( this, stnum ) ); }
    int GetIntQuery( char * str ) {
	int	result;

	// Ignoring return value ...
	api->GetIntQuery( this, str, &result );
	return( result );
    }
  public:
    DatabaseAPI *	    api;
    int			    id;
    clock_t		    start_time;
    clock_t		    stop_time;
    ThreadResults	    results;
    ThreadResults	    warm_results;
    char *		    my_script;	// used by ScriptFromFile
    char		    error_buffer[200];
    a_bool		    connected;
    int			    seed;
};


typedef enum {
    TSTATE_UNKNOWN,
    TSTATE_INITIALIZING,
    TSTATE_RUNNING
} a_test_state;

#define MAX_ITER	    20

class BenchMark {
  public:
    BenchMark()
    {
	thread_group_id	    = 0;
	num_threads	    = 1;
	num_groups	    = 0;
	iterations	    = 0;
	time_limit	    = 300;
	mean_cycle_time	    = 0;
	isolation_level	    = 0;
	commit_freq	    = 0;
	display_details	    = FALSE;
	prepare_once	    = TRUE;
	connect_string[0]   = '\0';
	test_name[0]	    = '\0';
	output_file[0]	    = '\0';
	output_fp	    = NULL;
	threads		    = NULL;
	work		    = NULL;
	script_file[0]	    = '\0';
	state		    = TSTATE_UNKNOWN;
	display_rate	    = 5;
    }
    ~BenchMark() {}
    a_test_state GetState()
    {
	return( state );
    }
    void SetState( a_test_state new_state )
    {
	state = new_state;
    }
  public:
    int			    thread_group_id;
    int			    num_threads;
    int			    num_groups;
    int			    iterations;
    unsigned short	    thread_count[MAX_ITER];
    int			    time_limit;	     // time limit for test in seconds
    int			    mean_cycle_time; // seconds between transactions
    int 		    isolation_level;
    int			    commit_freq;     // optional commit after nnn trans
    a_bool		    display_details;
    a_bool		    prepare_once;
    char		    connect_string[200];
    char		    test_name[100];
    char		    output_file[_MAX_PATH];
    FILE *		    output_fp;
    TransactionThread **    threads;
    UnitOfWork *	    work;
    char		    script_file[_MAX_PATH];
    a_test_state	    state;
    int			    display_rate;
};


extern void		    PrintSQLError( TransactionThread * thread );
extern void		    PrintError( TransactionThread * thread, char * msg );
extern UnitOfWork *	    FindWork( char * test_name );
extern unsigned long	    Random( TransactionThread * thread );

#endif
