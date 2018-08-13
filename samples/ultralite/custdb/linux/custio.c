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
#include <stdio.h>
#include <stdlib.h>
#if defined( UNDER_MVLINUX ) || defined( LINUX )
	#include <unistd.h>
#endif
#include "custdb.h"

#define SYNCH_METHOD	"tcpip"
#ifndef SYNCH_PARMS
#define SYNCH_PARMS		NULL
#endif

enum ErrorNumber {
	ERROR_INITIALIZE = 1,
	ERROR_SYNCHRONIZATION,
	ERROR_DATABASEERROR,
	ERROR_PRODUCTNOTFOUND
};

static bool DoSetHttpSynch( CDemoDB *demo );
static bool DoSetTcpipSynch( CDemoDB *demo );
static const TCHAR * GetErrorMsg( ErrorNumber errorNumber );
static int ReadChar();
static bool ReadString( TCHAR *buf, size_t bufSize );
static void WriteF( TCHAR const * fmt, ... );
static void UL_CALLBACK_FN ObserverFunc( ul_synch_status * status );

static void printHeadings()
/*************************/
{
	WriteF( TEXT("  Order  Customer               Product               Quantity  Status\n") );
	WriteF( TEXT("  -----  --------               -------               --------  ------\n") );
}

static bool printCurrentOrder( CDemoDB const * demo )
/***************************************************/
{
	if( demo->IsNoOrder() ) {
		WriteF( TEXT("No orders\n") );
		return false;
	}
	WriteF( TEXT("  %5ld  %-22s %-22s %5s   %-12s\n"),
			demo->GetOrderID(),
			demo->GetCust(),
			demo->GetProd(),
			demo->GetQuantStr(),
			demo->GetStatus() );
	return true;
}

