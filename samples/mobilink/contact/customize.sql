-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

parameters ml_userid, db_id;
go
set option public.global_database_id = {db_id}
go

CREATE SYNCHRONIZATION USER {ml_userid}
        TYPE 'TCPIP' 
        ADDRESS 'host=localhost;port=2439' 
go
CREATE SYNCHRONIZATION SUBSCRIPTION TO "DBA"."Product"
        FOR {ml_userid} OPTION SendColumnNames='ON'
go
CREATE SYNCHRONIZATION SUBSCRIPTION TO "DBA"."Contact"
        FOR {ml_userid} OPTION SendColumnNames='ON'
go
commit work
go



