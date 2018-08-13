-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Creating tables.' type info to client
go

set option public.global_database_id=1
go

create table customer (
	id int default global autoincrement primary key,
	name varchar( 128 )
	)
go

message '>>Adding data' type info to client
go

-- add data to customer table
insert into customer ( name ) values ( 'customer_1' );
insert into customer ( name ) values ( 'customer_2' );
insert into customer ( name ) values ( 'customer_3' );
insert into customer ( name ) values ( 'customer_4' );
insert into customer ( name ) values ( 'customer_5' );
insert into customer ( name ) values ( 'customer_6' );
go

-- add synchronization scripts
message '>>Adding synchronization scripts' type info to client
go

call ml_add_table_script( 'default', 'customer', 'upload_insert',
	'insert customer (id, name ) values ( {ml r.id}, {ml r.name} )' )
go

call ml_add_table_script( 'default', 'customer', 'upload_update',
	'update customer set name = {ml r.name} where id = {ml r.id}' )
go

call ml_add_table_script( 'default', 'customer', 'upload_delete',
	'delete from customer where id = {ml r.id}' )
go

call ml_add_table_script( 'default', 'customer', 'download_cursor',
	'select id, name from customer' )
go

call ml_add_table_script( 'default', 'customer', 'download_delete_cursor',
	'--{ml_ignore}' )
go

call ml_add_column( 'default', 'customer', 'id', 'integer' )
go

call ml_add_column( 'default', 'customer', 'name', 'varchar' )
go

message '>>Complete' type info to client


commit
go