int main()
/********/
{
	CDemoDB *	demo;
	char		ch = ' ';
	bool		success;
	const TCHAR * connectionParms = TEXT("DBF=custdb.udb");

	// variables to get data
	const TCHAR * errMsg;
	TCHAR		empID[DEMO_NAME_SIZE];
	TCHAR		cust[DEMO_NAME_SIZE];
	TCHAR		prod[DEMO_NAME_SIZE];
	TCHAR		quant[DEMO_NUMSTR_SIZE];
	TCHAR		disc[DEMO_NUMSTR_SIZE];

	demo = new CDemoDB;
	
	if( ! demo->Init( connectionParms ) ) {
		WriteF( TEXT("%s\n"), GetErrorMsg( ERROR_INITIALIZE ) );
		delete demo;
		return( 1 );
	}

	// allow chance to change synch parameters before the synch
	WriteF( TEXT("Enter synchronization stream parameters:\n") );
	WriteF( TEXT("Type t to use TCP/IP,\n") );
	WriteF( TEXT("     h to use HTTP, or\n") );
	WriteF( TEXT("     d to use default:\n") );
	ch = ReadChar();
	if( ch == 't' ) {
		DoSetTcpipSynch( demo );
	} else if( ch == 'h' ) {
		DoSetHttpSynch( demo );
	} else {
		demo->ConfigureSynch( SYNCH_METHOD, SYNCH_PARMS, false );
	}

	if( ( demo->GetEmployeeID() )[0] == '\0' ) {
		// new database; obtain an employee ID
		WriteF( TEXT("Enter employee ID (50)\n") );
		if( !ReadString( empID, DEMO_NUMSTR_SIZE ) ) {
			goto done;
		}
		
		// add this
		if( !demo->SetAndSaveEmployeeID( empID ) ) {
			goto done;
		}

		WriteF( TEXT("Synchronizing ...\n") );
		if( !demo->Synchronize( ObserverFunc ) ) {
			WriteF( TEXT("%s\n"), demo->GetSQLCodeMsg() );
			WriteF( TEXT("%s\n"), GetErrorMsg( ERROR_SYNCHRONIZATION ) );
			goto done;
		}
	}

	printHeadings();
	if( printCurrentOrder( demo ) ) {
		while( demo->MoveNextOrder() ) {
			printCurrentOrder( demo );
		}
		demo->ResetOrder();
		demo->MoveNextOrder();
	}
	WriteF( TEXT("\n") );
	printHeadings();
	for( ; ; ) {
		printCurrentOrder( demo );
		ch = ReadChar();
		if( ch == 'q' ) break;
		success = true;
		switch( ch ) {
			case 'a':
				success = demo->ProcessOrder( true, TEXT("Sure, why not?") );
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_DATABASEERROR );
				}
				break;
			case 'b':
				if( demo->IsFirstOrder() ) {
					WriteF( TEXT("On first order\n") );
					break;
				}
				success = demo->MoveNextOrder( -1 );
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_DATABASEERROR );
				}
				break;
			case 'c':
				WriteF( TEXT("\nCustomer List\n") );
				
				// open the customer list, step throught it, and close it
				demo->OpenCustomerList();
				while( demo->MoveNextCustomerList() ) {
					WriteF( TEXT("  %s\n"), demo->GetCurrentCust() );
				}
				demo->CloseCustomerList();
				WriteF( TEXT("\n") );
				break;
			case 'd':
				success = demo->ProcessOrder( false, TEXT("No way!") );
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_DATABASEERROR );
				}
				break;
			case 'f':
				if( demo->IsLastOrder() ) {
					WriteF( TEXT("On last order\n") );
					break;
				}
				success = demo->MoveNextOrder();
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_DATABASEERROR );
				}
				break;
			case 'h':
				DoSetHttpSynch( demo );
				break;
			case 'i':
				WriteF( TEXT("  Type customer name (use %% for wildcard).\n") );
				ReadString( cust, DEMO_NAME_SIZE );
				WriteF( TEXT("  Type product name (use %% for wildcard).\n") );
				ReadString( prod, DEMO_NAME_SIZE );
				WriteF( TEXT("  Type quantity to order.\n") );
				ReadString( quant, DEMO_NUMSTR_SIZE );
				WriteF( TEXT("  Type discount as a percentage.\n") );
				ReadString( disc, DEMO_NUMSTR_SIZE );

				// to make new order, we must set the cust and prod
				demo->SetProd( prod );
				demo->SetCust( cust );
				demo->SetQuantStr( quant );
				demo->SetDiscStr( disc );
				success = demo->NewOrder();
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_PRODUCTNOTFOUND );
				}

				// now we have the wrong info selected in our class
				// so reselect the same one
				demo->MoveNextOrder( 0 );
				break;
			case 'p':
				WriteF( TEXT("\nProduct List\n") );
				
				// open product list, print it, then close it
				demo->OpenProductList();
				while( demo->MoveNextProductList() ) {
					WriteF( TEXT("  %-22s  $%s\n"),
						demo->GetCurrentProd(),
						demo->GetCurrentPrice() );
				}
				demo->CloseProductList();
				WriteF( TEXT("\n") );
				break;
			case 'r':
				demo->Fini();
				demo->Init( connectionParms );
				WriteF( TEXT("Database Restarted\n") );
				break;
			case 's':
				WriteF( TEXT("Synchronizing ...\n") );
				success = demo->Synchronize( ObserverFunc );
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_SYNCHRONIZATION );
				}
				break;
			case 't':
				DoSetTcpipSynch( demo );
				break;
			case 'x':
				success = demo->DeleteOrder();
				if( ! success ) {
					errMsg = GetErrorMsg( ERROR_DATABASEERROR );
				}
				break;
			case '?':
			default:
				WriteF( TEXT("\nHelp\n") );
				WriteF( TEXT("a - approve\n") );
				WriteF( TEXT("b - backward\n") );
				WriteF( TEXT("c - customer list\n") );
				WriteF( TEXT("d - deny\n") );
				WriteF( TEXT("f - forward\n") );
				WriteF( TEXT("h - use HTTP synch. stream\n") );
				WriteF( TEXT("i - insert new order\n") );
				WriteF( TEXT("p - product list\n") );
				WriteF( TEXT("q - quit\n") );
				WriteF( TEXT("s - synchronize\n") );
				WriteF( TEXT("t - use TCP/IP synch. stream\n") );
				WriteF( TEXT("x - delete\n") );
				WriteF( TEXT("? - help\n") );
				WriteF( TEXT("\n") );
				break;
		}
		if( ! success ) {
			WriteF( TEXT("Operation failed.\n") );
			WriteF( TEXT("Error Diagnostic:\n%s\n"), errMsg );
		}
	}
	
 done:
	demo->Fini();
	delete demo;
	return( 0 );
}

