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

SQL Anywhere Transaction Test Utility
=====================================

Purpose
-------
    - The purpose of this utility is to make it relatively easy to 
      simulate multiple client machines accessing a server to perform 
      transactions. You can define what transactions are executed.
      This allows you to measure the load which can be handled by
      a given server configuration given your database design and
      set of transactions.

Setup
-----
    - Create tables in database by executing trantabs.sql using DBISQL.
    - If the transactions to be tested can be defined using unparameterized
      stored procedure calls, TRANTEST can be used without modification
      by placing the CALL statement in a file and referencing it with
      the -f switch.
    - If the file specified with -f contains one or more occurrences of
	{thread}
      these will be replaced with the thread number of each thread.
      For example, a file containing:
	call p{thread}()
      will cause thread 1 to execute "call p1()", thread 2 to execute
      "call p2()", etc.
    - If the transaction cannot be defined with procedure calls, add them
      to worklist.cpp. Then build TRANTEST using build.bat. You may need 
      to adjust the batch file for different compilers.
      
Pre-loading the database
------------------------
    - In order to accurately simulate server load, it may be necessary to
      populate the tables in the database to some level that could be
      considered typical. Testing with an empty database will usually
      not provide meaningful results.
    
Suggestions for use
-------------------
    - Don't run with too many threads (CPU on client will max out).
      If one client machine cannot support sufficient threads for your test,
      use more than one client machine, each with multiple threads.
    - Eliminate other network traffic, if possible, by running the server
      and client machines on a separate segment from the rest of the network.
    - Use a large packet size on both client and server (specified with -p
      on the server and the CBSize connection parameter on the client).
    - Allow time for the server to "warm up" before measuring transaction
      times. 
    - Ensure the test environment allows for reproducible runs:
	- start with the same database each time
	- eliminate disk fragmentation as a source of differences
    - Use delays to more accurately simulate concurrent use. By specifying an
      average transaction time (mean time between transactions), you can 
      estimate the maximum number of users that can be supported with a given 
      server configuration. 

Running tests from several clients concurrently
-----------------------------------------------
    - If a single client machine cannot support enough threads to simulate
      the desired server load, you can run tests from several machines
      concurrently. To do this, one machine is considered the "master".
      On the "master" machine, specify the number of machines participating
      via the -p switch. On all other machines, specify a unique thread group
      id from 1 to #machines-1.

Obtaining results
-----------------
    - Results are displayed on the screen at "display rate" intervals.
      These results can also be redirected to a file. The results of each run
      are recorded in the database and can be extracted to a comma-separated
      file with "getresults.sql". 
    *** Note: If the database is re-initialized before the next run, the
      results stored in the database will be lost. In this case, you should
      extract the results before re-initializing the database.
      
