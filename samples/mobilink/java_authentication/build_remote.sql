-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

create table cust ( 
	cust_id int primary key, 
	emp_id int, 
	cust_name char(20) )
go

create table emp ( 
	emp_id int primary key, 
	emp_name char(20))
go

CREATE PUBLICATION emp_cust (
TABLE cust,
TABLE emp
)
go

CREATE SYNCHRONIZATION USER ml_user
go

CREATE SYNCHRONIZATION SUBSCRIPTION 
TO emp_cust
FOR ml_user
TYPE 'tcpip'
ADDRESS 'host=localhost'
OPTION ScriptVersion='ver1'
go


