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

			     Database Tools Sample

Purpose
-------
This directory holds a database tools application that illustrates
how to call and compile the database tools library.
The application makes a backup of the SQL Anywhere sample
database to the C:\Temp directory on Windows or the /tmp directory
on UNIX.

Source code for the application is in main.cpp.

Requirements
------------
On Windows, the sample assumes that you have Visual Studio .NET 2003 or 
Visual Studio 2005 installed, and have an environment variable 
VCINSTALLDIR set. This should be done for you by the Visual Studio install, 
or you can use the vcvars32.bat file installed by Visual Studio. 

The source code can be compiled with other compilers.

See the file build.sh for UNIX-specific build instructions.

Procedure
---------
Run build.bat on Windows or build.sh on UNIX to compile the application.

Run run.bat on Windows or run.sh on UNIX to execute the application. The
backup copy of the database is in C:\TEMP.

Run clean.bat on Windows or clean.sh on UNIX to delete all generated files.
