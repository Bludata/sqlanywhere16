// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
//
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.
//
// *********************************************************************
#ifndef CUSTDB_H_INCLUDED
#define CUSTDB_H_INCLUDED

#include "platform.h"
#if defined( CUSTDB_CPP )
	#include "ulcpp.h"
#else
	#include "ulglobal.h"
#endif

#define SCRIPT_VERSION		TEXT( "custdb 16.0" )

// Fixed sizes for host variables
#define DEMO_NAME_SIZE		31
#define DEMO_NUMSTR_SIZE	11
#define DEMO_STATUS_SIZE	21
#define DEMO_NOTES_SIZE		51
#define DEMO_PARMS_SIZE		256

// Indicate a cached count/id value needs refetching
#define DEMO_VALUE_NOT_CACHED -1

class CDemoDB
{
	public:
		CDemoDB();
		~CDemoDB();

	public:
		// Initialization and finalization
		bool	Init( const TCHAR * connectionParms );
		bool	Fini( void );
		const TCHAR * GetEmployeeID( void ) const { return( m_EmpIDStr ); }
		bool	SetAndSaveEmployeeID( const TCHAR * id );

		// Access and apply Order values
		// Most accessor functions use strings and rely on the database
		// to perform conversions because this is most convenient to the
		// user interface.
		// Note also that most of the get functions are inline (no code
		// in the sqc/cpp file).
		void	SetCust( const TCHAR * cust );
		void	SetProd( const TCHAR * prod );
		void	SetQuantStr( const TCHAR * quantstr );
		void	SetDiscStr( const TCHAR * discstr );

		long	GetOrderID( void ) const { return( m_OrderID ); }
		const TCHAR * GetCust( void ) const { return( m_Cust ); }
		const TCHAR * GetProd( void ) const { return( m_Prod ); }
		const TCHAR * GetPriceStr( void ) const { return( m_PriceStr ); }
		const TCHAR * GetQuantStr( void ) const { return( m_QuantStr ); }
		const TCHAR * GetDiscStr( void ) const { return( m_DiscStr ); }
		const TCHAR * GetStatus( void ) const { return( m_Status ); }
		const TCHAR * GetNotes( void ) const { return( m_Notes ); }

		// Access Product List values while product list is open
		const TCHAR * GetCurrentProd( void ) const { return( m_ProdCurrent ); }
		const TCHAR * GetCurrentPrice( void ) const { return( m_PriceCurrent ); }

		// Access Customer List values while customer list is open
		const TCHAR * GetCurrentCust( void ) const { return( m_CustCurrent ); }

		// Navigate the Product List
		bool	OpenProductList( void );
		long	GetProductCount( void );
		bool	MoveNextProductList( int skip = 1 );
		void	CloseProductList( void );

		// Navigate the Customer List
		bool	OpenCustomerList( void );
		long	GetCustomerCount( void );
		bool	MoveNextCustomerList( int skip = 1 );
		void	CloseCustomerList( void );

		// Manage Orders
		bool NewOrder( void );
		bool ProcessOrder( bool accepted, const TCHAR * notes );
		bool DeleteOrder( void );

		bool MoveNextOrder( int skip = 1 );
		void ResetOrder( void );

		bool HasOrder( void ) const { return( !m_NoOrder ); }
		bool IsNoOrder( void ) const { return( m_NoOrder ); }
		bool IsFirstOrder( void ) const { return( m_MinOrderID == m_OrderID ); }
		bool IsLastOrder( void ) const { return( m_MaxOrderID == m_OrderID ); }

		// Synchronization
		void ConfigureSynch(
				const char *	 stream,
				const TCHAR *	 parms,
				bool			 enableOfflineSynch );
		bool	Synchronize( ul_synch_observer_fn observer );
		bool	GetSynchronizeResult( ul_synch_result * synchResult );

		// Error reporting
		bool LastOperationOK() { return( m_SQLCode >= 0 ); }
		an_sql_code GetSQLCode( void )	{ return( m_SQLCode ); }
		const TCHAR * GetSQLCodeMsg( void ) { return( m_ErrorMsg ); }

	private:
		// Internal implementation routines
		void initSynchInfo( ul_synch_info * info, ul_synch_observer_fn observer );
		bool doOrderRelativeFetch( int skip );
		bool doOrderAbsoluteFetch( int abs );
		bool getNextCustomerID( void );
		bool getNextOrderID( void );
		void skipToValidOrder( void );

		void notifyOrderListChange( void );
		void notifyCustListChange( void );
		void notifyProdListChange( void );

		static ul_error_action UL_CALLBACK_FN errorCallback(
		#if defined( CUSTDB_CPP )
			const ULError *		error,
			void *				user_data
		#else
			SQLCA *				sqlca,
			void *				user_data,
			ul_char *			buffer
		#endif
			);
		void ignoreError( an_sql_code sqlcode );
		void disableErrorAlert();
		void resetError( const TCHAR * context );
		void recordError( an_sql_code sql_code );

		bool charIsDigit( TCHAR c ) const {
			return( (c >= TEXT('0') && c <= TEXT('9')) ? true : false );
		}

	private:
		// parameters for ULSynchronize
		const char * m_Stream;
		TCHAR	m_SynchParms[DEMO_PARMS_SIZE];
		bool	m_EnableOfflineSynch;

		// host variables
		TCHAR	m_EmpIDStr[DEMO_NUMSTR_SIZE];

		// host variables -- orders
		bool	m_NoOrder;		// track presence of orders
		long	m_OrderID;
		long	m_MinOrderID;	// cache order...
		long	m_MaxOrderID;	// ...range
		long	m_CustID;
		TCHAR	m_Cust[DEMO_NAME_SIZE];
		long	m_ProdID;
		TCHAR	m_Prod[DEMO_NAME_SIZE];
		TCHAR	m_QuantStr[DEMO_NUMSTR_SIZE];
		TCHAR	m_PriceStr[DEMO_NUMSTR_SIZE];
		TCHAR	m_DiscStr[DEMO_NUMSTR_SIZE];
		TCHAR	m_Status[DEMO_STATUS_SIZE];
		TCHAR	m_Notes[DEMO_NOTES_SIZE];

		// host variables -- product list
		long	m_ProdCount;	// cache product count
		TCHAR	m_ProdCurrent[DEMO_NAME_SIZE];
		TCHAR	m_PriceCurrent[DEMO_NUMSTR_SIZE];

		// host variables -- customer list
		long	m_CustCount;	// cache customer count
		TCHAR	m_CustCurrent[DEMO_NAME_SIZE];

		// error information
		bool	m_EnableErrorAlert;
		an_sql_code m_IgnoreSQLCode;
		an_sql_code m_SQLCode;
		enum {	ERROR_MSG_LEN = 140,
				ERROR_CONTEXT_LEN = 20,
				ERROR_CALLBACK_BUF_LEN = 80 };
		TCHAR	m_ErrorContext[ERROR_CONTEXT_LEN];
		TCHAR	m_ErrorMsg[ERROR_MSG_LEN];
		TCHAR	m_ErrorCallbackBuf[ERROR_CALLBACK_BUF_LEN];

		// C++ Component objects
		#if defined( CUSTDB_CPP )
			ULConnection *			m_Conn;
			ULResultSet *			m_GetOrder;
			ULTable *				m_ProductList;
			ULTable *				m_CustomerList;
		#endif
};

#endif

// vim:ts=4:
