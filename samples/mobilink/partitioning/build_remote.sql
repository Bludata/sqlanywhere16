-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

parameters ml_userid, db_id;
go
-- creating tables (same as consolidated in this example)
message '>>Creating remote tables.' type info to client
go
set option public.global_database_id = {db_id}
go

create table emp (
	emp_id int default global autoincrement primary key ,
	emp_name varchar( 128 )
	)
go

create table cust (
	cust_id int default global autoincrement primary key,
	emp_id int references emp (emp_id ),
	cust_name varchar( 128 )
	)
go

message '>>Creating publication and subscription' type info to client
go
CREATE PUBLICATION emp_cust (
TABLE cust,
TABLE emp
)
go

CREATE SYNCHRONIZATION USER {ml_userid}
go

CREATE SYNCHRONIZATION SUBSCRIPTION 
TO emp_cust
FOR {ml_userid}
TYPE 'tcpip'
ADDRESS 'host=localhost'
go


