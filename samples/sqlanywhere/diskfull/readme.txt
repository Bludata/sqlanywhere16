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

		       Disk-Full Callback Sample

Purpose
-------
This directory contains a sample Disk-Full Callback DLL.  This DLL
contains an entry point that can be invoked by SQL Anywhere when it encounters
an OS Disk Full condition.

Requirements
------------
Regardless of the operating system, the sample assumes that
 - you have a SQLANY16 environment variable set to your SA directory.
   This should be done for you by the SQL Anywhere install.	
On Windows, the sample also assumes that
 - to use the makefile, you have Visual Studio 2005 or a later version 
   installed.
 - you have an environment variable VCINSTALLDIR set. This should be done for 
   you by the Visual Studio install, or you can use the vcvars32.bat file 
   installed by Visual Studio. 

The source code can be compiled with other compilers.

See the file build.sh for UNIX-specific build instructions.

Procedure
---------
Run build.bat on Windows or build.sh on UNIX to compile the DLL 
(shared object on UNIX).

Run show_exports.bat (show_exports.sh on UNIX) to display the exported
symbols.

Copy the DLL (shared object on UNIX) to a directory in the path. 

Start a database server with the command line option -fc diskfull.dll
(libdiskfull.sl HP-UX PARISC, libdiskfull.so on other UNIXes).


Customizing the Callback
------------------------
The callback function is designed to be generic.  It tries simply to
invoke a user-provided batchfile (or shell script, if on UNIX).  The
batch file should attempt to take some meaninful diagnostic or
corrective action.  If desired, this action could be performed within
the callback itself, rather than invoking a batch file.  To change the
name or location of the batchfile, or take other action on the
diskfull condition, modify the file diskfull.cpp.


  
