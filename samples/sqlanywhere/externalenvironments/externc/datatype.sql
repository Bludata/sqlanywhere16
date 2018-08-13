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

-- NOTE: this SQL file is meant to be run interactively. Execute each
-- statement individually and verify the results at each step.

-- Make sure you have built a dll containing the sample code in this
-- directory. Also make sure the dll is in the path so that it can be
-- found by the external environment.
-- For the purposes of this script, the assembly was named csqltest.dll
-- and the language used was c_odbc32. Adjustments will need to be made
-- for non-Windows platforms, as well any of the other c_odbc64, c_esql32
-- and c_esql64 languages can be used.

-- Procedure for setting the values of the various types
CREATE PROCEDURE CSetUp( IN t tinyint, IN s smallint, IN us unsigned smallint,
                         IN i int, IN ui unsigned int, IN big bigint,
			 IN ubig unsigned bigint, IN f float, IN d double )
    EXTERNAL NAME 'SetDataTypes@csqltest'
    LANGUAGE c_odbc32;
    
-- Set the various datatype values
CALL CSetUp( 1, -16000, 32000, -2000000000, 3000000000, -17000000000000000, 72057594037927698, 12345.678, -123456789.1234 );

-- Functions for fetching the various types
CREATE FUNCTION FetchCTiny() RETURNS tinyint
    EXTERNAL NAME 'FetchTiny@csqltest'
    LANGUAGE c_odbc32;
    
CREATE FUNCTION FetchCSmallint() RETURNS smallint
    EXTERNAL NAME 'FetchSmallint@csqltest'
    LANGUAGE c_odbc32;
    
CREATE FUNCTION FetchCUSmallint() RETURNS unsigned smallint
    EXTERNAL NAME 'FetchUSmallint@csqltest'
    LANGUAGE c_odbc32;
    
CREATE FUNCTION FetchCInt() RETURNS integer
    EXTERNAL NAME 'FetchInt@csqltest'
    LANGUAGE c_odbc32;
    
CREATE FUNCTION FetchCUInt() RETURNS unsigned integer
    EXTERNAL NAME 'FetchUInt@csqltest'
    LANGUAGE c_odbc32;
    
CREATE FUNCTION FetchCString( IN str1 long varchar, IN str2 long varchar) RETURNS long varchar
    EXTERNAL NAME 'FetchString@csqltest'
    LANGUAGE c_odbc32;
    
-- Call each function to retrieve the various datatypes
-- Should return the values 1, -16000, 32000, -2000000000, 3000000000, string 1 and string 2 
SELECT FetchCTiny(), FetchCSmallint(), FetchCUSmallint(),
       FetchCInt(), FetchCUInt(),
       FetchCString('string 1', 'and string 2')

-- Procedure which calls c_odbc32 to return various datatypes in output variables
CREATE PROCEDURE FetchCOuts( OUT t tinyint, OUT s smallint, OUT us unsigned smallint,
                             OUT i integer, OUT ui unsigned integer,
			     OUT big bigint, OUT ubig unsigned bigint,
			     OUT f float, OUT d double, OUT str long varchar )
    EXTERNAL NAME 'FetchOuts@csqltest'
    LANGUAGE c_odbc32;
    
-- Create variables and call the FetchCOuts procedure
CREATE VARIABLE @t tinyint;
CREATE VARIABLE @s smallint;
CREATE VARIABLE @us unsigned smallint;
CREATE VARIABLE @i integer;
CREATE VARIABLE @ui unsigned integer;
CREATE VARIABLE @big bigint;
CREATE VARIABLE @ubig unsigned bigint;
CREATE VARIABLE @f float;
CREATE VARIABLE @d double;
CREATE VARIABLE @str long varchar;

-- Call FetchCOuts procedure
CALL FetchCOuts(@t, @s, @us, @i, @ui, @big, @ubig, @f, @d, @str);

-- Verify the output variables, the values should be:
SELECT @t, @s, @us, @i, @ui, @big, @ubig, @f, @d, @str
