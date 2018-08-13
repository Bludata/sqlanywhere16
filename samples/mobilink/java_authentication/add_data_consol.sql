-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Adding rows to the cust table in the consolidated database' type info to client
go

insert into cust ( cust_id, emp_id, cust_name ) values ( 1, 2, 'yourcust13' );
insert into cust ( cust_id, emp_id, cust_name ) values ( 2, 2, 'yourcust14' );
insert into cust ( cust_id, emp_id, cust_name ) values ( 3, 2, 'yourcust15' );
commit;
go





