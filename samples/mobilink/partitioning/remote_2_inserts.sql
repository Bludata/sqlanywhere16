-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Adding rows to the cust table in remote database 2' type info to client
go

insert cust ( emp_id, cust_name ) values  ( 65538, 'remote_2_cust1' );
insert cust ( emp_id, cust_name ) values  ( 65538, 'remote_2_cust2' );
commit;
go


