-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Adding rows to the consolidated database' type info to client
go

insert into customer ( name ) values ( 'consol_cust13' );
insert into customer ( name ) values ( 'consol_cust14' );
insert into customer ( name ) values ( 'consol_cust15' );
commit;
go





