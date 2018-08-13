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
#include "custdb.h"

static const TCHAR * const GetOrderSQL =
TEXT("   SELECT order_id, disc, quant, notes, status,")
TEXT("          c.cust_id, cust_name, p.prod_id, prod_name, price")
TEXT("     FROM ULOrder o, ULCustomer c, ULProduct p")
TEXT("    WHERE o.cust_id = c.cust_id AND o.prod_id = p.prod_id")
TEXT(" ORDER BY order_id");
enum GetOrderColumn {
	CID_order_id = 1,
	CID_disc,
	CID_quant,
	CID_notes,
	CID_status,
	CID_cust_id,
	CID_cust_name,
	CID_prod_id,
	CID_prod_name,
	CID_price
};

CDemoDB::CDemoDB()
/****************/
	: m_Conn( NULL )
	, m_GetOrder( NULL )
	, m_ProductList( NULL )
	, m_CustomerList( NULL )
{
	// parameters for ULSynchronize
	m_Stream = NULL;
	m_SynchParms[0] = '\0';
	m_EnableOfflineSynch = false;

	// host variables
	m_EmpIDStr[0] = '\0';
	m_OrderID = 0;
	m_CustID = 0;
	m_Cust[0] = '\0';
	m_ProdID = 0;
	m_Prod[0] = '\0';
	m_QuantStr[0] = '\0';
	m_PriceStr[0] = '\0';
	m_DiscStr[0] = '\0';
	m_Status[0] = '\0';
	m_Notes[0] = '\0';
	m_ProdCurrent[0] = '\0';
	m_PriceCurrent[0] = '\0';
	m_CustCurrent[0] = '\0';

	// All remaining members are initialized during Init()
}

CDemoDB::~CDemoDB()
/*****************/
{
}

bool CDemoDB::Init( const TCHAR * connectionParms )
/*************************************************/
{
	resetError( TEXT("Startup") );

	// Initialize the UltraLite library.
	if( ! ULDatabaseManager::Init() ) {
		// unable to initialize database library
		recordError( m_Conn->GetLastError()->GetSQLCode() ); 
		return( false );
	}

	// Install the error callback function.
	ULDatabaseManager::SetErrorCallback( &errorCallback, this );

	ULDatabaseManager::EnableTcpipSynchronization();
	ULDatabaseManager::EnableHttpSynchronization();
	
	// Connect to the database.
	m_Conn = ULDatabaseManager::OpenConnection( connectionParms );
	if( m_Conn == NULL ) {
		// unable to start/connect to database
		ULDatabaseManager::Fini();
		return( false );
	}

	ULPreparedStatement * prepStmt;
	prepStmt = m_Conn->PrepareStatement( GetOrderSQL );
	if( prepStmt != NULL ) {
		m_GetOrder = prepStmt->ExecuteQuery();
		//prepStmt->Close();
	}
	if( m_GetOrder == NULL ) {
		// unable to open cursor
		ULDatabaseManager::Fini();
		return( false );
	}

	// Complete initialization of CDemoDB object.
	notifyOrderListChange();
	notifyCustListChange();
	notifyProdListChange();
	skipToValidOrder();

	// m_EmpIDStr was initialized as an empty string, and will remain so
	// if there are no rows in this table.
	ULTable * table;
	table = m_Conn->OpenTable( TEXT("ULIdentifyEmployee_nosync") );
	if( table ) {
		if( table->Next() ) {
			table->GetString( TEXT("emp_id"), m_EmpIDStr, DEMO_NUMSTR_SIZE );
		}
		table->Close();
	}

	return( m_SQLCode == SQLE_NOERROR ); // false if any error occurred
}

bool CDemoDB::Fini( void )
/************************/
{
	resetError( TEXT("Shutdown") );

	my_assert( m_CustomerList == NULL );
	my_assert( m_ProductList == NULL );
	m_GetOrder->Close();
	m_Conn->Close();
	ULDatabaseManager::Fini();
	return( m_SQLCode == SQLE_NOERROR ); // false if any error occurred
}

