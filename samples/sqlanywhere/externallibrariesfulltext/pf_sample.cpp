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
// pf_sample.cpp :
// Defines the exported functions and interfaces for prefilter DLL.
// Error numbers in this file are selected arbitrarily.

#include "string.h"
#include "extpfapiv1.h"

#if defined( _SQL_OS_WINNT )
    #if defined( _MSC_VER )
    #define DLL_FN __stdcall
    #else
    #define DLL_FN __declspec(dllexport) __stdcall
    #endif
#elif defined( UNIX )
    #define DLL_FN
#endif

#define MAX_TEXT_LENGTH 200

/**
 * This class implements the a_text_source interface to perform very
 * basic prefiltering of XML or HTML data. No checking of validity of the
 * document is done except for checking that all the tags are closed.
 */
class TAG_filter : public a_text_source {
public:
    TAG_filter();
    ~TAG_filter();

    // This method actually returns the data as requested by get_next_piece
    // function of the a_text_source interface
    a_sql_uint32 GetPiece( unsigned char **buffer, a_sql_uint32 *buf_len );

    a_sql_uint64 GetCurrentLength() const
    {
	return _length_so_far;
    }

    void BeginDocument()
    {
	_length_so_far = 0;
	_out_buf_pos = 0;
	_counter = 0;
    }

private:
    a_byte	    *_in_buffer;	// Input data from the producer
    a_byte	    *_out_buffer;	// Output buffer - pointer to it will
					// be returned to the consumer upon
					// the call to get_next_piece method
					// of the prefilter
    a_sql_uint32    _in_buf_pos;	// Current position in the input buffer
    a_sql_uint32    _in_buf_len;	// Current length of the input buffer
    a_sql_uint64    _length_so_far;	// Length of the filtered data
					// produced so far for the current
					// document
    a_sql_uint32    _out_buf_pos;	// Current position in the output
					// buffer
    short	    _counter;		// Count of the number of tag opening
					// symbols (<) seen so far without
					// tag closing symbols (>). Should be
					// 0 or 1.
};

extern "C"
a_sql_uint32 SQL_CALLBACK pf_begin_document( a_text_source *This )
/****************************************************************/
/**
 * Implementation of the begin_document function of the a_text_source interface.
 * Performs local initializations for a document, and passes the call on to
 * its producer.
 * Returns the return code of the producer.
 */
{
    // Perform per-document initialization
    (static_cast< TAG_filter * >(This))->BeginDocument();

    // Propagate the call to the producer
    return This->_my_text_producer->begin_document( This->_my_text_producer );
}

extern "C"
a_sql_uint32 SQL_CALLBACK pf_get_next_piece( a_text_source	*This,
					     unsigned char	**buffer,
					     a_sql_uint32	*buf_len )
/************************************************************************/
/**
 * Implementation of the get_next_piece method of the a_text_source
 * interface.
 * Returns a self-allocated buffer of filtered data, along with the length
 * of data in the buffer in the OUT parameters.
 * Returns 0 if the execution was successfull and uninterrupted, 1 otherwise.
 */
{
    return ( static_cast< TAG_filter * >(This) )->GetPiece( buffer, buf_len );
}

extern "C"
a_sql_uint64 SQL_CALLBACK pf_get_document_size( a_text_source *This )
/*******************************************************************/
/**
 * Implementation of the get_document_size method of the a_text_source
 * interface.
 * Returns the length of the data produced so far for the current document.
 * The expectation is that this method will be called once all the data
 * for the document is processed, right before or after the call to the
 * end_document.
 */
{
    return ( static_cast< TAG_filter * >(This) )->GetCurrentLength();
}

extern "C"
a_sql_uint32 SQL_CALLBACK pf_end_document( a_text_source *This )
/**************************************************************/
/**
 * Implementation of the end_document method of the a_text_source interface.
 * Passes the call on to the producer as there is no document-specific
 * cleanup to perform in this prefilter.
 * Returns the return code of the producer.
 */
{
    return This->_my_text_producer->end_document( This->_my_text_producer );
}

extern "C"
a_sql_uint32 SQL_CALLBACK pf_fini_all( a_text_source *This )
/**********************************************************/
/**
 * Implementation of the fini_all method of the a_text_source interface.
 * Passes the call on to the producer of this prefilter, then deletes
 * the prefilter.
 * Returns the return code of the producer, as the cleanup of this prefilter
 * is always successful.
 */
{
    TAG_filter	    *pf	    = static_cast<TAG_filter*>(This);
    a_sql_uint32    ret	    = 0;

    if( This->_my_text_producer != NULL ) {
	// Propagate the call to the producer
	ret = This->_my_text_producer->fini_all( This->_my_text_producer );
    }

    delete pf;
    return ret;
}

TAG_filter::TAG_filter()
/**********************/
{
    // Initialize the function pointers required for the a_text_source
    // interface
    begin_document = &pf_begin_document;
    get_next_piece = &pf_get_next_piece;
    end_document = &pf_end_document;
    get_document_size = &pf_get_document_size;
    fini_all = &pf_fini_all;

    // Initialize the data members of the a_text_source interface
    _my_text_producer = NULL;
    _my_word_producer = NULL;
    _my_text_consumer = NULL;
    _my_word_consumer = NULL;
    _context = NULL;

    // Initialize the output buffer
    _out_buffer = new a_byte[ MAX_TEXT_LENGTH ];

    // Initialize the input-related variables
    _in_buffer = NULL;
    _in_buf_pos = 0;
    _in_buf_len = 0;

    _length_so_far = 0;
}

