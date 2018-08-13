// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************

#ifndef _MLREPLAYCVECTOR_HPP_INCLUDED
#define _MLREPLAYCVECTOR_HPP_INCLUDED

#include "sqltype.h"
#include <stddef.h>
#include <string.h>

#define DEFAULT_GROWTH_FACTOR 2.0

/*
 * An implementation of a simple vector that is optimized for C types.
 */
template <class T>
class MLReplayCVector {
    public:
	/*
	 * growthFactor - the factor used to grow the vector
	 */
	explicit MLReplayCVector( float growthFactor = DEFAULT_GROWTH_FACTOR ) :
	/********************************************************************/
	    _data( NULL ),
	    _capacity( 0 ),
	    _used( 0 ),
	    _growthFactor( growthFactor )
	{
	}

	~MLReplayCVector( void )
	/**********************/
	{
	    Fini();
	}

	/*
	 * startingLen - the initial capacity of the vector
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool Init( asa_uint32 startingLength = 10 )
	/*****************************************/
	{
	    _capacity = startingLength;
	    _data = new T[ _capacity ];

	    return( NULL != _data );
	}

	void Fini( void )
	/***************/
	{
	    if( NULL != _data ) {
		delete [] _data;
		_used = 0;
		_capacity = 0;
		_data = NULL;
	    }
	}

	/*
	 * Adds elem to the vector at the given index.  Everything in the
	 * vector at index and onwards will be shifted one spot so that
	 * nothing is overwritten.
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool Add( asa_uint32 index, T &elem )
	/***********************************/
	{
	    bool	ok	= true;

	    if( !grow() ) {
		ok = false;
	    } else {
		// Shift everything after the new element.
		if( index < _used ) {
		    memmove( &_data[ index + 1 ],
			     &_data[ index ],
			     sizeof( T ) * ( _used - index ) );
		}

		_data[ index ] = elem;
		++_used;
	    }

	    return( ok );
	}

	/*
	 * Appends elem to the end of the vector.
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool Append( T &elem )
	/********************/
	{
	    return( Add( _used, elem ) );
	}

	/*
	 * Adds all elements in vec to this vector.
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool Append( MLReplayCVector< T > &vec )
	/**************************************/
	{
	    bool	ok	= true;

	    if( !grow( vec._used ) ) {
		ok = false;
	    } else {
		memmove( &_data[ _used ], vec._data, sizeof( T ) * vec._used );
		_used += vec._used;
	    }

	    return( ok );
	}

	/*
	 * Removes the element at the given index.  The data will be shifted so
	 * that there is no holes in the vector.
	 */
	void Remove( asa_uint32 index )
	/*****************************/
	{
	    if( index < ( _used - 1 ) ) {
		memmove( &_data[ index ],
			 &_data[ index + 1 ],
			 sizeof( T ) * ( _used - index + 1 ) );
	    }

	    --_used;
	}

	/*
	 * Returns the element at the given index.
	 */
	T & operator[]( asa_uint32 index )
	/********************************/
	{
	    return( _data[ index ] );
	}

	/*
	 * Returns the element at the given index.
	 */
	const T & operator[]( asa_uint32 index ) const
	/********************************************/
	{
	    return( _data[ index ] );
	}

	/*
	 * Returns how many elements are in the vector.
	 */
	asa_uint32 GetSize( void ) const
	/******************************/
	{
	    return( _used );
	}

	/*
	 * Clears the vector.
	 */
	void Clear( void )
	/****************/
	{
	    _used = 0;
	}
	
	/*
	 * Shrinks the vector so that there is no empty places in _data.
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool ShrinkToFit( void )
	/**********************/
	{
	    T		*newData	= NULL;
	    bool	ok		= true;

	    if( _capacity > _used ) {
		newData = new T[ _used ];

		if( NULL != newData ) {
		    _capacity = _used;
		    memmove( newData, _data, sizeof( T ) * _used );
		    delete [] _data;
		    _data = newData;
		} else {
		    ok = false;
		}
	    }

	    return( ok );
	}

    private:
	T		*_data;
	asa_uint32	_capacity;
	asa_uint32	_used;
	float		_growthFactor;

	/*
	 * Grows the vector by the given growth factor if necessary.
	 *
	 * minAmount - the minimum amount of new elements that should be
	 *             able to fit in the vector
	 *
	 * Returns true if the operation was successful; otherwise false.
	 */
	bool grow( asa_uint32 minAmount = 1 )
	/***********************************/
	{
	    T		*newData	= NULL;
	    asa_uint32	newCapacity	= 0;
	    bool	ok		= true;

	    if( ( _used + minAmount ) > _capacity ) {
		newCapacity = static_cast< asa_uint32 >( _capacity * _growthFactor );

		if( newCapacity <= _capacity ) {
		    // Incase our growth factor is <= 1.
		    newCapacity += _capacity;
		}

		if( newCapacity < ( _used + minAmount ) ) {
		    newCapacity += minAmount;
		}

		_capacity = newCapacity;

		newData = new T[ _capacity ];

		if( NULL == newData ) {
		    ok = false;
		} else {
		    memmove( newData, _data, sizeof( T ) * _used );
		    delete [] _data;
		    _data = newData;
		}
	    }

	    return( ok );
	}
};

#endif
