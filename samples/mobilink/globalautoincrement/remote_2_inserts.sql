-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

message '>>Adding rows to remote database 2' type info to client
go

insert customer ( name ) values  ('yourcust1' );
insert customer ( name ) values  ('yourcust2' );
commit;
go


