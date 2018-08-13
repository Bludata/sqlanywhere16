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

select * from customer order by id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go
/*
format fixed 
column widths ( 20, 20, 20 )
*/
