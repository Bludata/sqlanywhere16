-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

--
-- This command file reloads a database that was unloaded using "dbunload".

SET OPTION Statistics          = 3
go
SET OPTION Date_order          = 'YMD'
go
SET OPTION PUBLIC.Preserve_source_format = 'OFF'
go


-------------------------------------------------
--   Create userids and grant user permissions
-------------------------------------------------

GRANT CONNECT TO "DBA" IDENTIFIED BY "SQL"
go
GRANT RESOURCE, DBA, SCHEDULE TO "DBA"
go
GRANT CONNECT TO "dbo"  AT  3
go
GRANT GROUP TO "dbo"
go
GRANT RESOURCE, DBA TO "dbo"
go
GRANT CONNECT TO "sync_user"  AT  101 IDENTIFIED BY ENCRYPTED '\x5A\x24\x45\xAB\x00\x05\xE2\x85\xDF\xD0\xFE\xDD\x83\x8F\x80\xC0\x03\x5A\xBD\x69\xF0\x6E\xAC\xF4\x84\xE1\xAD\x6F\xAF\xC3\x69\xFD\x8D\x0C\x46\x8B'
go
GRANT REMOTE DBA TO "sync_user"
go
commit work
go


-------------------------------------------------
--   Create tables
-------------------------------------------------

CREATE TABLE "DBA"."SalesRep"
(
	"rep_id"        		integer NOT NULL DEFAULT global autoincrement,
	"name"  			char(40) NOT NULL,
	PRIMARY KEY ("rep_id")
)
go
CREATE TABLE "DBA"."Product"
(
	"id"    			integer NOT NULL,
	"name"  			char(15) NULL,
	"size"  			char(18) NULL,
	"quantity"      		integer NULL,
	"unit_price"    		money NULL,
	PRIMARY KEY ("id")
)
go
CREATE TABLE "DBA"."Customer"
(
	"cust_id"       		integer NOT NULL DEFAULT global autoincrement,
	"name"  			char(40) NOT NULL,
	"rep_id"        		integer NOT NULL,
	PRIMARY KEY ("cust_id")
)
go
CREATE TABLE "DBA"."Contact"
(
	"contact_id"    		integer NOT NULL DEFAULT global autoincrement,
	"name"  			char(40) NOT NULL,
	"cust_id"       		integer NOT NULL,
	PRIMARY KEY ("contact_id")
)
go
commit work
go

-------------------------------------------------
--   Add foreign key definitions
-------------------------------------------------


ALTER TABLE "DBA"."Customer"
	ADD FOREIGN KEY "SalesRep" ("rep_id") 
	REFERENCES "DBA"."SalesRep" ("rep_id")
go
COMMENT ON FOREIGN KEY "DBA"."Customer"."SalesRep" IS
	''
go

ALTER TABLE "DBA"."Contact"
	ADD FOREIGN KEY "Customer" ("cust_id") 
	REFERENCES "DBA"."Customer" ("cust_id")
go
COMMENT ON FOREIGN KEY "DBA"."Contact"."Customer" IS
	''
go
commit work
go

-------------------------------------------------
--   Create SQL remote definitions
-------------------------------------------------

CREATE REMOTE TYPE "FILE" ADDRESS ''
go
CREATE REMOTE TYPE "MAPI" ADDRESS ''
go
CREATE REMOTE TYPE "VIM" ADDRESS ''
go
CREATE REMOTE TYPE "SMTP" ADDRESS ''
go
CREATE REMOTE TYPE "FTP" ADDRESS ''
go
CREATE PUBLICATION "DBA"."Product"
(
	TABLE "DBA"."Product"( "id", "name", "size", "quantity", "unit_price" )
)
go
CREATE PUBLICATION dbo.dummy_pub_2
(
	TABLE dbo.RowGenerator
)
go
DROP PUBLICATION dbo.dummy_pub_2
go
CREATE PUBLICATION "DBA"."Contact"
(
	TABLE "DBA"."Contact",
	TABLE "DBA"."SalesRep",
	TABLE "DBA"."Customer"
)
go

-------------------------------------------------
--   Check view definitions
-------------------------------------------------

GRANT CONNECT TO "DBA" IDENTIFIED BY ENCRYPTED '\xF0\x63\x88\x5D\xE3\x1C\x23\xA0\xBF\x42\x08\xCF\x9E\xB1\x14\xB7\x9E\xD9\x3D\xBF\xBA\xC9\xE1\x30\x09\xD7\x33\x07\xD7\x00\xC3\xF2\x68\xF1\x35\xD1'
go
commit work
go


-------------------------------------------------
--   Set option values
-------------------------------------------------


SET OPTION Statistics =
go
SET OPTION Date_order =
go
SET OPTION PUBLIC.Preserve_source_format=
go


--
--SQL Option Statements for user PUBLIC
--