bool CDemoDB::SetAndSaveEmployeeID( const TCHAR * id )
/****************************************************/
{
	int					i;

	resetError( TEXT("Save Employee ID") );

	// The CustDB sample uses a numerical user id, but this is not
	// a requirement.
	// Do a strncpy, but only for digits:
	for( i = 0; i < DEMO_NUMSTR_SIZE - 1; i++ ) {
		if( !charIsDigit( id[i] ) ) {
			break;
		}
		m_EmpIDStr[i] = id[i];
	}
	m_EmpIDStr[i] = '\0';

	// Save the employee id in the database.
	ULTable * table;
	table = m_Conn->OpenTable( TEXT("ULIdentifyEmployee_nosync") );
	if( table ) {
		table->InsertBegin();
		table->SetString( TEXT("emp_id"), m_EmpIDStr );
		table->Insert();
		table->Close();
	}

	m_Conn->Commit();
	return( m_SQLCode == SQLE_NOERROR ); // false if any error occurred
}

void CDemoDB::SetCust( const TCHAR * cust )
/*****************************************/
{
	my_strncpy( m_Cust, cust, DEMO_NAME_SIZE - 1 );
	m_Cust[DEMO_NAME_SIZE - 1] = '\0';
}

void CDemoDB::SetProd( const TCHAR * prod )
/*****************************************/
{
	my_strncpy( m_Prod, prod, DEMO_NAME_SIZE - 1 );
	m_Prod[DEMO_NAME_SIZE - 1] = '\0';
}

void CDemoDB::SetQuantStr( const TCHAR * quantstr )
/*************************************************/
{
	my_strncpy( m_QuantStr, quantstr, DEMO_NUMSTR_SIZE - 1 );
	m_QuantStr[DEMO_NUMSTR_SIZE - 1] = '\0';
}

void CDemoDB::SetDiscStr( const TCHAR * discstr )
/***********************************************/
{
	my_strncpy( m_DiscStr, discstr, DEMO_NUMSTR_SIZE - 1 );
	m_DiscStr[DEMO_NUMSTR_SIZE - 1] = '\0';
}

bool CDemoDB::OpenProductList( void )
/***********************************/
{
	resetError( TEXT("Open product list") );
	// Create a cursor to the product list.
	my_assert( m_ProductList == NULL );
	m_ProductList = m_Conn->OpenTable( TEXT("ULProduct"), TEXT("ULProductName") );
	return( m_ProductList != NULL );
}

long CDemoDB::GetProductCount( void )
/***********************************/
{
	resetError( TEXT("Count products") );
	// m_ProdCount caches the product count value for efficiency.
	if( m_ProdCount == DEMO_VALUE_NOT_CACHED ) {
		ULTable * table = m_Conn->OpenTable( TEXT("ULProduct") );
		if( table ) {
			m_ProdCount = table->GetRowCount();
			table->Close();
		}
	}
	return( m_ProdCount );
}

bool CDemoDB::MoveNextProductList( int skip )
/*******************************************/
{
	resetError( TEXT("Fetch product") );
	// Move the product list cursor.
	if( m_ProductList->Relative( skip ) ) {
		m_ProductList->GetString( TEXT("prod_name"), m_ProdCurrent, DEMO_NAME_SIZE );
		m_ProductList->GetString( TEXT("price"), m_PriceCurrent, DEMO_NUMSTR_SIZE );
		return( true );
	}
	return( false );
}

void CDemoDB::CloseProductList( void )
/************************************/
{
	m_ProductList->Close();
	m_ProductList = NULL;
}

bool CDemoDB::OpenCustomerList( void )
/************************************/
{
	resetError( TEXT("Open customer list") );
	// Create cursor to the customer list.
	my_assert( m_CustomerList == NULL );
	m_CustomerList = m_Conn->OpenTable( TEXT("ULCustomer"), TEXT("ULCustomerName") );
	return( m_CustomerList != NULL );
}

long CDemoDB::GetCustomerCount( void )
/************************************/
{
	resetError( TEXT("Count customers") );
	// m_CustCount caches the customer count value for efficiency.
	if( m_CustCount == DEMO_VALUE_NOT_CACHED ) {
		ULTable * table = m_Conn->OpenTable( TEXT("ULCustomer") );
		if( table ) {
			m_CustCount = table->GetRowCount();
			table->Close();
		}
	}
	return( m_CustCount );
}

bool CDemoDB::MoveNextCustomerList( int skip )
/********************************************/
{
	resetError( TEXT("Fetch customer") );
	// Move the customer list cursor.
	if( m_CustomerList->Relative( skip ) ) {
		m_CustomerList->GetString( TEXT("cust_name"), m_CustCurrent, DEMO_NAME_SIZE );
		return( true );
	}
	return( false );
}

