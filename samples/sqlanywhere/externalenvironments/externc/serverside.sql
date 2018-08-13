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

-- Procedure for calling out to C_ODBC32 to create the ExtServerSide_Tab table
CREATE PROCEDURE c_create_table()
    EXTERNAL NAME 'CreateTable@csqltest'
    language C_ODBC32;
    
-- Procedure for calling out to C_ODBC32 to populate the ExtServerSide_Tab table
CREATE PROCEDURE c_populate_table()
    EXTERNAL NAME 'PopulateTable@csqltest'
    language C_ODBC32;
    
-- Procedure for calling out to C_ODBC32 to update the ExtServerSide_Tab table
CREATE PROCEDURE c_update_table()
    EXTERNAL NAME 'UpdateTable@csqltest' language C_ODBC32;
    
-- Procedure for calling out to C_ODBC32 to delete from the ExtServerSide_Tab table
CREATE PROCEDURE c_delete_table()
    EXTERNAL NAME 'DeleteTable@csqltest' language C_ODBC32;
    
-- Procedure for calling out to C_ODBC32 to drop the ExtServerSide_Tab table
CREATE PROCEDURE c_drop_table()
    EXTERNAL NAME 'DropTable@csqltest' language C_ODBC32;

-- Verify that the ExtServerSide_Tab table does not exist, the following should return 0
SELECT count(*) from SYS.SYSTABLE WHERE table_name='ExtServerSide_Tab';

-- Call C_ODBC32 to create the ExtServerSide_Tab table
call c_create_table();

-- Verify that the ExtServerSide_Tab table got created, the following should return 1
SELECT count(*) from SYS.SYSTABLE WHERE table_name='ExtServerSide_Tab';

-- Call C_ODBC32 to populate the ExtServerSide_Tab table
call c_populate_table();

-- Verify that the table has 1000 rows
SELECT count(*) FROM ExtServerSide_Tab;

-- Before updating the table, verify that the number of rows where column
-- c1 is equal to column c3 is 0
SELECT count(*) FROM ExtServerSide_Tab WHERE c1 = c3

-- Call C_ODBC32 to update the ExtServerSide_Tab table
call c_update_table();

-- Verify that all 1000 rows were updated
SELECT count(*) FROM ExtServerSide_Tab WHERE c1 = c3

-- Call C_ODBC32 to delete from the ExtServerSide_Tab table
call c_delete_table();

-- Verify that the table has no rows
SELECT count(*) FROM ExtServerSide_Tab

-- Call C_ODBC32 to drop the ExtServerSide_Tab table
call c_drop_table();

-- Verify that the table was dropped
SELECT count(*) FROM SYS.SYSTABLE WHERE table_name='ExtServerSide_Tab'
