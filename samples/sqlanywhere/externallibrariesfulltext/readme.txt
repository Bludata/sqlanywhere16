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

		    Full Text Search with External Libraries

Purpose
-------
This directory contains external prefilter and term breaker sample libraries,
each defined in a DLL that can be called by the SQL Anywhere database server
if specified using the ALTER TEXT CONFIGURATION statement.

Source code for the DLLs can be found in the pf_sample.cpp, tb_sample.cpp and
ifilterprefilter.cpp files.

The pf_sample library presents a simple typical prefilter library conforming
to the workflow presented in the documentation. The prefilter provided by the
pf_sample library accepts text documents that contain tags denoted by '<' and
'>' (for example, xml or html documents). The prefilter filters out the tags
and returns the remaining data to the caller.

The ifilterprefilter library is a more complex prefilter library that uses the
IFilter interface to extract text from documents such as PDF, Word or Excel
files. This library consumes all of the document data from its producer
on the first call to get_next_piece. This behaviour is required because the
IFilter interface requires the complete document before any filtered data can
be returned.
Typically, if Microsoft Office is installed on the computer, IFilters for the
Microsoft Office documents, as well as for XML and txt documents are available.
Additionally, if Adobe Acrobat Reader is installed, IFilter for PDF documents
is available. The ifilterprefilter library utilizes the IFilters available on
the computer where the database server is running. 
IFilter libraries for additional document types, or different IFilters for PDF
documents can be obtained from 3rd party vendors.

The tb_sample library is a simple term breaker library. It differs from the
built-in SQL Anywhere GENERIC term breaker in two ways:
1) apostrophe is treated as a part of the word, not as a term breaker, and
2) all letters are converted to lower case to allow for case insensitive
searching on a case sensitive database.

Requirements
------------
Each sample library assumes that you have a SQLANY16 environment variable set
to your SQL Anywhere install directory. This variable was set for you during
the SQL Anywhere install.

On Windows, the sample libraries also assume that
 - you have Visual Studio .NET 2003 (or later) installed so that you can
   use the makefile
 - you have a VCINSTALLDIR environment variable set. This variable should have
   been set for you by the Visual Studio install. If it was not set, you can
   use the vcvars32.bat file installed by Visual Studio to set the variable.

The source code for pf_sample and tb_sample can be compiled with other
compilers as well.

See the build.sh file for UNIX-specific build instructions for pf_sample and
tb_sample libraries.

See the documentation for the CONTAINS search condition for more information
about keywords and full text queries.

The ifilterprefilter sample requires that the Microsoft Word document IFilter
and PDF IFilters be available on the computer where the database server is
running in order to execute successfully.

Setup Steps
-----------
On Windows:
1.  Run build.bat to compile the DLLs. Note that IFilter sample can only be
    compiled on Windows, and requires the Visual Studio compiler.
2.  Run show_exports.bat to display the exported symbols for all libraries
3.  Copy the DLLs to a directory in your PATH.

On UNIX:
1.  Run build.sh to compile the shared objects. Note that IFilter sample is
    not included with the UNIX sample as it cannot be compiled under UNIX.
2.  Run show_exports.sh to display the exported symbols for all libraries
3.  Copy the shared objects to a directory in the library path.

On both platforms:
1.  Start a database server on any database
2.  Start DBISQL and connect to the database

Procedure
---------
To test simple prefilter sample (pf_sample.dll):
    In DBISQL, execute the following command to define the table, text
    configuration and text index for the test:
	read pf_sample.sql

    In DBISQL, execute the following command to populate and query the table:
	read pf_sample_tests.sql
    The results are displayed in the results pane. Before doing any successful
    inserts, the test also performs an unsuccessful insert to get the error
    message from the server. See messages in the messages pane.

    Full text queries used in the sample search for a single term, 'body' or
    'page'. If the prefilter was not used, body would be found in all html
    documents inserted, and page would be found in the xml document inserted.
    With the prefilter, both terms are found only when they appear in the
    actual text of the documents, not in the tags.

To test IFilter prefilter sample (Windows-only):
    In DBISQL, execute the following command to define the user, table, text
    configuration and text index for the test:
	read ifilter_pf.sql

    In DBISQL, execute the following command to populate and query the table:
	read ifilter_pf_tests.sql
    Example queries for this sample demonstrate the differences in behaviour
    between phrases and AND searches, as well as the differences between "not"
    being treated as a term vs. as a keyword.

    Note that this prefilter will not return an error if it cannot identify
    the extension of the document, or if the document is invalid. In most
    error cases, the prefilter library will skip the offending document.

To test simple term breaker sample:
    In DBISQL, execute:
	read tb_sample.sql
    to define table, text configuration and text index for the test.

    In DBISQl, execute the following command to populate and query the table:
	read tb_sample_tests.sql
    Full text queries used in the sample search for:
	- term 'p* - any term beginning with an apostrophe, followed by a p.
	If the GENERIC built-in term breaker of SQL Anywhere server were used,
	this query would match any term beginning with p, as apostrophe would
	not be included as part of the term. Additionally, on a case sensitive
	database this query would not match the actual term it is looking for
	('P'), since the query contains lower-case p.
	With the sample term breaker, the only document that will match the
	query is the document containing 'P'.
	- term mary's. As above, this query relies on the term conversion
	to lower case to find the required document. If apostrophe was not
	included in the term, this query would match the document beginning
	with 'Mary s '.

All generated files can be deleted by running clean.bat.
