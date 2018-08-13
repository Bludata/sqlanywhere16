-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

select 'Database: ' || db_name();
output to 'report.txt'
append
go

select 'Table: emp '; 
output to 'report.txt'
append
go
select emp_id,emp_name from emp order by emp_id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go

select 'Table: cust '; 
output to 'report.txt'
append
go
select cust_id,emp_id,cust_name from cust order by cust_id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go
/*
format fixed 
column widths ( 20, 20, 20 )
*/
