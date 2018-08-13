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

#include "trantest.hpp"


BenchMark *		    BMark = NULL;
int			    ExitCode = 0;
int			    DesiredResponse = 2;
int			    WarmUpTime = 0;

Mutex			    ActiveThreadCountMutex;
long			    ThreadsActive = 0;

a_bool			    TablesAvailable = TRUE;

a_test_api		    APIType = API_NONE;

static char		    CmdLine[1000];


static double RandomNumber( int *seed )
/*************************************/
// Implementation of a "minimal standard" multiplicative linear
// congruential random number generator.  See Park and Miller (1988),
// CACM 31(10), pp. 1192-1201 and Press et al. (1992), Numerical
// Recipes in C (2nd edition, Chapter 7, pp. 279)
//
// Result is a pseudo-random number n where 0 < n < 1 (ie. neither 0.0
// nor 1.0 can be the result).
{
    int		a = 16807;
    int		m = 2147483647;
    int		q = 127773;
    int		r = 2836;
    int		mask = 123459876;
    int		k;
    double	result;

    *seed ^= mask;	// XOR with MASK to ensure a non-0 seed value.
    k = (*seed) / q;
    *seed = a * ( (*seed) - k * q ) - r * k;
    if( (*seed) < 0 ) {
	*seed += m;
    }
    result = (double) *seed * ( 1.0 / (double) m );
    /* Ensure the endpoints 0.0 and 1.0 cannot be produced. */
    if( result < 1.2e-7 ) {
	result = 1.2e-7;
    } else if( result > (1.0 - 1.2e-7) ) {
	result = 1.0 - 1.2e-7;
    }
    *seed ^= mask;	// XOR again before return
    return( result );
}

unsigned long Random( TransactionThread * thread )
/************************************************/
{
    double	rnd = RandomNumber( &thread->seed );
    return( (unsigned long) (ULONG_MAX * rnd) );
}

void PrintError( TransactionThread * thread, char * msg )
/*******************************************************/
{
    ExitCode = 1;
    printf( "Error [thread %d]: %s\n", thread->id, msg );
}

static void ShowUsage()
/*********************/
{ 
    printf( "Usage: TRANTEST <switches>\n\n" );
    printf(
	    "Switches:\n"
	    "\t-a <api>       API to use (ESQL or ODBC)\n"
	    "\t-c <str>       connection string\n"
	    "\t-d             display per-thread statistics\n"
	    "\t-f <file>      SQL script file\n"
	    "\t-g <num>       thread group id\n"
	    "\t-i <num>       isolation level\n"
	    "\t-k <num>       commit after 'num' transactions\n"
	    "\t-l <num>       limit for test in secs (default 300)\n"
	    "\t-m <num>       mean time between transactions for each thread (ms)\n"
	    "\t-n <list>      number of threads to run at each iteration\n"
	    "\t               (e.g. -n 1,5,10,20)\n"
	    "\t-o <file>      output results to file\n"
	    "\t-p <num>       number of machines (thread groups)\n"
	    "\t-r <num>       display refresh rate (seconds)\n"
	    "\t-t <str>       name of test to run\n"
	    "\t-u <num>       maximum desired response time (secs)\n"
	    "\t-w <num>       warm-up time (secs)\n"
	    "\t-x             prepare and drop on each execution\n"
	);
}	    

static char * ArgVal( int argc, char * argv[], int &index )
/*********************************************************/
{
    if( index >= argc ) return( NULL );
    if( argv[index][2] == '\0' ) {
	if( (index+1) >= argc || argv[index+1][0] == '-' ) {
	    return( NULL );
#if !defined( UNIX )
	} else if (argv[index+1][0] == '/' ) {
	    return( NULL );
#endif
	} else {
	    return( argv[++index] );
	}
    } else {
	return( &argv[index][2] );
    }
}

static a_bool CheckArg( char * src, char * dst )
/**********************************************/
{ 
    if( src == NULL || *src == '\0' ) return( FALSE );
    strcpy( dst, src );
    return( TRUE );
}