void CDemoDB::CloseCustomerList( void )
/*************************************/
{
	m_CustomerList->Close();
	m_CustomerList = NULL;
}

bool CDemoDB::NewOrder( void )
/****************************/
{
	bool					found;
	ULPreparedStatement * 	ps;

	resetError( TEXT("Insert order") );

	// Insert a new order, with product and customer lookup.
	if( !getNextOrderID() ) {
		return( false );
	}

	// Lookup product; fail if no matching product found.
	//TODO: check for multiple matches - ambiguous
	found = m_Conn->ExecuteScalar( &m_ProdID, 0, UL_TYPE_S_LONG,
			TEXT("SELECT prod_id FROM ULProduct WHERE prod_name LIKE ?"),
			m_Prod );
	if( ! found ) {
		// No product name match.
		m_Conn->Rollback(); // cancel order id changes
		doOrderRelativeFetch( 0 ); // refetch old values
		return( false );
	}

	// Lookup customer; add a new one if none matching found.
	found = m_Conn->ExecuteScalar( &m_CustID, 0, UL_TYPE_S_LONG,
			TEXT("SELECT cust_id FROM ULCustomer WHERE cust_name LIKE ?"),
			m_Cust );
	if( ! found ) {
		if( m_Conn->GetLastError()->GetSQLCode() == SQLE_NOTFOUND ) {
			// Above query did not find the customer (NOTFOUND only set on failed Next()).
			// Add a new customer to customer table.
			if( !getNextCustomerID() ) {
				m_Conn->Rollback();
				doOrderRelativeFetch( 0 );
				return( false );
			}
			ps = m_Conn->PrepareStatement( TEXT("INSERT INTO ULCustomer VALUES( ?, ? )") );
			if( ps != NULL ) {
				ps->SetParameterInt( 1, m_CustID );
				ps->SetParameterString( 2, m_Cust );
				found = ps->ExecuteStatement();
				ps->Close();
			}
			notifyCustListChange(); // added a customer
		}
	}
	if( ! found ) {
		m_Conn->Rollback();
		doOrderRelativeFetch( 0 );
		return( false );
	}
	
	// Note the status and notes columns are NULL for new orders.
	ULTable * orderTable;
	orderTable = m_Conn->OpenTable( TEXT("ULOrder") );
	if( orderTable != NULL ) {
		orderTable->SetInt( TEXT("order_id"), m_OrderID );
		orderTable->SetInt( TEXT("cust_id"), m_CustID );
		orderTable->SetInt( TEXT("prod_id"), m_ProdID );
		orderTable->SetString( TEXT("emp_id"), m_EmpIDStr );
		orderTable->SetString( TEXT("disc"), m_DiscStr );
		orderTable->SetString( TEXT("quant"), m_QuantStr );
		orderTable->Insert(); // errors checked below via callback...
		orderTable->Close();
	}
	m_Conn->Commit();
	if( m_SQLCode != SQLE_NOERROR ) { // any error signaled for insert or commit?
		m_Conn->Rollback();
		doOrderRelativeFetch( 0 );
		return( false );
	}

	// Position on the newly inserted row. It's the last row
	// because of the ORDER BY on GetOrderCursor and the way
	// new order ids are selected.
	m_GetOrder->Last();
	doOrderRelativeFetch( 0 );
	notifyOrderListChange(); // added an order
	return( true );
}

bool CDemoDB::ProcessOrder( bool accepted, const TCHAR * notes )
/**************************************************************/
{
	bool					ok = false;
	ULPreparedStatement * 	ps;
	long					count;

	resetError( TEXT("Process order") );

	// Accept or deny the current order.
	my_strncpy( m_Notes, notes, DEMO_NOTES_SIZE - 1 );
	m_Notes[DEMO_NOTES_SIZE - 1] = '\0';
	if( accepted ) {
		my_strcpy( m_Status, TEXT( "Approved" ) );
	} else {
		my_strcpy( m_Status, TEXT( "Denied" ) );
	}

	ps = m_Conn->PrepareStatement(
		TEXT("UPDATE ULOrder SET status = ?, notes = ? WHERE order_id = ?") );
	if( ps != NULL ) {
		ps->SetParameterString( 1, m_Status );
		ps->SetParameterString( 2, m_Notes );
		ps->SetParameterInt( 3, m_OrderID );
		count = ps->ExecuteStatement();
		ok = count == 1; // affected one row
		ps->Close();
	}
	if( ! ok ) {
		// This is essentially an internal error -- most likely cause is
		// the order doesn't exist.
		doOrderRelativeFetch( 0 ); // reset old values
		return( false );
	}

	// The ULOrder table was updated, refresh cursor with new values
	doOrderRelativeFetch( 0 );

	if( !m_Conn->Commit() ) {
		return( false );
	}

	return( true );
}

