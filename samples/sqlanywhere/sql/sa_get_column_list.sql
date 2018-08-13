-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- This sample code is provided AS IS, without warranty or liability
-- of any kind.
-- 
-- You may use, reproduce, modify and distribute this sample code
-- without limitation, on the condition that you retain the foregoing
-- copyright notice and disclaimer as to the original code.  
-- 
-- *********************************************************************

CREATE OR REPLACE PROCEDURE sa_get_column_list(
    IN    @object_name       VARCHAR(257)
   ,IN    @exclude_list      LONG VARCHAR DEFAULT ''
   ,IN    @separator         VARCHAR(255) DEFAULT ', '
   ,IN    @only_keys         CHAR(1) DEFAULT NULL
)
RESULT( column_list LONG VARCHAR )
BEGIN
    DECLARE @table_name    VARCHAR(128);
    DECLARE @owner_name    VARCHAR(128);
    DECLARE @dot_at        INT;

    -- Check if an owner name has been specified
    SET @dot_at = LOCATE( @object_name, '.' );
    
    IF( @dot_at > 0 ) THEN
        -- Split off the table name
        SET @table_name = SUBSTR( @object_name, @dot_at+1 );
         -- Get the owner name
        SET @owner_name = SUBSTR( @object_name, 1, @dot_at-1 );
    ELSE
        -- Object name does not contain an owner
        SET @owner_name = user_name();
        SET @table_name = @object_name;
    END IF;

    SELECT list( sc.column_name, @separator
                 ORDER BY sc.column_id ) AS column_list
      FROM SYS.SYSTAB st
       KEY JOIN SYS.SYSUSER su
       KEY JOIN SYS.SYSTABCOL sc
     WHERE st.table_name = @table_name
       AND su.user_name = @owner_name
       AND sc.column_name NOT IN (
                     SELECT row_value
                       FROM dbo.sa_split_list(@exclude_list)
       )
       AND (ISNULL(@only_keys,'N') = 'N' OR
	    (@only_keys = 'Y' 
	    AND EXISTS (SELECT * FROM SYS.SYSIDXCOL ixc 
			WHERE ixc.table_id = sc.table_id
			AND ixc.column_id = sc.column_id
			AND ixc.index_id = 0)));

END
go

grant execute on sa_get_column_list to PUBLIC
go
