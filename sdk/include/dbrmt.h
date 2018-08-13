// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************

#ifndef _DBRMT_H_INCLUDED
#define _DBRMT_H_INCLUDED

/// \internal
#define II_DBRMT_H

#include "sqlca.h"

#if defined( _SQL_PACK_STRUCTURES )
#include "pshpk1.h"
#endif

#if !defined( _DLLAPI_H_INCLUDED )
    #include "dllapi.h"
#endif

/// \file dbrmt.h

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

/** Holds information needed for the dbremote utility using the DBTools
 * library.
 *
 * The dbremote utility sets the following defaults before processing any command-line options:
 *
 * <ul>
 * <li>version = DB_TOOLS_VERSION_NUMBER
 * <li>argv = (argument vector passed to application)
 * <li>deleted = TRUE
 * <li>apply = TRUE
 * <li>more = TRUE
 * <li>link_debug = FALSE
 * <li>max_length = 50000
 * <li>memory = 2 * 1024 * 1024
 * <li>frequency = 1
 * <li>threads = 0
 * <li>receive_delay = 60
 * <li>send_delay = 0
 * <li>log_size = 0
 * <li>patience_retry = 1
 * <li>resend_urgency = 0
 * <li>log_file_name = (set from command line)
 * <li>truncate_remote_output_file = FALSE
 * <li>remote_output_file_name = NULL
 * <li>no_user_interaction = TRUE (if user interface is not available)
 * <li>errorrtn = (address of an appropriate routine)
 * <li>msgrtn = (address of an appropriate routine)
 * <li>confirmrtn = (address of an appropriate routine)
 * <li>msgqueuertn = (address of an appropriate routine)
 * <li>logrtn = (address of an appropriate routine)
 * <li>warningrtn = (address of an appropriate routine)
 * <li>set_window_title_rtn = (address of an appropriate routine)
 * <li>progress_msg_rtn = (address of an appropriate routine)
 * <li>progress_index_rtn = (address of an appropriate routine)
 * </ul>
 *
 * \sa DBRemoteSQL()
 */