bool CDemoDB::DeleteOrder( void )
/*******************************/
{
	bool					ok = false;
	ULPreparedStatement * 	ps;
	long					count;

	resetError( TEXT("Delete order") );

	ps = m_Conn->PrepareStatement( TEXT("DELETE FROM ULOrder WHERE order_id = ?") );
	if( ps != NULL ) {
		ps->SetParameterInt( 1, m_OrderID );
		count = ps->ExecuteStatement();
		ok = count == 1; // affected one row
		ps->Close();
	}
	if( ! ok ) {
		// This is essentially an internal error -- most likely cause is
		// the order doesn't exist.
		return( false );
	}

	if( !m_Conn->Commit() ) {
		return( false );
	}

	skipToValidOrder();
	notifyOrderListChange();
	return( true );
}

bool CDemoDB::MoveNextOrder( int skip )
/*************************************/
{
	resetError( TEXT("Fetch order") );
	return( doOrderRelativeFetch( skip ) );
}

void CDemoDB::ResetOrder( void )
/******************************/
{
	m_GetOrder->BeforeFirst();
}

void CDemoDB::ConfigureSynch(
/***************************/
	const char *		stream,
	const TCHAR *		parms,
	bool				enableOfflineSynch )
{
	m_Stream = stream;
	// The stream_parms parameter contains connection and stream-specific
	// options, such as "host=myhost.mycorp.com" or "host=172.31.143.23".
	if( parms != NULL ) {
		my_strncpy( m_SynchParms, parms, DEMO_PARMS_SIZE - 1 );
		m_SynchParms[DEMO_PARMS_SIZE - 1] = '\0';
	} else {
		m_SynchParms[0] = '\0';
	}
	m_EnableOfflineSynch = enableOfflineSynch;
}

bool CDemoDB::Synchronize( ul_synch_observer_fn observer )
/********************************************************/
{
	ul_synch_info		info;

	resetError( TEXT("Synchronize") );

	// Perform synchronization.
	// If this method is called on a separate thread, the main thread
	// _cannot_ access the sqlca during the synchronization.
	// To permit this (database operations on the main thread during
	// synchronization), initialize another ULSqlca for the synchronize
	// thread here and open a second connection.

	if( m_Stream == NULL ) {
		return( false );
	}
	initSynchInfo( &info, observer );

	disableErrorAlert(); // Application UI will display alert in this case
	m_Conn->Synchronize( &info );
	if( !m_Conn->GetLastError()->IsOK() ) {
		return( false );
	}
	notifyOrderListChange();
	notifyCustListChange();
	notifyProdListChange();
	skipToValidOrder();
	return( true );
}

bool CDemoDB::GetSynchronizeResult( ul_synch_result * synchResult )
/*****************************************************************/
{
	return( m_Conn->GetSyncResult( synchResult ) );
}

void CDemoDB::initSynchInfo( ul_synch_info * info, ul_synch_observer_fn observer )
/********************************************************************************/
{
	m_Conn->InitSyncInfo( info );
	info->user_name = m_EmpIDStr;
	info->version = SCRIPT_VERSION;
	info->stream = m_Stream;
	info->stream_parms = m_SynchParms;
	info->observer = observer;
	info->user_data = m_Conn->GetSqlca();
	info->send_download_ack = ul_true;
}

