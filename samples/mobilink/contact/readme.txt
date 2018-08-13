# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
*******************************************************************
You may use, reproduce, modify and distribute this sample code without limitation, 
on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  

*******************************************************************

		    MobiLink Contact Sample

Purpose
-------
The sample illustrates synchronization of data between
a consolidated database and two remote databases.

The database consists of three main tables:
- SalesRep contains a list of salespeople.
- Customer contains a list of customers.
- Contact contains a list of contacts. A contact is a person at one of 
  the customers.
- Product is a list of products sold to the customers.

There is a one-to-many relationship between salespeople and customers, and 
a one-to-many relationship between customers and contacts. The Product
table is not related to the other tables.

Each remote database is one salesperson's database. It has two
publications:
Contact: 
  sends the following data to the consolidated database:
  - changes to the customer and contact tables.
  receives the following data from the consolidated database:
  - only one row from SalesRep. 
  - only those customers assigned to them.
  - only those contacts associated with customers assigned to them.

Product:
  sends the following data to the consolidated database:
  - any change in quantity associated with an order.
  receives the following data from the consolidated database:
  - a complete snapshot of all product information.

The consolidated database contains synchronization scripts to illustrate
the following:
  - maintenance of information in tables across foreign key relationships.
  - scripts that permit territory realignment (reassignment of customers
    across sales reps.)
  - error logging.
  - conflict resolution on the Product table.

Procedure
---------
If you are running this sample on UNIX, substitute .sh for .bat in the 
following instructions.

Run build.bat to create the consolidated and remote databases, 
                 add scripts, publications, and data.

Run step1.bat to start the MobiLink synchronization server.
Run step2.bat to synchronize.
Run step3.bat to shut down the MobiLink synchronization server.

You can modify the information in the tables and resynchronize 
to watch the scripts at work.

Run report.bat to list contents of each database to report.txt.

Run clean.bat to delete all generated files.

