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

		       External Stored Procedure Sample

Purpose
-------
This directory contains several sample external stored procedures defined
in a DLL which can be called from SQL using SQL Anywhere.  
Source code for the DLL is in extproc..

Requirements
------------
The sample assumes that
 - you have a SQLANY16 environment variable set to your SA directory.
   This should be done for you by the SQL Anywhere install.	
On Windows, the sample also assumes that
 - to use the makefile, you have Visual Studio .NET 2003 or Visual Studio 2005 installed
 - you have an environment variable VCINSTALLDIR set. This should be done for 
   you by the Visual Studio install, or you can use the vcvars32.bat file 
   installed by Visual Studio. 

The source code can be compiled with other compilers.

See the file build.sh for UNIX-specific build instructions.

Procedure
---------
Run build.bat on Windows or build.sh on UNIX to compile the DLL (shared
object on UNIX).

Run show_exports.bat on Windows or show_exports.sh on UNIX to display
the exported symbols.

Copy the DLL (shared object) to a directory in the path on Windows or in 
the library path on UNIX. 

Start a database server on any database.

Start DBISQL and connect to the database.

In DBISQL, execute:
    read extproc.sql
to define the stored procedures.

In DBISQL, execute:
    read tests.sql
to call the procedures. The results are displayed in the results pane.

All generated files can be deleted by running clean.bat.


Debugging an external procedure
-------------------------------

The following assumes that you will be debugging under Windows using 
Visual Studio 2005 or a later version.

 -Stop the database server to ensure that it is not using the external 
    procedure DLL.
 - Edit the makefile and change DebugOptions to be:
    DebugOptions=/Od /Zi
 - Run clean.bat
 - Run build.bat
 - Start the database server using:
   devenv /debugexe <SA-bin-dir>\dbeng16.exe <full path to database>
 - When Visual Studio starts, use File/Open to navigate to the extproc.cpp 
   file. Double click on extproc.cpp to open that file.
 - Set a breakpoint in the function you wish to debug.
 - Press F5 to start execution of the database server. You will be notified 
   that there is no debugging information available for the database server. 
   Click OK to proceed.
 - Start DBISQL and execute a call to the stored procedure you wish to debug. 
   This should cause the breakpoint to be hit.
  
