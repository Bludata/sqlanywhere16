# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
Upgrading from Version 9.0.1 and later to Version 9.0.2
=======================================================

Upgrading A MobiLink Consolidated Database From Version 9.0.1 
==============================================================

This upgrade process does the following:
   
    - Rename the "ml_user" column in ml_listening table to "name" 
    - Drops the unused tables ml_qa_repository_props and ml_qa_global_props
    - Drops the unused procedure ml_qa_staged_status_for_client
    - Creates the ml_qa_delivery table
    - Alters the ml_qa_repository table
    - Populates the ml_qa_repository and ml_qa_delivery tables

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
Apply the MobiLink\upgrade\9.0.1\upgrade_???.sql SQL script to the
consolidated database. 

