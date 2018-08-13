# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
Upgrading A MobiLink Consolidated Database From Version 8.0.0
=============================================================

This upgrade process is only for DB2 UDB and does the following:

    - Export the data of old ml_user to a file called ml_userdata.ixf.
    
    - Drop the old ml_user table.

    - Recreate the new ml_user table.
    
    - Import the data from ml_userdata.ixf to the new ml_user table.


Upgrading IBM DB2 UDB Consolidated Databases
--------------------------------------------

The upgrade path for your IBM DB2 UDB database depends on the DB2 version
you want to use.

Prior to IBM DB2 UDB version 6.0, table and procedure names were limited
to 18 characters. The MobiLink setup scripts in MobiLink versions
8.0.0 take this into account and truncate all table and procedure names
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

In this upgrade process, there is no difference between long name and short
name DB2 UDB. But for later convenience, we still give two different upgrade
script files

To do upgrading, only apply the MobiLink\upgrade\8.0.0\upgrade_db2tolong.sql
SQL script or the Mobilink\upgrade\8.0.0\upgrade_db2.sql SQL script
to the consolidated database. The start of this script contains
a CONNECT statement that must be changed so it will work with the instance
you want to connect to. Create a copy of this script and modify the copy.


No further steps are required.
