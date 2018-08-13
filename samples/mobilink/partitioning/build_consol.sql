-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Creating tables.' type info to client
go

set option public.global_database_id = 1
go

create table emp (
	emp_id int default global autoincrement primary key ,
	emp_name varchar( 128 ),
	last_modified timestamp default timestamp
	)
go
create table cust (
	cust_id int default global autoincrement primary key,
	emp_id int references emp (emp_id ),
	cust_name varchar( 128 ),
	last_modified timestamp default timestamp
	)
go
message '>>Adding data' type info to client
go
begin
 	declare e1 int;
 	declare e2 int;
 	declare e3 int;
 	declare e4 int;
 	declare e5 int;
 	declare e6 int;
	insert emp ( emp_name ) values ( 'emp1' );
	set e1=@@identity;
	insert emp ( emp_name ) values ( 'emp2' );
	set e2=@@identity;
	insert emp ( emp_name ) values ( 'emp3' );
	set e3=@@identity;
	insert emp ( emp_name ) values ( 'emp4' );
	set e4=@@identity;
	insert emp ( emp_name ) values ( 'emp5' );
	set e5=@@identity;
	insert emp ( emp_name ) values ( 'emp6' );
	set e6=@@identity;
	insert cust ( emp_id, cust_name ) values ( e1, 'cust1' );
	insert cust ( emp_id, cust_name ) values ( e1, 'cust2' );
	insert cust ( emp_id, cust_name ) values ( e2, 'cust3' );
	insert cust ( emp_id, cust_name ) values ( e2, 'cust4' );
	insert cust ( emp_id, cust_name ) values ( e3, 'cust5' );
	insert cust ( emp_id, cust_name ) values ( e3, 'cust6' );
	insert cust ( emp_id, cust_name ) values ( e3, 'cust7' );
	insert cust ( emp_id, cust_name ) values ( e5, 'cust8' );
	insert cust ( emp_id, cust_name ) values ( e5, 'cust9' );
	insert cust ( emp_id, cust_name ) values ( e5, 'cust10' );
	insert cust ( emp_id, cust_name ) values ( e6, 'cust11' );
	commit
end
go

-- add synchronization scripts
message '>>Adding synchronization scripts' type info to client
go
call ml_add_table_script( 'default', 'cust', 'upload_insert',
	'insert cust (cust_id, emp_id, cust_name ) values ( {ml r.cust_id}, {ml r.emp_id}, {ml r.cust_name})' )
go

call ml_add_table_script( 'default', 'emp', 'download_cursor',
	'select emp_id, emp_name from emp where last_modified >= {ml s.last_table_download} and emp_name={ml s.username}' )
go
call ml_add_table_script( 'default', 'emp', 'download_delete_cursor',
	'--{ml_ignore}' )
go
call ml_add_table_script( 'default', 'cust', 'download_cursor',
	'select cust_id, cust.emp_id, cust_name from cust key join emp where cust.last_modified >= {ml s.last_table_download} and emp.emp_name = {ml s.username}' )
go
call ml_add_table_script( 'default', 'cust', 'download_delete_cursor',
	'--{ml_ignore}' )
go

call ml_add_column( 'default', 'emp', 'emp_id', 'integer' )
go

call ml_add_column( 'default', 'emp', 'emp_name', 'varchar' )
go

call ml_add_column( 'default', 'cust', 'cust_id', 'integer' ) 
go

call ml_add_column( 'default', 'cust', 'emp_id', 'integer' )
go

call ml_add_column( 'default', 'cust', 'cust_name', 'varchar' )
go

message '>>Complete' type info to client


