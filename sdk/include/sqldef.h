// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _SQLDEF_H_INCLUDED
#define _SQLDEF_H_INCLUDED
#define II_SQLDEF

#include "sqlca.h"
#include "sqlda.h"
#include "sqlerr.h"
#include "sqlstate.h"

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk1.h"
#endif

/********************************************/
/* general definition of database constants */
/********************************************/

#define DB_MAX_IDENTIFIER_LEN   128

/**************************************************/
/* definitions for connection parms to dblib      */
/*   - used in functions: db_build_parms          */
/*                        db_free_parms           */
/*                        db_start                */
/*                        db_parm_connect         */
/**************************************************/

typedef struct a_dblib_info {
    char	*userid;
    char	*password;
    char	*database_name;
    char	*connection_name;
    char	*dbstartcommline;
} a_dblib_info;


/**************************************************/
/* constants for return values of DOS executables */
/**************************************************/

typedef short int an_exit_code;

#define EXIT_OKAY                   0   /* everything is okay */
#define EXIT_FAIL                   1   /* general failure */
#define EXIT_BAD_DATA               2   /* invalid file format, etc.*/
#define EXIT_FILE_ERROR             3   /* file not found, */
                                        /* unable to open, etc. */
#define EXIT_OUT_OF_MEMORY          4   /* out of memory */
#define EXIT_BREAK                  5   /* terminated by user */
#define EXIT_COMMUNICATIONS_FAIL    6   /* failed communications */
#define EXIT_MISSING_DATABASE       7   /* missing required db name */
#define EXIT_PROTOCOL_MISMATCH      8   /* client/server protocol */
                                        /* mismatch */
#define EXIT_UNABLE_TO_CONNECT      9   /* unable to connect to db */
#define EXIT_ENGINE_NOT_RUNNING     10  /* database not running */
#define EXIT_SERVER_NOT_FOUND       11  /* server not running */
#define EXIT_BAD_ENCRYPT_KEY        12	/* missing or bad encryption key */
#define EXIT_DB_VER_NEWER	    13	/* server must be upgraded to run db */
#define EXIT_FILE_INVALID_DB	    14	/* file is not a database */
#define EXIT_LOG_FILE_ERROR	    15	/* log file was missing or */
					/* other log file error */
#define EXIT_FILE_IN_USE	    16	/* file in use */
#define EXIT_FATAL_ERROR	    17	/* fatal error or assertion occurred */
#define EXIT_MISSING_LICENSE_FILE   18	/* missing server license file */
#define EXIT_BACKGROUND_SYNC_ABORTED  19  /* background synchronization aborted
                                           to let higher priority operations
					   proceed */
#define EXIT_FILE_ACCESS_DENIED     20	/* access to database file denied */
#define EXIT_SERVER_NAME_IN_USE     21	/* another server running with this name */
#define EXIT_USAGE 		    255 /* invalid parameters on command line */
/*****************************/
/* exit codes 200 to 254 are */
/* reserved for internal use */
/* ***************************/


/************************************************/
/* constants for return value of db_find_engine */
/************************************************/

#define DB_ENGINE               0x0001
#define DB_CLIENT               0x0002
#define DB_CAN_MULTI_DB_NAME    0x0004
#define DB_DATABASE_SPECIFIED   0x0008
#define DB_ACTIVE_CONNECTION    0x0010
#define DB_CONNECTION_DIRTY     0x0020
#define DB_CAN_MULTI_CONNECT    0x0040
#define DB_NO_DATABASES         0x0080

/**********************************/
/* host language type definitions */
/**********************************/

#include "sqlhosttype.h"

/**************************/
/* Backup operation types */
/**************************/

#define DB_BACKUP_START             1
#define DB_BACKUP_OPEN_FILE         2
#define DB_BACKUP_READ_PAGE         3
#define DB_BACKUP_CLOSE_FILE        4
#define DB_BACKUP_END               5
#define DB_BACKUP_READ_RENAME_LOG   6
#define DB_BACKUP_PARALLEL_START    7
#define DB_BACKUP_PARALLEL_READ     8
#define DB_BACKUP_INFO		    9

/******************************/
/* Log Backup operation types */
/******************************/

#define DB_LOG_BACKUP_START         51
#define DB_LOG_BACKUP_READ_PAGE     52
#define DB_LOG_BACKUP_READ_PAGE_WAIT 53
#define DB_LOG_BACKUP_END           54

/******************************/
/* Backup info types          */
/******************************/

#define DB_BACKUP_INFO_PAGES_IN_BLOCK	0
#define DB_BACKUP_INFO_CHKPT_LOG	1

/****************************************/
/* Values for DB_BACKUP_INFO_CHKPT_LOG  */
/****************************************/

#define DB_BACKUP_CHKPT_COPY	0
#define DB_BACKUP_CHKPT_NOCOPY  1

/**************************/
/* Backup file constants  */
/**************************/

#define DB_BACKUP_MAX_FILE          12
#define DB_BACKUP_WRITE_FILE        -1
#define DB_BACKUP_TRANS_LOG_FILE    -2

/**************************/
/* Backup version         */
/**************************/

#define DB_BACKUP_VERSION            1

/****************************/
/* db_environment constants */
/****************************/

#define DB_ENV_FLAGS                0       /* Short int */
#define DB_ENV_ENGVERSION           1       /* String */
#define DB_ENV_ENGNAME              2       /* String */
#define DB_ENV_DBNAME               3       /* String */
#define DB_ENV_SRVNAME              4       /* String */
#define DB_ENV_SRVVERSION           5       /* String */

/**********************************/
/* db_interface_option constants */
/**********************************/

typedef int			    a_db_interface_option;

#define DBO_ANSI_TRUNCATION         1
#define DBO_ANSI_BLANKS             2

/**************************************/
/* db_init_dll return value constants */
/**************************************/

#define ESQLDLL_OK		    0
#define ESQLDLL_DLL_NOT_FOUND	    1
#define ESQLDLL_WRONG_VERSION	    2

/*******************************************/
/* Message types from the message callback */
/*******************************************/
#define MESSAGE_TYPE_INFO	    0
#define MESSAGE_TYPE_WARNING	    1
#define MESSAGE_TYPE_ACTION	    2
#define MESSAGE_TYPE_STATUS  	    3
#define MESSAGE_TYPE_PROGRESS  	    4

/*******************************************/
/* OEM String constants for finding value within database file header */
/*******************************************/
#define DB_OEM_STRING_PSXLEN 8	/* length of prefix/suffix markers */
#define DB_OEM_STRING_PREFIX "\xDA\x7A\xBA\x5E\0EM="
#define DB_OEM_STRING_SUFFIX "=ME\0\x5E\xBA\x7A\xDA"

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif
