// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _DBTOOLS_H_INCLUDED
#define _DBTOOLS_H_INCLUDED

#include "sqlca.h"
#include "dllapi.h"
#include "dbtlvers.h"
#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk1.h"
#endif
 
/// \file dbtools.h

//  Generic interface pieces
//***************************************************************************

#if defined(__unix) || defined(_AIX)
    #if !defined(a_bit_field)
	/// \internal
        #define a_bit_field unsigned int
	/// \internal
        #define a_bit_short unsigned int
    #endif
#else
    #if !defined(a_bit_field)
	/// \internal
        #define a_bit_field unsigned char
	/// \internal
        #define a_bit_short unsigned short
    #endif
#endif

/** Specifies a variable list of names.
 */
typedef struct a_name {
    /// Pointer to the next name in the list or NULL.
    struct a_name *	next;
    /// One or more bytes comprising the name.
    char		name[1];
} a_name, * p_name;

/** DBTools information callback used to initialize and finalize the
 * DBTools library calls.
 *
 * \sa DBToolsInit()
 * \sa DBToolsFini()
 */
typedef struct a_dbtools_info {
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
} a_dbtools_info;

/** Prepares the DBTools library for use.
 *
 * The primary purpose of the DBToolsInit function is to load the SQL
 * Anywhere messages library. The messages library contains localized
 * versions of error messages and prompts used by the functions in the
 * DBTools library.
 *
 * The DBToolsInit function must be called at the start of any application
 * that uses the DBTools interface, before any other DBTools functions.
 *
 * \param pdi Pointer to a properly initialized a_dbtools_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{A DBTools example, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/pg-dbtools-de.html", "programming", "pg-dbtools-de"}
 *
 * \sa a_dbtools_info structure
 * \sa DBToolsFini()
 */
extern _crtn short _entry DBToolsInit( const a_dbtools_info *pdi );

/** Decrements a reference counter and frees resources when an application
 * is finished with the DBTools library.
 *
 * The DBToolsFini function must be called at the end of any application
 * that uses the DBTools interface. Failure to do so can lead to lost memory
 * resources. 
 *
 * \param pdi Pointer to a properly initialized a_dbtools_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \sa a_dbtools_info structure
 * \sa DBToolsInit()
 */
extern _crtn short _entry DBToolsFini( const a_dbtools_info *pdi );

/** Returns the version number of the DBTools library.
 *
 * Use the DBToolsVersion function to check that the DBTools library is not
 * older than one against which your application is developed. While
 * applications can run against newer versions of DBTools, they cannot run
 * against older versions.
 *
 * \seealso{Version numbers and compatibility, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-version-numbers.html", "programming", "dbt-version-numbers"}
 */
extern _crtn short _entry DBToolsVersion( void );

//***************************************************************************
// backup database (DBBACKUP) interface
//***************************************************************************

/*
    Example:
    a_backup_db Structure settings for equivalent of following command:
    dbbackup -c "uid=dba;pwd=sql;dbf=d:\db\demo.db" c:\temp

    version		DB_TOOLS_VERSION_NUMBER
    errorrtn		0x0040.... callback_error(char *)
    msgrtn		0x0040.... callback_usage(char *)
    confirmrtn		0x0040.... callback_confirm(char *)
    statusrtn		0x0040.... callback_status(char *)
    output_dir		"c:\\temp"
    connectparms	"uid=dba;pwd=sql;dbf=d:\\db\\demo.db"
    backup_database	1
    backup_logfile	1
			    
*/

/** Used in the a_backup_db structure to control copying of the
 * checkpoint log.
 *
 * \sa a_backup_db structure
 * \sa DBBackup()
 */
enum { // Checkpoint
    /// Use to generate WITH CHECKPOINT LOG COPY clause.
    BACKUP_CHKPT_LOG_COPY = 0,
    /// Use to generate WITH CHECKPOINT LOG NOCOPY clause.
    BACKUP_CHKPT_LOG_NOCOPY,
    /// Use to generate WITH CHECKPOINT LOG RECOVER clause.
    BACKUP_CHKPT_LOG_RECOVER,
    /// Use to generate WITH CHECKPOINT LOG AUTO clause.
    BACKUP_CHKPT_LOG_AUTO,
    /// Use to omit WITH CHECKPOINT clause.
    BACKUP_CHKPT_LOG_DEFAULT
};

/** Used in the a_backup_db structure to control auto tuning of writers.
 *
 * \sa a_backup_db structure
 * \sa DBBackup()
 */
enum { // Autotune
    /// Use to leave AUTO TUNE WRITERS clause unspecified.
    BACKUP_AUTO_TUNE_UNSPECIFIED = 0,
    /// Use to generate AUTO TUNE WRITERS ON clause.
    BACKUP_AUTO_TUNE_ON,
    /// Use to generate AUTO TUNE WRITERS OFF clause.
    BACKUP_AUTO_TUNE_OFF
};

/** Used in the a_backup_db structure to control enabling of backup history.
 *
 * \sa a_backup_db structure
 * \sa DBBackup()
 */
enum { // History
    /// Use to leave HISTORY clause unspecified.
    BACKUP_HISTORY_UNSPECIFIED = 0,
    /// Use to generate HISTORY ON clause.
    BACKUP_HISTORY_ON,
    /// Use to generate HISTORY OFF clause.
    BACKUP_HISTORY_OFF
};

/** Holds the information needed to perform backup tasks using the DBTools
 * library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa Checkpoint enumeration
 * \sa DBBackup()
 */
typedef struct a_backup_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK	confirmrtn;
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK	statusrtn;
    /// Path to the output directory for backups, for example: "c:\backup".
    const char *	output_dir;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    const char *	connectparms;
    /// File name for the live backup file.
    /// Set by dbbackup -l option.
    const char *	hotlog_filename;
    /// Number of pages in data blocks. If set to 0, then the default is 128.
    /// Set by dbbackup -b option. 
    a_sql_uint32	page_blocksize;
    /// Control copying of checkpoint log. Must be one of
    /// BACKUP_CHKPT_LOG_COPY, BACKUP_CHKPT_LOG_NOCOPY,
    /// BACKUP_CHKPT_LOG_RECOVER, BACKUP_CHKPT_LOG_AUTO, or
    /// BACKUP_CHKPT_LOG_DEFAULT.
    /// Set by dbbackup -k option.
    char		chkpt_log_type;
    /// Indicates that the operation was interrupted when non-zero.
    char		backup_interrupted;
    /// Back up the database file.
    /// Set TRUE by dbbackup -d option.
    a_bit_field backup_database	    : 1;
    /// Back up the transaction log file.
    /// Set TRUE by dbbackup -t option.
    a_bit_field backup_logfile	    : 1;
    /// Operate without confirmation.
    /// Set TRUE by dbbackup -y option.
    a_bit_field no_confirm	    : 1;
    /// Operate without printing messages.
    /// Set TRUE by dbbackup -q option.
    a_bit_field quiet		    : 1;
    /// Rename the transaction log.
    /// Set TRUE by dbbackup -r option.
    a_bit_field rename_log	    : 1;
    /// Delete the transaction log.
    /// Set TRUE by dbbackup -x option.
    a_bit_field truncate_log	    : 1;
    /// Rename the local backup of the transaction log.
    /// Set TRUE by dbbackup -n option.
    a_bit_field rename_local_log    : 1;
    /// Perform backup on server using BACKUP DATABASE.
    /// Set TRUE by dbbackup -s option.
    a_bit_field server_backup	    : 1;
    /// Display progress messages.
    /// Set TRUE by dbbackup -p option.
    a_bit_field progress_messages   : 1;
    /// Wait before start.
    /// Set TRUE by dbbackup -wb option.
    a_bit_field wait_before_start   : 1;
    /// Wait after end.
    /// Set TRUE by dbbackup -wa option.
    a_bit_field wait_after_end      : 1;
    /// Comment used for the WITH COMMENT clause
    const char *	backup_comment;
    /// Enable/disable auto tune writers.
    /// Must be one of BACKUP_AUTO_TUNE_UNSPECIFIED, BACKUP_AUTO_TUNE_ON, or
    /// BACKUP_AUTO_TUNE_OFF.
    /// Use to generate AUTO TUNE WRITERS OFF clause.
    /// Set by dbbackup -aw[-] option
    char		auto_tune_writers;
    /// Backup history.
    /// Must be one of BACKUP_HISTORY_UNSPECIFIED, BACKUP_HISTORY_ON, or
    /// BACKUP_HISTORY_OFF.
    /// Set by dbbackup -h[-] option
    char		backup_history;
} a_backup_db;

/** Backs up a database. This function is used by the dbbackup utility.
 *
 * The DBBackup function manages all client-side database backup tasks. For a
 * description of these tasks, see
 * \salink{Backup utility (dbbackup), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbbackup.html", "dbadmin", "dbbackup"}.
 *
 * To perform a server-side backup, use the BACKUP DATABASE statement.
 *
 * \param pdb Pointer to a properly initialized a_backup_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{BACKUP statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/backup-statement.html", "sqlref", "backup-statement"}
 *
 * \sa a_backup_db
 */
extern _crtn short _entry DBBackup( const a_backup_db *pdb );

//***************************************************************************
// change database logfile name (DBLOG) interface
//***************************************************************************

/** Holds the information needed to perform dblog tasks using the DBTools library.
 *
 * \sa DBChangeLogName()
 */
typedef struct a_change_log {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Database file name.
    const char *	dbname;
    /// Transaction log file name, or NULL if there is no log.
    const char *	logname;	    // (logname = NULL) for no log
    /// The new name of the transaction log mirror file. Equivalent to dblog -m option.
    const char *	mirrorname;
    /// Change the current offset to the specified value. This is for use
    /// only in resetting a transaction log after an unload and reload to
    /// match dbremote or dbmlsync settings. Equivalent to dblog -x option.
    char *		zap_current_offset;
    /// Change the starting offset to the specified value. This is for use
    /// only in resetting a transaction log after an unload and reload to
    /// match dbremote or dbmlsync settings. Equivalent to dblog -z option.
    char *		zap_starting_offset;
    /// The encryption key for the database file. Equivalent to dblog -ek or -ep option.
    char *		encryption_key;
    /// The new generation number. Reserved, use zero.
    unsigned short	generation_number;
    /// If 1, just display the name of the transaction log. If 0, permit changing of the log name.
    a_bit_field query_only	    : 1;
    /// Operate without printing messages.
    /// Set TRUE by dblog -q option.
    a_bit_field quiet		    : 1;
    /// Set TRUE to permit changing of the mirror log name.
    /// Set TRUE by dblog -m, -n, or -r option.
    a_bit_field change_mirrorname   : 1;
    /// Set TRUE to permit changing of the transaction log name.
    /// Set TRUE by dblog -n or -t option.
    a_bit_field change_logname	    : 1;
    /// Reserved, use FALSE.
    a_bit_field ignore_ltm_trunc    : 1;
    /// For SQL Remote. Resets the offset kept for the delete_old_logs option,
    /// allowing transaction logs to be deleted when they are no longer needed.
    /// Set TRUE by dblog -ir option.
    a_bit_field ignore_remote_trunc : 1;
    /// Reserved. Use FALSE.
    a_bit_field	set_generation_number : 1;
    /// When using dbmlsync, resets the offset kept for the delete_old_logs
    /// option, allowing transaction logs to be deleted when they are no
    /// longer needed.
    /// Set TRUE by dblog -is option.
    a_bit_field ignore_dbsync_trunc : 1;
} a_change_log;

/** Changes the name of the transaction log file. This function is used by
 * the dblog utility.
 *
 * The -t option of the Transaction Log utility (dblog) changes the name of
 * the transaction log. DBChangeLogName provides a programmatic interface to
 * this function.
 *
 * \param pcl Pointer to a properly initialized a_change_log structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Transaction Log utility (dblog), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dblog.html", "dbadmin", "dblog"}
 * \seealso{ALTER DATABASE statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/alter-database-statement.html", "sqlref", "alter-database-statement"}
 *
 * \sa a_change_log structure
 */
extern _crtn short _entry DBChangeLogName( const a_change_log *pcl );

//***************************************************************************
// get database log file information interface
//***************************************************************************

/** Used to obtain the log file and mirror log file information of a
 * non-running database.
 *
 * \sa DBLogFileInfo()
 */
typedef struct a_log_file_info {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Database file name.
    const char *	dbname;
    /// The encryption key for the database file.
    const char *	encryption_key;
    /// Buffer for transaction log file name, or NULL.
    char *		logname;
    /// Size of buffer for transaction log file name, or zero.
    size_t		logname_size;
    /// Buffer for mirror log file name, or NULL.
    char *		mirrorname;
    /// Size of buffer for mirror log file name, or zero.
    size_t		mirrorname_size;
    /// Reserved for internal use and must set to NULL.
    void *		reserved;
} a_log_file_info;

/** Returns the log file and mirror log file paths of a non-running database
 * file. Note that this function will only work for databases that have
 * been created with SQL Anywhere 10.0.0 and up.
 *
 * \param plfi Pointer to a properly initialized a_log_file_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \sa a_log_file_info structure
 */
extern _crtn short _entry DBLogFileInfo( const a_log_file_info *plfi );

//***************************************************************************
// create a new database (DBINIT) interface
//***************************************************************************

/** Verbosity enumeration specifies the volume of output.
 *
 * \sa a_create_db structure
 * \sa DBCreate()
 */
enum { // Verbosity
    /// No output.
    VB_QUIET,
    /// Normal amount of output.
    VB_NORMAL,
    /// Verbose output, useful for debugging.
    VB_VERBOSE
};

/** Blank padding enumeration specifies the blank_pad setting in a_create_db.
 *
 * \sa a_create_db structure
 * \sa DBCreate()
 */
enum { // Padding
    /// Does not use blank padding.
    NO_BLANK_PADDING,
    /// Uses blank padding.
    BLANK_PADDING
};

/** Used in the a_create_db structure, to specify the value of db_size_unit. 
 *
 * \sa a_create_db structure
 * \sa DBCreate()
 */
enum { // Unit
    /// Units not specified.
    DBSP_UNIT_NONE,
    /// Size is specified in pages.
    DBSP_UNIT_PAGES,
    /// Size is specified in bytes.
    DBSP_UNIT_BYTES,
    /// Size is specified in kilobytes.
    DBSP_UNIT_KILOBYTES,
    /// Size is specified in megabytes.
    DBSP_UNIT_MEGABYTES,
    /// Size is specified in gigabytes.
    DBSP_UNIT_GIGABYTES,
    /// Size is specified in terabytes.
    DBSP_UNIT_TERABYTES
};

/** Holds the information needed to create a database using the DBTools library.
 *
 * \seealso{Using checksums to detect corruption, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/using-checksums.html", "dbadmin", "using-checksums"}
 *
 * \sa Padding enumeration
 * \sa Unit enumeration
 * \sa Verbosity enumeration
 * \sa DBCreate()
 */
typedef struct a_create_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Database file name.
    const char		*dbname;
    /// New transaction log name. Equivalent to dbinit -t option.
    const char		*logname;
    /// The command line used to start the database server. For example:
    /// "c:\SQLAny16\bin32\dbsrv16.exe".
    /// If NULL, the default START parameter is "dbeng16 -gp <page_size> -c 10M" for SQL Anywhere
    /// where page_size is specified below.
    /// Note that "-c 10M" is appended if page_size >= 2048.
    const char		*startline;
    /// The collation for the database. Equivalent to dbinit -z option.
    const char		*default_collation;
    /// The NCHAR COLLATION for the database when not NULL. Equivalent to dbinit -zn option.
    const char		*nchar_collation;
    /// The character set encoding. Equivalent to dbinit -ze option.
    const char		*encoding;
    /// Transaction log mirror name. Equivalent to dbinit -m option.
    const char		*mirrorname;
    /// Reserved. Use NULL.
    const char		*data_store_type;
    /// The encryption key for the database file. Used with encrypt, it
    /// generates the KEY clause. Equivalent to dbinit -ek option.
    const char		*encryption_key;
    /// The encryption algorithm (AES, AES256, AES_FIPS, or AES256_FIPS).
    /// Used with encrypt and encryption_key, it generates the ALGORITHM
    /// clause. Equivalent to dbinit -ea option.
    const char		*encryption_algorithm;
    /// Reserved. Use NULL.
    void		*iq_params;
    /// Used with db_size, must be one of DBSP_UNIT_NONE, DBSP_UNIT_PAGES,
    /// DBSP_UNIT_BYTES, DBSP_UNIT_KILOBYTES, DBSP_UNIT_MEGABYTES,
    /// DBSP_UNIT_GIGABYTES, or DBSP_UNIT_TERABYTES. When not
    /// DBSP_UNIT_NONE, it generates the corresponding keyword (for example,
    /// DATABASE SIZE 10 MB is generated when db_size is 10 and db_size_unit
    /// is DBSP_UNIT_MEGABYTES). See Database size unit enumeration.
    int			db_size_unit;
    /// When not 0, generates the DATABASE SIZE clause. Equivalent to dbinit -dbs option.
    unsigned int	db_size;
    /// The page size of the database. Equivalent to dbinit -p option.
    unsigned short	page_size;
    /// See Verbosity enumeration (VB_QUIET, VB_NORMAL, VB_VERBOSE).
    char		verbose;
    /// One of 'y', 'n', or 'f' (yes, no, French). Generates one of the
    /// ACCENT RESPECT, ACCENT IGNORE or ACCENT FRENCH clauses.
    char		accent_sensitivity;
    /// When not NULL, generates the DBA USER xxx clause. Equivalent to dbinit -dba option.
    char		*dba_uid;
    /// When not NULL, generates the DBA PASSWORD xxx clause. Equivalent to dbinit -dba option.
    char		*dba_pwd;
    /// Must be one of NO_BLANK_PADDING or BLANK_PADDING. Treat blanks as
    /// significant in string comparisons and hold index information to
    /// reflect this. See Blank padding enumeration.
    /// Equivalent to dbinit -b option.
    a_bit_field blank_pad	    : 2;
    /// Make string comparisons case sensitive and hold index information
    /// to reflect this. Set TRUE by dbinit -c option.
    a_bit_field respect_case	    : 1;
    /// Set TRUE to generate the ENCRYPTED ON clause or, when encrypted_tables
    /// is also set, the ENCRYPTED TABLES ON clause.
    /// Set TRUE by dbinit -e? options.
    a_bit_field encrypt		    : 1;
    /// Set TRUE to omit the generation of Watcom SQL compatibility views
    /// SYS.SYSCOLUMNS and SYS.SYSINDEXES. Set TRUE by dbinit -k option.
    a_bit_field	avoid_view_collisions : 1;
    /// Set TRUE to include system procedures needed for jConnect.
    /// Set FALSE by dbinit -i option.
    a_bit_field jconnect	    : 1;
    /// Set to TRUE for ON or FALSE for OFF. Generates one of CHECKSUM ON or
    /// CHECKSUM OFF clauses. 
    /// Set TRUE by dbinit -s option.
    a_bit_field checksum            : 1;
    /// Set TRUE to encrypt tables. Used with encrypt, it generates the
    /// ENCRYPTED TABLE ON clause instead of the ENCRYPTED ON clause.
    /// Set TRUE by dbinit -et option.
    a_bit_field encrypted_tables    : 1;
    /// Set TRUE to use the default case sensitivity for the locale. This
    /// only affects UCA. If set TRUE then we do not add the CASE RESPECT
    /// clause to the CREATE DATABASE statement.
    a_bit_field	case_sensitivity_use_default : 1;
    /// Set TRUE to retain the SQL SECURITY Model for version 12.0.1 or earlier system stored procedures.
    /// Set TRUE by dbinit -pd option.
    a_bit_field sys_proc_definer    : 1;
} a_create_db;

/** Creates a database. This function is used by the dbinit utility.
 *
 * \param pcdb Pointer to a properly initialized a_create_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Initialization utility (dbinit), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbinit.html", "dbadmin", "dbinit"}
 *
 * \sa a_create_db structure
 */
extern _crtn short _entry DBCreate( a_create_db *pcdb );

//***************************************************************************
// erase a database (DBERASE)
//***************************************************************************

/** Holds information needed to erase a database using the DBTools library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 *
 * \sa DBErase()
 */
typedef struct an_erase_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK	confirmrtn;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Database file name.
    const char *	dbname;
    /// The encryption key for the database file.
    /// Equivalent to dberase -ek or -ep options.
    const char *	encryption_key;
    /// Operate without printing messages (1), or print messages (0).
    /// Set TRUE by dberase -q option.
    a_bit_field	quiet	: 1;
    /// Erase without confirmation (1) or with confirmation (0).
    /// Set TRUE by dberase -y option.
    a_bit_field	erase	: 1;
} an_erase_db;

/** Erases a database file and/or transaction log file. This function is
 * used by the dberase utility.
 *
 * \param pedb Pointer to a properly initialized an_erase_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Erase utility (dberase), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dberase.html", "dbadmin", "dberase"}
 *
 * \sa an_erase_db structure
 */
extern _crtn short _entry DBErase( const an_erase_db *pedb );

//***************************************************************************
// get information from a database about how it was created (DBINFO)
//***************************************************************************

/** Holds information needed for dbinfo and dbunload utilities using the
 * DBTools library.
 *
 * \sa a_db_info structure
 * \sa DBInfo()
 * \sa DBInfoDump()
 * \sa DBInfoFree()
 */
typedef struct a_sysinfo {
    /// The page size for the database.
    unsigned short  page_size;
    /// The collation sequence for the database.
    char	    default_collation[11];
    /// 1 to indicate that the other bit fields are valid.
    a_bit_field	    valid_data		: 1;
    /// 1 if blank padding is used in this database, 0 otherwise.
    a_bit_field	    blank_padding	: 1;
    /// 1 if the database is case sensitive, 0 otherwise.
    a_bit_field	    case_sensitivity	: 1;
    /// 1 if the database is encrypted, 0 otherwise.
    a_bit_field	    encryption		: 1;
} a_sysinfo;

/** Holds information about a table needed as part of the a_db_info structure.
 *
 * \sa a_db_info structure
 * \sa DBInfo()
 * \sa DBInfoDump()
 * \sa DBInfoFree()
 */
typedef struct a_table_info {
    /// Next table in the list.
    struct a_table_info *next;
    /// Name of the table.
    char *		table_name;
    /// ID number for this table.
    a_sql_uint32	table_id;
    /// Number of table pages.
    a_sql_uint32 	table_pages;
    /// Number of index pages.
    a_sql_uint32 	index_pages;
    /// Number of bytes used in table pages.
    a_sql_uint32 	table_used;
    /// Number of bytes used in index pages.
    a_sql_uint32 	index_used;
    /// Table space utilization as a percentage.
    a_sql_uint32	table_used_pct;
    /// Index space utilization as a percentage.
    a_sql_uint32	index_used_pct;
} a_table_info;

/** Holds the information needed to return DBInfo information using the
 * DBTools library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 * \seealso{Using checksums to detect corruption, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/using-checksums.html", "dbadmin", "using-checksums"}
 *
 * \sa a_table_info structure
 * \sa a_sysinfo structure
 * \sa DBInfo()
 * \sa DBInfoDump()
 * \sa DBInfoFree()
 */
typedef struct a_db_info {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK	statusrtn;
    /// Pointer to a_table_info structure.
    a_table_info	*totals;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    const char		*connectparms;
    /// Pointer to the database file name buffer.
    char		*dbnamebuffer;
    /// Pointer to the transaction log file name buffer.
    char		*lognamebuffer;
    /// Pointer to the mirror file name buffer.
    char		*mirrornamebuffer;
    /// Pointer to the char collation string buffer.
    char		*charcollationspecbuffer;
    /// Pointer to the char encoding string buffer.
    char		*charencodingbuffer;
    /// Pointer to the nchar collation string buffer.
    char		*ncharcollationspecbuffer;
    /// Pointer to the nchar encoding string buffer.
    char		*ncharencodingbuffer;
    /// Size of dbnamebuffer (for example, _MAX_PATH).
    unsigned short	dbbufsize;
    /// Size of lognamebuffer (for example, _MAX_PATH).
    unsigned short	logbufsize;
    /// Size of mirrornamebuffer (for example, _MAX_PATH).
    unsigned short	mirrorbufsize;
    /// Size of charcollationspecbuffer (at least 256+1).
    unsigned short	charcollationspecbufsize;
    /// Size of charencodingbuffer (at least 50+1).
    unsigned short	charencodingbufsize;
    /// Size of ncharcollationspecbuffer (at least 256+1).
    unsigned short	ncharcollationspecbufsize;
    /// Size of ncharencodingbuffer (at least 50+1).
    unsigned short	ncharencodingbufsize;
    /// Inline a_sysinfo structure.
    a_sysinfo		sysinfo;
    // The following page usage values are returned by DBInfo(), DBInfoDump()
    /// Size of database file (in pages).
    a_sql_uint32	file_size;
    /// Number of free pages.
    a_sql_uint32	free_pages;
    /// Number of bitmap pages in the database.
    a_sql_uint32	bit_map_pages;
    /// Number of pages that are not table pages, index pages, free pages,
    /// or bitmap pages.
    a_sql_uint32	other_pages;
    /// Set TRUE to operate without confirming messages.
    /// Set TRUE by dbinfo -q option.
    a_bit_field quiet		    : 1;
    /// Set TRUE to report page usage statistics, otherwise FALSE.
    /// Set TRUE by dbinfo -u option.
    a_bit_field page_usage	    : 1;
    /// If set TRUE, global checksums are enabled (a checksum on every
    /// database page).
    a_bit_field checksum	    : 1;
    /// If set TRUE, encrypted tables are supported.
    a_bit_field encrypted_tables    : 1;
} a_db_info;

/** Returns information about a database file. This function is used by the
 * dbinfo utility.
 *
 * \param pdbi Pointer to a properly initialized a_db_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Information utility (dbinfo), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbinfo.html", "dbadmin", "dbinfo"}
 *
 * \sa a_db_info structure
 * \sa DBInfoDump()
 * \sa DBInfoFree()
 */
extern _crtn short _entry DBInfo( a_db_info *pdbi );

/** Returns information about a database file. This function is used by the
 * dbinfo utility when the -u option is used.
 *
 * \param pdbi Pointer to a properly initialized a_db_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \sa a_db_info structure
 * \sa DBInfo()
 * \sa DBInfoFree()
 */
extern _crtn short _entry DBInfoDump( a_db_info *pdbi );

/** Frees resources after the DBInfoDump function is called.
 *
 * \param pdbi Pointer to a properly initialized a_db_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \sa a_db_info structure
 * \sa DBInfo()
 * \sa DBInfoDump()
 */
extern _crtn short _entry DBInfoFree( a_db_info *pdbi );

//***************************************************************************
// translate log file to SQL (DBTRAN) interface
//***************************************************************************

/** The type of a user list, as used by an a_translate_log structure.
 *
 * \sa a_translate_log structure
 * \sa DBTranslateLog()
 */
enum { // UserList
    /// Include operations from all users.
    DBTRAN_INCLUDE_ALL,
    /// Include operations only from the users listed in the supplied user list.
    DBTRAN_INCLUDE_SOME,
    /// Exclude operations from the users listed in the supplied user list.
    DBTRAN_EXCLUDE_SOME
};

/** Holds information needed for transaction log translation using the
 * DBTools library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa a_name structure
 * \sa UserList enumeration
 * \sa DBTranslateLog()
 */
typedef struct a_translate_log {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short  version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK    errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK    msgrtn;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK    confirmrtn;
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK    statusrtn;
    /// Address of a logging callback routine to write messages only to a log file or NULL.
    MSG_CALLBACK    logrtn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    const char *    connectparms;
    /// Name of the transaction log file. If NULL, there is no log.
    const char *    logname;
    /// Name of the SQL output file. If NULL, then the name is based on
    /// the transaction log file name. Equivalent to dbtran -n option.
    const char *    sqlname;
    /// The encryption key for the database file. Equivalent to dbtran -ek option.
    const char *    encryption_key;
    /// Transaction logs directory. Equivalent to dbtran -m option.
    /// The sqlname pointer must be set and connectparms must be NULL.
    const char *    logs_dir;
    /// Reserved, use NULL.
    const char *    include_source_sets;
    /// Reserved, use NULL.
    const char *    include_destination_sets;
    /// Reserved, use NULL.
    const char *    include_scan_range;
    /// Reserved, use NULL.
    const char *    repserver_users;
    /// Reserved, use NULL.
    const char *    include_tables;
    /// Reserved, use NULL.
    const char *    include_publications;
    /// Reserved, use NULL.
    const char *    queueparms;
    /// Reserved, use NULL.
    const char *    match_pos;
    /// A linked list of user names. Equivalent to dbtran -u user1,...
    /// or -x user1,...
    /// Select or omit transactions for listed users.
    p_name	    userlist;
    /// Output from most recent checkpoint before time. The number of minutes
    /// since January 1, 0001. Equivalent to dbtran -j option.
    a_sql_uint32    since_time;		// 0 or number of minutes since January 1, 0001 (-j)
    /// Reserved, use 0.
    a_sql_uint32    debug_dump_size;
    /// Reserved, use 0.
    a_sql_uint32    recovery_ops;
    /// Reserved, use 0.
    a_sql_uint32    recovery_bytes;
    /// Set to DBTRAN_INCLUDE_ALL unless you want to include or exclude a
    /// list of users. DBTRAN_INCLUDE_SOME for -u, or DBTRAN_EXCLUDE_SOME
    /// for -x. 
    char	    userlisttype;
    /// Set to TRUE to operate without printing messages.
    /// Set TRUE by dbtran -q option.
    a_bit_field quiet		    : 1;
    /// Set to FALSE if you want to include rollback transactions in output.
    /// Set FALSE by dbtran -a option.
    a_bit_field remove_rollback	    : 1;
    /// Set TRUE to produce ANSI standard SQL transactions.
    /// Set TRUE by dbtran -s option.
    a_bit_field ansi_sql	    : 1;
    /// Set TRUE for output from most recent checkpoint.
    /// Set TRUE by dbtran -f option.
    a_bit_field since_checkpoint    : 1;
    /// Set TRUE to replace the SQL file without a confirmation.
    /// Set TRUE by dbtran -y option.
    a_bit_field replace		    : 1;
    /// Set TRUE to include trigger-generated transactions.
    /// Set TRUE by dbtran -t, -g and -sr options.
    a_bit_field	include_trigger_trans : 1;
    /// Set TRUE to include trigger-generated transactions as comments.
    /// Set TRUE by dbtran -z option.
    a_bit_field	comment_trigger_trans : 1;
    /// Set TRUE to leave the generated SQL file if log error detected.
    /// Set TRUE by dbtran -k option.
    a_bit_field	leave_output_on_error : 1;
    /// Reserved; set to FALSE.
    a_bit_field debug		    : 1;
    /// Reserved; set to FALSE.
    a_bit_field debug_sql_remote    : 1;
    /// Reserved; set to FALSE.
    a_bit_field debug_dump_hex	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field debug_dump_char	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field debug_page_offsets  : 1;
    /// Reserved; set to FALSE.
    a_bit_field omit_comments	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field use_hex_offsets	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field	use_relative_offsets: 1;
    /// Reserved; set to FALSE.
    a_bit_field include_audit	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field chronological_order : 1;
    /// Reserved; set to FALSE.
    a_bit_field force_recovery	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field include_subsets	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field force_chaining	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field	generate_reciprocals: 1;
    /// Reserved; set to FALSE.
    a_bit_field match_mode	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field show_undo	    : 1;
    /// Reserved; set to FALSE.
    a_bit_field extra_audit	    : 1;
} a_translate_log;

/** Translates a transaction log file to SQL. This function is used by the 
 * dbtran utility.
 *
 * \param ptl Pointer to a properly initialized a_translate_log structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Log Translation utility (dbtran), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbtran.html", "dbadmin", "dbtran"}
 *
 * \sa a_translate_log structure
 */
extern _crtn short _entry DBTranslateLog( const a_translate_log *ptl );

//***************************************************************************
// synchronize log file to MobilLink
//***************************************************************************

// The upload_defs field of a_sync_db points to a linked list of a_syncpub 
// structures with one node for each instance of the -n option on the
// command line.

// For example, the command line
//	dbmlsync -n pub1 -eu sv=one -n pub2,pub3
// would yield a linked list of 2 nodes as follows:
// 
//				node1		node2
//    next			ptr to Node2	NULL
//    pub_name			"pub1"		"pub2,pub3"
//    ext_opt			"sv=one"	NULL

/** Holds information needed for the dbmlsync utility.
 *
 * \seealso{DBTools interface for dbmlsync, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-dbtools.html", "mlclient", "mc-dbtools"}
 *
 * \sa a_sync_db structure
 * \sa DBSynchronizeLog()
 */
typedef struct a_syncpub {
    /// Pointer to the next node in the list, NULL for the last node.
    struct a_syncpub *	next;
    /// Publication name(s) separated by commas (deprecated).
    /// This is the same string that would follow the dbmlsync -n option.
    /// Only 1 of pub_name and subscription may be non-NULL.
    char *		pub_name;
    /// Subscription name(s) separated by commas.
    /// This is the same string the would follow the dbmlsync -s option.
    /// Only 1 of pub_name and subscription may be non-NULL.
    char *		subscription;
    /// Extended options in the form "keyword=value;...".
    /// These are the same options the would follow the dbmlsync -eu option.
    char *		ext_opt;
} a_syncpub;

/** 
 * \internal
 */
typedef short a_msgqueue_ret;

/** Holds information needed for the dbmlsync utility using the DBTools library.
 * Some members correspond to features accessible from the dbmlsync command
 * line utility. Unused members should be assigned the value 0, FALSE, or
 * NULL, depending on data type.
 *
 * \seealso{dbmlsync syntax, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mobilink-ml-syncclient.html", "mlclient", "mobilink-ml-syncclient"}
 * \seealso{DBTools interface for dbmlsync, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-dbtools.html", "mlclient", "mc-dbtools"}
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa DBSynchronizeLog()
 */  
typedef struct a_sync_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short  version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK    errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK    msgrtn;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK    confirmrtn;
    /// Address of a logging callback routine to write messages only to a log file or NULL.
    MSG_CALLBACK    logrtn;
    /// Function to call to change the title of the dbmlsync window (Windows only).
    SET_WINDOW_TITLE_CALLBACK set_window_title_rtn;
    /// Function called by DBMLSync when it wants to sleep. The parameter
    /// specifies the sleep period in milliseconds. The function should
    /// return the following, as defined in dllapi.h.
    ///
    /// <ul>
    /// <li> MSGQ_SLEEP_THROUGH indicates that the routine slept for the requested number of milliseconds. This is usually the value you should return.
    /// <li> MSGQ_SHUTDOWN_REQUESTED indicates that you would like the synchronization to terminate as soon as possible.
    /// <li> MSGQ_SYNC_REQUESTED indicates that the routine slept for less than the requested number of milliseconds and that the next synchronization should begin immediately if a synchronization is not currently in progress.
    /// </ul>
    MSG_QUEUE_CALLBACK	msgqueuertn;
    /// Function called to change the text in the status window, above the progress bar.
    MSG_CALLBACK    progress_msg_rtn;
    /// Function called to update the state of the progress bar.
    SET_PROGRESS_CALLBACK progress_index_rtn;
    /// Reserved; use NULL.
    USAGE_CALLBACK  usage_rtn;
    /// Reserved; use NULL.
    STATUS_CALLBACK status_rtn;
    /// Function called to display warning messages.
    MSG_CALLBACK    warningrtn;
    /// Linked list of publications/subscriptions to synchronize.
    a_syncpub *	    upload_defs;
    /// Reserved; use NULL.
    a_syncpub *	    last_upload_def;
    /// Transaction logs directory.
    /// Last item specified on dbmlsync command line.
    const char *    offline_dir;
    /// Reserved; use NULL.
    const char *    include_scan_range;
    /// Reserved; use NULL.
    const char *    raw_file;
    /// Database server message log file name.
    /// Equivalent to dbmlsync -o or -ot option.
    const char *    log_file_name;
    /// Name of download file to apply.
    /// Equivalent to dbmlsync -ba option or NULL if option not specified.
    const char *    apply_dnld_file;
    /// Name of download file to create.
    ///	Equivalent to dbmlsync -bc option or NULL if option not specified.
    const char *    create_dnld_file;
    /// Specify extra string to include in download file.
    ///	Equivalent to dbmlsync -be option.
    const char *    dnld_file_extra;
    /// Reserved; use NULL.
    const char *    encrypted_stream_opts;
    /// The argv array for this run, the last element of the array must be NULL
    char **	    argv;
    /// Reserved; use NULL.
    char **	    ce_argv;
    /// Reserved; use NULL.
    char **	    ce_reproc_argv;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    char *	    connectparms;
    /// Extended options in the form "keyword=value;...".
    /// Equivalent to dbmlsync -e option.
    char *	    extended_options;
    /// Name of the program to display in the window caption (for example, DBMLSync).
    char *	    default_window_title;
    /// The MobiLink password or NULL, if the option is not specified.
    /// Equivalent to the dbmlsync -mp option.
    char *	    mlpassword;
    /// The new MobiLink password or NULL, if the option is not specified.
    /// Equivalent to the dbmlsync -mn option.
    char *	    new_mlpassword;
    /// The encryption key for the database file.
    /// Equivalent to the dbmlsync -ek option.
    char *	    encryption_key;
    /// The MobiLink user to synchronize (deprecated).
    /// Equivalent to the dbmlsync -u option.
    char *	    user_name;
    /// User authentication parameters.
    /// Equivalent to the dbmlsync -ap option.
    char *	    sync_params;
    /// Reserved; use NULL.
    char *	    preload_dlls;
    /// Synchronization profile to execute.
    /// Equivalent to the dbmlsync -sp option.
    char *	    sync_profile;
    /// Reserved; use NULL.
    char *	    sync_opt;
    /// Set TRUE to disable offline logscan (cannot use with -x).
    /// Equivalent to the dbmlsync -do option.
    a_sql_uint32    no_offline_logscan;
    /// Reserved; use 0.
    a_sql_uint32    debug_dump_size;
    /// Reserved; use 0.
    a_sql_uint32    dl_insert_width;
    /// Size in bytes of log file when renaming and restarting the transaction log.
    /// Specify 0 for unspecified size.
    /// Equivalent to the dbmlsync -x option.
    a_sql_uint32    log_size;
    /// Set the logscan polling period in seconds. Usually 60.
    /// Equivalent to the dbmlsync -pp option.
    a_sql_uint32    hovering_frequency;
    /// Set the estimated upload row count (for optimization).
    /// Equivalent to the dbmlsync -urc option.
    a_sql_uint32    est_upld_row_cnt;
    /// Set the download read size.
    /// Equivalent to the dbmlsync -drs option.
    a_sql_uint32    dnld_read_size;
    /// Reserved; use 0.
    a_sql_uint32    dnld_fail_len;
    /// Reserved; use 0.
    a_sql_uint32    upld_fail_len;
    /// Set communication port when running in server mode.
    /// Equivalent to the dbmlsync -po option.
    a_sql_uint32    server_port;
    /// Reserved; use 0.
    a_sql_uint32    dlg_info_msg;

    // The min cache size is stored in the min_cache and min_cache_suffix
    // fields.  The min_cache_suffix contains one of the following values:
    //	'B'	indicates that the value stored in the min_cache field is
    //		specified in bytes
    //   'P'	indicates that the value stored in the min_cache field is
    //		a percentage
    //	'\0'	indicates that no value has been set for min_cache and
    //		the default value should be used.
    // The min_cache field contains an integer value expressed in
    // units determined by the min_cache_suffix field.
    // Here are some examples of how the values would be set for various
    // commandline options:
    //
    // option			min_cache	min_cache_suffix
    // -cl 2000			2000		'B'
    // -cl 5 K			5 * 1024	'B'
    // -cl 10 P			10		'P'
    // (-cl not specified)	0		'\0'
    //
    // The max_cache, max_cache_suffix, init_cache and init_cache_suffix
    // fields are set using the same rules described above for the min_cache
    // and min_cache_suffix fields

    /// Minimum size for cache. 
    /// Equivalent to the dbmlsync -cl option.
    a_sql_uint32    min_cache;
    /// Suffix for minimum cache size ('B' for bytes, 'P' for percentage,
    /// or 0 if not specified.
    char	    min_cache_suffix;
    /// Maximum size for cache. 
    /// Equivalent to the dbmlsync -cm option.
    a_sql_uint32    max_cache; 
    /// Suffix for maximum cache size ('B' for bytes, 'P' for percentage,
    /// or 0 if not specified.
    char	    max_cache_suffix;
    /// Initial size for cache. 
    /// Equivalent to the dbmlsync -ci option.
    a_sql_uint32    init_cache;
    /// Suffix for initial cache size ('B' for bytes, 'P' for percentage,
    /// or 0 if not specified.
    char	    init_cache_suffix;
    /// Number of times to retry an interrupted background synchronization.
    /// Equivalent to the dbmlsync -bkr option.
    a_sql_int32	    background_retry;
    /// Set TRUE to ping MobiLink server.
    /// Equivalent to the dbmlsync -pi option.
    a_bit_field ping			: 1;
    /// Set TRUE to update generation number when download file is applied.
    /// Equivalent to the dbmlsync -bg option.
    a_bit_field	dnld_gen_num		: 1;
    /// Set TRUE to do a background synchronization.
    /// Equivalent to the dbmlsync -bk option.
    a_bit_field background_sync		: 1;
    /// Set TRUE to drop connections with locks on tables being synchronized.
    /// Equivalent to the dbmlsync -d option.
    a_bit_field	kill_other_connections	: 1;
    /// Set TRUE to continue a previously failed download.
    /// Equivalent to the dbmlsync -dc option.
    a_bit_field	continue_download	: 1;
    /// Set TRUE to perform download-only synchronization.
    /// Equivalent to the dbmlsync -ds option.
    a_bit_field	download_only		: 1;
    /// Set TRUE to ignore errors that occur in hook functions.
    /// Equivalent to the dbmlsync -eh option.
    a_bit_field	ignore_hook_errors	: 1;
    /// Set TRUE to ignore scheduling.
    /// Equivalent to the dbmlsync -is option.
    a_bit_field	ignore_scheduling	: 1;
    /// Set TRUE to close window on completion.
    /// Equivalent to the dbmlsync -qc option.
    a_bit_field	autoclose		: 1;
    /// Set TRUE when setting a new MobiLink password. See new_mlpassword field.
    /// Equivalent to the dbmlsync -mn option.
    a_bit_field	changing_pwd		: 1;
    /// Set TRUE to disable logscan polling.
    /// Equivalent to the dbmlsync -p option.
    a_bit_field ignore_hovering		: 1;
    /// Set TRUE to persist the MobiLink connection between synchronizations.
    /// Set FALSE to close the MobiLink connection between synchronizations.
    /// Equivalent to the dbmlsync -pc{+|-} option.
    a_bit_field persist_connection	: 1;
    /// Set TRUE to check for schema changes between synchronizations.
    /// Equivalent to the dbmlsync -sc option.
    a_bit_field	allow_schema_change	: 1;
    /// Set TRUE to resend upload using remote offset on progress mismatch.
    /// when remote offset is less than consolidated offset.
    /// Equivalent to the dbmlsync -r or -rb option.
    a_bit_field	retry_remote_behind	: 1;
    /// Set TRUE to run in server mode.
    /// Equivalent to the dbmlsync -sm option.
    a_bit_field server_mode		: 1;
    /// Set TRUE to upload each database transaction separately.
    /// Equivalent to the dbmlsync -tu option.
    a_bit_field	trans_upload		: 1;
    /// Set TRUE to resend upload using remote offset on progress mismatch
    /// when remote offset is greater than consolidated offset.
    /// Equivalent to the dbmlsync -ra option.
    a_bit_field	retry_remote_ahead 	: 1;
    /// Set TRUE to perform upload-only synchronization.
    /// Equivalent to the dbmlsync -uo option.
    a_bit_field	upload_only		: 1;
    /// Set TRUE to set verbosity at a minimum.
    /// Equivalent to the dbmlsync -v option.
    a_bit_field verbose_minimum 	: 1;
    /// Set FALSE to show connect string, TRUE to hide the connect string.
    /// Equivalent to the dbmlsync -vc option.
    a_bit_field	hide_conn_str		: 1;
    /// Set FALSE to show MobiLink password, TRUE to hide the MobiLink password.
    /// Equivalent to the dbmlsync -vp option.
    a_bit_field	hide_ml_pwd		: 1;
    /// Set TRUE to show upload/download row counts.
    /// Equivalent to the dbmlsync -vn option.
    a_bit_field	verbose_row_cnts	: 1;
    /// Set TRUE to show command line and extended options.
    /// Equivalent to the dbmlsync -vo option.
    a_bit_field	verbose_option_info	: 1;
    /// Set TRUE to show upload/download row values.
    /// Equivalent to the dbmlsync -vr option.
    a_bit_field	verbose_row_data	: 1;
    /// Set TRUE to show hook script information.
    /// Equivalent to the dbmlsync -vs option.
    a_bit_field verbose_hook		: 1;
    /// Set TRUE to show upload stream information.
    /// Equivalent to the dbmlsync -vu option.
    a_bit_field verbose_upload		: 1;
    /// Set TRUE to show message IDs.
    /// Equivalent to the dbmlsync -vi option.
    a_bit_field verbose_msgid		: 1;
    /// Set TRUE to rename and restart the transaction log. See log_size field.
    /// Equivalent to the dbmlsync -x option.
    a_bit_field	rename_log		: 1;
    /// Reserved; use 0.
    a_bit_field allow_outside_connect	: 1;
    /// Reserved; use 0.
    a_bit_field cache_verbosity 	: 1;
    /// Reserved; use 0.
    a_bit_field connectparms_allocated  : 1;
    /// Reserved; use 0.
    a_bit_field debug			: 1;
    /// Reserved; use 0.
    a_bit_field debug_dump_char		: 1;
    /// Reserved; use 0.
    a_bit_field debug_dump_hex		: 1;
    /// Reserved; use 0.
    a_bit_field debug_page_offsets	: 1;
    /// Reserved; use 0.
    a_bit_field dl_use_put		: 1;
    /// Reserved; use 0.
    a_bit_field entered_dialog		: 1;
    /// Reserved; use 0.
    a_bit_field ignore_debug_interrupt	: 1;
    /// Reserved; use 0.
    a_bit_field lite_blob_handling	: 1;
    /// Reserved; use 0.
    a_bit_field no_schema_cache 	: 1;
    /// Reserved; use 0.
    a_bit_field no_stream_compress	: 1;
    /// Reserved; use 0.
    a_bit_field output_to_file		: 1;
    /// Reserved; use 1.
    a_bit_field output_to_mobile_link	: 1;
    /// Reserved; use 0.
    a_bit_field prompt_again		: 1;
    /// Reserved; use 0.
    a_bit_field prompt_for_encrypt_key	: 1;
    /// Reserved; use 0.
    a_bit_field strictly_ignore_trigger_ops : 1;
    /// Reserved; use 0.
    a_bit_field use_fixed_cache 	: 1;
    /// Reserved; use 0.
    a_bit_field use_hex_offsets		: 1;
    /// Reserved; use 0.
    a_bit_field use_relative_offsets	: 1;
    /// Reserved; use 0.
    a_bit_field used_dialog_allocation	: 1;
    /// Reserved; use 0.
    a_bit_field verbose			: 1;
    /// Reserved; use 0.
    a_bit_field verbose_download	: 1;
    /// Reserved; use 0.
    a_bit_field verbose_download_data	: 1;
    /// Reserved; use 0.
    a_bit_field verbose_protocol	: 1;
    /// Reserved; use 0.
    a_bit_field verbose_server		: 1;
    /// Reserved; use 0.
    a_bit_field verbose_upload_data	: 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_cli_bit_to_cli_max : 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_cli_bit_to_cli_both : 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_serv_bit_to_cli_max : 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_serv_bit_to_cli_both : 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_serv_bit_to_serv_max : 1;
    /// Reserved; use 0.
    a_bit_field protocol_add_serv_bit_to_serv_both : 1;
    /// Reserved; use 0.
    a_bit_field strictly_free_memory : 1;
    /// Reserved; use 0.
    a_bit_field reserved : 8;
} a_sync_db;

/** Synchronize a database with a MobiLink server.
 * \param psdb Pointer to a properly initialized a_sync_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{DBTools interface for dbmlsync, "http://dcx.sybase.com/goto?page=sa160/en/mlclient/mc-dbtools.html", "mlclient", "mc-dbtools"}
 *
 * \sa a_sync_db structure
 */
extern _crtn short _entry DBSynchronizeLog( const a_sync_db *psdb );

// Obsolete name
/// @internal
extern _crtn short _entry DBSyncronizeLog( const a_sync_db *psdb );

//***************************************************************************
// unload the database into files (DBUNLOAD)
//***************************************************************************

/** The type of unload being performed, as used by the an_unload_db structure.
 *
 * \sa an_unload_db structure
 * \sa DBUnload()
 */
enum { // Unload
    /// Unload both data and schema.
    UNLOAD_ALL,
    /// Unload data. Do not unload schema. Equivalent to dbunload -d option.
    UNLOAD_DATA_ONLY,
    /// No data. Unload schema only. Equivalent to dbunload -n option.
    UNLOAD_NO_DATA,
    /// No data. Include LOAD/INPUT statements in reload script. Equivalent to dbunload -nl option.
    UNLOAD_NO_DATA_FULL_SCRIPT,
    /// No data. Objects will be output ordered by name.
    UNLOAD_NO_DATA_NAME_ORDER
};

/*
    Example 1:
    an_unload_db Structure settings for equivalent of following command:
    dbunload -ar -c "uid=dba;pwd=sql;dbf=c:\temp\demo.db;eng=testdb"

    version		DB_TOOLS_VERSION_NUMBER
    connectparms	"uid=dba;pwd=sql;dbf=c:\\temp\\demo.db;eng=testdb"
    reload_filename	"reload.sql"
    errorrtn		0x0040.... callback_error(char *)
    msgrtn		0x0040.... callback_usage(char *)
    statusrtn		0x0040.... callback_status(char *)
    confirmrtn		0x0040.... callback_confirm(char *)
    verbose		1
    use_internal_unload	1
    use_internal_reload	1
    replace_db		1
    preserve_ids	1

    All other fields are 0 or NULL.

    Example 2:
    an_unload_db Structure settings for equivalent of following command:
    dbunload -ac "uid=dba;pwd=sql;dbf=demoRL.db"
             -c "uid=dba;pwd=sql;dbf=C:\temp\demo.db;eng=testdb"

    version		DB_TOOLS_VERSION_NUMBER
    connectparms	"uid=dba;pwd=sql;dbf=C:\\temp\\demo.db;eng=testdb"
    reload_filename	"reload.sql"
    errorrtn		0x0040.... callback_error(char *)
    msgrtn		0x0040.... callback_usage(char *)
    statusrtn		0x0040.... callback_status(char *)
    confirmrtn		0x0040.... callback_confirm(char *)
    verbose		1
    use_internal_unload	1
    use_internal_reload	1
    reload_connectparms	"uid=dba;pwd=sql;dbf=demoRL.db"
    replace_db		0
    preserve_ids	1

    All other fields are 0 or NULL.
*/

/** Holds information needed to unload a database using the DBTools library
 * or extract a remote database for SQL Remote. Those fields used by the
 * dbxtract SQL Remote Extraction utility are indicated.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa Verbosity enumeration
 * \sa DBUnload()
 */
typedef struct an_unload_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;	
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK	statusrtn;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK	confirmrtn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    const char *	connectparms;
    /// Directory for unloading data files.
    const char *	temp_dir;
    /// Name to use for the reload SQL script file (for example, reload.sql).
    /// Set by dbunload -r option.
    const char *	reload_filename;
    /// Reserved; use NULL.
    const char *	ms_filename;
    /// Like temp_dir but for internal unloads on server side.
    const char *	remote_dir;
    /// The subscriber name to be used by dbxtract. NULL otherwise.
    const char *	subscriber_username;
    /// The site name to be used by dbxtract. NULL otherwise.
    const char *	site_name;
    /// The template name to be used by dbxtract. NULL otherwise.
    const char *	template_name;
    /// The encryption key for the database file.
    /// Set by dbunload/dbxtract -ek or -ep option.
    const char *	encryption_key;
    /// The encryption algorithm which may be "simple", "aes", "aes256",
    /// "aes_fips", "aes256_fips", or NULL for none.
    /// Set by dbunload/dbxtract -ea option.
    const char *	encryption_algorithm;
    /// Reserved; use NULL.
    const char *	locale;
    /// Reserved; use NULL.
    const char *	startline;
    /// Reserved; use NULL.
    const char *	startline_old;
    /// Connection parameters such as user ID, password, and database for
    /// the reload database.
    /// Set by dbunload/dbxtract -ac option.
    char *		reload_connectparms;
    /// Name of the new database file to create and reload.
    /// Set by dbunload/dbxtract -an option.
    char *		reload_db_filename;
    /// Filename of the new database transaction log or NULL.
    /// Set by dbxtract -al option.
    char *		reload_db_logname;
    /// Selective table list.
    /// Set by dbunload -e and -t options.
    p_name		table_list;
    /// Reserved; use NULL.
    a_sysinfo		sysinfo;
    /// Reserved; use 0.
    long		notemp_size;
    /// Reserved; use 0.
    int			ms_reserve;
    /// Reserved; use 0.
    int			ms_size;
    /// The isolation level at which to operate.
    /// Set by dbxtract -l option.
    unsigned short	isolation_level;
    /// The reloaded database page size.
    /// Set by dbunload -ap option.
    unsigned short	reload_page_size;
    /// Set Unload enumeration (UNLOAD_ALL and so on).
    /// Set by dbunload/dbxtract -d, -k, -n options.
    char		unload_type;
    /// See Verbosity enumeration (VB_QUIET, VB_NORMAL, VB_VERBOSE).
    char		verbose;
    /// The escape character (normally, "\"). Used when escape_char_present
    /// is TRUE. Set TRUE by dbunload/dbxtract -p option.
    char		escape_char;
    /// Reserved; set to 0.
    char		unload_interrupted;
    /// Set TRUE for unordered data. Indexes will not be used to unload data.
    /// Set by dbunload/dbxtract -u option.
    a_bit_field unordered		: 1; // dbunload -u sets TRUE
    /// Set TRUE to replace an existing SQL script file without confirmation.
    /// Set by dbunload/dbxtract -y option.
    a_bit_field	no_confirm		: 1;
    /// Set TRUE to Perform an internal unload.
    /// Set TRUE by dbunload/dbxtract -i? option.
    /// Set FALSE by dbunload/dbxtract -x? option.
    a_bit_field	use_internal_unload	: 1;
    /// Set TRUE to generate statements to refresh text indexes and valid materialized views.
    /// Set TRUE by dbunload/dbxtract -g option.
    a_bit_field	refresh_mat_view	: 1;
    /// Set TRUE to indicate that a list of tables has been provided. See table_list field.
    /// Set TRUE by dbunload -e or -t options.
    a_bit_field	table_list_provided	: 1;
    /// Set FALSE to indicate that the list contains tables to be included.
    /// Set TRUE to indicate that the list contains tables to be excluded.
    /// Set TRUE by dbunload -e option.
    a_bit_field	exclude_tables		: 1;
    /// Set TRUE to preserve user IDs. This is the normal setting.
    /// Set FALSE by dbunload -e option.
    a_bit_field	preserve_ids		: 1;
    /// Set TRUE to replace the database.
    /// Set TRUE by dbunload -ar option.
    a_bit_field	replace_db		: 1;
    /// Set TRUE to indicate that the escape character in escape_char is defined.
    /// Set TRUE by dbunload/dbxtract -p option.
    a_bit_field	escape_char_present	: 1;
    /// Set TRUE to perform an internal reload. This is the normal setting.
    /// Set TRUE by dbunload/dbxtract -ii and -xi option.
    /// Set FALSE by dbunload/dbxtract -ix and -xx option.
    a_bit_field	use_internal_reload	: 1;
    /// Set TRUE to redo computed columns.
    /// Set TRUE by dbunload -dc option.
    a_bit_field	recompute		: 1;
    /// Set TRUE to make auxiliary catalog (for use with diagnostic tracing).
    /// Set TRUE by dbunload -k option.
    a_bit_field	make_auxiliary		: 1;
    /// Set TRUE to collapse to a single dbspace file (for use with diagnostic tracing).
    /// Set TRUE by dbunload -kd option.
    a_bit_field	profiling_uses_single_dbspace : 1;
    /// Set TRUE to enable encrypted tables in new database (with -an or -ar).
    /// Set TRUE by dbunload/dbxtract -et option.
    a_bit_field	encrypted_tables	: 1;
    /// Set TRUE to remove encryption from encrypted tables.
    /// Set TRUE by dbunload/dbxtract -er option.
    a_bit_field	remove_encrypted_tables	: 1;
    /// Set TRUE if performing a remote database extraction.
    /// Set FALSE by dbunload.
    /// Set TRUE by dbxtract.
    a_bit_field	extract			: 1;
    /// Set TRUE to start subscriptions. This is the default for dbxtract.
    /// Set FALSE by dbxtract -b option.
    a_bit_field	start_subscriptions	: 1;
    /// Set TRUE to exclude foreign keys.
    /// Set TRUE by dbxtract -xf option.
    a_bit_field	exclude_foreign_keys	: 1;
    /// Set TRUE to exclude stored procedures.
    /// Set TRUE by dbxtract -xp option.
    a_bit_field	exclude_procedures	: 1;
    /// Set TRUE to exclude triggers.
    /// Set TRUE by dbxtract -xt option.
    a_bit_field	exclude_triggers	: 1;
    /// Set TRUE to exclude views.
    /// Set TRUE by dbxtract -xv option.
    a_bit_field	exclude_views		: 1;
    /// Set TRUE to indicate that isolation_level has been set for all
    /// extraction operations.
    /// Set TRUE by dbxtract -l option.
    a_bit_field	isolation_set		: 1;
    /// Set TRUE to extract fully qualified publications.
    /// Set TRUE by dbxtract -f option.
    a_bit_field	include_where_subscribe : 1;
    /// Set TRUE to exclude procedure hooks.
    /// Set TRUE by dbxtract -xh option.
    a_bit_field	exclude_hooks		: 1;
    /// Set TRUE to compress table data files.
    /// Set TRUE by dbunload -cp option.
    a_bit_field	compress_output		: 1;
    /// Set TRUE to display database creation command (sql or dbinit).
    /// Set TRUE by dbunload -cm sql or -cm dbinit option.
    a_bit_field	display_create		: 1;
    /// Set TRUE to display dbinit database creation command.
    /// Set TRUE by dbunload -cm dbinit option.
    a_bit_field	display_create_dbinit	: 1;
    /// Set TRUE to preserve identity values for AUTOINCREMENT columns.
    /// Set TRUE by dbunload -l option.
    a_bit_field	preserve_identity_values: 1;
    /// Set TRUE to suppress reload status messages for tables and indexes.
    /// Set TRUE by dbunload -qr option.
    a_bit_field	no_reload_status	: 1;
    /// Reserved; set FALSE.
    a_bit_field	startline_name		: 1;
    /// Reserved; set FALSE.
    a_bit_field	debug			: 1;
    /// Reserved; set FALSE.
    a_bit_field	schema_reload		: 1;
    /// Reserved; set FALSE.
    a_bit_field	genscript		: 1;
    /// Reserved; set FALSE.
    a_bit_field	runscript		: 1;
    /// Set TRUE to suppress inclusion of column statistics.
    /// Set TRUE by dbunload -ss option.
    a_bit_field	suppress_statistics	: 1;
} an_unload_db;

/** Unloads a database. This function is used by the dbunload and dbxtract utilities.
 *
 * \param pudb Pointer to a properly initialized an_unload_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Unload utility (dbunload), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbunload.html", "dbadmin", "dbunload"}
 * \seealso{Extraction utility (dbxtract), "http://dcx.sybase.com/goto?page=sa160/en/sqlremote/dbxtract.html", "sqlremote", "dbxtract"}
 *
 * \sa an_unload_db structure
 */
extern _crtn short _entry DBUnload( an_unload_db *pudb );

//***************************************************************************
// upgrade the system tables of a database (DBUPGRAD)
//***************************************************************************

/** Holds information needed to upgrade a database using the DBTools library.
 *
 * \seealso{Callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa DBUpgrade()
 */
typedef struct an_upgrade_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK	statusrtn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    const char *	connectparms;
    /// Set TRUE to operate without printing messages.
    /// Set TRUE by dbupgrad -q option.
    a_bit_field		quiet 		: 1;
    /// Set TRUE to upgrade the database to include jConnect procedures.
    /// Set FALSE by dbupgrad -i option.
    a_bit_field		jconnect	: 1;
    /// Set TRUE to restart the database after the upgrade.
    /// Set FALSE by the dbupgrad -nrs option.
    a_bit_field		restart		: 1;
    /// Assign 0 to upgrade the database to have the pre-16.0 SQL SECURITY model for
    /// legacy system stored procedures when upgrading from pre-16.0 releases. When upgrading from
    /// a version 16.0 or later database retain the current SQL SECURITY model (same as not specifying -pd).
    ///
    /// Assign 1 to upgrade the database to have the pre-16.0 SQL SECURITY model for
    /// legacy system stored procedures (same as -pd y)
    ///
    /// Assign 2 to upgrade the database to have the pre-16.0 SQL SECURITY model for
    /// legacy system stored procedures (same as -pd n).
    unsigned short	sys_proc_definer;
} an_upgrade_db;

/** Upgrades a database file. This function is used by the dbupgrad utility.
 *
 * \param pudb Pointer to a properly initialized an_upgrade_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Upgrade utility (dbupgrad), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbupgrad.html", "dbadmin", "dbupgrad"}
 * \seealso{ALTER DATABASE statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/alter-database-statement.html", "sqlref", "alter-database-statement"}
 *
 * \sa an_upgrade_db structure
 */
extern _crtn short _entry DBUpgrade( const an_upgrade_db *pudb );

