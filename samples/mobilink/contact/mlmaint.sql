-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

-------------------------------------------------
--   Create convenience owner for maintenance tables
-------------------------------------------------
GRANT CONNECT TO "mlmaint" 
go

-------------------------------------------------
--   Create maintenance tables
-------------------------------------------------
CREATE TABLE "mlmaint"."errorlog"
(
	error_id      		integer NOT NULL DEFAULT autoincrement,
	action_code   		integer NULL,
	error_code    		integer NULL,
	error_message 		text NULL,
	user_name     		varchar(128) NULL,
	table_name 			varchar(128) NULL,
	error_time    		timestamp NULL DEFAULT timestamp,
	PRIMARY KEY ("error_id")
)
go
CREATE TABLE "mlmaint"."audit_connection_statistics" (
	id INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY ,
	user_name VARCHAR(128),
	warnings INTEGER,
	errors INTEGER,
	deadlocks INTEGER,
	synchronized_tables INTEGER,
	connection_retries INTEGER
)
go

CREATE TABLE "mlmaint"."audit_table_statistics" (
	id INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY ,
	user_name VARCHAR(128),
	table_name VARCHAR(128),
	warnings INT,
	errors INT
)
go

CREATE TABLE "mlmaint"."audit_upload_statistics" (
	id INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY ,
	user_name VARCHAR(128),
	table_name VARCHAR(128),
	warnings INT,
	errors INT,
	inserted_rows INT,
	deleted_rows INT,
	updated_rows INT,
	conflicted_updates INT,
	ignored_inserts INT,
	ignored_deletes INT,
	ignored_updates INT,
	bytes INT,
	deadlocks INT
)
go

-------------------------------------------------
--   Create procedures
-------------------------------------------------
CREATE PROCEDURE "mlmaint".audit_table_statistics( IN user_name VARCHAR(128),
	IN table_name VARCHAR(128),
	IN warnings INT,
	IN errors INT) AS 
BEGIN
    INSERT INTO "mlmaint"."audit_table_statistics" ( user_name, table_name, warnings, errors)
    VALUES ( user_name, table_name, warnings, errors ) 
END
go

CREATE PROCEDURE "mlmaint".audit_upload_statistics( 
	IN user_name VARCHAR(128),
	IN table_name VARCHAR(128),
	IN warnings INT,
	IN errors INT,
	IN inserted_rows INT,
	IN deleted_rows INT,
	IN updated_rows INT,
	IN conflicted_updates INT,
	IN ignored_inserts INT,
	IN ignored_deletes INT,
	IN ignored_updates INT,
	IN bytes INT,
	IN deadlocks INT
) AS 
BEGIN
	INSERT INTO "mlmaint"."audit_upload_statistics"( 
	    user_name, 
	    table_name, 
	    warnings, 
	    errors, 
	    inserted_rows, 
	    deleted_rows, 
	    updated_rows,
	    conflicted_updates,
	    ignored_inserts, 
	    ignored_deletes, 
	    ignored_updates , 
	    bytes, 
	    deadlocks )
	VALUES ( 
	    user_name, 
	    table_name,	
	    warnings,
	    errors, 
	    inserted_rows, 
	    deleted_rows, 
	    updated_rows,
	    conflicted_updates,
	    ignored_inserts, 
	    ignored_deletes, 
	    ignored_updates,
	    bytes, 
	    deadlocks )
END
go

call ml_add_table_script( 'default', 'Product', 'synchronization_statistics',
'call mlmaint.audit_table_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors} )' );
go
call ml_add_table_script( 'default', 'SalesRep', 'synchronization_statistics',
'call mlmaint.audit_table_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors} )' );
go
call ml_add_table_script( 'default', 'Customer', 'synchronization_statistics',
'call mlmaint.audit_table_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors} )' );
go
call ml_add_table_script( 'default', 'Contact', 'synchronization_statistics',
'call mlmaint.audit_table_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors} )' );
go
call ml_add_table_script( 'default', 'Product', 'upload_statistics', 
'call mlmaint.audit_upload_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors}, {ml s.inserted_rows}, {ml s.deleted_rows}, {ml s.updated_rows}, {ml s.conflicted_updates}, {ml s.ignored_inserts}, {ml s.ignored_deletes}, {ml s.ignored_updates}, {ml s.bytes}, {ml s.deadlocks} )' );
go
call ml_add_table_script( 'default', 'SalesRep', 'upload_statistics', 
'call mlmaint.audit_upload_statistics( {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors}, {ml s.inserted_rows}, {ml s.deleted_rows}, {ml s.updated_rows}, {ml s.conflicted_updates}, {ml s.ignored_inserts}, {ml s.ignored_deletes}, {ml s.ignored_updates}, {ml s.bytes}, {ml s.deadlocks} )' );
go
call ml_add_table_script( 'default', 'Customer', 'upload_statistics', 
'call mlmaint.audit_upload_statistics( 
     {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors}, {ml s.inserted_rows}, {ml s.deleted_rows}, {ml s.updated_rows}, {ml s.conflicted_updates}, {ml s.ignored_inserts}, {ml s.ignored_deletes}, {ml s.ignored_updates}, {ml s.bytes}, {ml s.deadlocks} )' );
go
call ml_add_table_script( 'default', 'Contact', 'upload_statistics', 
'call mlmaint.audit_upload_statistics( 
     {ml s.username}, {ml s.table}, {ml s.warnings}, {ml s.errors}, {ml s.inserted_rows}, {ml s.deleted_rows}, {ml s.updated_rows}, {ml s.conflicted_updates}, {ml s.ignored_inserts}, {ml s.ignored_deletes}, {ml s.ignored_updates}, {ml s.bytes}, {ml s.deadlocks} )' );
go

call ml_add_connection_script( 'default', 'upload_statistics', 
'call mlmaint.audit_upload_statistics( {ml s.username}, NULL, {ml s.warnings}, {ml s.errors}, {ml s.inserted_rows}, {ml s.deleted_rows}, {ml s.updated_rows}, {ml s.conflicted_updates}, {ml s.ignored_inserts}, {ml s.ignored_deletes}, {ml s.ignored_updates}, {ml s.bytes}, {ml s.deadlocks} )' );
go
call ml_add_connection_script( 'default', 'report_error', 
    'insert into mlmaint.errorlog( 
        action_code, 
	error_code, 
	error_message, 
	user_name, 
	table_name )
     values( {ml s.action_code}, {ml s.error_code}, {ml s.error_message}, {ml s.username}, {ml s.table} )' )
go
call ml_add_connection_script( 'default', 'synchronization_statistics', 
    'insert into mlmaint.audit_connection_statistics( 
        user_name, 
	warnings, 
	errors, 
	deadlocks, 
	synchronized_tables, 
	connection_retries )
     values ( {ml s.username}, {ml s.warnings}, {ml s.errors}, {ml s.deadlocks}, {ml s.synchronized_tables}, {ml s.connection_retries} )' );
go
