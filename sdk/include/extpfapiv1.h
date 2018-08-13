// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
#ifndef _EXTPFAPI_H_INCLUDE
#define _EXTPFAPI_H_INCLUDE
#include "exttxtcmn.h"

#define EXTPF_V1_API	1

#if defined( _SQL_PACK_STRUCTURES )
    #if defined( _MSC_VER ) && _MSC_VER > 800
	#pragma warning(push)
        #pragma warning(disable:4103)
    #endif
    #include "pshpk4.h"
#endif

/**
 * An external prefilter library is required to implement the following two
 * functions:
 *
 * extern "C" a_sql_uint32 *extpf_use_new_api();
 *	This function must return the API version supported by the library.
 *	Current version of the API is EXTPF_V1_API.
 *
 * extern "C" a_sql_uint32 (SQL_CALLBACK *<init_function_name>)(
 *				a_init_pre_filter * );
 *	This function is the entry point function to the external prefilter
 *	library. The name of this function mush be provided to the database
 *	server using the
 *	    ALTER TEXT CONFIGURATION ... PREFILTER EXTERNAL NAME ...
 *	statement.
 *	The return value of this function is 0 if the prefilter initialization
 *	was successful, and 1 otherwise.
 */

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct a_text_source {
    // Mark beginning of prefiltering of a single document. This method is
    // called once for every document being tokenized
    a_sql_uint32 (SQL_CALLBACK *begin_document)( a_text_source*		/*This*/
					       );

    // Get next chunk of bytes from the document. This method will be called
    // multiple times during processing of the document.
    // The consumer of the prefilter will call this method until all the data
    // in the document is consumed or an error occurs
    a_sql_uint32 (SQL_CALLBACK *get_next_piece)( a_text_source*		/*This*/
						, unsigned char**	/*buffer*/
						, a_sql_uint32*		/*buffer length*/
					       );

    // Mark completion of the prefiltering process for a single document
    a_sql_uint32 (SQL_CALLBACK *end_document)( a_text_source*		/*This*/
					     );

    // Get the length of the document after processing
    a_sql_uint64 (SQL_CALLBACK *get_document_size)( a_text_source*	/*This*/
						  );

    // Mark completion of this session of prefiltering. This method
    // should be used to clean up any allocations done by the library
    // during this prefiltering session. This method will be called
    // by the consumer of this module just before closing the pipeline
    a_sql_uint32 (SQL_CALLBACK *fini_all)( a_text_source*		/*This*/
					 );

    // Maintain server context. The prefilter will use this
    // for the following:
    //	1. Error reporting
    //	2. Message logging
    //	3. Interrupt processing
    p_server_context _context;

    /* NOTE: NONE OR ONLY ONE OF THE FOLLOWING TWO POINTERS CAN BE
     * VALID AT ANY POINT IN TIME. BOTH THE POINTERS SHOULD NOT BE
     * IN AN INITIALIZED STATE SIMULTANEOUSLY. A MODULE CAN NOT HAVE
     * MORE THAN ONE PRODUCER/CONSUMER
     */

    // Pointer to a a_text_source producer of this prefilter object
    // The prefilter must use this pointer to communicate with its producer
    // as the database server might replace this pointer in case character set
    // conversion between the prefilter and its producer is required
    a_text_source *_my_text_producer;

    // Pointer to a a_word_source producer of this prefilter module.
    // This field is reserved for FUTER USE and should be set to NULL 
    // for the current version of the API.
    a_word_source *_my_word_producer;

    /* NOTE: FOLLOWING TWO POINTERS ARE KEPT FOR FUTURE USE. THEY
     * SHOULD BE SET TO NULL FOR THIS RELEASE
     */

    // Pointer to the a_text_source consumer
    a_text_source *_my_text_consumer;

    // Pointer to a a_word_source consumer
    a_word_source *_my_word_consumer;
} a_text_source, *p_text_source;

typedef struct a_init_pre_filter
{
    // Holds the pointer to the text producer of the new prefilter
    // This value is initialized by the caller of the
    // entry point function
    a_text_source *in_text_source;

    // This value is set to 1 if the data being passed to the prefilter
    // is binary, and is set to 0 otherwise.
    // If this value is set to 1, no charset conversion is done on the
    // input to the prefilter, even if actual_charset handled by this
    // prefilter is different than the desired_charset
    short is_binary;

    // Desired charset. This value is initialized by the caller of the
    // entry point function to the character set of the input data (the
    // character set of the text index for which the prefilter is initialized)
    const char* desired_charset;

    // The external library should initialize this pointer to point to the new
    // prefilter object containing all the function and value pointers as
    // required by a_text_source interface
    a_text_source *out_text_source;

    // charset supported by the external library. The database server will
    // expect the prefilter output to be in this character set. If is_binary
    // is 0, input data for this prefilter will also be converted to this
    // character set
    char* actual_charset;
} a_init_pre_filter, *p_init_pre_filter;

#if defined(__cplusplus)
}
#endif

#if defined( _SQL_PACK_STRUCTURES )
    #include "poppk.h"
    #if defined( _MSC_VER ) && _MSC_VER > 800
        #pragma warning(pop)
    #endif
#endif

#endif //_EXTPFAPI_H_INCLUDE
