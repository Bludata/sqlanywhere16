-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- This sample code is provided AS IS, without warranty or liability of
-- any kind.
-- 
-- You may use, reproduce, modify and distribute this sample code without
-- limitation, on the condition that you retain the foregoing copyright 
-- notice and disclaimer as to the original code.  
-- 
-- *******************************************************************

-- Install the datatype.php script into the database as 'datatype'
INSTALL EXTERNAL OBJECT 'phpdatatype' NEW FROM FILE 'datatype.php' ENVIRONMENT php;


-- PHP can only return strings, let's check that
CREATE FUNCTION FetchPhpString( IN pick int, IN str1 char(128), IN str2 char(128) ) RETURNS char(128)
    EXTERNAL NAME '<file=phpdatatype> print fetch_string( $argv[1], $argv[2], $argv[3] )'
    LANGUAGE php;

-- Call the above function to retrieve the string datatype
-- Should return the value string 1 
SELECT FetchPhpString(1, 'string 1', 'string 2');

-- Procedure which call PHP to return various datatypes in output variables
-- note that PHP doesn't support unsigned integers, nor integers bigger than
-- 32-bits, so anything above that must be passed as a double
CREATE PROCEDURE FetchPhpOuts( INOUT b bit, INOUT s smallint, 
                               INOUT us unsigned smallint,
                               INOUT i integer, INOUT ui unsigned integer,
                               INOUT big bigint, INOUT dub double,
			       INOUT str long varchar )
    EXTERNAL NAME '<file=phpdatatype> $argv[1] = fetch_bit( $argv[1] ); 
                                      $argv[2] = fetch_smallint( $argv[2] ); 
                                      $argv[3] = fetch_usmallint( $argv[3] ); 
                                      $argv[4] = fetch_int( $argv[4] ); 
                                      $argv[5] = fetch_uint( $argv[5] ); 
                                      $argv[6] = fetch_bigint( $argv[6] ); 
                                      $argv[7] = fetch_double( $argv[7] ); 
                                      $argv[8] = fetch_string( 3, $argv[8], 
                                          " returned in an output variable" );'
    LANGUAGE php;
    
-- Create variables and call the FetchPhpOuts procedure
CREATE VARIABLE @b bit;
CREATE VARIABLE @s smallint;
CREATE VARIABLE @us unsigned smallint;
CREATE VARIABLE @i integer;
CREATE VARIABLE @ui unsigned integer;
CREATE VARIABLE @big bigint;
CREATE VARIABLE @double double;
CREATE VARIABLE @str long varchar;

SET @b = 1;
SET @s = 20;
SET @us = 300;
SET @i = 1;
SET @ui = 9000000;
SET @big = 700;
SET @double = 1.30000;
SET @str = 'this is a string';

CALL FetchPhpOuts(@b, @s, @us, @i, @ui, @big, @double, @str);

-- Verify the output variables, the values should be:
-- 0, -16020, 32300, -2000000001, 3009000000, -17000000000700, 4.4415, this is a string returned in an output variable
SELECT @b, @s, @us, @i, @ui, @big, @double, @str

