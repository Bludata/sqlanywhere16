-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************


message '>>Adding rows to the cust table in the consolidated database' type info to client
go

insert into cust ( emp_id, cust_name ) values ( 65537, 'customer for emp1' );
insert into cust ( emp_id, cust_name ) values ( 65538, 'customer for emp2' );
insert into cust ( emp_id, cust_name ) values ( 65539, 'customer for emp3' );
commit;
go





