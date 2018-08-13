// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef _EXTPFTBAPI_H_INCLUDE
#define _EXTPFTBAPI_H_INCLUDE
#include "exttxtcmn.h"

#define EXTTB_V1_API	1

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk4.h"
#endif

/**
 * An external term breaker library is required to implement the following two
 * functions:
 *
 * extern "C" a_sql_uint32 *exttb_use_new_api();
 *	This function must return the API version supported by the library.
 *	Current version of the API is EXTTB_V1_API.
 *
 * extern "C" a_sql_uint32 (SQL_CALLBACK *<init_function_name>)(
 *				a_init_term_breaker * );
 *	This function is the entry point function to the external term breaker
 *	library. The name of this function mush be provided to the database
 *	server using the
 *	    ALTER TEXT CONFIGURATION ... TERM BREAKER GENERIC EXTERNAL NAME ...
 *	statement.
 *	The return value of this function is 0 if the term breaker
 *	initialization was successful, and 1 otherwise.
 */

#if defined(__cplusplus)
extern "C" {
#endif

typedef enum a_term_breaker_for 
{
    TERM_BREAKER_FOR_LOAD = 0,
    TERM_BREAKER_FOR_QUERY
} a_term_breaker_for;

// This structure holds a tuple of token returned by the term breaker
// This also holds information about the length of the token as well
// as its position in the document
// The external term breaker library should allocate and fill an array 
// of this structure during the execution of get_words() entry-point
typedef struct a_term
{
    // Term returned by the term breaker.
    unsigned char *word;

    // Length of the term in bytes
    a_sql_uint32 len;

    // Length of the term in characters
    a_sql_uint32 ch_len;

    // Position of the term in the document
    a_sql_uint64 pos;
} a_term, *p_term;

// This structure is the interface for implementing external
// term breaker. The external term breaker library must implement
// this interface
typedef struct a_word_source
{
    // Mark the beginning of term breaking for a single document.
    // This method is called once for every document being tokenized.
    a_sql_uint32 (SQL_CALLBACK *begin_document)(a_word_source*		/*This*/
						, a_sql_uint32		/*use prefix */
					       );

    // Get part of the list of terms from the document being tokenized. This
    // method will return an array of a_term structures where each
    // element of the array holds information about the term, its
    // length and its position in the document.
    // This method will be called multiple times for a single document 
    // until there are no more terms to return for the document, or an error
    // occurs
    a_sql_uint32 (SQL_CALLBACK *get_words)(a_word_source*		/*This*/
					   , a_term**			/*terms*/
					   , a_sql_uint32*		/*number of terms*/
					  );

    // This method marks the completion of term breaking for a single
    // document. This method should perform all the cleanup required after
    // processing a single document
    a_sql_uint32 (SQL_CALLBACK *end_document)(a_word_source*		/*This*/
					     );

    // Mark completion of a session of a pipeline operation. This method
    // will be called for every session of pipeline operation. This
    // method will be called by the consumer of this term breaker just before 
    // the pipeline is closed
    a_sql_uint32 (SQL_CALLBACK *fini_all)(a_word_source*		/*This*/
					 );

    // Ponter to the server's context. The external term breaker will use
    // this context for the following tasks:
    // 	1. Error reporting
    // 	2. Message logging
    // 	3. Interrupt handling
    a_server_context *_context;

    /* NOTE: AT MOST ONE OF THE FOLLOWING TWO PRODUCER POINTERS CAN BE
     * NOT NULL AT ANY POINT IN TIME. 
     */
    // Pointer to a a_text_source producer of this term breaker. The term
    // breaker must use this pointer to communicate with its text producer
    // as database server may change this pointer in case character set
    // conversion of the term breaker input is required
    a_text_source *_my_text_producer;

    // Pointer to a term breaker who is also a producer to this
    // term breaker
    a_word_source *_my_word_producer;

    /* NOTE: FOLLOWING POINTERS ARE RESERVED FOR FUTURE USE ONLY. THEY
     * SHOULD BE INITIALIZED BY THE EXTERNAL LIBRARY FOR THIS RELEASE
     */
    // Pointer to a pre-filter who is also a consumer to this term breaker
    a_text_source *_my_text_consumer;

    // Pointer to a term breaker who is also a consumer to this
    // term breaker
    a_word_source *_my_word_consumer;
} a_word_source, *p_word_source;

typedef struct a_init_term_breaker
{
    // Holds a pointer to the text producer of the new term breaker.
    // This value is initialized by the caller of the entry point function
    a_text_source *in_text_source;

    // Desired charset. This value is initialized by the caller of the entry
    // point function to the character set of the input data of this term
    // breaker. This can be the character set of the data produced by the
    // database server or the external prefilter
    const char* desired_charset;

    // The external library should initialize this pointer to point to the new
    // term breaker object containing all the function and value pointers
    // as required by a_word_source interface
    a_word_source *out_word_source;

    // charset supported by the external library. The database server will
    // expect the term breaker output to be in this character set. If this
    // character set is different from desired_charset, the database server 
    // will convert the input to the term breaker to this character set
    char* actual_charset;

    // Purpose of initializing the term breaker:
    // 	1) TERM_BREAKER_FOR_LOAD - The term breaker is being initialized for
    // 	text index population or update operation
    //  2) TERM_BREAKER_FOR_QUERY - The term breaker is being initialized for
    //  parsing query elements, stoplist, or input to sa_(n)char_terms stored
    //  procedure
    a_term_breaker_for term_breaker_for;
} a_init_term_breaker, *p_init_term_breaker;

#if defined(__cplusplus)
}
#endif

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif //_EXTPFTBAPI_H_INCLUDE
