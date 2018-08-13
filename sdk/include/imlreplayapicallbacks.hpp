// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _IMLREPLAYAPICALLBACKS_HPP_INCLUDED
#define _IMLREPLAYAPICALLBACKS_HPP_INCLUDED

#include "sqltype.h"

class IMLReplayRow;

/*
 * A class that can be used by the MLReplay API to obtain information from or
 * perform operations in MLReplay.
 */
class IMLReplayAPICallbacks {
    public:
	virtual ~IMLReplayAPICallbacks( void )
	/************************************/
	{
	}

	/*
	 * These functions can be used to log errors, warnings, and information messages
	 * respectively to the MLReplay log.
	 *
	 * The format of the messages will be:
	 *
	 * X. YYYY-MM-DD hh:mm:ss.sss. <Y> The actual message/error/warning
	 *
	 * where X will be I for a message, E for an error, or W for a warning and Y
	 * will be the simulated client number or "Main" if simulatedClientNum is 0.
	 *
	 * Notes:
	 *
	 * 1) The messages are truncated to 36 KB (including the prefix of
	 * X. YYYY-MM-DD hh:mm:ss.sss. <Y> ).
	 *
	 * 2) A newline will be automatically added to all messages.
	 *
	 * simulatedClientNum	- the simulated client the error, warning, or message is
	 * 			  about
	 * fmt			- the format of the message
	 */
	virtual void LogMessage( asa_uint32 simulatedClientNum, const char *fmt, ... ) const = 0;
	virtual void LogError( asa_uint32 simulatedClientNum, const char *fmt, ... ) const = 0;
	virtual void LogWarning( asa_uint32 simulatedClientNum, const char *fmt, ... ) const = 0;

	/*
	 * Returns the value associated with the given name as defined on the
	 * MLReplay command line, or NULL if no such value can be found.
	 */
	virtual const char * GetValueFromName( const char *name ) const = 0;

	/*
	 * Returns the total number of simulated clients in this MLReplay
	 * instance.
	 */
	virtual asa_uint32 GetNumSimulatedClients( void ) const = 0;

	/*
	 * Returns the number of times to repeat replaying the recorded
	 * protocol.  The number of repetitions will be greater than 0 unless
	 * the -rnt option is used, in which case it will always be 0.
	 */
	virtual asa_uint32 GetNumRepetitions( void ) const = 0;

	/*
	 * Returns the total number of synchronizations in the recorded
	 * protocol being replayed.
	 */
	virtual asa_uint32 GetNumRecordedSyncs( void ) const = 0;

	/*
	 * Functions used by generated code that should not be modified.
	 */
	virtual IMLReplayRow * CreateMLReplayRow( asa_uint32	tableIndex,
						  asa_uint32	numTables,
						  asa_uint8	ssopcode,
						  const char	*tableName,
						  asa_uint32	simulatedClientNum ) const = 0;

	virtual void DestroyMLReplayRow( IMLReplayRow *row ) const = 0;

	virtual asa_uint32 GetNumRecordedInserts( asa_uint32	tableIndex,
						  asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;

	virtual asa_uint32 GetNumRecordedUpdates( asa_uint32	tableIndex,
						  asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;

	virtual asa_uint32 GetNumRecordedDeletes( asa_uint32	tableIndex,
						  asa_uint32	recordedSyncNum,
						  asa_uint32	uploadTransNum ) const = 0;

};

#endif
