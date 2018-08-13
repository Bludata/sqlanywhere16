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

		       Using Java in the database sample

Purpose
-------
This directory holds source code for the example in 
"Using Java in the database".

Requirements
------------
The sample assumes that
 - you have a SQLANY16 environment variable set to your SA directory.
   This should be done for you by the SQL Anywhere install.	
 - you have defined the "SQL Anywhere 16 Demo" data source.
   This should also be done for you by the SQL Anywhere install.	
 - you have a JDK installed, including the Java compiler (javac).
 - you have a JAVA_HOME environment variable set to your JDK installation
   directory.
 - you have a JAVAC environment variable set to your JDK's javac executable.
 - you have a CLASSPATH environment variable set to this directory before
   running the demo database.


Procedure
---------
If you are running this sample on UNIX, substitute .sh for .bat in the 
following instructions.

Run build.bat to compile the Java class file, install it into the database,
    and create cover functions for the Java methods in this class file.

Run run.bat to call the Java methods.

Run clean.bat to delete all generated files except the report files.
