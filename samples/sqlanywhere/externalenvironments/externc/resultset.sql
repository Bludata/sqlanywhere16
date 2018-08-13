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

-- Procedure for calling C_ODBC32 and retrieving result sets
CREATE PROCEDURE CGetResultSet1() RESULT( c1 int, c2 char(128) )
    DYNAMIC RESULT SETS 1
    EXTERNAL NAME 'GetResultSet1@csqltest'
    LANGUAGE C_ODBC32;
CREATE PROCEDURE CGetResultSet2() RESULT( c3 int, c4 char(128) )
    DYNAMIC RESULT SETS 1
    EXTERNAL NAME 'GetResultSet2@csqltest'
    LANGUAGE C_ODBC32;
CREATE PROCEDURE CGetResultSet3() RESULT( c1 int, c2 char(128), c3 int, c4 char(128) )
    DYNAMIC RESULT SETS 1
    EXTERNAL NAME 'GetResultSet3@csqltest'
    LANGUAGE C_ODBC32;

-- Call each procedure to see the result set coming back
SELECT * FROM CGetResultSet1() ORDER BY c1;
SELECT * FROM CGetResultSet2() ORDER BY c3;
SELECT * FROM CGetResultSet3() ORDER BY c1;
