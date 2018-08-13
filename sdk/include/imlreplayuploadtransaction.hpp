// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _IMLREPLAYUPLOADTRANSACTION_HPP_INCLUDED
#define _IMLREPLAYUPLOADTRANSACTION_HPP_INCLUDED

#include "sqltype.h"

class IMLReplayUploadTable;

/*
 * This is an interface for the upload transaction class that will be generated
 * by the API generator.  The upload transaction class will be populated with
 * data in the GetUploadTransaction callback.  MLReplay will then retrieve the
 * data and send it to MobiLink.
 */
class IMLReplayUploadTransaction {
    public:
	virtual ~IMLReplayUploadTransaction( void )
	/*****************************************/
	{
	}

	/*
	 * Initializes the UploadTransaction.
	 */
	virtual bool Init( void ) = 0;

	/*
	 * Finishes the UploadTransaction.
	 */
	virtual void Fini( void ) = 0;

	/*
	 * Returns the number of tables.
	 */
	virtual asa_uint32 GetNumUploadTables( void ) const = 0;

	/*
	 * Returns the table with the given index.
	 */
	virtual const IMLReplayUploadTable * GetUploadTable( asa_uint32 tableIndex ) const = 0;

	/*
	 * Frees all the row data for all the tables.
	 */
	virtual void FreeAllUploadRows( void ) = 0;
};

#endif