bool CDemoDB::doOrderRelativeFetch( int skip )
/********************************************/
{
	// Fetch an order using a relative offset (including 0, which would
	// refetch the current order).
	if( m_GetOrder->Relative( skip ) ) {
		m_OrderID = m_GetOrder->GetInt( CID_order_id );
		m_GetOrder->GetString( CID_disc, m_DiscStr, DEMO_NUMSTR_SIZE );
		m_GetOrder->GetString( CID_quant, m_QuantStr, DEMO_NUMSTR_SIZE );
		if( m_GetOrder->IsNull( CID_status ) ) {
			m_Status[0] = '\0';
		} else {
			m_GetOrder->GetString( CID_status, m_Status, DEMO_STATUS_SIZE );
		}
		if( m_GetOrder->IsNull( CID_notes ) ) {
			m_Notes[0] = '\0';
		} else {
			m_GetOrder->GetString( CID_notes, m_Notes, DEMO_NOTES_SIZE );
		}
		m_CustID = m_GetOrder->GetInt( CID_cust_id );
		m_GetOrder->GetString( CID_cust_name, m_Cust, DEMO_NAME_SIZE );
		m_ProdID = m_GetOrder->GetInt( CID_prod_id );
		m_GetOrder->GetString( CID_prod_name, m_Prod, DEMO_NAME_SIZE );
		m_GetOrder->GetString( CID_price, m_PriceStr, DEMO_NUMSTR_SIZE );
		return( true );
	}
	return( false );
}

bool CDemoDB::getNextCustomerID( void )
/*************************************/
{
	bool					ok;
	TCHAR					sql[60];

	ok = m_Conn->ExecuteScalar( &m_CustID, 0, UL_TYPE_S_LONG,
		TEXT("SELECT min( pool_cust_id ) FROM ULCustomerIDPool") );
	if( ok ) {
		// For statements just executed once, you may build a dynamic SQL
		// statement by substituting the parameters yourself, rather than
		// using "?"s and SetParameter.
		my_sprintf( sql,
			TEXT("DELETE FROM ULCustomerIDPool WHERE pool_cust_id = %ld"), m_CustID );
		ok = m_Conn->ExecuteStatement( sql );
		if( ok ) {
			ok = m_Conn->GetLastError()->GetSQLCount() == 1; // check affected rows
		}
	}

	// Don't commit this change now... it must be rolled back if the
	// current transaction doesn't complete fully.

	return( ok );
}

bool CDemoDB::getNextOrderID( void )
/**********************************/
{
	bool					ok;
	TCHAR					sql[60];

	ok = m_Conn->ExecuteScalar( &m_OrderID, 0, UL_TYPE_S_LONG,
		TEXT("SELECT min( pool_order_id ) FROM ULOrderIDPool") );
	if( ok ) {
		// For statements just executed once, you may build a dynamic SQL
		// statement by substituting the parameters yourself, rather than
		// using "?"s and SetParameter.
		my_sprintf( sql,
			TEXT("DELETE FROM ULOrderIDPool WHERE pool_order_id = %ld"), m_OrderID );
		ok = m_Conn->ExecuteStatement( sql );
		if( ok ) {
			ok = m_Conn->GetLastError()->GetSQLCount() == 1; // check affected rows
		}
	}

	// Don't commit this change now... it must be rolled back if the
	// current transaction doesn't complete fully.

	return( ok );
}

void CDemoDB::skipToValidOrder( void )
/************************************/
{
	if( !doOrderRelativeFetch( 0 ) ) {
		// In this case the cursor is either before the first row or
		// after the last row. Try moving down to a valid row.
		if( !doOrderRelativeFetch( 1 ) ) {
			// In this case the cursor was on the last row which was
			// just deleted. Move up to a valid row.
			doOrderRelativeFetch( -1 );
		}
	}
}

void CDemoDB::notifyOrderListChange( void )
/*****************************************/
{
	bool					ok = false;
	ULPreparedStatement *	ps;
	ULResultSet *			result;

	// The data in the ULOrder table has changed.
	// Set the MaxOrderID, MinOrderID, and NoOrder members.

	ps = m_Conn->PrepareStatement( TEXT("SELECT max(order_id), min(order_id) FROM ULOrder") );
	if( ps ) {
		result = ps->ExecuteQuery();
		if( result ) {
			if( result->Next() ) {
				if( !result->IsNull( 1 )  &&  !result->IsNull( 2 ) ) {
					m_MaxOrderID = result->GetInt( 1 );
					m_MinOrderID = result->GetInt( 2 );
					ok = true;
				}
			}
			result->Close();
		}
		ps->Close();
	}
	if( ! ok ) {
		m_NoOrder = true;
		m_MaxOrderID = DEMO_VALUE_NOT_CACHED;
		m_MinOrderID = DEMO_VALUE_NOT_CACHED;
	} else {
		m_NoOrder = false;
	}
}