static void UL_CALLBACK_FN ObserverFunc( ul_synch_status * status )
/*****************************************************************/
{
	if( status->flags & UL_SYNCH_STATUS_FLAG_IS_BLOCKING ) return;

	switch( status->state ) {
	case UL_SYNCH_STATE_STARTING:
		WriteF( TEXT("Starting synchronization\n") );
		break;
	case UL_SYNCH_STATE_CONNECTING:
		WriteF( TEXT("Connecting to server\n") );
		break;
	case UL_SYNCH_STATE_SENDING_HEADER:
		WriteF( TEXT("Sending header\n") );
		break;
	case UL_SYNCH_STATE_SENDING_TABLE:
		WriteF( TEXT("Sending table %hs (%d of %d)\n"),
			status->table_name,
			status->sync_table_index, status->sync_table_count );
		break;
	case UL_SYNCH_STATE_FINISHING_UPLOAD:
		WriteF( TEXT("Finishing upload\n") );
		break;
	case UL_SYNCH_STATE_RECEIVING_UPLOAD_ACK:
		WriteF( TEXT("Acknowledging upload\n") );
		break;
	case UL_SYNCH_STATE_RECEIVING_TABLE:
		WriteF( TEXT("Receiving table %hs (%d of %d)\n"),
			status->table_name,
			status->sync_table_index, status->sync_table_count );
		break;
	case UL_SYNCH_STATE_COMMITTING_DOWNLOAD:
		WriteF( TEXT("Committing download\n") );
		break;
	case UL_SYNCH_STATE_SENDING_DOWNLOAD_ACK:
		WriteF( TEXT("Acknowledging download\n") );
		break;
	case UL_SYNCH_STATE_DISCONNECTING:
		WriteF( TEXT("Disconnecting\n") );
		break;
	case UL_SYNCH_STATE_DONE:
		WriteF( TEXT("Synchronization complete\n") );
		break;
	case UL_SYNCH_STATE_ERROR:
		WriteF( TEXT("Synchronization error: ") );
		if( status->info->upload_ok ) {
			WriteF( TEXT("Data was uploaded and committed, but an error occurred during download\n") );
		} else {
			WriteF( TEXT("No data was uploaded or downloaded\n") );
		}
		break;
	default: // ignore newer observer states
		break;
	}
}

static bool DoSetTcpipSynch( CDemoDB *demo )
/******************************************/
{
	TCHAR		synchOptBuf[DEMO_PARMS_SIZE];
	TCHAR		synchOpts[DEMO_PARMS_SIZE];

	synchOpts[0] = '\0';
	WriteF( TEXT("Using TCP/IP synchronization stream.\n") );
	WriteF( TEXT("Enter host name (. = use default host) or TCP/IP address:\n") );
	ReadString( synchOptBuf, DEMO_PARMS_SIZE );
	if( synchOptBuf[0] != '.' ) {
		my_sprintf( synchOpts, TEXT("host=%s;"), synchOptBuf );
	}
	demo->ConfigureSynch( "tcpip", synchOpts, false );
	return true;
}

static bool DoSetHttpSynch( CDemoDB *demo )
/*****************************************/
{
	TCHAR		synchOptBuf[DEMO_PARMS_SIZE];
	TCHAR		synchOpts[DEMO_PARMS_SIZE];

	synchOpts[0] = '\0';
	WriteF( TEXT("Using HTTP synchronization stream.\n") );
	WriteF( TEXT("Enter host name (. = use default host) or TCP/IP address:\n") );
	ReadString( synchOptBuf, DEMO_PARMS_SIZE );
	if( synchOptBuf[0] != '.' ) {
		my_sprintf( synchOpts, TEXT("host=%s;"), synchOptBuf );
	}
	demo->ConfigureSynch( "http", synchOpts, false );
	return true;
}

static const TCHAR * GetErrorMsg( ErrorNumber errorNumber )
/*********************************************************/
{
	const TCHAR *		s;

	switch( errorNumber ) {
	case ERROR_INITIALIZE:
		s = TEXT("Could not initialize database");
		break;
	case ERROR_SYNCHRONIZATION:
		s = TEXT("Synchronization failed. Please check that:\n")
			TEXT("- Mobilink server is running with correct communications protocol\n")
			TEXT("- synchronization stream and parameters are correct\n")
			TEXT("- network connection is active");
		break;
	case ERROR_DATABASEERROR:
		s = TEXT("Database error");
		break;
	case ERROR_PRODUCTNOTFOUND:
		s = TEXT("Product not found in database");
		break;
	default:
		s = TEXT("???");
		break;
	}
	return s;
}

// INPUT-OUTPUT routines
#ifndef _tprintf
	#define _tprintf	printf
	#define _vtprintf	vprintf
#endif

static int ReadChar()
/*******************/
{
	int					ch;

	// skip empty lines and spaces
	do {
		ch = getchar();
	} while( ch == '\n' || ch == ' ' );
	return ch;
}

static bool ReadString( TCHAR *buf, size_t bufSize )
/**************************************************/
{
	int					ch;
	TCHAR *				bufEnd;

	// skip empty lines and spaces
	do {
		ch = getchar();
	} while( ch == '\n' || ch == ' ' );

	// read string
	bufEnd = buf + bufSize - 1;
	while( ch != '\n' && ch != -1 && buf < bufEnd ) {
		*buf++ = ch;
		ch = getchar();
	}
	*buf = '\0';
	return (bool) ( ch != -1 );
}

static void WriteF( TCHAR const * fmt, ... )
/******************************************/
{
	va_list				args;

	va_start( args, fmt );
	_vtprintf( fmt, args );
	va_end( args );
}

// vim:ts=4:
