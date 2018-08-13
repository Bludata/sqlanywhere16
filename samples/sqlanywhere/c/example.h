// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without limitation, 
// on the condition that you retain the foregoing copyright notice and disclaimer 
// as to the original code.  
// 
// *******************************************************************
/* EXAMPLE.H    Common header file for all examples
*/

#if defined( __WINDOWS_386__ )			\
||  defined( __NT__ )				\
||  (defined( __386__ ) && !defined( UNIX ))	\
||  defined( _M_I386 )				\
||  defined( UNDER_CE )
    // Get definition for TCHAR and related functions.
    #include <windows.h>
    #include <tchar.h>
#else
    // Define TCHAR and related functions.
    typedef char		TCHAR;
    #define _tcslen(s)		strlen(s)
    #define _tcscpy(d,s)	strcpy(d,s)
    #define _tcscat(d,s)	strcat(d,s)
    #define _tcsncpy(d,s,n)	strncpy(d,s,n)
    #define _stprintf		sprintf
    #define _vstprintf		vsprintf
    #define LPTSTR		LPSTR
    #ifndef TEXT
    #define TEXT(s)		s
    #endif
#endif
    
#if !defined( _countof )
    #define _countof( array )	(sizeof( array )/sizeof( array[0] ))
#endif

int	Displaytext( int, TCHAR *, ... );
int	Displaystringtext( int, int, TCHAR * );
void	Display_systemerror( TCHAR * );
void	Display_refresh( void );
void	GetValue( TCHAR *, TCHAR *, int );
void	GetTableName( TCHAR *, int );

int	WSQLEX_Init( void );
void	WSQLEX_Process_Command( int );
int	WSQLEX_Finish( void );

#define IDM_HELP 		101
#define IDM_PRINT 		102
#define IDM_UP 			103
#define IDM_DOWN 		104
#define IDM_BOTTOM 		105
#define IDM_TOP 		106
#define IDM_QUIT 		107
#define IDM_NAME 		108
#define IDM_INSERT		109
#define IDE_STRING_EDIT		101

#if !defined( TRUE )
    #define TRUE            	1
#endif

#if !defined( FALSE )
    #define FALSE           	0
#endif

#define MAX_TABLE_NAME		50
#define NAME_LEN		50
#define MAX_FETCH_SIZE		50
#define DEFAULT_SCREEN_WIDTH	79
#define MAX_SCREEN_WIDTH	1024
#define NULL_TEXT       	TEXT( "(NULL)" )
#define NULL_TEXT_LEN   	_countof( NULL_TEXT )

#if defined(_MSC_VER)
    #if _MSC_VER >= 800
	#define _exportkwd
    #else
	#define _exportkwd	_export
    #endif
#elif defined(__WATCOMC__)
    #define _exportkwd		__export
#else
    #define _exportkwd		_export
#endif

#define MY_NEWLINE_STR		TEXT( "\n" )
#define MY_NEWLINE_CHAR		'\n'
