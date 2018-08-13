// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
//
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.
//
// *******************************************************************
-- This file populates the sample table and its text index and then
-- performs full text searches on the table.
-- The results of the searches are stored in the temp table and
-- displayed at the end.

BEGIN
    DECLARE LOCAL TEMPORARY TABLE results(
	pk INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY,
	contains_query char(100),
	result_pk INTEGER,
	result_value LONG VARCHAR,
	result_score DOUBLE ) ON COMMIT PRESERVE ROWS;

    MESSAGE 'Testing regular insert - values containing apostrophes and capital letters' TO CLIENT;
    BEGIN
	INSERT INTO dba.text_sample_table( value )
	VALUES ( 'Mary''s lamb was white as snow, and so was Lilly''s. They walked with the lambs and the lambs'' friends down the hillside until they found a patch of green-green grass.' );
	INSERT INTO dba.text_sample_table( value )
	VALUES ( 'We''re going to settle down in the country.' );

	INSERT INTO dba.text_sample_table( value )
	VALUES ( 'There are many capital cities with names beginning with ''P'', for example, Paris and Prague.' );

	INSERT INTO dba.text_sample_table( value )
	VALUES ( 'Mary s - looks almost like the Mary-apostrophe-s in the other document.' );
	COMMIT;
    END;

    MESSAGE 'Testing full text queries over the inserted data' TO CLIENT;
    BEGIN
	INSERT INTO results( contains_query, result_pk, result_value,
	    result_score )
	SELECT '''p*', *
	FROM dba.text_sample_table CONTAINS( value, '''p*' );

	INSERT INTO results( contains_query, result_pk, result_value,
	    result_score )
	SELECT 'mary''s', *
	FROM dba.text_sample_table CONTAINS( value, 'mary''s' );

	COMMIT;
    END;

    SELECT contains_query, result_value, result_score
    FROM results
    ORDER BY pk;
END


