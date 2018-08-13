// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
CREATE TABLE T1 (
	pk1	INTEGER,
	pk2     INTEGER,
	c1	varchar(30000),
	PRIMARY KEY(pk1, pk2)
);

CALL ml_add_table_script( 'MLReplayDemo', 'T1', 'upload_insert',
	'INSERT INTO T1 VALUES( cast({ml s.remote_id} as INTEGER), {ml r.2}, {ml r.3} )' );
	
CALL ml_add_table_script( 'MLReplayDemo', 'T1', 'download_cursor',
	'SELECT pk1, pk2, c1 FROM T1' );

CALL ml_add_table_script( 'MLReplayDemo', 'T1', 'download_delete_cursor',
	'--{ml_ignore}' );
	
COMMIT;
