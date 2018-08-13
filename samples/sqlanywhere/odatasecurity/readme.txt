// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// *********************************************************************

		       SAP Sybase OData Server: Secure View Sample

Purpose
-------
This sample demonstrates how to use various features of the SAP Sybase OData Server including:
- Loading a server certificate to enable HTTPS communication.
- Using database authentication to limit access to sensitive data.
- Using an OSDL model to filter tables from the service schema and enable access 
  to database views.


Requirements
------------
The sample requires the third-party component OData4J Version 0.7
 - This component is available at http://code.google.com/p/odata4j/

The sample assumes that
 - you have a SQLANY16 environment variable set to your SQLAnywhere directory.
   This should be done for you by the SQL Anywhere install.	
 - you have defined the "SQL Anywhere 16 Demo" ODBC data source.
   This should have been done for you by the SQL Anywhere install.	
 - you have a JDK installed, including the Java compiler (javac).
 - you have a JAVA_HOME environment variable set to your JDK installation
   directory.
 - you have a JAVAC environment variable set to your JDK's javac executable.
 - you have a CLASSPATH environment variable that includes the full path
   to the OData4J client bundle .jar file (odata4j-0.7.0-clientbundle.jar).


Procedure
---------
If you are running this sample on Unix, substitute .sh for .bat in the 
following instructions.

Run build.bat to compile the Java class file and enable the EmployeeConfidential
view in the database.

Run start_server.bat to launch the OData server.

Run run.bat to run the Java program that will read from the service.

Run stop_server.bat to shut down the OData server.

Run clean.bat to delete all generated files.

