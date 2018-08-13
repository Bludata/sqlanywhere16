# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
			UltraLite C/C++ CustDB Sample

Purpose
-------
This directory holds a sample application called CustDB written using
the C/C++-based interfaces supported by UltraLite.

For complete documentation, please see "UltraLite CustDB samples" in the
UltraLite Database Management and Reference section of the documentation
(http://dcx.sybase.com/1600en/uladmin/fo-custdb.html), and "Exploring the
CustDB sample for MobiLink" in the MobiLink - Getting Started section of
the documentation (http://dcx.sybase.com/1600en/mlstart/ml-custdb.html).


Files
-----
custdb.h - defines the CDemoDB class, which contains the database code
custdb.sqc - Embedded SQL implementation of CDemoDB (not used for iPhone/ 
             Mac OS X) 
custdbcpp.cpp - C++ Interface implementation of CDemoDB


Building the sample (Windows)
-----------------------------
Open the project file using Visual Studio (the project in VS9 should load
with Visual Studio 2008 and 2010).
Choose your target platform in Visual Studio and build the project.

Building the sample (Linux)
---------------------------
Run the build.sh script in the linux sub-directory.
(On a Windows desktop, run the mv_build.sh script in the Linux sub-directory.)

Building the sample (iPhone)
----------------------------
Open the Xcode project iphone/CustDB.xcodeproj and build the project.


The UltraLite database file must be deployed with the application.  Pre-built 
database files are supplied in the CustDB directory.

The command shell scripts makedbs.cmd (Windows) and makedbs.sh (Mac OS X and
Linux) can be used to rebuild both the SQL Anywhere consolidated database and
the UltraLite remote database.


Start the MobiLink server before running the CustDB sample - the sample will
automatically synchronize when first launched.

Running MobiLink (Windows)
--------------------------
Start MobiLink using the MobiLink -> "Synchronization Server Sample" link in
the start menu.

Running MobiLink (Linux)
------------------------
Run the mobilink.sh script.

Running MobiLink (iPhone)
-------------------------
It is not necessary to start MobiLink - by default the CustDB application will
synchronize through a Relay Server hosted by Sybase at relayserver.sybase.com
(with URL suffix /ias_relay_server/client/rs_client.dll/sqlany.CustDB16).

On all systems, MobiLink can also be started with the following command line:
    mlsrv16 -c "DSN=SQL Anywhere 16 CustDB" -vcrs

Note that the "SQL Anywhere 16 CustDB" datasource is created by the installer
on Windows, and by the sample_config script on Mac OS X and Linux.

By default, only the TCPIP MobiLink network protocol is started. To use HTTP,
for example, add the -x http switch. Note that on Mac OS X and Linux, you must
be root to start HTTP on port 80.