static a_bool GetParameters( int argc, char * argv[] )  
/****************************************************/
{
    char		    arg[_MAX_PATH];
    int			    index;
    char		    argtype;

    if( argc <= 1 ) {
	ShowUsage();
	return( FALSE );
    }
    for( index = 1; index < argc && argv[index] != NULL ; ++index ) {
	if( argv[index][0] != '-' &&  argv[index][0] != '/' ) {
	    ShowUsage();
	    return( FALSE );
	}
	argtype = argv[index][1];
	if( argtype != 'd' &&
	    argtype != 'x' &&
	    argtype != '?' ) {
	    if( !CheckArg( ArgVal( argc, argv, index ), arg ) ) {
		printf( "Expecting value after /%c\n", argtype );
		ShowUsage();
		return( FALSE );
	    }
	}
	switch( argtype ) {
	    case 'a':
		if( stricmp( arg, "ESQL" ) == 0 ) {
		    APIType = API_ESQL;
		} else if( stricmp( arg, "ODBC" ) == 0 ) {
		    APIType = API_ODBC;
		} else {
		    ShowUsage();
		    return( FALSE );
		}
		break;
	    case 'c':
		strcpy( BMark->connect_string, arg );
		break;
	    case 'd':
		BMark->display_details = TRUE;
		break;
	    case 'f':
		strcpy( BMark->script_file, arg );
		strcpy( BMark->test_name, "script" );
		break;
	    case 'g':
		BMark->thread_group_id = atoi( arg );
		break;
	    case 'i':
		BMark->isolation_level = atoi( arg );
		break;
	    case 'k':
		BMark->commit_freq = atol( arg );
		break;
	    case 'l':
		BMark->time_limit = atoi( arg );
		break;
	    case 'm':
		BMark->mean_cycle_time = atoi( arg );
		break;
	    case 'n':
	    {
		char *		str;
		char *		list = arg;
		int		iter;

		for( iter = 0; ; ++iter ) {
		    if( iter > MAX_ITER ) {
			printf( "Too many iterations\n" );
			return( FALSE );
		    }
		    str = strchr( list, ',' );
		    if( str == NULL ) {
			BMark->thread_count[iter] = (unsigned short) atoi( list );
			break;
		    }
		    *str = '\0';
		    BMark->thread_count[iter] = (unsigned short) atoi( list );
		    list = ++str;
		}
		BMark->iterations = iter + 1;
		break;
	    }
	    case 'o':
		strcpy( BMark->output_file, arg );
		break;
	    case 'p':
		BMark->num_groups = atoi( arg );
		break;
	    case 'r':
		BMark->display_rate = atoi( arg );
		break;
	    case 't':
		strcpy( BMark->test_name, arg );
		break;
	    case 'u':
		DesiredResponse = atoi( arg );
		break;
	    case 'w':
		WarmUpTime = atoi( arg );
		break;
	    case 'x':
		BMark->prepare_once = FALSE;
		break;
	    case '?':
		ShowUsage();
		return( FALSE );
	    default:
		printf( "Invalid option \"%s\"\n", argv[index] );
		ShowUsage();
		return( FALSE );
	}
    }
    BMark->work = FindWork( BMark->test_name );
    if( BMark->work == NULL ) {
	printf( "Test \"%s\" not found\n", BMark->test_name );
	return( FALSE );
    }
    if( APIType == API_NONE ) {
	printf( "Database API not specified\n" );
	return( FALSE );
    }
    if( BMark->iterations == 0 ) {
	printf( "Number of threads at each iteration not specified\n" );
	return( FALSE );
    }
    if( BMark->num_groups == 0 && BMark->thread_group_id == 0 ) {
	BMark->num_groups = 1;
    }

    return( TRUE );
}

static a_bool SaveResults( TransactionThread * main_thread )
/**********************************************************/
{ 
    TransactionThread * thread;
    int			i;
    ThreadResults *	results;
    char		result_str[500];

    if( !TablesAvailable ) {
	return( TRUE );
    }
    for( i = 0; i < BMark->num_threads; ++ i ) {
	thread = BMark->threads[i];
	results = &thread->warm_results;
	results->Calculate( thread->stop_time -
			(thread->start_time + WarmUpTime * CLOCKS_PER_SEC) );
	sprintf( result_str,
	    "INSERT INTO TT_Result "
		"( run_nbr, thread_group, thread_num, trans, "
		"   avg_response, max_response, avg_waiting, percent_under ) "
	    "SELECT (select max(run_nbr) from TT_RunDesc),"
		"%d, %d, %d, %d, %d, %d, %d",
		BMark->thread_group_id,
		thread->id,
		results->transactions,
		results->average_response,
		(int) results->max_response,
		results->average_waiting,
		(int) results->percent_under );
	main_thread->ExecSQLString( result_str );
    }

    main_thread->Commit();

    return( TRUE );
}

