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

-- Install the serverside.php script into the database as 'sphp'
INSTALL EXTERNAL OBJECT 'sphp' NEW FROM FILE 'serverside.php' ENVIRONMENT php;

-- Procedure for calling out to php to create the sphp_Tab table
CREATE PROCEDURE create_sphp_Tab()
    EXTERNAL NAME '<file=sphp> sphp_create_table()' language php;
    
-- Procedure for calling out to php to populate the sphp_Tab table
CREATE PROCEDURE populate_sphp_Tab(IN num_rows INTEGER)
    EXTERNAL NAME '<file=sphp> sphp_populate_table($argv[1])'
    language php;
    
-- Procedure for calling out to php to update the sphp_Tab table
CREATE PROCEDURE update_sphp_Tab()
    EXTERNAL NAME '<file=sphp> sphp_update_table()' language php;
    
-- Procedure for calling out to php to delete from the sphp_Tab table
CREATE PROCEDURE delete_sphp_Tab()
    EXTERNAL NAME '<file=sphp> sphp_delete_table()' language php;
    
-- Procedure for calling out to php to drop the sphp_Tab table
CREATE PROCEDURE drop_sphp_Tab()
    EXTERNAL NAME '<file=sphp> sphp_drop_table()' language php;

-- Call php to create the sphp_Tab table
call create_sphp_Tab();

-- Call php to populate the sphp_Tab table with 1000 rows
call populate_sphp_Tab( 1000 );

-- Verify that the table has 1000 rows
SELECT count(*) FROM sphp_Tab;

-- Call php to update the sphp_Tab table
call update_sphp_Tab();

-- Verify that all 1000 rows were updated
SELECT count(*) FROM sphp_Tab WHERE c1 = c3;

-- Call php to delete from the sphp_Tab table
call delete_sphp_Tab();

-- Verify that the table has no rows
SELECT count(*) FROM sphp_Tab;

-- Call php to drop the sphp_Tab table
call drop_sphp_Tab();

-- Verify that the table was dropped
SELECT count(*) FROM SYS.SYSTABLE WHERE table_name='sphp_Tab'