void CDemoDB::notifyCustListChange()
/**********************************/
{
	// The data in the ULCustomer table has changed.
	// Indicate cached count must be refetched.
	m_CustCount = DEMO_VALUE_NOT_CACHED;
}

void CDemoDB::notifyProdListChange()
/**********************************/
{
	// The data in the ULProduct table has changed.
	// Indicate cached count must be refetched.
	m_ProdCount = DEMO_VALUE_NOT_CACHED;
}

ul_error_action CDemoDB::errorCallback(
/*************************************/
	const ULError *		error,
	void *				user_data )
{
	ul_error_action		action;
	CDemoDB *			self = reinterpret_cast<CDemoDB *>(user_data);
	const TCHAR *		device_io_msg =
		TEXT("Unable to access database file. ")
		TEXT("Ensure space is available and any media card is inserted.");
	const TCHAR *		incorrect_volumn_msg =
		TEXT("A different media card was inserted. ")
		TEXT("Please reinsert the original media card.");

	error->GetString( self->m_ErrorCallbackBuf, ERROR_CALLBACK_BUF_LEN );
	switch( error->GetSQLCode() ) {
	case SQLE_NOTFOUND:
		// Suppress this warning. It is used for flow control.
		return UL_ERROR_ACTION_DEFAULT;

	case SQLE_DEVICE_IO_FAILED:
		if( my_okcancel_dialog( device_io_msg ) ) {
			return UL_ERROR_ACTION_TRY_AGAIN;
		} else {
			action = UL_ERROR_ACTION_CANCEL;
		}
		break;

	case SQLE_INCORRECT_VOLUME_ID:
		if( my_okcancel_dialog( incorrect_volumn_msg ) ) {
			return UL_ERROR_ACTION_TRY_AGAIN;
		} else {
			action = UL_ERROR_ACTION_CANCEL;
		}
		break;

	default:
		action = UL_ERROR_ACTION_DEFAULT;
		break;
	}
	if( error->GetSQLCode() == self->m_IgnoreSQLCode ) {
		self->m_IgnoreSQLCode = SQLE_NOERROR; // only ignore once
	} else {
		self->recordError( error->GetSQLCode() );
	}
	return action;
}

void CDemoDB::ignoreError( an_sql_code sqlcode )
/**********************************************/
{
	// ignore this error (once)
	m_IgnoreSQLCode = sqlcode;
}

void CDemoDB::disableErrorAlert()
/*******************************/
{
	// disable error alert (once)
	m_EnableErrorAlert = false;
}

void CDemoDB::resetError( const TCHAR * context )
/***********************************************/
{
	m_EnableErrorAlert = true;
	m_IgnoreSQLCode = SQLE_NOERROR;
	m_SQLCode = SQLE_NOERROR;
	my_strncpy( m_ErrorContext, context, ERROR_CONTEXT_LEN - 1 );
	m_ErrorContext[ERROR_CONTEXT_LEN - 1] = '\0';
	m_ErrorMsg[0] = '\0';
	m_ErrorCallbackBuf[0] = '\0';
}

void CDemoDB::recordError( an_sql_code sql_code )
/***********************************************/
{
	my_assert( sql_code != 0 );
	if( m_SQLCode < 0 ) {
		// Already recorded an error in this context. Ignore this one.
		// (But do override warnings with errors.)
		return;
	}
	m_SQLCode = sql_code;
	// We've chosen our buffer lengths so we know nothing can overflow here:
	// context + error callback buffer + text we include here < m_ErrorMsg size
	// m_ErrorCallbackBuf could be empty, that's okay.
	my_assert( ERROR_CONTEXT_LEN + ERROR_CALLBACK_BUF_LEN + 35 < ERROR_MSG_LEN );
	my_sprintf( m_ErrorMsg, TEXT("Error during '%s' operation. %s"),
				m_ErrorContext, m_ErrorCallbackBuf );
	if( m_EnableErrorAlert ) {
		my_error_msg( m_ErrorMsg );
	} else {
		m_EnableErrorAlert = true; // only disable once
	}
}

// vim:ts=4:
