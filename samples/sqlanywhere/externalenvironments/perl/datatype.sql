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

-- Install the datatype.pl script into the database as 'perldatatype'
INSTALL EXTERNAL OBJECT 'perldatatype' NEW FROM FILE 'datatype.pl' ENVIRONMENT perl;

-- Functions for fetching the various types
CREATE FUNCTION FetchPerlBit( IN v bit ) RETURNS bit
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_bit($sa_perl_arg0)'
    LANGUAGE perl;
    
CREATE FUNCTION FetchPerlSmallint( IN v smallint ) RETURNS smallint
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_smallint($sa_perl_arg0)'
    LANGUAGE perl;
    
CREATE FUNCTION FetchPerlUSmallint( IN v unsigned smallint ) RETURNS unsigned smallint
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_usmallint($sa_perl_arg0)'
    LANGUAGE perl;
    
CREATE FUNCTION FetchPerlInt( IN v integer ) RETURNS integer
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_int($sa_perl_arg0)'
    LANGUAGE perl;
    
CREATE FUNCTION FetchPerlUInt( IN v unsigned integer ) RETURNS unsigned integer
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_uint($sa_perl_arg0)'
    LANGUAGE perl;
    
CREATE FUNCTION FetchPerlString( IN pick int, IN str1 char(128), IN str2 char(128) ) RETURNS char(128)
    EXTERNAL NAME '<file=perldatatype> $sa_perl_return=fetch_string($sa_perl_arg0, $sa_perl_arg1, $sa_perl_arg2)'
    LANGUAGE perl;
    
-- Call each function to retrieve the various datatypes
-- Should return the values 1, -16100, 32100, -2000000100, 3000000100, string 1 
SELECT FetchPerlBit(0), FetchPerlSmallint(100), FetchPerlUSmallint(100),
       FetchPerlInt(100), FetchPerlUInt(100),
       FetchPerlString(1, 'string 1', 'string 2')

-- Procedure which call perl to return various datatypes in output variables
CREATE PROCEDURE FetchPerlOuts( OUT b bit, OUT s smallint, OUT us unsigned smallint,
                                OUT i integer, OUT ui unsigned integer,
				OUT str long varchar )
    EXTERNAL NAME '<file=perldatatype> fetch_outputs($sa_perl_arg0, $sa_perl_arg1,
                                                     $sa_perl_arg2, $sa_perl_arg3,
						     $sa_perl_arg4, $sa_perl_arg5)'
    LANGUAGE perl;
    
-- Create variables and call the FetchPerlOuts procedure
CREATE VARIABLE @b bit;
CREATE VARIABLE @s smallint;
CREATE VARIABLE @us unsigned smallint;
CREATE VARIABLE @i integer;
CREATE VARIABLE @ui unsigned integer;
CREATE VARIABLE @str long varchar;
CALL FetchPerlOuts(@b, @s, @us, @i, @ui, @str);

-- Verify the output variables, the values should be:
-- 0, -16020, 32300, -2000000001, 3009000000, this is a string returned in an output variable
SELECT @b, @s, @us, @i, @ui, @str