typedef struct a_remote_sql {
    /// DBTools version number (DB_TOOLS_VERSION_NUMBER).
    unsigned short	version;
    /// Address of a confirmation request callback routine or NULL.
    MSG_CALLBACK	confirmrtn;
    /// Address of an error message callback routine or NULL.
    MSG_CALLBACK	errorrtn;
    /// Address of an information message callback routine or NULL.
    MSG_CALLBACK	msgrtn;
    /// Function called by DBRemoteSQL when it wants to sleep. The parameter
    /// specifies the sleep period in milliseconds. The function should
    /// return the following, as defined in dllapi.h.
    ///
    /// <ul>
    /// <li> MSGQ_SLEEP_THROUGH indicates that the routine slept for the requested number of milliseconds. This is usually the value you should return.
    /// <li> MSGQ_SHUTDOWN_REQUESTED indicates that you would like the synchronization to terminate as soon as possible.
    /// </ul>
    MSG_QUEUE_CALLBACK	msgqueuertn;
    /// Parameters needed to connect to the database. They take the form of connection strings, such as the following:
    /// "UID=DBA;PWD=sql;DBF=demo.db".
    ///
    ///	The database server would be started by the connection string START parameter. For example:
    /// "START=c:\SQLAny16\bin32\dbeng16.exe".
    ///
    /// A full example connection string including the START parameter:
    ///	"UID=DBA;PWD=sql;DBF=demo.db;START=c:\SQLAny16\bin32\dbeng16.exe".
    char *		connectparms;
    /// Should identify the directory with offline transaction logs (DBRemoteSQL only).
    /// Corresponds to the transaction_logs_directory argument of dbremote.
    char *		transaction_logs;
    /// When set TRUE, messages are received. If receive and send are both
    /// FALSE then both are assumed TRUE. It is recommended to set receive
    /// and send FALSE. Corresponds to the dbremote -r option.
    a_bit_field		receive : 1;
    /// When set TRUE, messages are sent. If receive and send are both
    /// FALSE then both are assumed TRUE. It is recommended to set receive
    /// and send FALSE. Corresponds to the dbremote -s option.
    a_bit_field		send : 1;
    /// When set, extra information is produced. Corresponds to the
    /// dbremote -v option.
    a_bit_field		verbose : 1;
    /// Normally set TRUE. When not set, messages are not deleted after they
    /// are applied. Corresponds to dbremote -p option.
    a_bit_field		deleted : 1;
    /// Normally set TRUE. When not set, messages are scanned but not
    /// applied. Corresponds to dbremote -a option.
    a_bit_field		apply : 1;
    /// When set TRUE, force exit after applying message and scanning log (this
    /// is the same as at least one user having 'always' send time). When
    /// cleared, allow run mode to be determined by remote users send times.
    a_bit_field		batch : 1;
    /// This should be set to TRUE.
    a_bit_field		more : 1;
    /// This should usually be cleared (FALSE) in most cases. When set TRUE,
    /// trigger actions are replicated. Care should be exercised.
    a_bit_field		triggers : 1;
    /// When set TRUE, debug output is included.
    a_bit_field		debug : 1;
    /// When set TRUE, logs are renamed and restarted (DBRemoteSQL only).
    a_bit_field		rename_log : 1;
    /// When set TRUE, only logs that are backed up are processed. Don't
    /// send operations from a live log. Corresponds to the dbremote -u option. 
    a_bit_field		latest_backup : 1;
    /// Reserved for internal use and must set to FALSE.
    a_bit_field		scan_log : 1;       
    /// When set TRUE, debugging will be turned on for links.
    a_bit_field		link_debug : 1;
    /// Reserved for internal use and must set to FALSE.
    a_bit_field		full_q_scan : 1;
    /// When set TRUE, no user interaction is requested.
    a_bit_field		no_user_interaction : 1;
    /// Reserved for internal use and must set to FALSE.
    a_bit_field		unused : 1;
    /// Set to the maximum length (in bytes) a message can have. This affects
    /// sending and receiving. The recommended value is 50000. Corresponds
    /// to the dbremote -l option. 
    a_sql_uint32	max_length;
    /// Set to the maximum size (in bytes) of memory buffers to use while
    /// building messages to send. The recommended value is at least
    /// 2 * 1024 * 1024. Corresponds to the dbremote -m option. 
    a_sql_uint32	memory;
    /// Reserved for internal use and must set to 0.
    a_sql_uint32	frequency;
    /// Set the number of worker threads that should be used to apply
    /// messages. This value must not exceed 50. Corresponds to the
    /// dbremote -w option. 
    a_sql_uint32	threads;
    /// This value is used when applying messages. Commits are ignored until
    /// DBRemoteSQL has at least this number of operations(inserts, deletes,
    /// updates) that are uncommitted. Corresponds to the dbremote -g option. 
    a_sql_uint32	operations;
    /// Reserved for internal use and must set to NULL.
    char *		queueparms;
    /// Reserved for internal use and must set to NULL.
    char *		locale;
    /// Set this to the time (in seconds) to wait between polls for new
    /// incoming messages. The recommended value is 60. Corresponds to the
    /// dbremote -rd option. 
    a_sql_uint32	receive_delay;
    /// Set this to the number of polls for incoming messages that
    /// DBRemoteSQL should wait before assuming that a message it is
    /// expecting is lost. For example, if patience_retry is 3 then
    /// DBRemoteSQL tries up to three times to receive the missing
    /// message. Afterward, it sends a resend request. The recommended
    /// value is 1. Corresponds to the dbremote -rp option. 
    a_sql_uint32	patience_retry;
    /// Pointer to a function that prints the given message to a log
    /// file. These messages do not need to be seen by the user.
    MSG_CALLBACK	logrtn;
    /// When set TRUE, log offsets are shown in hexadecimal notation;
    /// otherwise decimal notation is used.
    a_bit_field		use_hex_offsets : 1;
    /// When set TRUE, log offsets are displayed as relative to the start
    /// of the current log file. When set FALSE, log offsets from the
    /// beginning of time are displayed.
    a_bit_field		use_relative_offsets : 1;
    /// Reserved for internal use and must set to FALSE.
    a_bit_field		debug_page_offsets : 1;
    /// Reserved for internal use and must set to 0.
    a_sql_uint32	debug_dump_size;
    /// Set the time (in seconds) between scans of the log file for new
    /// operations to send. Set to zero to allow DBRemoteSQL to choose a
    /// good value based on user send times. Corresponds to the dbremote
    /// -sd option.
    a_sql_uint32	send_delay;
    /// Set the time (in seconds) that DBRemoteSQL waits after seeing
    /// that a user needs a rescan before performing a full scan of the
    /// log. Set to zero to allow DBRemoteSQL to choose a good value
    /// based on user send times and other information it has
    /// collected. Corresponds to the dbremote -ru option. 
    a_sql_uint32	resend_urgency;
    /// Reserved for internal use and must set to NULL.
    char *		include_scan_range;
    /// Pointer to a function that resets the title of the window
    /// (Windows only). The title could be "database_name (receiving,
    /// scanning, or sending) - default_window_title". 
    SET_WINDOW_TITLE_CALLBACK set_window_title_rtn;
    /// A pointer to the default window title string.
    char *		default_window_title;
    /// Pointer to a function that displays a progress message.
    MSG_CALLBACK	progress_msg_rtn;
    /// Pointer to a function that updates the state of the progress
    /// bar. This function takes two unsigned integer arguments index
    /// and max. On the first call, the values are the minimum and
    /// maximum values (for example, 0, 100). On subsequent calls, the
    /// first argument is the current index value (for example, between
    /// 0 and 100) and the second argument is always 0. 
    SET_PROGRESS_CALLBACK progress_index_rtn;
    /// Pointer to a parsed command line (a vector of pointers to
    /// strings). If not NULL, then DBRemoteSQL will call a message
    /// routine to display each command line argument except those
    /// prefixed with -c, -cq, or -ek. 
    char **		argv;
    /// DBRemoteSQL renames and restarts the online transaction log
    /// when the size of the online transaction log is greater than
    /// this value. Corresponds to the dbremote -x option. 
    a_sql_uint32	log_size;
    /// Pointer to an encryption key. Corresponds to the dbremote -ek option.
    char *		encryption_key;
    /// Pointer to the name of the DBRemoteSQL output log to which the
    /// message callbacks print their output. If send is TRUE, the error
    /// log is sent to the consolidated (unless this pointer is NULL). 
    const char *	log_file_name;
    /// When set TRUE, the remote output file is truncated rather than
    /// appended to. Corresponds to the dbremote -rt option.
    a_bit_field 	truncate_remote_output_file:1;
    /// Pointer to the name of the DBRemoteSQL remote output file. Corresponds
    /// to the dbremote -ro or -rt option.
    char *		remote_output_file_name;
    /// Pointer to a function that displays the given warning message. If
    /// NULL, the errorrtn function is called instead. 
    MSG_CALLBACK	warningrtn;
    /// Pointer to the name of the directory containing offline mirror
    /// transaction logs. Corresponds to the dbremote -ml option.
    char *		mirror_logs;
} a_remote_sql;


