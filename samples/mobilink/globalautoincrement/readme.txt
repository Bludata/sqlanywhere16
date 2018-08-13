# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
*******************************************************************
You may use, reproduce, modify and distribute this sample code without limitation, 
on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  

*******************************************************************

		    MobiLink Global Autoincrement Sample

Purpose
-------
The sample illustrates how the global autoincrement column default
provides a useful way of maintaining primary key uniqueness throughout
a MobiLink installation.

The sample shows synchronization between a consolidated database and two
remote databases.

Each database consists of a single table, holding customer data. 
The synchronization scripts are the default generated scripts, which
employ snapshot synchronization.

Requirements
------------
The sample assumes that
 - you have SQL Anywhere Studio installed

Procedure
---------
If you are running this sample on UNIX, substitute .sh for .bat in the 
following instructions:

Run build.bat to create the consolidated and remote databases, 
                 add scripts, publications, and data.

Run step1.bat to start the MobiLink synchronization server.
Run step2.bat to - synchronize, 
                 - add additional data at remote and consolidated databases,
		 - synchronize again.
Run step3.bat to shut down the MobiLink synchronization server.

Run report.bat to list contents of each database to report.txt.

Run clean.bat to delete all generated files.

