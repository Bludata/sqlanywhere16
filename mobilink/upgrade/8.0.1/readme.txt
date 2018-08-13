# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
Upgrading A MobiLink Consolidated Database From Version 8.0.1
=============================================================

This upgrade process does the following:
    
    - Adds the following columns:
	ml_user.last_upload_time
	ml_user.last_download_time
    - Adds the following columns:
	ml_subscription.last_upload_time
	ml_subscription.last_download_time
	ml_subscription.subscription_id
    - Changes the ml_subscription primary key to ( user_id, subscription_id )
    - Replaces the ml_add_user stored procedure
    - Adds the ml_add_dnet_table_script and ml_add_dnet_connection_script
      stored procedures.

ASA consolidated databases are upgraded via the normal ASA upgrade process.
Do not follow the steps below if you are using an ASA consolidated database.

In the steps below, substitute one of the following for ???:

    ase	    Sybase Adaptive Server Enterprise
    mss	    Microsoft SQL Server
    ora	    Oracle
    db2tolong IBM DB2 UDB with short name procedures installed
    db2     IBM DB2 UDB with long name procedures installed. Requires 
	    UDB version 6.0 or higher.
    
Please note that the SQL script files mentioned below may require
modification to work in your environment. This is particularly true for
the DB2 scripts, which contain a connection statement that must be altered
before it will work. If you do need to modify a script file, we suggest
that you first copy the script file and modify the copy.

Step 1 
------
Apply the MobiLink\upgrade\8.0.x\upgrade_???.sql SQL script to the
consolidated database. 

