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

SQL Anywhere Fetch Performance Tools
/**********************************/

FETCHTST:
--------

FETCHTST can be used to test fetch rates for an arbitrary query.
The query is specified in a text file (default test.sql) as a SELECT statement
or procedure call.
FETCHTST reads this file, PREPAREs a SQL statement for the query, DESCRIBEs
the result set, and fetches the rows. By default, the row values are not saved.
A connection string can be specified to allow FETCHTST to connect to
the server; the default is UID=DBA;PWD=sql. At completion, the application will
display the times taken to execute each part of the query.

Multiple statements can be specified in the file, with each terminated by a line
containing only "go" at the start of the line. Statements which do not return
result sets can also be included. Comments (//, --, and /* */) are permitted.

FETCHTST is implemented using ESQL.

Usage: FETCHTST [options] [<file1> [.. <fileN>]]
Options:
   -a [ams]        : add to output m:min/max, or s:std.dev, or a:all
   -b nnn          : fetch nnn records at a time
   -c conn_str     : database connection string
   -ce             : continue execution after SQL error
   -d describe_type: statement or cursor
   -e fname        : execute file of SQL before running sql statements
   -es cmd_str     : execute the command string at the start of each iteration
   -ee cmd_str     : execute the command string at the end of each iteration
   -f file         : output rows to 'file' (otherwise rows are not output)
   -g              : generate category summary (group by SQL text prefix)
   -ga             : same as -aa -g -gc -u
   -gc             : print engine cpu usage per statement
   -gm nnn         : skip the first nnn 'message' statements
   -gs nnn         : skip the first nnn 'select' queries
   -gt             : print statement totals only
   -h              : this help usage information
   -i nnn          : think time (milliseconds) between statements
   -is n           : set isolation level at beginning to n
   -j nnn          : repeat each file nnn times
   -k              : disable prefetching
   -l nnn          : stop after nnn records
   -m              : display summary only
   -n              : execute queries only
   -o outfile      : record fetch duration in file
   -oa outfile     : record all output in file
   -oc outfile     : record SQL step times to comma delimited file
   -oc help        : display help on how to load -oc outfile into a table
   -p              : display plan
   -q              : quiet mode
   -r nnn          : output status every nnn rows
   -ro             : READ ONLY cursors (default FOR UPDATE)
   -s nnn          : skip by nnn records
   -t cursor_type  : INSENSITIVE or SCROLL
   -u              : display timers in microseconds (default milliseconds)
   -v              : display statement before executing
   -w nnn          : number of OPEN/CLOSEs
   -x nnn          : number of DESCRIBEs to execute for each query
   -yd nnn         : wait nnn milliseconds after engine starts
   -ym             : start a new engine for each iteration or file
   -yn eng_name    : name the engine 'eng_name'
   -ys start_str   : start the engine using the given start string
   -z nnn          : fetch as strings - max size nnn
<file1> .. <fileN> : name of file(s) containing sql statement(s)
                     - file(s) may contain multiple queries and other SQL,
                       separated by a line containing only "go"
                     - default file is "test.sql" if none specified.


ODBCFET:
-------

ODBCFET is similar to FETCHTST, but with less functionality.  ODBCFET is
implemented using ODBC.

Usage: ODBCFET [options] fname
Options:
   -b nnn          : fetch nnn rows at a time
   -c conn_str     : database connection string
   -d              : display datatypes
   -f              : use SQLFetch (not SQLExtendedFetch)
   -g              : use SQLGetData (not SQLBindCol)
   -l nnn          : stop after nnn rows
   -o file         : record fetch duration to file
   -t cursor_type  : DYNAMIC, INSENSITIVE, or SCROLL (default NOSCROLL)
   -z              : fetch as string (default uses native types)


OLEDBFET:
--------

OLEDBFET is also similar to FETCHTST, but with less functionality.  OLEDBFET is
implemented using OLEDB and is only available on Windows.

Usage: OLEDBFET [options] <file>
Options:
   -b nnn          : fetch nnn records at a time
   -c conn_str     : database connection string
   -d              : show described types & lengths
   -l nnn          : stop after nnn records
   -n              : just fetch row, don't get into user buffer
   -t cursor_type  : DYNAMIC, INSENSITIVE or SCROLL (default FORWARD_ONLY)
   -v              : show data fetched for all rows
   -z nnn          : fetch as strings - max size nnn
<file>             : name of file containing sql statement
                     - default file is "test.sql" if none specified.
