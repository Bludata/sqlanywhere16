-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
grant connect to ml_server identified by 'sql'
go

-- alternatively, one could grant individual table permissions
-- to ml_server
grant DBA to ml_server
go

grant group to DBA
go

grant membership in group DBA to ml_server
go