static a_bool DoTest( TransactionThread * thread )
/************************************************/
{
    clock_t		now;
    clock_t		start;		// clock at start of transaction
    clock_t		response;
    clock_t		avg_resp;
    clock_t		waiting;
    clock_t		delay;
    int			ntrans;
    int			ms_delay;
    clock_t		mean_ticks;	// mean cycle time in clock ticks
    double		drand;		// random value between 0 and 1

    thread->start_time = clock();
    thread->stop_time = thread->start_time +
			    (BMark->time_limit * CLOCKS_PER_SEC);

    mean_ticks = BMark->mean_cycle_time;
    start = clock();
    for( ;; ) {
	now = clock();
	if( now > thread->stop_time ) break;
	start = now;
	if( mean_ticks > 0 ) {
	    if( thread->results.transactions > 0 ) {
		ntrans = thread->results.transactions;
		avg_resp = (clock_t) (thread->results.response / ntrans);
		// Delay for a random time from 0 to the average unused time
		// per cycle.
		if( avg_resp < mean_ticks ) {
		    drand = ((double) Random( thread )) / ((double) ULONG_MAX);
		    delay = (clock_t) (drand * (mean_ticks - avg_resp));
		} else {
		    delay = 0;
		}
		// We must delay at least until the starting period for the
		// next cycle.
		if( (ntrans * mean_ticks) > (now - thread->start_time) ) {
		    delay += ((ntrans * mean_ticks) - (now - thread->start_time));
		}
		if( delay > 0 ) {
		    ms_delay = _ticks_to_ms( delay );
		    // must wait to start transaction 
		    MySleep( ms_delay );
		    start = clock();
		}
	    }
	}
	if( !BMark->work->DoWork( thread ) ) {
	    thread->Rollback();
	    return( FALSE );
	}

	now = clock();
	response = now - start;

	waiting = 0;
	if( response > (DesiredResponse * CLOCKS_PER_SEC) ) {
	    waiting = response - (DesiredResponse * CLOCKS_PER_SEC);
	}

	thread->results.AddToTotals( response, waiting );
	if( (start - thread->start_time)/CLOCKS_PER_SEC >= WarmUpTime ) {
	    thread->warm_results.AddToTotals( response, waiting );
	}

	if( BMark->commit_freq != 0
	&&  (thread->results.transactions % BMark->commit_freq) == 0 ) {
	    thread->Commit();
	}
    }
    
    thread->Rollback();
    
    return( TRUE );
}

static void WaitForState( a_test_state next_state )
/*************************************************/
{
    while( BMark->GetState() != next_state ) {
	MySleep( 1000 );
    }
}

void ThreadMain( void * ptr )
/***************************/
{
    TransactionThread *	    thread  = (TransactionThread *)ptr;

    if( !thread->Connect() ) {
	printf( "Error - could not connect to database\n" );
	Terminate( 1 );
    }

    if( BMark->work->InitWork( thread ) ) {
	WaitForState( TSTATE_RUNNING );
    
	if( !DoTest( thread ) ) {
	    printf( "Thread %d failed\n", thread->id );
	}
	
	BMark->work->FiniWork( thread );
    }
	
    if( !thread->Disconnect() ) {
	printf( "Error disconnecting from database" );
	Terminate( 1 );
    }
    
    DecrThreadCount();
}

static void OpenOutputFile()
/**************************/
{
    BMark->output_fp = stdout;
    if( BMark->output_file[0] != '\0' ) {
	FILE *		fp;
	
	fp = fopen( BMark->output_file, "w" );
	if( fp != NULL ) {
	    BMark->output_fp = fp;
	} else {
	    printf( "Unable to open output file\n" );
	}
    }
}

static void CloseOutputFile()
/***************************/
{
    if( BMark->output_fp != stdout ) {
	fclose( BMark->output_fp );
	BMark->output_fp = NULL;
    }
}

static void OutputCommandLine( int argc, char * argv[] )
/******************************************************/
// Print out the command line so the output shows the options used
{
    int			    index;
    FILE *		    fp;

    strcpy( CmdLine, "TRANTEST" );
    for( index = 1; index < argc && argv[index] != NULL ; ++index ) {
	strcat( CmdLine, " " );
	strcat( CmdLine, argv[index] );
	if( stricmp( argv[index], "-c" ) == 0 ) {
	    strcat( CmdLine, " \"" );
	    strcat( CmdLine, argv[++index] );
	    strcat( CmdLine, "\"" );
	}
    }
    for( fp = BMark->output_fp;; ) {
	fprintf( fp, "\n%s\n", CmdLine );
	if( fp == stdout ) break;
	fp = stdout;
    }
}

