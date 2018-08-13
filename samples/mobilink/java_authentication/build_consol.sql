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

create table login_added( 
	user_name char(30), 
	add_time char(30) ) 
go

create table login_audit( 
	user_name char(30), 
	audit_time char(30), 
	audit_action char(20))
go

call ml_add_java_connection_script( 'ver1','authenticate_user',
'CustEmpScripts.authenticateUser' )
go

call ml_add_java_connection_script( 'ver1',
'end_connection','CustEmpScripts.endConnection')
go

call ml_add_table_script( 'ver1', 'emp',
'upload_insert', 'INSERT INTO emp(emp_id, emp_name) VALUES( ?, ?) ')
go

call ml_add_table_script( 'ver1', 'emp',
'upload_update', 'UPDATE emp SET emp_name = ? WHERE emp_id = ? ')
go

call ml_add_table_script( 'ver1', 'emp',
'upload_delete', 'DELETE FROM emp WHERE emp_id = ? ')
go

call ml_add_table_script( 'ver1', 'emp',
'download_cursor', 'SELECT emp_id, emp_name FROM emp')
go

call ml_add_table_script( 'ver1', 'emp',
'download_delete_cursor','--{ml_ignore}')
go

call ml_add_table_script( 'ver1', 'cust',
'upload_insert', 'INSERT INTO cust(cust_id, emp_id, cust_name) VALUES ( ?, ?, ? ) ')
go

call ml_add_table_script( 'ver1', 'cust',
'upload_update', 'UPDATE cust set emp_id = ?, cust_name = ? WHERE cust_id = ? ')
go

call ml_add_table_script( 'ver1', 'cust',
'upload_delete', 'DELETE FROM cust WHERE cust_id = ? ')
go

call ml_add_table_script( 'ver1', 'cust',
'download_cursor', 'SELECT cust_id, emp_id, cust_name FROM cust')
go

call ml_add_table_script( 'ver1', 'cust',
'download_delete_cursor','--{ml_ignore}')
go


