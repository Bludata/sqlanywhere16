-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- This sample code is provided AS IS, without warranty or liability of
-- any kind.
-- 
-- You may use, reproduce, modify and distribute this sample code without
-- limitation, on the condition that you retain the foregoing copyright 
-- notice and disclaimer as to the original code.  
-- 
-- *******************************************************************

-- This example creates some HTTP services that use PHP as the backend language
-- To run this example:
-- 1) start your database server with "-xs http{port=80}"
-- 2) then run this script to set up the server (only do this once)
-- 3) open up http://localhost/<service-name>/<page-name>
-- example: http://localhost/simple/index.php

-- create a table with some PHP pages 
-- these could also be read off the disk when evaluating the request
-- but let's put them in a table to demonstrate the benefits of having
-- your entire web site contained within one .db file
CREATE TABLE php_pages ( "name" varchar(1000), contents long binary );

-- read a couple of example pages into the table
INSERT INTO php_pages ( "name", contents )
SELECT 'index.php', xp_read_file( 'index.php' );

INSERT INTO php_pages ( "name", contents )
SELECT 'phpinfo.php', xp_read_file( 'phpinfo.php' );

INSERT INTO php_pages ( "name", contents )
SELECT 'session.php', xp_read_file( 'session.php' );

-- create a web service function to evaluate an HTTP request as a PHP page
-- access through: http://localhost/simple/index.php 
-- or phpinfo.php or session.php
CREATE PROCEDURE evaluate_php_http( IN pathname varchar(1000) )
RESULT (rawdoc LONG BINARY)
BEGIN
    CALL dbo.sa_set_http_header( 'Content-Type', 'text/html' );
    
    SELECT "dbo".sa_http_php_page( contents ) FROM
        php_pages WHERE "name" = pathname;
END;

CREATE SERVICE "simple" TYPE 'raw' AUTHORIZATION OFF USER "dba" URL ELEMENTS
AS CALL evaluate_php_http( :url1 );

-- create a web service function to evaluate an HTTP request as a PHP page
-- but this one allows you to adjust headers on the way
-- access through: http://localhost/complex/index.php
-- or phpinfo.php or session.php
CREATE PROCEDURE evaluate_php_http_complex( IN pathname varchar(1000) )
RESULT (rawdoc LONG BINARY)
BEGIN
    DECLARE headers LONG VARCHAR;

    SELECT list( name || ': ' || value, char(13) || char(10) ) INTO headers 
    FROM sa_http_header_info();

    CALL dbo.sa_set_http_header( 'Content-Type', 'text/html' );

    SELECT "dbo".sa_http_php_page_interpreted( contents,
        http_header( '@HttpMethod' ), 
        http_header( '@HttpURI' ), 
        http_header( '@HttpVersion' ), 
        headers, 
        HTTP_BODY() ) FROM php_pages WHERE "name" = pathname;
END;

CREATE SERVICE "complex" TYPE 'raw' AUTHORIZATION OFF USER "dba" URL ELEMENTS
AS CALL evaluate_php_http_complex( :url1 );

-- create a web service function to evaluate an HTTP request as a PHP page
-- but this creates a custom PHP function to evaluate the page
-- access through: http://localhost/custom/index.php
-- or phpinfo.php or session.php
CREATE FUNCTION http_php_page_interpreted( IN php_page LONG VARCHAR,
    IN method LONG VARCHAR,
    IN url LONG VARCHAR,
    IN version LONG VARCHAR,
    IN headers LONG BINARY,
    IN request_body LONG BINARY ) 
RETURNS LONG VARCHAR
EXTERNAL NAME 'sqlanywhere_extenv_start_http( $argv[2], 
    $argv[3], $argv[4], $argv[5], $argv[6] ); 
    print "this is a custom http interpretation script\n";
    eval( " ?> " . $argv[1] . " <?php " );' 
LANGUAGE php;

CREATE PROCEDURE evaluate_php_http_custom( IN pathname varchar(1000) )
RESULT (rawdoc LONG BINARY)
BEGIN
    DECLARE headers LONG VARCHAR;

    SELECT list( name || ': ' || value, char(13) || char(10) ) INTO headers 
    FROM sa_http_header_info();

    CALL dbo.sa_set_http_header( 'Content-Type', 'text/html' );

    SELECT http_php_page_interpreted( contents,
        http_header( '@HttpMethod' ), 
        http_header( '@HttpURI' ), 
        http_header( '@HttpVersion' ), 
        headers, 
        HTTP_BODY() ) FROM php_pages WHERE "name" = pathname;
END;

CREATE SERVICE "custom" TYPE 'raw' AUTHORIZATION OFF USER "dba" URL ELEMENTS
AS CALL evaluate_php_http_custom( :url1 );


-- create a service that uses SQL Anywhere as the back-end storage for the
-- session variables 
-- access through: http://localhost/session/session.php
CREATE TABLE sessions ( 
    session_id VARCHAR(32), 
    updated TIMESTAMP DEFAULT CURRENT TIMESTAMP,
    data LONG VARCHAR,
    PRIMARY KEY ( session_id ) );

INSTALL EXTERNAL OBJECT 'phpsession' 
NEW FROM FILE 'sa_session.php' ENVIRONMENT php;

CREATE FUNCTION http_php_page_with_session( IN php_page LONG VARCHAR,
    IN method LONG VARCHAR,
    IN url LONG VARCHAR,
    IN version LONG VARCHAR,
    IN headers LONG BINARY,
    IN request_body LONG BINARY ) 
RETURNS LONG VARCHAR
EXTERNAL NAME '<file=phpsession>sqlanywhere_extenv_start_http( $argv[2], 
    $argv[3], $argv[4], $argv[5], $argv[6] );
    eval( " ?> " . $argv[1] . " <?php " );' 
LANGUAGE php;

CREATE PROCEDURE evaluate_php_http_with_session( IN pathname varchar(1000) )
RESULT (rawdoc LONG BINARY)
BEGIN
    -- we have to declare a result variable and select into that variable
    -- otherwise SQLAnywhere will send the headers before the PHP code gets
    -- to execute, so the PHP code could not set headers
    DECLARE "result" long binary;
    DECLARE headers LONG VARCHAR;

    SELECT list( name || ': ' || value, char(13) || char(10) ) INTO headers 
    FROM sa_http_header_info();

    CALL dbo.sa_set_http_header( 'Content-Type', 'text/html' );

    SELECT http_php_page_with_session( contents,
        http_header( '@HttpMethod' ), 
        http_header( '@HttpURI' ), 
        http_header( '@HttpVersion' ), 
        headers, 
        HTTP_BODY() ) INTO "result" FROM php_pages WHERE "name" = pathname;

    COMMIT;

    SELECT "result";
END;

CREATE SERVICE "session" TYPE 'raw' AUTHORIZATION OFF USER "dba" URL ELEMENTS
AS CALL evaluate_php_http_with_session( :url1 );
