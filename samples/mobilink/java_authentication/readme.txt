# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
*******************************************************************
You may use, reproduce, modify and distribute this sample code without limitation, 
on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  

*******************************************************************

			      MobiLink Java Sample

Purpose
-------
The sample illustrates how to write Java synchronization logic. The sample
uses Java synchronization logic to provide user authentication.

The database consists of two tables:
- emp contains a list of salespeople.
- cust contains a list of customers.
There is a one-to-many relationship between salespeople and customers.

The remote database is one salesperson's database. It receives the
following data from the consolidated database:
- only one row from emp (employee emp2).
- only those customers assigned to emp2.
All the relevant data is downloaded to the remote database each time (snapshot
synchronization).

All customer data entered at the remote database is synchronized to the
consolidated database.

On the first synchronization, a user ID is added to the login_added table.
On subsequrent synchronizations, a row is added to the login_audit table.
In this example, there is no test before adding a user ID to the login_added
table.

Procedure
---------
This test requires JDK version 1.6.  Please make sure the Sun Java JDK 1.6
is installed on your test machine and one of the following environment
variables, JAVAHOME, JAVA_HOME, JDKHOME, or JDK_HOME is set properly.

If you are running this sample on UNIX, substitute .sh for .bat in the 
following instructions.

Run build.bat to create the consolidated and remote databases, 
                 add scripts, publications, and data.

Run step1.bat to start the MobiLink synchronization server.
Run step2.bat to synchronize 
Run step3.bat to shut down the MobiLink synchronization server.

Run report.bat to list contents of each database to report.txt.

At the end of this process, data is synchronized and a row is added
to login_added. You may wish to run through the process again to
see a row added to login_audit.

Run clean.bat to delete all generated files.

Files
-----
build_consol.sql and build_remote.sql contain SQL instructions to create the
database objects. build_remote.sql creates a publication, a synchronization 
user and a synchronization subscription. The synchronization scripts at the
consolidated database are created automatically by the MobiLink database
server.