static void DisplayActiveStats( a_bool show_headings )
/****************************************************/
{
    int			    i;
    clock_t		    now;
    clock_t		    duration;
    a_clock_counter	    tot_time = 0;
    TransactionThread *	    thread;
    ThreadResults	    results;
    ThreadResults	    totals;
    FILE *		    fp;

    if( show_headings ) {
	for( fp = BMark->output_fp;; ) {
	    fprintf( fp, "\n" );
	    fprintf( fp, " ----------------------------------------------------------------- \n" );
	    fprintf( fp, "|   |         |         |      |Average |Maximum |Average |Percent|\n" );
	    fprintf( fp, "|   |         |  Total  |      |Response|Response|Waiting | Under |\n" );
	    fprintf( fp, "|   | #Trans. | #Trans. | T/sec|Time(ms)|Time(ms)|Time(ms)|%2d Secs|\n", DesiredResponse );
	    fprintf( fp, " ----------------------------------------------------------------- \n" );
	    if( fp == stdout ) break;
	    fp = stdout;
	}
    }

    now = clock();
    memset( &totals, 0, sizeof( totals ) );
    for( i = 0; i < BMark->num_threads; ++ i ) {
	thread = BMark->threads[i];
	if( now > thread->stop_time ) {
	    duration = thread->stop_time - thread->start_time;
	} else {
	    duration = now - thread->start_time;
	}
	if( (now - thread->start_time)/CLOCKS_PER_SEC > WarmUpTime ) {
	    thread->warm_results.Copy( &results );
	    duration -= (WarmUpTime * CLOCKS_PER_SEC);
	} else {
	    thread->results.Copy( &results );
	}
	results.Calculate( duration );
	if( BMark->display_details ) {
	    for( fp = BMark->output_fp;; ) {
		fprintf( fp, " %3d %9d %9d %6.1f %8d %8d %8d %7.1f\n",
		    i+1,
		    results.trans_in_interval,
		    results.transactions,
		    results.tps,
		    results.average_response,
		    _ticks_to_ms( results.max_response ),
		    results.average_waiting,
		    results.percent_under
		  );
		if( fp == stdout ) break;
		fp = stdout;
	    }
	}
	totals.transactions += results.transactions;
	totals.trans_in_interval += results.trans_in_interval;
	totals.under += results.under;
	totals.response += results.response;
	totals.waiting += results.waiting;
	if( results.max_response > totals.max_response ) {
	    totals.max_response = results.max_response;
	}
	tot_time += duration;
    }
    totals.Calculate( (clock_t) (tot_time/BMark->num_threads) );
    for( fp = BMark->output_fp;; ) {
	fprintf( fp, "     %9d %9d %6.1f %8d %8d %8d %7.1f\n",
	    totals.trans_in_interval,
	    totals.transactions,
	    totals.tps,
	    totals.average_response,
	    _ticks_to_ms( totals.max_response ),
	    totals.average_waiting,
	    totals.percent_under
	  );
	if( fp == stdout ) break;
	fp = stdout;
    }
}

