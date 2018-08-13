# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
Upgrading A MobiLink Consolidated Database From Version 9.0.0 
==============================================================

This upgrade process does the following:
    
    - Replaces all Mobilink system stored procedures
    - Adds the ml_property table and the ml_add_property stored procedure
    - Adds server-initiated synchronization (SIS) tables and stored procedures

ASA consolidated databases are upgraded via the normal ASA upgrade process.
Do not follow the steps below if you are using an ASA consolidated database.

In the steps below, substitute one of the following for ???:

    db2tolong IBM DB2 UDB with short name procedures installed
    db2       IBM DB2 UDB with long name procedures installed. Requires 
	    UDB version 6.0 or higher.
    
Please note that the SQL script files mentioned below may require
modification to work in your environment. This is particularly true for
the DB2 scripts, which contain a connection statement that must be altered
before it will work. If you do need to modify a script file, we suggest
that you first copy the script file and modify the copy.

Step 1 
------
Apply the MobiLink\upgrade\9.0.0\upgrade_???.sql SQL script to the
consolidated database. 

