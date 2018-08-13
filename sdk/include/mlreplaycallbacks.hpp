// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _MLREPLAYCALLBACKS_H_INCLUDED
#define _MLREPLAYCALLBACKS_H_INCLUDED

#include "mlreplayapi.hpp"
#include "sqltype.h"

class IMLReplayAPICallbacks;
class IMLReplayUploadTable;
class IMLReplayUploadTransaction;
class IMLReplayRow;

#ifdef __cplusplus
extern "C" {
#endif
/*
 * Callbacks MLReplay will use.
 */

/*
 * Returns the API version.
 */
_MLREPLAY_EXPORT asa_uint32 _MLREPLAY_CDECL GetMLReplayAPIVersion( void );

/*
 * Creates and initializes an implementation of IMLReplayUploadTransaction that
 * MLReplay will use to populate the replay session with custom data.
 *
 * mlrAPICallbacks	- callbacks to provide information from MLReplay
 * uploadTrans		- an output parameter that will be set to an
 * 			  implementation of IMLReplayUploadTransaction
 *
 * Returns true if the operation succeeds; otherwise false, which cancels the
 * replay session.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL CreateAndInitMLReplayUploadTransaction( IMLReplayUploadTransaction	**uploadTrans,
									      const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Cleanup any memory used when calling InitUploadTransaction.
 *
 * uploadTrans	- an implementation of IMLReplayUploadTransaction
 */
_MLREPLAY_EXPORT void _MLREPLAY_CDECL DestroyMLReplayUploadTransaction( IMLReplayUploadTransaction *uploadTrans );

/*
 * Initialize any global variables that will be used by the callbacks.
 *
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 * 			  can be used to customize replay behaviour
 *
 * Returns true if the operation succeeds; otherwise returns false, which
 * cancels the replay.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL GlobalInit( const IMLReplayAPICallbacks *mlrAPICallbacks );

/*
 * Clean up any global variables.
 *
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 * 			  can be used to customize replay behaviour
 */
_MLREPLAY_EXPORT void _MLREPLAY_CDECL GlobalFini( const IMLReplayAPICallbacks *mlrAPICallbacks );

/*
 * Returns the custom transaction data for the given simulated client and
 * transaction.
 *
 * NOTE: This callback may be called concurrently.
 *
 * repetitionNum	- current repetition number
 * simulatedClientNum	- the simulated client number used to distinguish this
 *			  simulated client from other simulated clients in this
 *			  mlreplay instance
 * recordedSyncNum	- the synchronization number (ordinal 1) within the
 *			  recorded protocol
 * uploadTransNum	- the transaction number (ordinal 1) within the given
 *			  synchronization
 * numUploadedTrans	- the total number of upload transactions in the given
 *			  synchronization
 * uploadTrans		- an output parameter that must be set with the upload
 *			  operations for the current transaction
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 * 			  can be used to customize replay behaviour
 *
 * Returns true if the operation succeeds; otherwise returns false, which
 * cancels the replay.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL GetUploadTransaction( asa_uint32			repetitionNum,
							    asa_uint32			simulatedClientNum,
							    asa_uint32			recordedSyncNum,
							    asa_uint32			uploadTransNum,
							    asa_uint32			numUploadedTrans,
							    IMLReplayUploadTransaction	*uploadTrans,
							    const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Give MLReplay the authentication information for the specified simulated
 * client.  Note that if username, password, authenticationParameters, script
 * version and/or ldt are NULL, the corresponding value from the recorded
 * protocol will be used.  If remoteID is NULL, then a GUID will be generated
 * and used for the remote ID.  The format of the ldt output parameter should be
 * yyyy-MM-dd hh:mm:ss.SSS.
 *
 * simulatedClientNum		- the simulated client number used to
 * 				  distinguish this simulated client from other
 * 				  simulated clients in this mlreplay instance
 * remoteID			- an output parameter that must be set to the
 *				  remote ID of this simulated client, which must
 *				  be a unique value across all mlreplay instances
 * username			- an output parameter that must be set to the
 *				  MobiLink username for this simulated client
 * password			- an output parameter that must be set to the
 *				  password for the MobiLink user
 * scriptVersion		- an output parameter that must be set to the
 *				  script version for the MobiLink user to use
 * authenticationParameters	- an output parameter that must be set to an
 *				  array of authentication parameters for this
 *				  simulated client
 * numAuthenticationParameters	- an output parameter set to the number of
 *				  authentication parameters returned in
 *				  authenticationParameters 
 * ldt				- an output parameter that must be set to the
 *				  last download time
 * mlrAPICallbacks		- callbacks to provide information from MLReplay
 * 				  that can be used to customize replay behaviour
 *
 * Returns true if the operation succeeds; otherwise returns false, which
 * cancels the replay session.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL IdentifySimulatedClient( asa_uint32			simulatedClientNum,
							       char				**remoteID,
							       char				**username,
							       char				**password,
							       char				**scriptVersion,
							       char				***authenticationParameters,
							       asa_uint16			*numAuthenticationParameters,
							       char				**ldt,
							       const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Cleanup any memory used when calling IdentifySimulatedClient.
 *
 * simulatedClientNum		- the simulated client number used to
 * 				  distinguish this simulated client from other
 * 				  simulated clients in this mlreplay instance
 * remoteID			- the remote ID given by the call to
 *				  IdentifySimulatedClient for the given
 *				  simulated client
 * username			- the username given by the call to
 *				  IdentifySimulatedClient for the given
 *				  simulated client
 * password			- the password given by the call to
 *				  IdentifySimulatedClient for the given
 *				  simulated client
 * scriptVersion		- the script version given by the call to
 *				  IdentifySimulatedClient for the given
 *				  simulated client
 * authenticationParameters	- the authentication parameters given by the
 *				  call to IdentifySimulatedClient for the given
 *				  simulated client
 * numAuthenticationParameters	- the number of authentication parameters given
 *				  by the call to IdentifySimulatedClient for the
 *				  given simulated client 
 * ldt				- the last download time given by the call to
 *				  IdentifySimulatedClient for the given simulated
 *				  client
 * mlrAPICallbacks		- callbacks to provide information from MLReplay
 * 				  that can be used to customize replay behaviour
 */
_MLREPLAY_EXPORT void _MLREPLAY_CDECL FiniIdentifySimulatedClient( asa_uint32			simulatedClientNum,
								   char				*remoteID,
								   char				*username,
								   char				*password,
								   char				*scriptVersion,
								   char				**authenticationParameters,
								   asa_uint16			numAuthenticationParameters,
								   char				*ldt,
								   const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Coordinate when each simulated client will be created based on the given
 * simulated client number and the number of simulated client.  Note that
 * simulated client i is not created until:
 *
 *   1) DelayCreationOfSimulatedClient has returned for simulated clients
 *      1,...,i - 1
 *   2) DelayCreationOfSimulatedClient( numRepetitions, i, numSimulatedClients, namesAndValues )
 *      returns
 *
 * DelayCreationOfSimulatedClient will not be called for simulated client i
 * until DelayCreationOfSimulatedClient has returned for simulated clients
 * 1, ..., i - 1.
 *
 * simulatedClientNum	- the simulated client number used to distinguish this
 *			  simulated client from other simulated clients in this
 *			  mlreplay instance
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 *			  can be used to customize replay behaviour
 * 
 * Return true if the specified simulated client is supposed to be created.  If
 * false is returned, the specified simulated client will not be created, but
 * all other simulated clients will still be created.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL DelayCreationOfSimulatedClient( asa_uint32			simulatedClientNum,
								      const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Coordinate when each simulated client will be destroyed.  The specified
 * simulated client will not be destroyed until this callback returns.
 *
 * NOTE: This callback may be called concurrently.
 *
 * simulatedClientNum	- the simulated client number used to distinguish this
 *			  simulated client from other simulated clients in this
 *			  mlreplay instance
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 *			  can be used to customize replay behaviour
 */
_MLREPLAY_EXPORT void _MLREPLAY_CDECL DelayDestructionOfSimulatedClient( asa_uint32			simulatedClientNum,
									 const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * Return the time (in milliseconds) to delay while applying the download to
 * simulate slow devices.
 *
 * NOTE: This callback may be called concurrently.
 *
 * repetitionNum		- current repetition number
 * simulatedClientNum		- the simulated client number used to
 *				  distinguish this simulated client from other
 *				  simulated clients in this mlreplay instance
 * recordedSyncNum		- the synchronization number (ordinal 1) within
 *				  the recorded protocol
 * recordedDownloadApplyTime	- the recorded download apply time (in
 * 				  milliseconds)
 * mlrAPICallbacks		- callbacks to provide information from MLReplay
 *			  	  that can be used to customize replay behaviour
 */
_MLREPLAY_EXPORT asa_uint32 _MLREPLAY_CDECL GetDownloadApplyTime( asa_uint32			repetitionNum,
								  asa_uint32			simulatedClientNum,
								  asa_uint32			recordedSyncNum,
								  asa_uint32			recordedDownloadApplyTime,
								  const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * A callback used to report that the simulated client has finished a replay.
 *
 * NOTE: This callback may be called concurrently.
 *
 * repetitionNum	- current repetition number
 * simulatedClientNum	- the simulated client number used to distinguish this
 *			  simulated client from other simulated clients in this
 *			  mlreplay instance
 * success		- whether or not the simulated client completed
 *			  successfully
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 *			  can be used to customize replay behaviour
 *
 * Returns true on success; otherwise returns false.  The overall success of the
 * replay will be determined by the result of this callback and whether or not
 * MLReplay has determined that it was successful (the value of the success
 * parameter).  If MLReplay has determined that the replay failed, then the
 * value returned by this callback will have no affect.  However, if
 * MLReplay has determined that the replay was successful and this callback
 * returns false, then MLReplay will treat it as if it failed.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL ReportEndOfReplay( asa_uint32			repetitionNum,
							 asa_uint32			simulatedClientNum,
							 bool				success,
							 const IMLReplayAPICallbacks	*mlrAPICallbacks );

/*
 * A callback used to coordinate when each simulated client begins replaying.
 *
 * NOTE: This callback may be called concurrently.
 *
 * repetitionNum	- current repetition number
 * simulatedClientNum	- the simulated client number used to distinguish this
 *			  simulated client from other simulated clients in this
 *			  mlreplay instance
 * mlrAPICallbacks	- callbacks to provide information from MLReplay that
 *			  can be used to customize replay behaviour
 *
 * Return true if the replay is supposed to be performed; otherwise return
 * false.
 */
_MLREPLAY_EXPORT bool _MLREPLAY_CDECL DelayStartOfReplay( asa_uint32			repetitionNum,
							  asa_uint32			simulatedClientNum,
							  const IMLReplayAPICallbacks	*mlrAPICallbacks );

#ifdef __cplusplus
}
#endif

#endif