SET OPTION "PUBLIC"."Replication_error_piece" = ''
go
SET OPTION "PUBLIC"."Replication_error" = ''
go
SET OPTION "PUBLIC"."Replicate_all" = 'Off'
go
SET OPTION "PUBLIC"."Recovery_time" = '2'
go
SET OPTION "PUBLIC"."Quoted_identifier" = 'On'
go
SET OPTION "PUBLIC"."Quote_all_identifiers" = 'Off'
go
SET OPTION "PUBLIC"."Quiet" = 'Off'
go
SET OPTION "PUBLIC"."Query_plan_on_open" = 'Off'
go
SET OPTION "PUBLIC"."Qualify_owners" = 'On'
go
SET OPTION "PUBLIC"."Preserve_source_format" = 'On'
go
SET OPTION "PUBLIC"."Prefetch" = 'On'
go
SET OPTION "PUBLIC"."Precision" = '30'
go
SET OPTION "PUBLIC"."Percent_as_comment" = 'On'
go
SET OPTION "PUBLIC"."Output_nulls" = ''
go
SET OPTION "PUBLIC"."Output_length" = '0'
go
SET OPTION "PUBLIC"."Output_format" = 'ASCII'
go
SET OPTION "PUBLIC"."Optimization_level" = '9'
go
SET OPTION "PUBLIC"."Optimization_goal" = 'First-row'
go
SET OPTION "PUBLIC"."On_tsql_error" = 'Conditional'
go
SET OPTION "PUBLIC"."On_error" = 'Prompt'
go
SET OPTION "PUBLIC"."NULLS" = '(NULL)'
go
SET OPTION "PUBLIC"."Non_keywords" = ''
go
SET OPTION "PUBLIC"."Nearest_century" = '50'
go
SET OPTION "PUBLIC"."Min_table_size_for_histogram" = '1000'
go
SET OPTION "PUBLIC"."Min_password_length" = '0'
go
SET OPTION "PUBLIC"."Max_work_table_hash_size" = '20'
go
SET OPTION "PUBLIC"."Max_statement_count" = '50'
go
SET OPTION "PUBLIC"."Max_plans_cached" = '20'
go
SET OPTION "PUBLIC"."Max_hash_size" = '10'
go
SET OPTION "PUBLIC"."Max_cursor_count" = '50'
go
SET OPTION "PUBLIC"."Login_procedure" = 'sp_login_environment'
go
SET OPTION "PUBLIC"."Optimization_logging" = 'Off'
go
SET OPTION "PUBLIC"."Login_mode" = 'Standard'
go
SET OPTION "PUBLIC"."Verify_threshold" = '1000'
go
SET OPTION "PUBLIC"."Verify_all_columns" = 'Off'
go
SET OPTION "PUBLIC"."User_estimates" = 'Override-magic'
go
SET OPTION "PUBLIC"."Tsql_variables" = 'Off'
go
SET OPTION "PUBLIC"."Tsql_hex_constant" = 'On'
go
SET OPTION "PUBLIC"."Truncation_length" = '30'
go
SET OPTION "PUBLIC"."Truncate_with_auto_commit" = 'On'
go
SET OPTION "PUBLIC"."Truncate_timestamp_values" = 'Off'
go
SET OPTION "PUBLIC"."Truncate_date_values" = 'On'
go
SET OPTION "PUBLIC"."Timestamp_format" = 'YYYY-MM-DD HH:NN:SS.SSS'
go
SET OPTION "PUBLIC"."Time_format" = 'HH:NN:SS.SSS'
go
SET OPTION "PUBLIC"."Thread_swaps" = '18'
go
SET OPTION "PUBLIC"."Thread_stack" = '16384'
go
SET OPTION "PUBLIC"."Thread_count" = '0'
go
SET OPTION "PUBLIC"."TDS_Empty_string_is_null" = 'Off'
go
SET OPTION "PUBLIC"."Subscribe_by_remote" = 'On'
go
SET OPTION "PUBLIC"."String_rtruncation" = 'Off'
go
SET OPTION "PUBLIC"."Statistics" = '3'
go
SET OPTION "PUBLIC"."SR_TimeStamp_Format" = 'hh:nn:ss.Ssssss yyyy/mm/dd'
go
SET OPTION "PUBLIC"."SR_Time_Format" = 'hh:nn:ss.Ssssss'
go
SET OPTION "PUBLIC"."SR_Date_Format" = 'yyyy/mm/dd'
go
SET OPTION "PUBLIC"."SQLStart" = ''
go
SET OPTION "PUBLIC"."SQLConnect" = ''
go
SET OPTION "PUBLIC"."SQL_flagger_warning_level" = 'W'
go
SET OPTION "PUBLIC"."SQL_flagger_error_level" = 'W'
go
SET OPTION "PUBLIC"."Screen_format" = 'Text'
go
SET OPTION "PUBLIC"."Scale" = '6'
go
SET OPTION "PUBLIC"."Save_remote_passwords" = 'On'
go
SET OPTION "PUBLIC"."Row_counts" = 'Off'
go
SET OPTION "PUBLIC"."RI_Trigger_time" = 'After'
go
SET OPTION "PUBLIC"."Suppress_TDS_debugging" = 'Off'
go
SET OPTION "PUBLIC"."Wait_for_commit" = 'Off'
go
SET OPTION "PUBLIC"."Cooperative_commit_timeout" = '250'
go
SET OPTION "PUBLIC"."Conversion_error" = 'On'
go
SET OPTION "PUBLIC"."Continue_after_raiserror" = 'On'
go
SET OPTION "PUBLIC"."Compression" = '6'
go
SET OPTION "PUBLIC"."Commit_on_exit" = 'On'
go
SET OPTION "PUBLIC"."Command_delimiter" = ';'
go
SET OPTION "PUBLIC"."Close_on_endtrans" = 'On'
go
SET OPTION "PUBLIC"."Cis_rowset_size" = '50'
go
SET OPTION "PUBLIC"."Cis_option" = '0'
go
SET OPTION "PUBLIC"."Checkpoint_time" = '60'
go
SET OPTION "PUBLIC"."Char_OEM_Translation" = 'Detect'
go
SET OPTION "PUBLIC"."Chained" = 'On'
go
SET OPTION "PUBLIC"."Blocking_timeout" = '0'
go
SET OPTION "PUBLIC"."Blocking" = 'On'
go
SET OPTION "PUBLIC"."Blob_threshold" = '256'
go
SET OPTION "PUBLIC"."Cooperative_commits" = 'On'
go
SET OPTION "PUBLIC"."Background_priority" = 'Off'
go
SET OPTION "PUBLIC"."Automatic_timestamp" = 'Off'
go
SET OPTION "PUBLIC"."Auto_refetch" = 'On'
go
SET OPTION "PUBLIC"."Auto_commit" = 'Off'
go
SET OPTION "PUBLIC"."Auditing" = 'Off'
go
SET OPTION "PUBLIC"."Assume_distinct_servers" = 'Off'
go
SET OPTION "PUBLIC"."Ansinull" = 'On'
go
SET OPTION "PUBLIC"."Ansi_update_constraints" = 'Cursors'
go
SET OPTION "PUBLIC"."Ansi_permissions" = 'On'
go
SET OPTION "PUBLIC"."Ansi_integer_overflow" = 'Off'
go
SET OPTION "PUBLIC"."Ansi_close_cursors_on_rollback" = 'Off'
go
SET OPTION "PUBLIC"."Ansi_blanks" = 'Off'
go
SET OPTION "PUBLIC"."Allow_sync_pkey_update" = 'Off'
go
SET OPTION "PUBLIC"."Allow_replication_pkey_update" = 'On'
go
SET OPTION "PUBLIC"."Allow_nulls_by_default" = 'On'
go
SET OPTION "PUBLIC"."Bell" = 'On'
go
SET OPTION "PUBLIC"."Log_max_requests" = '100'
go
SET OPTION "PUBLIC"."Log_detailed_plans" = 'On'
go
SET OPTION "PUBLIC"."Lock_rejected_rows" = 'Off'
go
SET OPTION "PUBLIC"."ISQL_quote" = ''''
go
SET OPTION "PUBLIC"."ISQL_plan" = 'SHORT'
go
SET OPTION "PUBLIC"."ISQL_log" = ''
go
SET OPTION "PUBLIC"."ISQL_field_separator" = ','
go
SET OPTION "PUBLIC"."ISQL_escape_character" = '\'
go
SET OPTION "PUBLIC"."ISQL_command_timing" = 'On'
go
SET OPTION "PUBLIC"."Isolation_level" = '0'
go
SET OPTION "PUBLIC"."Input_format" = 'ASCII'
go
SET OPTION "PUBLIC"."Headings" = 'On'
go
SET OPTION "PUBLIC"."Global_database_id" = '0'
go
SET OPTION "PUBLIC"."Database_authentication" = ''
go
SET OPTION "PUBLIC"."First_day_of_week" = '7'
go
SET OPTION "PUBLIC"."Fire_triggers" = 'On'
go
SET OPTION "PUBLIC"."External_remote_options" = 'Off'
go
SET OPTION "PUBLIC"."Extended_join_syntax" = 'On'
go
SET OPTION "PUBLIC"."Exclude_operators" = ''
go
SET OPTION "PUBLIC"."Escape_character" = 'On'
go
SET OPTION "PUBLIC"."Echo" = 'On'
go
SET OPTION "PUBLIC"."Divide_by_zero_error" = 'On'
go
SET OPTION "PUBLIC"."Delete_old_logs" = 'Off'
go
SET OPTION "PUBLIC"."Delayed_commits" = 'Off'
go
SET OPTION "PUBLIC"."Delayed_commit_timeout" = '500'
go
SET OPTION "PUBLIC"."Default_timestamp_increment" = '1'
go
SET OPTION "PUBLIC"."Date_order" = 'YMD'
go
SET OPTION "PUBLIC"."Date_format" = 'YYYY-MM-DD'
go
SET OPTION "PUBLIC"."Float_as_double" = 'Off'
go
commit work
go

