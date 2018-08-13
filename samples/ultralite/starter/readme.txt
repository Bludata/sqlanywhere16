# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
			UltraLite C++ Starter Sample

Purpose
-------
This directory holds a simple sample application that demonstrates how to use
the UltraLite C++ API to create and connect to databases, create tables, insert
and fetch data, and capture errors.

For complete documentation of UltraLite connection parameters, please see:
    http://dcx.sybase.com/1600en/uladmin_en16/fo-connparms.html

And for creation parameters please see:
    http://dcx.sybase.com/1600en/uladmin_en16/fo-creationparms.html

Files
-----
ulsample.cpp - sample code
build.sh - script to build the sample using g++

On Mac OS X, consider creating an Xcode project to host this sample. Start by
creating a new Mac OS X Application/Command Line Tool project. Please see the
"Application development" section in the UltraLite - C and C++ Programming
Guide to learn how to configure an UltraLite Xcode project. Also consider
stepping through the application in the debugger to see how it works.

This sample creates its own database if one doesn't exist. Subsequent runs of
the sample add more data to the database. After running the sample, also try
using dbisql to examine the database:
    dbisql -ul -c dbf=ulsample.udb
