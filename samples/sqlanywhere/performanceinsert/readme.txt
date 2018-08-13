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

SQL Anywhere Insert Performance Tool
/**********************************/

INSTEST can be used to test insert rates into a table. It reads a file which 
contains a query. By default, INSTEST will DESCRIBE the 
result types of the query and will then use PUT requests to insert rows.
The query is specified in a text file (default test.sql) as a SELECT statement.
Alternatively, the text file can contain a SELECT statement and an INSERT
statement, separated by a semi-colon. The SELECT is used to indicate the types
of the columns being inserted.
The number of rows to be generated is specified as an option.
If required, INSTEST can generate unique values for each column. A starting 
value can be specified. If the table being populated has a DEFAULT AUTOINCREMENT
primary key, omitting the key column from the SELECT list may be sufficient
to allow multiple rows to be inserted without violating uniqueness constraints.
If the table contains foreign key references, these can be handled by 
supplying appropriate constants in the INSERT statement.

Usage: INSTEST [options] [fname]
Options:
   -c conn_str     : database connection string
   -i              : use INSERT (default = PUT)
   -k rows         : CHECKPOINT frequency (default = never)
   -m rows         : COMMIT frequency (default = never)
   -n cols         : number of non-null columns
   -o outfile      : record duration in file
   -q              : quiet mode
   -w width        : rows to insert per request
   -r rows         : rows to insert
   -v start_value  : starting value (for keys)
   -x              : generate unique row values