TAG_filter::~TAG_filter()
/***********************/
{
    delete [] _out_buffer;
    _out_buffer = NULL;
}

a_sql_uint32
TAG_filter::GetPiece( unsigned char **buffer, a_sql_uint32 *buf_len )
/*******************************************************************/
/**
 * Main action performed by the prefilter.
 * This method obtains input from the producer as necessary, filters the
 * data and places the output into the output buffer, then passes the
 * pointer to the output buffer and the length of the output back as OUT
 * parameters.
 * Returns 0 if the execution was successfull and uninterrupted, 1 otherwise.
 */
{
    for( ;; ) {
        if( _in_buf_pos == 0 || _in_buf_pos == _in_buf_len ) {
	    // Either the beginning of the document processing or
	    // all the input received so far was consumed.
            // Reset the input-related variables.
	    _in_buf_len = 0;
	    _in_buf_pos = 0;

	    // Check if the operation was interrupted
	    if( _context->get_is_cancelled( _context ) == 1 ) {
		char * msg = "Prefiltering interrupted";
		_context->log_message( _context, msg, ( short )strlen( msg ) );
		return 1;
	    }

	    // Get data from the producer
	    _my_text_producer->get_next_piece(
			    _my_text_producer, &_in_buffer, &_in_buf_len );

	    if( _in_buf_len == 0 ) {
		// No more data from the producer
                if( _counter > 0 ) {
		    // Error - unclosed tag
                    *buf_len = 0;
                    *buffer = NULL;
		    if( _context != NULL ) {
			// Error - tag opened but not closed in the document
			char *  msg =
				"Unclosed tag encountered in the document";
			_context->set_error( _context, 18001, msg,
					( short )strlen( msg ) );
		    }
		    return 1;
                } else {
		    // Return the data produced so far, and mark all
		    // the produced data was returned to the consumer
                    *buf_len = _out_buf_pos;
                    *buffer = _out_buffer;
		    _out_buf_pos = 0;
		    return 0;
                }
	    }
        }

	while( _in_buf_pos < _in_buf_len ) {
	    // While there is input data to process in the current chunk
	    if( _in_buffer[ _in_buf_pos ] == '<' ) {
		if( _counter > 0 ) {
		    // Error - tag opening before the previous tag was closed
		    if( _context != NULL ) {
			char *	msg =
				"Tag opening before previous tag is closed";
			_context->set_error( _context, 18002, msg,
					( short )strlen( msg ) );
		    }
		    return 1;
		}

		// Increment tag counter
                ++_counter;

		// Output a space in case there is no space before and after
		// the removed tag
		_out_buffer[ _out_buf_pos ] = ' ';
		++_out_buf_pos;

            } else if( _in_buffer[ _in_buf_pos ] == '>' ) {
		if( _counter != 1 ) {
		    // Error - tag closing a second time
		    if( _context != NULL ) {
			char *	msg =
				"Tag closed too many times";
			_context->set_error( _context, 18003, msg,
					( short )strlen( msg ) );
		    }
		    return 1;
		}
		// Decrement the tag counter
                --_counter;

            } else if( _counter == 0 ) {
		// Copy data from input to output buffer
                _out_buffer[ _out_buf_pos ] = _in_buffer[ _in_buf_pos ];
                ++_out_buf_pos;
                ++_length_so_far;
            } // else current character is within a tag - ignore it

	    // Advance to the next input character
            ++_in_buf_pos;

            if( _out_buf_pos == MAX_TEXT_LENGTH ) {
		// Output buffer is full - return to the consumer, mark
		// all the produced data as consumed
                *buf_len = _out_buf_pos;
                *buffer = _out_buffer;
                _out_buf_pos = 0;
		return 0;
            }
        } // end of while( _in_buf_pos < _in_buf_len ) loop
    } // end of for( ;; )
}

#ifdef __cplusplus
extern "C"
#endif // __cplusplus
a_sql_uint32 DLL_FN tag_filter( a_init_pre_filter *pf_init )
/**********************************************************/
/**
 * Implementation of the entry point function of this prefilter library.
 * Sets up and returns an instance of the prefilter (TAG_filter).
 */
{
    a_text_source	    *ts	    = new TAG_filter();

    // Copy producer and context pointers into the prefilter
    ts->_my_text_producer = pf_init->in_text_source;
    ts->_context = pf_init->in_text_source->_context;

    // Set up the return values
    pf_init->out_text_source = ts;
    // actual_charset is not modified here since this prefilter library works
    // independent of the input data character set - the characters it is
    // looking up or introducing into the output data are expected to be
    // represented by the same values in all character sets encountered.
    // Those values are <, > and space.

    // The setup of the prefilter always succeeds
    return 0;
}

#ifdef __cplusplus
extern "C"
#endif // __cplusplus
a_sql_uint32 DLL_FN extpf_use_new_api()
/*************************************/
/**
 * Implementation of the extpf_use_new_api function requred for the prefilter
 * library.
 */
{
    return EXTPF_V1_API;
}