#if defined( _SQL_PACK_STRUCTURES )
#include "poppk.h"
#endif

/** Accesses the SQL Remote Message Agent.
 * For information about the features you can access, see
 * \salink{SQL Remote Message Agent utility (dbremote), "http://dcx.sybase.com/goto?page=sa160/en/sqlremote/dbrem.html", "sqlremote", "dbrem"}.
 * 
 * \param prs Pointer to a properly initialized a_remote_sql structure.
 *
 * \return  Return code, as listed in 
 * \salink{Software component exit codes, "http://dcx.sybase.com/goto?page=sa160/en/dbprogramming/software-exit-codes.html", "programming", "software-exit-codes"}.
 *
 * \seealso{Introducing SQL Remote, "http://dcx.sybase.com/goto?page=sa160/en/sqlremote/sr-concepts.html", "sqlremote", "sr-concepts"}
 *
 * \sa a_remote_sql structure
 */
extern _crtn short _entry DBRemoteSQL( a_remote_sql *prs );

//************* SQL Remote message encoding interface *******************
//              =====================================
//
// This is an interface for encoding SQL Remote messages
// When SQL Remote generates a message it is in the form of random looking
// bytes. It is sometimes necessary to transform this message into a format
// more suitable for sending through a communications channel.
// one example would be translating the message bytes into uuencoded text
// for transport on a medium which only supports ascii characters.
// SQL Remote ships with an encoding DLL that does something similar to
// this.
//
// Any code which handles a Text message should assume that it may be corrupt
// and return ENCODE_CORRUPT if it is. It is not necessary that this
// level ensures the message is not corrupt (ie. by including a
// crc in the message) SQL Remote will do corruption detection on the 
// message after this level is done with it.
//
// If the functionality of the existing dll is required in a new dll
// the new dll can load and call the existing dll

/// \internal
typedef enum encode_ret {
    ENCODE_SUCCESS,
    ENCODE_CORRUPT,
    ENCODE_OUT_OF_MEM
} encode_ret;

/// \internal
typedef void a_encode_info;

/// \internal
extern _crtn a_encode_info * _entry EncodeInit(   a_sql_uint32   max_encoded_len,
					    	  a_sql_uint32 * max_unencoded_len,
						  MSG_CALLBACK	  msgcb,
					    	  char * 	  local_user );
// EncodeInit() is passed the max_encoded_len and needs to fill in
// max_unencoded_len.
// max_unencoded_len must be set to the maximum length of an unencoded
// message that will produce an encoded message of size less that or
// equal to max_encoded_len
// for example if encoding a message doubles its size then EncodedInit()
// would contain the line
// => *max_unencoded_len = max_encoded_len/2;

/// \internal
extern _crtn void _entry EncodeFini( a_encode_info * info );
/// \internal
extern _crtn encode_ret _entry EncodeMessage(	a_encode_info*	info,
						char *		remote_user,
						char *		inmessage,
						a_sql_uint32 	inmessage_len,
						char *		outbuf,
						a_sql_uint32 	outbuf_len,
						a_sql_uint32 *	outmessage_len );
// outbuf is preallocated to the length passed in as outbuflen
// the resulting message size should be placed in *outmessagelen
/// \internal
extern _crtn encode_ret _entry DecodeMessage(	a_encode_info *	info,
						char *		inmessage,
						a_sql_uint32	inmessage_len,
						char *		outbuf,
						a_sql_uint32	outbuf_len,
						a_sql_uint32 * outmessage_len );
// this function is very similar to EncodeMessage, in this case
// inbuf contains an encoded message and upon exit outbuf
// should contain the decoded message, outmessage_len should
// be the length of the decoded message
// NOTE: see comments above about detecting corrupt messages

#endif
