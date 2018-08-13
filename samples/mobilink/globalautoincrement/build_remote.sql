-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

-- creating tables (same as consolidated in this example)
parameters user_id, db_id
go

set option PUBLIC.GLOBAL_DATABASE_ID={db_id}
go

message '>>Creating remote tables.' type info to client
go

create table customer (
	id int default global autoincrement primary key ,
	name varchar( 128 )
	)
go

message '>>Creating publication and subscription' type info to client
go
CREATE PUBLICATION customer_pub(
TABLE customer
)
go

CREATE SYNCHRONIZATION USER {user_id}
go

CREATE SYNCHRONIZATION SUBSCRIPTION 
TO customer_pub
FOR {user_id}
TYPE 'tcpip'
ADDRESS 'host=localhost'
go