//***************************************************************************
// validate the tables of a database (DBVALID)
//***************************************************************************

/** The type of validation being performed, as used by the a_validate_db structure.
 *
 * \seealso{Using checksums to detect corruption, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/using-checksums.html", "dbadmin", "using-checksums"}
 *
 * \sa a_validate_db structure
 * \sa DBValidate()
 */
enum { // Validation
    /// Validate with the default check only.
    VALIDATE_NORMAL = 0,
    /// (obsolete)
    VALIDATE_DATA,
    /// (obsolete)
    VALIDATE_INDEX,
    /// Validate with express check. Equivalent to dbvalid -fx option.
    VALIDATE_EXPRESS,
    /// (obsolete)
    VALIDATE_FULL,
    /// Validate database checksums. Equivalent to dbvalid -s option.
    VALIDATE_CHECKSUM,
    /// Validate database. Equivalent to dbvalid -d option.
    VALIDATE_DATABASE,
    /// Perform all possible validation activities.
    VALIDATE_COMPLETE
};

/** Holds information needed for database validation using the DBTools library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa a_name structure
 * \sa DBValidate()
 * \sa Validation enumeration
 */
typedef struct a_validate_db {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Address of a status message callback routine or NULL.
    MSG_CALLBACK	statusrtn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    const char *	connectparms;
    /// Pointer to a linked list of table names or index names
    /// (when the index field is set TRUE).
    /// This is set by the dbvalid object-name-list argument.
    p_name		tables;
    /// The type of validation to perform. One of VALIDATE_NORMAL,
    /// VALIDATE_EXPRESS, VALIDATE_CHECKSUM, etc.
    /// See Validation enumeration.
    char		type;
    /// Set TRUE to operate without printing messages.
    /// Set TRUE by dbvalid -q option.
    a_bit_field	quiet : 1;
    /// Set TRUE to validate indexes. The tables field points to a list of
    /// indexes.
    /// Set TRUE by dbvalid -i option.
    /// Set FALSE by dbvalid -t option.
    a_bit_field	index : 1;
} a_validate_db;

/** Validates all or part of a database. This function is used by the dbvalid utility.
 *
 * Caution:
 * Validating a table or an entire database should be performed while no
 * connections are making changes to the database; otherwise, spurious
 * errors may be reported indicating some form of database corruption even
 * though no corruption actually exists.
 *
 * \param pvdb Pointer to a properly initialized a_validate_db structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Validation utility (dbvalid), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbvalid.html", "dbadmin", "dbvalid"}
 * \seealso{VALIDATE statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/validate-statement.html", "sqlref", "validate-statement"}
 *
 * \sa a_validate_db structure
 */
extern _crtn short _entry DBValidate( const a_validate_db *pvdb );

//***************************************************************************
// truncate transaction log interface
//***************************************************************************

/** Holds information needed for transaction log truncation using the DBTools library.
 *
 * \seealso{Using callback functions, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/dbt-using-callback-functions.html", "programming", "dbt-using-callback-functions"}
 * \seealso{Connection parameters, "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/da-conparm.html", "dbadmin", "da-conparm"}
 *
 * \sa DBTruncateLog()
 */
typedef struct a_truncate_log {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbsrv16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbsrv16.exe".
    const char *	connectparms;
    /// Truncate was interrupted if non-zero
    char		truncate_interrupted;
    /// Set TRUE to operate without printing messages.
    /// Set TRUE by dbbackup -q option.
    a_bit_field quiet		: 1;
    /// Set TRUE to indicate backup on server using BACKUP DATABASE.
    /// Set TRUE by dbbackup -s option when dbbackup -x option is specified.
    a_bit_field server_backup	: 1;
} a_truncate_log;

/** Truncates a transaction log file. This function is used by the dbbackup utility.
 *
 * \param ptl Pointer to a properly initialized a_truncate_log structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Backup utility (dbbackup), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dbbackup.html", "dbadmin", "dbbackup"}
 * \seealso{BACKUP statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/backup-statement.html", "sqlref", "backup-statement"}
 *
 * \sa a_truncate_log structure
 */
extern _crtn short _entry DBTruncateLog( const a_truncate_log *ptl );

//***************************************************************************
// File creation version interface
//***************************************************************************

/** Used in the a_db_version_info structure, to indicate the version of
 * SQL Anywhere that initially created the database.
 *
 * \sa a_db_version_info structure
 * \sa DBCreatedVersion()
 */
enum { // Version
    /// Unable to determine the version of SQL Anywhere that created the database.
    VERSION_UNKNOWN = 0,
    /// Database was created using SQL Anywhere version 9 or earlier.
    VERSION_PRE_10 = 9,
    /// Database was created using SQL Anywhere version 10.
    VERSION_10 = 10,
    /// Database was created using SQL Anywhere version 11.
    VERSION_11 = 11,
    /// Database was created using SQL Anywhere version 12.
    VERSION_12 = 12,
    /// Database was created using SQL Anywhere version 16.
    VERSION_16 = 16
};

/** Holds information regarding which version of SQL Anywhere was used to
 * create the database.
 *
 * \sa DBCreatedVersion()
 * \sa Version enumeration
 */
typedef struct a_db_version_info {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Name of the database file to check.
    const char		*filename;
    /// Set to one of VERSION_UNKNOWN, VERSION_PRE_10, etc. indicating
    /// the server version that created the database file.
    char		created_version;
} a_db_version_info;

/** Determines the version of SQL Anywhere that was used to create a
 * database file, without attempting to start the database. Currently,
 * this function only differentiates between databases built with version
 * 9 or earlier and those built with version 10 or later.
 *
 * Version information is not set if a failing code is returned.
 *
 * \param pdvi Pointer to a properly initialized a_db_version_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{CREATE DATABASE statement, "http://dcx.sybase.com/goto?page=sa160/en/dbreference/create-database-statement.html", "sqlref", "create-database-statement"}
 *
 * \sa a_db_version_info structure
 * \sa Version enumeration
 */
extern _crtn short _entry DBCreatedVersion( a_db_version_info *pdvi );

//***************************************************************************
// license a server (DBLIC)
//***************************************************************************

/*
    Example 1: Establish new settings.
    a_dblic_info Structure settings for equivalent of following command:
    dblic -l perseat -u 1234 c:\SQLAny16\bin32\dbsrv16.exe "Your Name" "Your Company"

    version		DB_TOOLS_VERSION_NUMBER
    exename		"c:\\SQLAny16\\bin32\\dbsrv16.exe"
    username		"Your Name"
    compname		"Your Company"
    platform_str	NULL
    nodecount		1234
    conncount		1000000
    type		LICENSE_TYPE_PERSEAT
    quiet		0
    errorrtn		(MSG_CALLBACK)ErrorCallBack
    msgrtn		(MSG_CALLBACK)MessageCallBack
    query_only		0

    Example 2: Query the current settings.
    a_dblic_info Structure settings for equivalent of following command:
    dblic c:\SQLAny16\bin32\dbsrv16.exe

    version		DB_TOOLS_VERSION_NUMBER
    exename		NULL
    username		NULL
    compname		NULL
    platform_str	NULL
    nodecount		-1
    conncount		1000000
    type		LICENSE_TYPE_PERSEAT
    quiet		0
    errorrtn		(MSG_CALLBACK)ErrorCallBack
    msgrtn		(MSG_CALLBACK)MessageCallBack
    query_only		1
*/

#include "lictype.h"

/** Holds information containing licensing information. You must use this
 * information only in a manner consistent with your license agreement.
 *
 * \sa DBLicense()
 */
typedef struct a_dblic_info {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
#if defined( INSTALL ) || defined( DBINSTALL )
    char *		errorrtn;
#else
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
#endif
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Name of the server executable or license file.
    char	 	*exename;
    /// User name for licensing.
    char	 	*username;
    /// Company name for licensing.
    char	 	*compname;
    /// Number of nodes licensed.
    a_sql_int32	 	nodecount;
    /// Maximum number of connections licensed.
    /// To set, use 1000000L for default.
    a_sql_int32	 	conncount;
    /// See lictype.h for values. One of LICENSE_TYPE_PERSEAT,
    /// LICENSE_TYPE_CONCURRENT, or LICENSE_TYPE_PERCPU.
    a_license_type	type;
    /// Reserved; set NULL.
    /// Set by dblic -k option.
    char		*installkey;
    /// Set TRUE to operate without printing messages.
    /// Set TRUE by dblic -q option.
    a_bit_field		quiet		: 1;
    /// Set TRUE to just display the license information.
    /// Set FALSE to permit changing the information.
    a_bit_field		query_only	: 1;
} a_dblic_info;

/** Modifies or reports the licensing information of the database server.
 *
 * \param pdi Pointer to a properly initialized a_dblic_info structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Server Licensing utility (dblic), "http://dcx.sybase.com/goto?page=sa160/en/dbadmin/dblic.html", "dbadmin", "dblic"}
 *
 * \sa a_dblic_info structure
 */
extern _crtn short _entry DBLicense( const a_dblic_info *pdi );

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif
