// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of
// any kind.
//
// You may use, reproduce, modify and distribute this sample code without
// limitation, on the condition that you retain the foregoing copyright
// notice and disclaimer as to the original code.
//
// *******************************************************************
// tb_sample.cpp :
// Defines the exported functions and interfaces for external term breaker
// library used with full text search

#include <ctype.h>
#include "assert.h"
#include "string.h"
#include "exttbapiv1.h"
#include "extpfapiv1.h"

#if defined( _SQL_OS_WINNT )
    #if defined( _MSC_VER )
    #define DLL_FN __stdcall
    #else
    #define DLL_FN __declspec(dllexport) __stdcall
    #endif
#elif defined( UNIX )
    #define DLL_FN
    #define _stricmp	strcasecmp
#endif

// Maximum length of a term that can be produced by this term breaker.
// This value is chosen to match the maximum number of characters allowed
// in a single term by SQL Anywhere server.
#define MAX_TERM_LENGTH 61

// Maximum number of the terms this term breaker will return in the buffer.
// This number was chosen arbitrarily and should be adjusted based on the
// application needs. The number may be different between depending on the
// term_breaker_for field passed into the entry point function - a larger
// number of terms will be expected in a document in case the pipeline
// is created for document parsing than for query element parsing.
#define MAX_TERMS 10

bool allow_in_word( char c )
/**************************/
/**
 * Returns true if the token is an apostrophe (is allowed to be a part
 * of the term according to the rules of this term breaker), and false
 * otherwise
 */
{
    switch( c ) {
	case '\'':
	case '`':
	    return true;
	default:
	    return false;
    }
}

/**
 * This class implements the a_word_source interface to perform term
 * breaking for full text search.
 * This term breaker allows characters and digits (as defined by the
 * isalnum() function) to be part of the terms.
 * Apostrophes are also included as part of the terms.
 *
 * The terms produced by this term breaker are in lower case.
 */
class Termbreaker : public a_word_source {
public:
    Termbreaker();
    ~Termbreaker();

    // This method processes the input data and generates terms according to the
    // term breaking and processing rules stated above
    a_sql_uint32 GetWords(a_term **words, a_sql_uint32 *num_words);

    void BeginDocument( a_sql_uint32 is_prefix )
    {
	_term_pos_in_doc = 1;
	_is_prefix = is_prefix;
    }


private:
    a_byte	    *_in_buffer;	// Input data from the producer
    a_term	    _words[MAX_TERMS];	// Output buffer - pointer to it will
					// be returned to the consumer upon
					// the call to the get_words method of
					// the term breaker
    a_byte	    _last_partial_term[MAX_TERM_LENGTH]; // A buffer that
					// accumulates partial term data
    a_sql_uint32    _in_buf_pos;	// Current position in the input buffer
    a_sql_uint32    _in_buf_len;	// Current length of the input buffer
    a_sql_uint32    _last_term_pos;	// Position within the term currently
					// being read from the input byte
					// array
    a_sql_uint32    _term_pos_in_doc;	// Position of the term currently
					// being read in the document
    a_sql_uint32    _is_prefix;		// true if the document currently
					// being processed is a prefix term
					// from a CONTAINS query - at least
					// one term has to be returned
};

extern "C"
a_sql_uint32 SQL_CALLBACK tb_begin_document( a_word_source  *This,
					     a_sql_uint32   is_prefix )
/*********************************************************************/
/**
 * Implementation of the begin_document function of the a_word_source interface.
 * Performs local initializations for a document, and passes the call on to
 * the producer.
 * Returns the return code of the producer.
 */
{
    // Perform per-document initialization of the term breaker
    (static_cast<Termbreaker*>(This))->BeginDocument( is_prefix );

    // Propagate the call to the producer
    return This->_my_text_producer->begin_document(This->_my_text_producer);
}

extern "C"
a_sql_uint32 SQL_CALLBACK tb_get_words( a_word_source	    *This
					, a_term	    **words
					, a_sql_uint32	    *num_words )
/**********************************************************************/
/**
 * Implementation of the get_words method of the a_word_source interface.
 * Returns a self-allocated buffer of a_term structures, where each a_term
 * structure represents a term in the input document. The buffer of terms
 * and the number of words returned in it are passed back in the OUT
 * parameters.
 */
{
    return static_cast<Termbreaker*>(This)->GetWords(words, num_words);
}

extern "C"
a_sql_uint32 SQL_CALLBACK tb_end_document( a_word_source *This )
/**************************************************************/
/**
 * Implementation of the end_document method of the a_word_source interface.
 * Passes the call on to the producer as there is no document-specific
 * cleanup to perform in this term breaker.
 * Returns the return code of the producer.
 */
{
    return This->_my_text_producer->end_document( This->_my_text_producer );
}

extern "C"
a_sql_uint32 SQL_CALLBACK tb_fini_all( a_word_source *This )
/**********************************************************/
/**
 * Implementation of the fini_all method of the a_word_source interface.
 * Passes the call on to the producer of this term breaker, then deletes
 * the term breaker.
 * Returns the return code of the producer, as the cleanup of this term breaker
 * is always successful.
 */
{
    Termbreaker	    *my_term_breaker	= static_cast<Termbreaker*>(This);
    a_sql_uint32    ret			= 0;

    // Propagate the call to the producer
    ret = This->_my_text_producer->fini_all( This->_my_text_producer );

    delete my_term_breaker;
    return ret;
}

Termbreaker::Termbreaker()
/************************/
{
    // Initialize the function pointers required for the a_word_source
    // interface
    begin_document = &tb_begin_document;
    get_words = &tb_get_words;
    end_document = &tb_end_document;
    fini_all = &tb_fini_all;

    // Initialize the data members of the a_word_source interface
    _my_text_producer = NULL;
    _my_word_producer = NULL;
    _my_text_consumer = NULL;
    _my_word_consumer = NULL;
    _context = NULL;

    for( int i = 0; i < MAX_TERMS; i++ ) {
	// Allocate space for term storage
	_words[ i ].word = new a_byte[ MAX_TERM_LENGTH ];
    }

    // Initialize input-related variables
    _in_buffer = 0;
    _in_buf_pos = 0;
    _in_buf_len = 0;

    // Initialize variables related to the current term
    _last_partial_term[0] = '\0';
    _last_term_pos = 0;
}

Termbreaker::~Termbreaker()
/*************************/
{
    for(int i = 0; i < MAX_TERMS; i++) {
	// Free up the space allocated for term storage
	delete [] _words[i].word;
    }
}

a_sql_uint32 Termbreaker::GetWords( a_term **words, a_sql_uint32 *num_words )
/***************************************************************************/
/**
 * Main action performed by the term breaker.
 * This method obtains input data from the producer as necessary and
 * extracts terms from the input bytes. Each generated term is annotated
 * with its length and position within the document.
 *
 * Returns 0 if the execution was uninterrupted, and 1 otherwise.
 *
 * Note that this term breaker does not generate any errors - all input data
 * is assumed valid and is handled as such.
 */
{
    // True if at least one character of the next term is found
    bool word_found = false;
    // Number of terms produced so far. Also marks the position in the output
    // array
    int last_word_pos = 0;
    // Current character
    char c;

    for( ;; ) {
	if(_in_buf_pos == 0 || _in_buf_pos == _in_buf_len) {
	    // Either the beginning of the document processing, or all the
	    // input data received so far was consumed.
	    // Reset the input-related variables.
	    _in_buf_len = 0;
	    _in_buf_pos = 0;

	    // Check if the operation was interrupted
	    if( _context->get_is_cancelled( _context ) == 1 ) {
		char * msg = "Term breaking interrupted";
		_context->log_message( _context, msg, ( short )strlen( msg ) );
		return 1;
	    }

	    //Get data from the producer
	    _my_text_producer->get_next_piece( _my_text_producer,
					&_in_buffer, &_in_buf_len );
	    if( _in_buf_len == 0 ) {
		if( _last_term_pos > 0 || _is_prefix == 1 ) {
		    // Last term of the document was not generated yet
		    // OR
		    // Document being parsed is a prefix, and either there
		    // was no term in the document, or the data at the end
		    // of the document did not constitute a term

		    // Make sure the term is null-terminated.
		    // If _is_prefix == 1, the term may be of length 0.
		    if( _last_term_pos < MAX_TERM_LENGTH - 1 ) {
			_last_partial_term[ _last_term_pos ] = '\0';
		    } else {
			// Term that is too long - generate an empty term
			_last_partial_term[ 0 ] = '\0';
		    }

		    strcpy( (char *)( _words[last_word_pos].word ),
				    (const char *)_last_partial_term );

		    // This term breaker accepts only single-byte characters
		    _words[ last_word_pos ].len = _last_term_pos;
		    _words[ last_word_pos ].ch_len = _last_term_pos;
		    _words[last_word_pos].pos = _term_pos_in_doc;

		    ++last_word_pos;
		    _last_term_pos = 0;
		    _is_prefix = 0;
		}

		*num_words = last_word_pos;
		*words = _words;
		return 0;
	    }
	}

	//We have a chunk of input data, parse it and extract terms
	while( _in_buf_pos < _in_buf_len ) {
	    c = _in_buffer[ _in_buf_pos ];

	    if( isalnum( c ) || allow_in_word( c ) ) {
		// Current character is part of a term
		if( _last_term_pos < MAX_TERM_LENGTH - 1 ) {
		    // The term is not longer than permitted - collect the
		    // character

		    // Want all text to be lower case
		    _last_partial_term[ _last_term_pos ] =
			    ( isupper( c ) != 0 ) ? (char)tolower( c ) : c;

		    if( !word_found ) {
			// Found a new word that needs to be output
			word_found = true;
		    }

		    ++_last_term_pos;
		} // else the term is longer than permitted by this term
		  // breaker - ignore the following bytes

	    } else if( word_found ) {
		// Found a character that is not part of a term, and the
		// previous characters constitute a term

		if( _last_term_pos < MAX_TERM_LENGTH ) {
		    // Valid term - output to the output array
		    _last_partial_term[ _last_term_pos ] = '\0';

		    strcpy( (char *)( _words[ last_word_pos ].word ),
					(const char *)_last_partial_term );

		    // This term breaker accepts only single byte characters
		    _words[ last_word_pos ].len = _last_term_pos;
		    _words[ last_word_pos ].ch_len = _last_term_pos;
		    _words[ last_word_pos ].pos = _term_pos_in_doc;
		    // Increment the number of terms produced
		    last_word_pos++;
		}

		// Even if the term was filtered based on the length, its
		// position has to be counted
		++_term_pos_in_doc;

		_last_term_pos = 0;
		word_found = false;

		if( last_word_pos == MAX_TERMS ) {
		    // Output buffer is full
		    *num_words = last_word_pos;
		    *words = _words;
		    return 0;
		}
	    } // else the character is not a part of a term and is not
	      // signaling the end of a term - do nothing

	    _in_buf_pos++;
	} // end of while( _in_buf_pos < _in_buf_len )
    } // end of for( ;; )
}

#ifdef __cplusplus
extern "C"
#endif // __cplusplus
a_sql_uint32 DLL_FN tb_sample( a_init_term_breaker *tb )
/******************************************************/
/**
 * Implementation of the entry point function of this term breaker library.
 * Sets up and returns an instance of the term breaker.
 */
{
    a_word_source	*ws	= new Termbreaker();

    // Copy producer and context pointers into the term breaker
    // It is expected that the database server might change the producer
    // pointer after getting the term breaker
    ws->_my_text_producer = tb->in_text_source;
    ws->_context = tb->in_text_source->_context;

    // Set up the return values
    tb->out_word_source = ws;

    // This term breaker library can only handle ASCII characters in terms.
    tb->actual_charset = "cp-1252";

  return 0;
}

#ifdef __cplusplus
extern "C"
#endif // __cplusplus
a_sql_uint32 DLL_FN exttb_use_new_api()
/**
 * Implementation of the exttb_use_new_api function requred for the prefilter
 * library.
 */
{
    return( EXTTB_V1_API );
}
