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

select 'Table: SalesRep';
output to 'report.txt'
append
go

select rep_id, "name"
from SalesRep order by rep_id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go

select 'Table: Customer';
output to 'report.txt'
append
go

select cust_id, "name", rep_id
from Customer order by cust_id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go

select 'Table: Contact';
output to 'report.txt'
append
go

select contact_id, "name", cust_id
from Contact order by cust_id;
output to 'report.txt'
format ascii delimited by '\x09'
quote ''
append 
go
