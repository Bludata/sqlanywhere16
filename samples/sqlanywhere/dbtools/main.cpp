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

#include <stdio.h>
#include "string.h"
#include "dbtools.h"
#include "sqldef.h"
#include "sqlos.h"

#if defined( WIN32 ) || defined( WIN64 )
    #include "windows.h"
    #define TEMPDIR "C:\\Temp"
#else
    #include <sys/param.h> // for MAXPATHLEN
    #define TEMPDIR "/tmp"
    #define CALLBACK 
    #define _MAX_PATH MAXPATHLEN
#endif

// WIN64 test comes first because WIN32 also defined
#if defined( WIN64 )
    #define DBBACKUP "DBBackup"
    #define DBTOOLSINIT "DBToolsInit"
    #define DBTOOLSFINI "DBToolsFini"
#elif defined( WIN32 )
    #define DBBACKUP "_DBBackup@4"
    #define DBTOOLSINIT "_DBToolsInit@4"
    #define DBTOOLSFINI "_DBToolsFini@4"
#else
    #define DBBACKUP "DBBackup"
    #define DBTOOLSINIT "DBToolsInit"
    #define DBTOOLSFINI "DBToolsFini"
#endif

#if defined( WIN32 ) || defined( WIN64 )
    #define DBTOOLSLIB "dbtool16.dll"
#elif defined( HP ) && defined( PARISC )
    #define DBTOOLSLIB "libdbtool16_r.sl"
#elif defined( MACOSX )
    #define DBTOOLSLIB "libdbtool16_r.dylib"
#elif defined( UNIX )
    #define DBTOOLSLIB "libdbtool16_r.so"
#endif

typedef an_exit_code (CALLBACK *DBTOOLSPROC)( void * );

#if defined( WIN32 ) || defined( WIN64 )
    typedef HINSTANCE a_dll_handle;

    static a_dll_handle LibLoad( const char *name )
    {
        return LoadLibrary( name );
    }

    static void LibFree( a_dll_handle h )
    {
        FreeLibrary( h );
    }

    static DBTOOLSPROC ProcAddrGet( a_dll_handle h, const char *name )
    {
        return (DBTOOLSPROC) GetProcAddress( (HMODULE) h, name );
    }
#elif defined( UNIX )
    #include <dlfcn.h>
    typedef void * a_dll_handle;

    static a_dll_handle LibLoad( const char *name )
    {
        return dlopen( name, RTLD_NOW );
    }

    static void LibFree( a_dll_handle h )
    {
        dlclose( h );
    }

    static DBTOOLSPROC ProcAddrGet( a_dll_handle h, const char *name )
    {
        return (DBTOOLSPROC) dlsym( h, name );
    }
#else
    #error "Need to implement shared object loading gear for this platform."
#endif

extern short _callback ConfirmCallBack( char * str )
{
#if defined( WIN32 ) || defined( WIN64 )
        if( MessageBox( NULL, str, "Backup",
                 MB_YESNO|MB_ICONQUESTION ) == IDYES )
#else
        int choice;
        do {
                printf( "%s [Y/N] ", str );
		while( ( choice = getchar() ) == '\n' ) continue;
	} while( choice != 'Y' && choice != 'y' &&
                 choice != 'N' && choice != 'n' );
        if( choice == 'Y' || choice == 'y' )
#endif
        {
                return 1;
        }
        return 0;
}

extern short _callback MessageCallBack( char * str )
{
        if( str != NULL )
        {
                fprintf( stdout, "%s\n", str );
        }
        return 0;
}

extern short _callback StatusCallBack( char * str )
{
        if( str != NULL )
        {
                fprintf( stdout, "%s\n", str );
        }
        return 0;
}

extern short _callback ErrorCallBack( char * str )
{
        if( str != NULL )
        {
                fprintf( stdout, "%s\n", str );
        }
        return 0;
}

int main( int argc, char * argv[] )
{
        an_exit_code            sts;
        a_dbtools_info          dbt_info;
        a_backup_db             backup_info;
        char                    dir_name[ _MAX_PATH + 1];
        char                    connect[ 256 ];
        a_dll_handle            hnd;
        DBTOOLSPROC             dbbackup;
        DBTOOLSPROC             dbtoolsinit;
        DBTOOLSPROC             dbtoolsfini;

        // Always initialize to 0 so new versions
        // of the structure will be compatible.
        memset( &backup_info, 0, sizeof( a_backup_db ) );
        backup_info.version = DB_TOOLS_VERSION_NUMBER;
        backup_info.quiet = 0;
        backup_info.no_confirm = 0;
        backup_info.confirmrtn = (MSG_CALLBACK)ConfirmCallBack;
        backup_info.errorrtn = (MSG_CALLBACK)ErrorCallBack;
        backup_info.msgrtn = (MSG_CALLBACK)MessageCallBack;
        backup_info.statusrtn = (MSG_CALLBACK)StatusCallBack;

        if( argc > 1 )
        {
                strncpy( dir_name, argv[1], _MAX_PATH );
        }
        else
        {
                // DBTools does not expect (or like) a trailing slash
                strcpy( dir_name, TEMPDIR );
        }
        backup_info.output_dir = dir_name;

        if( argc > 2 )
        {
                strncpy( connect, argv[2], 255 );
        }
        else
        {
                strcpy( connect, "DSN=SQL Anywhere 16 Demo" );
        }
        backup_info.connectparms = connect;
        backup_info.quiet = 0;
        backup_info.no_confirm = 0;
        backup_info.backup_database = 1;
        backup_info.backup_logfile = 1;
        backup_info.rename_log = 0;
        backup_info.truncate_log = 0;

        hnd = LibLoad( DBTOOLSLIB );
        if( hnd == NULL )
        {
                return 0;   // failed
        }
        dbt_info.errorrtn = (MSG_CALLBACK)ErrorCallBack;
        dbbackup = ProcAddrGet( hnd, DBBACKUP );
        dbtoolsinit = ProcAddrGet( hnd, DBTOOLSINIT );
        dbtoolsfini = ProcAddrGet( hnd, DBTOOLSFINI );
        sts = (*dbtoolsinit)( &dbt_info );
	// Possible return codes are defined in sqldef.h
        if( sts == EXIT_OKAY ) {
                sts = (*dbbackup)( &backup_info );
                sts = (*dbtoolsfini)( &dbt_info );
        }
        LibFree( hnd );
        return 0;
}
