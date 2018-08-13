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


Tracetime Perl Script


Purpose
-------

The main purpose of the Tracetime Perl Script is to try to determine
statement execution times using request log output, allowing the most
expensive statements to be located. For statements that are "executed"
such as inserts and updates, this is relatively straightforward. For
queries, the approach is to calculate the time from preparing the
statement to dropping it, including describing it, opening a cursor,
fetching rows, and closing the cursor. For most queries, this will be
an accurate reflection of the amount of time taken. In cases where the
cursor is left open while other actions are performed, the time for
the statement will be shown as a large value but will not be a true
indication that the query is costly.


Requirements
------------

The script requires that the server be started with the following
command line options to create the request log:

     -zr sql -zo request-log-filename

The "-zr sql" option enables request logging and specifies that only a
subset of the requests are logged. The "-zo request-log-filename"
option specifies the location for logging. Request logs can also be
created using the sa_server_option stored procedure. See the
documentation for descriptions of the following parameter values for
this procedure:
    RequestLogging
    RequestLogFile
    RequestLogMaxSize
    RequestLogNumFiles

Procedure
---------

To run the script, use the following command line:

     perl tracetime.pl request-log-filename [format={fixed|sql}] [conn=nnn]

To find the most costly statements, run the script with the
"format=fixed" parameter and pipe the output through "sort/R" (on
Windows) to order the longest statements first. For example:

    perl tracetime.pl myreqlog.txt format=fixed | sort /rec 65535 /R >sorted.txt

