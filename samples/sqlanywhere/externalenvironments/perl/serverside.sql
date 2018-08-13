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

-- Install the serverside.pl script into the database as 'sperl'
INSTALL EXTERNAL OBJECT 'sperl' NEW FROM FILE 'serverside.pl' ENVIRONMENT perl;

-- Procedure for calling out to perl to create the sperl_Tab table
CREATE PROCEDURE create_sperl_Tab()
    EXTERNAL NAME '<file=sperl> sperl_create_table()' language perl;
    
-- Procedure for calling out to perl to populate the sperl_Tab table
CREATE PROCEDURE populate_sperl_Tab(IN num_rows INTEGER)
    EXTERNAL NAME '<file=sperl> sperl_populate_table($sa_perl_arg0)'
    language perl;
    
-- Procedure for calling out to perl to update the sperl_Tab table
CREATE PROCEDURE update_sperl_Tab()
    EXTERNAL NAME '<file=sperl> sperl_update_table()' language perl;
    
-- Procedure for calling out to perl to delete from the sperl_Tab table
CREATE PROCEDURE delete_sperl_Tab()
    EXTERNAL NAME '<file=sperl> sperl_delete_table()' language perl;
    
-- Procedure for calling out to perl to drop the sperl_Tab table
CREATE PROCEDURE drop_sperl_Tab()
    EXTERNAL NAME '<file=sperl> sperl_drop_table()' language perl;

-- Call perl to create the sperl_Tab table
call create_sperl_Tab();

-- Call perl to populate the sperl_Tab table with 1000 rows
call populate_sperl_Tab( 1000 );

-- Verify that the table has 1000 rows
SELECT count(*) FROM sperl_Tab;

-- Call perl to update the sperl_Tab table
call update_sperl_Tab();

-- Verify that all 1000 rows were updated
SELECT count(*) FROM sperl_Tab WHERE c1 = c3;

-- Call perl to delete from the sperl_Tab table
call delete_sperl_Tab();

-- Verify that the table has no rows
SELECT count(*) FROM sperl_Tab;

-- Call perl to drop the sperl_Tab table
call drop_sperl_Tab();

-- Verify that the table was dropped
SELECT count(*) FROM SYS.SYSTABLE WHERE table_name='sperl_Tab'
