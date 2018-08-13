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

-- A sample insert that triggers an error in the external library is performed
-- before any successful inserts are done

BEGIN
    DECLARE LOCAL TEMPORARY TABLE results(
	pk INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY,
	contains_query char(100),
	result_pk INTEGER,
	result_value LONG VARCHAR,
	result_score DOUBLE ) ON COMMIT PRESERVE ROWS;

    DECLARE value_holder LONG VARCHAR;
    declare len int;

    MESSAGE 'Testing error condition - malformed HTML tags' TO CLIENT;
    BEGIN
	DECLARE external_lib_err
	EXCEPTION FOR SQLSTATE 'WT032';

	SET value_holder = '<html><head>
      <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
      <title>CREATE TABLE statement</tit';

	MESSAGE value_holder TO CLIENT;

	INSERT INTO dba.text_sample_table( value )
	VALUES ( value_holder );

	EXCEPTION
	    WHEN external_lib_err THEN
		MESSAGE ERRORMSG() TO CLIENT;
		ROLLBACK;
	    WHEN OTHERS THEN RESIGNAL;
    END;

    MESSAGE 'Testing regular insert - HTML/XML value' TO CLIENT;
    BEGIN
	INSERT INTO dba.text_sample_table( value )
	VALUES ( '
	    <html>
		<head>
		    <title>What items should be placed in the body of
			the paper?
		    </title>
		</head>
		<body>The body of the essay is supposed to contain five
		    paragraphs. The first paragrahp should introduce the
		    reader to the topic of the paper and briefly mention
		    the points that will be elaborated on in the discussion
		    section.
		</body>
	    </html>' );
	INSERT INTO dba.text_sample_table( value )
	VALUES ( '
	    <html>
		<head>
		    <title>Very short page
		    </title>
		</head>
		<body>No information is contained on this page.
		</body>
	    </html>' );

	INSERT INTO dba.text_sample_table( value )
	VALUES ( '
	    <xml><page>City of Toronto</page><city size="big" population="over 1 mln">Toronto</city> is a multicultural city.</xml>' );
	COMMIT;
    END;

    MESSAGE 'Testing full text queries over the inserted data' TO CLIENT;
    BEGIN
	INSERT INTO results( contains_query, result_pk, result_value,
	    result_score )
	SELECT 'body', *
	FROM dba.text_sample_table CONTAINS( value, 'body' );

	INSERT INTO results( contains_query, result_pk, result_value,
	    result_score )
	SELECT 'page', *
	FROM dba.text_sample_table CONTAINS( value, 'page' );

	COMMIT;
    END;

    SELECT contains_query, result_value, result_score
    FROM results
    ORDER BY pk;
END

