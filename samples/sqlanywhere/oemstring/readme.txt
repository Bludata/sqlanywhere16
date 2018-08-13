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

		       Database OEM String Extraction Example

Purpose
-------
This directory contains two examples on how to extract the OEM string
from a database file header.

Requirements
------------
The PERL sample assumes that
 - you have perl installed on your computer.

Regardless of the operating system, the C sample assumes that
 - you have a SQLANY16 environment variable set to your SA directory.
   This should be done for you by the SQL Anywhere install.	
If you use Windows, the C sample also assumes that
 - to use the makefile, you have Visual Studio 2005 or a later version
   installed.
 - you have an environment variable VCINSTALLDIR set. This should be done for 
   you by the Visual Studio install, or you can use the vcvars32.bat file 
   installed by Visual Studio. 

The source code can be compiled with other compilers.

For UNIX build instructions, see the file build.sh.

Procedure
---------
Run build.bat (build.sh on UNIX) to compile the dboem.exe (dboem on UNIX)
binary.

If you have not already set an OEM string in a database,
then start your database and then run:
	dbisql set option public.oem_string = 'This is a sample OEM string.'
and then shutdown your database.

Run either:
	Windows - .\dboem.exe <name-of-a-database-file>
	UNIX    - ./dboem <name-of-a-database-file>
or
	Windows - perl .\dboem.pl <name-of-a-database-file>
        UNIX    - perl ./dboem.pl <name-of-a-database-file>

Both of these commands will print out the oem string that is currently set
within the database.

The perl script will, by default, print the oem string in hex.
To make the perl script to print a single text line, use:
	perl .\dboem.pl -t <name-of-a-database-file>


Run clean.bat (clean.sh on UNIX) to delete all generated files.