int main( int argc, char * argv[] )  
/*********************************/
{
    int			    thread;	    
    int			    iter;
    TransactionThread *	    main_thread;
    char		    sync_stmt[1000];
    a_bool		    show_headings;
    int			    run_nbr = 0;

    BMark = new BenchMark;
    
    if( !GetParameters( argc, argv ) ) {
	ExitCode = 1;
	return( ExitCode );
    }

    main_thread = new TransactionThread( 0, BMark->thread_group_id );
    main_thread->Connect();
    if( main_thread->GetIntQuery(
	"Select if db_property('Name') = 'utility_db' then 1 else 0 endif" ) == 1 ) {
	TablesAvailable = FALSE;
    } else if( main_thread->GetIntQuery(
	"Select count(*) from SYS.SYSTABLE where table_name='TT_Result'" ) == 0 ) {
	TablesAvailable = FALSE;
    }
    if( !TablesAvailable ) {
	if( BMark->num_groups > 1 ) {
	    printf( "TRANTEST tables not found. Run:  DBISQL READ TRANTABS.SQL\n" );
	    ExitCode = 1;
	    return( ExitCode );
	} else {
	    printf( "TRANTEST tables not found: results will not be recorded.\n" );
	}
    }

    OpenOutputFile();
    OutputCommandLine( argc, argv );

    for( iter = 0; iter < BMark->iterations; ++iter ) {
	BMark->num_threads = BMark->thread_count[iter];
	ThreadsActive = 0;
	BMark->SetState( TSTATE_INITIALIZING );

	if( TablesAvailable ) {
	    if( BMark->thread_group_id == 0 ) {
		sprintf( sync_stmt,
		    "insert into TT_RunDesc "
			"(thread_count, run_duration, parms) "
			"values( %d, %d, '%s')",
			    BMark->num_threads * BMark->num_groups,
			    BMark->time_limit,
			    CmdLine );
		if( !main_thread->ExecSQLString( sync_stmt ) ) {
		    // Perhaps tables haven't been created
		    break;
		}
		// Delete rows from a previous run.
		main_thread->ExecSQLString(
		    "delete from TT_Sync where status='RUNNING'" );
		main_thread->Commit();
	    }
    
	    sprintf( sync_stmt,
		"delete from TT_Sync where thread_group=%d",
			BMark->thread_group_id );
	    main_thread->ExecSQLString( sync_stmt );
	    sprintf( sync_stmt,
		"insert into TT_Sync (thread_group, status) "
		    "values (%d, 'STARTING')",
			BMark->thread_group_id );
	    main_thread->ExecSQLString( sync_stmt );
	    main_thread->Commit();
	}

	BMark->threads = (TransactionThread **) calloc( BMark->num_threads, sizeof( void * ) );
	for( thread = 0; thread < BMark->num_threads; thread++ ) {
	    BMark->threads[thread] = new TransactionThread( thread + 1, BMark->thread_group_id );
	    StartThread( ThreadMain, (void *) BMark->threads[thread] );
	    IncrThreadCount();
	}

	// Give threads an opportunity to achieve a stable state
	MySleep( 3000 );

	if( BMark->thread_group_id == 0 ) {
	    if( TablesAvailable ) {
		while( main_thread->GetIntQuery(
			"select count(*) from TT_Sync where status='STARTING'" )
			    != BMark->num_groups ) {
		    printf( "Waiting for other machines...\n" );
		    MySleep( 3000 );
		}
		main_thread->ExecSQLString(
		    "update TT_Sync "
		    "set status='RUNNING'" );
		main_thread->Commit();
	    }
	} else {
	    sprintf( sync_stmt,
		"select count(*) from TT_Sync where status='RUNNING' "
		"and thread_group=%d", BMark->thread_group_id );
	    while( main_thread->GetIntQuery( sync_stmt ) != 1 ) {
		printf( "Waiting for master machine (thread group 0)...\n" );
		MySleep( 3000 );
	    }
	}

	BMark->SetState( TSTATE_RUNNING );

	show_headings = TRUE;
	// Wait for tests to complete:
	while( ThreadsActive != 0 ) {
	    MySleep( BMark->display_rate * 1000 );
	    DisplayActiveStats( show_headings );
	    show_headings = FALSE;
	}

	if( BMark->thread_group_id != 0 || BMark->num_groups > 1 ) {
	    // Get run_nbr & num_groups before saving results, so master does
	    // not start another iteration before we can obtain the values.
	    run_nbr = main_thread->GetIntQuery(
		"select max(run_nbr) from TT_Result" );
	    if( BMark->num_groups == 0 ) {
		// We are not the master machine, so determine the number of
		// machines participating
		BMark->num_groups = main_thread->GetIntQuery(
		    "select count(*) from TT_Sync where status='RUNNING'" );
	    }
	}

	SaveResults( main_thread );

	for( thread = 0; thread < BMark->num_threads; thread++ ) {
	    delete BMark->threads[thread];
	}
	free( BMark->threads );

	if( BMark->thread_group_id != 0 || BMark->num_groups > 1 ) {
	    // Wait until all machines have reported results
	    sprintf( sync_stmt,
		"select count(*) from TT_Result "
		"where run_nbr=%d",
		run_nbr );
	    while( main_thread->GetIntQuery( sync_stmt ) !=
		    (BMark->num_groups * BMark->num_threads) ) {
		printf( "Waiting for results to be recorded...\n" );
		MySleep( 3000 );
	    }
	}
    }

    CloseOutputFile();

    main_thread->Disconnect();
    delete main_thread;

    delete BMark;

    return( ExitCode );
}
