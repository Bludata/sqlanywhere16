# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
Upgrading A MobiLink Consolidated Database From Version 7.0.x
=============================================================

This upgrade process does the following:

    - Adds the last_upload_time and last_download_time columns
      to the ml_user table.

    - Adds the script_language column to the ml_script table.
    
    - Adds the ml_subscription table.

    - Replaces the ml_add_user stored procedure.
    
    - Replaces the ml_add_table_script and ml_add_connection_script
      stored procedures.
      
    - Adds the ml_add_java_table_script and ml_add_java_connection_script
      stored procedures.
      
    - Adds the ml_add_lang_table_script and ml_add_lang_connection_script
      stored procedures.

The following steps are only for DB2:

    - Export the data of old ml_user to a file called ml_userdata.ixf.
    
    - Drop the old ml_user table.

    - Recreate the new ml_user table.
    
    - Import the data from ml_userdata.ixf to the new ml_user table.

ASA consolidated databases are upgraded via the normal ASA upgrade process.
Do not follow the steps below if you are using an ASA consolidated database.

In the steps below, substitute one of the following for ???:

    ase	    Sybase Adaptive Server Enterprise
    mss	    Microsoft SQL Server
    ora	    Oracle
    
Please note that the SQL script files mentioned below may require
modification to work in your environment. This is particularly true for
the DB2 scripts, which contain a connection statement that must be altered
before it will work. If you do need to modify a script file, we suggest
that you first copy the script file and modify the copy.

The steps for DB2 UDB consolidated datbases are different, and are shown
below the steps for non-DB2 consolidated databases.


Step 1 (non-DB2)
----------------

Apply the MobiLink\upgrade\7.0.x\upgrade_???.sql SQL script to the
consolidated database. If an error occurs because the ml_add_user script
isn't defined when it is dropped, you may safely ignore the error.

No further steps are required.


Upgrading IBM DB2 UDB Consolidated Databases
--------------------------------------------

The upgrade path for your IBM DB2 UDB database depends on the DB2 version
you want to use.

Prior to IBM DB2 UDB version 6.0, table and procedure names were limited
to 18 characters. The MobiLink setup scripts in MobiLink versions
7.0.x take this into account and truncate all table and procedure names
to 18 characters or less.

When MobiLink Server connects to a DB2 UDB consolidated database, it
queries the ODBC driver for the longest possible table name.
MobiLink Server then uses that length to truncate any table
references in the SQL statements that it uses to access the MobiLink
system tables.

IBM DB2 UDB versions 6.0 and higher allow much longer table and
procedure names. When MobiLink Server queries the ODBC driver for the
longest possible table name, it is returned a value that is long enough for
all MobiLink system tables and stored procedures, so no name truncation is
performed by MobiLink Server.

There two different upgrade paths. Each is described below.

A) MobiLink 7.0.x on DB2 UDB 5.x to MobiLink 9.0.x on DB2 UDB 5.x

   The MobiLink system table names and stored procedure names are still
   limited to 18 characters.

B) MobiLink 7.0.x on DB2 UDB 5.x to MobiLink 9.0.x on DB2 UDB 6.x or higher

   The MobiLink system table names and stored procedure names are
   not truncated. Data in the MobiLink system tables that have truncated
   names must be copied into new tables with full names. The tables with
   truncated names must then be deleted. Similarly, MobiLink stored
   procedures with full names will be created, and stored procedures
   with truncated names will be deleted.

The different steps for (A) and (B) are listed below.

A) Step 1 (DB2 5.x)
-------------------

Copy the MobiLink\setup\SyncDB2.class file to the SQLLIB\FUNCTION directory
on the DB2 server machine. You probably need to restart the instance.
Please consult your DB2 documentation for details.

A) Step 2 (DB2 5.x)
-------------------

Apply the MobiLink\upgrade\7.0.x\upgrade_db2.sql SQL script to the
consolidated database. The start of this script contains a CONNECT
statement that must be changed so it will work with the instance
you want to connect to. Create a copy of this script and modify the copy.

If an error occurs because the ml_add_user script isn't defined
when it is dropped, you may safely ignore the error.

No further steps are required.


B) Step 1 (DB2 6.x or higher)
-----------------------------

Upgrade your DB2 UDB 5.x database to the newer version. Ensure that the old
MobiLink system tables and stored procedures exist in the upgraded database.
Please consult your DB2 documentation for details on upgrading your DB2
database.

B) Step 2 (DB2 6.x or higher)
-----------------------------

Copy the MobiLink\setup\SyncDB2Long.class file to the SQLLIB\FUNCTION
directory on the DB2 server machine. You probably need to restart the
instance. Please consult your DB2 documentation for details.

B) Step 3 (DB2 6.x or higher)
-----------------------------

Apply the MobiLink\upgrade\7.0.x\upgrade_db2tolong.sql SQL script
to the consolidated database. The start of this script contains
a CONNECT statement that must be changed so it will work with the instance
you want to connect to. Create a copy of this script and modify the copy.

If an error occurs because the ml_add_user script isn't defined
when it is dropped, you may safely ignore the error.

No further steps are required.
