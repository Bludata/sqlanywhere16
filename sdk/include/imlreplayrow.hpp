// *****************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// *****************************************************
#ifndef _IMLREPLAYROW_HPP_INCLUDED
#define _IMLREPLAYROW_HPP_INCLUDED

#include "sqltype.h"

class IMLReplayRow {
    public:
	virtual ~IMLReplayRow( void )
	/***************************/
	{
	}

	/*
	 * The following methods append the specified data to the row.  If src
	 * is NULL (for method were src is a pointer), these methods will return
	 * false.
	 *
	 * colName - the name of the column
	 * src     - the data to append
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendUShort( const char *colName, asa_uint16 src ) = 0;

	virtual bool AppendSShort( const char *colName, asa_int16 src ) = 0;

	virtual bool AppendULong( const char *colName, asa_uint32 src ) = 0;

	virtual bool AppendSLong( const char *colName, asa_int32 src ) = 0;

	virtual bool AppendUBig( const char *colName, asa_uint64 src ) = 0;

	virtual bool AppendSBig( const char *colName, asa_int64 src ) = 0;

	virtual bool AppendTiny( const char *colName, asa_uint8 src ) = 0;

	virtual bool AppendBit( const char *colName, asa_uint8 src ) = 0;

	virtual bool AppendDate( const char *colName, const char *src ) = 0;

	virtual bool AppendTime( const char *colName, const char *src ) = 0;

	virtual bool AppendTimestamp( const char *colName, const char *src ) = 0;

	virtual bool AppendTimestampTZ( const char *colName, const char *src ) = 0;

	virtual bool AppendReal( const char *colName, float src ) = 0;

	virtual bool AppendDouble( const char *colName, double src ) = 0;

	virtual bool AppendNumeric( const char *colName, const char *src ) = 0;

	virtual bool AppendUUID( const char *colName, const unsigned char *src ) = 0;
	/*
	 * The following methods append the specified data to the row.  If src
	 * is NULL these method will return false.
	 *
	 * colName - the name of the column
	 * src     - the data to append
	 * length  - the number of bytes of data in src
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendBinary( const char		*colName,
				   const unsigned char	*src,
				   asa_uint32		length ) = 0;

	virtual bool AppendString( const char		*colName,
				   const unsigned char	*src,
				   asa_uint32		length ) = 0;

	virtual bool AppendFixchar( const char		*colName,
				    const unsigned char	*src,
				    asa_uint32		length ) = 0;

	virtual bool AppendVarchar( const char		*colName,
				    const unsigned char	*src,
				    asa_uint32		length ) = 0;

	virtual bool AppendVarbinary( const char		*colName,
				      const unsigned char	*src,
				      asa_uint32		length ) = 0;

	virtual bool AppendVarbit( const char		*colName,
				   const unsigned char	*src,
				   asa_uint32		length ) = 0;

	virtual bool AppendNChar( const char		*colName,
				  const unsigned char	*src,
				  asa_uint32		length ) = 0;

	virtual bool AppendNVarchar( const char			*colName,
				     const unsigned char	*src,
				     asa_uint32			length ) = 0;
	/*
	 * The following methods append the specified data to the row.  If src
	 * is NULL and the row is not for a delete, these method will return false.
	 *
	 * colName - the name of the column
	 * src     - the data to append
	 * length  - the number of bytes of data in src
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendLongNVarchar( const char		*colName,
					 const unsigned char	*src,
					 asa_uint32		length ) = 0;

	virtual bool AppendLongVarchar( const char		*colName,
					const unsigned char	*src,
					asa_uint32		length ) = 0;

	virtual bool AppendLongBinary( const char		*colName,
				       const unsigned char	*src,
				       asa_uint32		length ) = 0;

	virtual bool AppendJava( const char		*colName,
				 const unsigned char	*src,
				 asa_uint32		length ) = 0;

	virtual bool AppendXML( const char		*colName,
				const unsigned char	*src,
				asa_uint32		length ) = 0;

	virtual bool AppendSerialization( const char		*colName,
					  const unsigned char	*src,
					  asa_uint32		length ) = 0;

	virtual bool AppendLongVarbit( const char		*colName,
				       const unsigned char	*src,
				       asa_uint32		length ) = 0;

	/*
	 * The following method appends the specified data to the row.  If src
	 * is NULL, isDBMLSync is true, and the row is not for a delete, this
	 * method will return false.
	 *
	 * colName	- the name of the column
	 * src		- the data to append
	 * srid		- the srid for the geometry value
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendGeometry( const char	*colName,
				     const char	*src,
				     asa_int32	srid ) = 0;
	/*
	 * The following methods append the specified data to the row.  If the
	 * data is NULL (the isNull parameter is true), the data will not be
	 * added but instead the corresponding NULL bit will be set in the bit
	 * bytes part of the row.
	 *
	 * colName  - the name of the column
	 * src      - the data to append
	 * isNull   - whether or not it is null
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendNullableUShort( const char	*colName,
					   asa_uint16	src,
					   bool		isNull ) = 0;

	virtual bool AppendNullableSShort( const char	*colName,
					   asa_int16	src,
					   bool		isNull ) = 0;

	virtual bool AppendNullableULong( const char	*colName,
					  asa_uint32	src,
					  bool		isNull ) = 0;

	virtual bool AppendNullableSLong( const char	*colName,
					  asa_int32	src,
					  bool		isNull ) = 0;

	virtual bool AppendNullableUBig( const char	*colName,
					 asa_uint64	src,
					 bool		isNull ) = 0;

	virtual bool AppendNullableSBig( const char	*colName,
					 asa_int64	src,
					 bool		isNull ) = 0;

	virtual bool AppendNullableTiny( const char	*colName,
					 asa_uint8	src,
					 bool		isNull ) = 0;

	virtual bool AppendNullableBit( const char	*colName,
					asa_uint8	src,
				       	bool		isNull ) = 0;

	virtual bool AppendNullableReal( const char	*colName,
					 float		src,
					 bool		isNull ) = 0;

	virtual bool AppendNullableDouble( const char	*colName,
					   double	src,
					   bool		isNull ) = 0;
	/*
	 * The following methods append the specified data to the row.  If the
	 * src is NULL, the data will not be added but instead the corresponding
	 * NULL bit will be set in the bit bytes part of the row.
	 *
	 * colName - the name of the column
	 * src     - the data to append
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendNullableDate( const char *colName, const char *src ) = 0;

	virtual bool AppendNullableTime( const char *colName, const char *src ) = 0;

	virtual bool AppendNullableTimestamp( const char *colName, const char *src ) = 0;

	virtual bool AppendNullableTimestampTZ( const char *colName, const char *src ) = 0;

	virtual bool AppendNullableNumeric( const char *colName, const char *src ) = 0;

	virtual bool AppendNullableUUID( const char		*colName,
					 const unsigned char	*src ) = 0;
	/*
	 * The following methods append the specified data to the row.  If the
	 * src is NULL, the data will not be added but instead the corresponding
	 * NULL bit will be set in the bit bytes part of the row.
	 *
	 * colName - the name of the column
	 * src     - the data to append
	 * length  - the number of bytes of data in src
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendNullableBinary( const char		*colName,
					   const unsigned char	*src,
					   asa_uint32		length ) = 0;

	virtual bool AppendNullableString( const char		*colName,
					   const unsigned char	*src,
					   asa_uint32		length ) = 0;

	virtual bool AppendNullableFixchar( const char		*colName,
					    const unsigned char	*src,
					    asa_uint32		length ) = 0;

	virtual bool AppendNullableVarchar( const char		*colName,
					    const unsigned char	*src,
					    asa_uint32		length ) = 0;

	virtual bool AppendNullableVarbinary( const char		*colName,
					      const unsigned char	*src,
					      asa_uint32		length ) = 0;

	virtual bool AppendNullableVarbit( const char		*colName,
					   const unsigned char	*src,
					   asa_uint32		length ) = 0;

	virtual bool AppendNullableNChar( const char		*colName,
					  const unsigned char	*src,
					  asa_uint32		length ) = 0;

	virtual bool AppendNullableNVarchar( const char			*colName,
					     const unsigned char	*src,
					     asa_uint32			length ) = 0;

	virtual bool AppendNullableLongNVarchar( const char		*colName,
						 const unsigned char	*src,
						 asa_uint32		length ) = 0;

	virtual bool AppendNullableLongVarchar( const char		*colName,
						const unsigned char	*src,
						asa_uint32		length ) = 0;

	virtual bool AppendNullableLongBinary( const char		*colName,
					       const unsigned char	*src,
					       asa_uint32		length ) = 0;

	virtual bool AppendNullableJava( const char		*colName,
					 const unsigned char	*src,
					 asa_uint32		length ) = 0;

	virtual bool AppendNullableXML( const char		*colName,
					const unsigned char	*src,
					asa_uint32		length ) = 0;

	virtual bool AppendNullableSerialization( const char		*colName,
						  const unsigned char	*src,
						  asa_uint32		length ) = 0;

	virtual bool AppendNullableLongVarbit( const char		*colName,
					       const unsigned char	*src,
					       asa_uint32		length ) = 0;

	/*
	 * The following method appends the specified data to the row.
	 *
	 * colName	- the name of the column
	 * src		- the data to append
	 * srid		- the srid for the geometry value
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool AppendNullableGeometry( const char	*colName,
					     const char	*src,
					     asa_int32	srid ) = 0;
	/*
	 * This method should be called when all data has been appended to the
	 * row so that any operations required once all the data is appended can
	 * be performed.
	 *
	 * Returns true if the operation succeeds; otherwise false.
	 */
	virtual bool DoneAppend( void ) = 0;

	/*
	 * Sets flags for appending the columns.
	 */
	virtual void SetFlags( asa_uint16 flags ) = 0;
};

#endif
