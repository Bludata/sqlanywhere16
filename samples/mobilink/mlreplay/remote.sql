// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
CREATE TABLE T1 (
	pk1	INTEGER,
	pk2	INTEGER,
	c1	varchar(30000),
	PRIMARY KEY(pk1,pk2)
);

SET OPTION PUBLIC.ml_remote_id = '0';

CREATE PUBLICATION P1 (
    TABLE T1
);

CREATE SYNCHRONIZATION USER U1;

CREATE SYNCHRONIZATION SUBSCRIPTION 
    TO P1
    FOR U1
    TYPE 'TCPIP'
    ADDRESS 'host=localhost;port=2439';
