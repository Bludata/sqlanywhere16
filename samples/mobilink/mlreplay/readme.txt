# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
*******************************************************************************
You may use, reproduce, modify and distribute this sample code without
limitation, on the condition that you retain the foregoing copyright notice and
disclaimer as to the original code.  

*******************************************************************************

                                 MLReplay Sample

Purpose
-------
This sample demonstrates how to use MLReplay.

Requirements
------------
The sample assumes that you have SQL Anywhere Studio installed

Procedure
---------
If you are running this sample on UNIX, substitute .sh for .bat in the 
following instructions:

Run build.bat to create the consolidated and remote databases, add scripts, and
                 publications.

Edit step1.bat and set the two variables to the desired values.  NUM_ROWS is the
                 number of rows of data each simulated client will upload to the
                 consolidated and a minimum amount of data that will be
                 downloaded by each simulated client.  NUM_SIMULATED_CLIENTS is
                 the number of concurrent simulated clients.

Run step1.bat to create the NUM_ROWS and NUM_SIMULATED_CLIENTS variables.

Run step2.bat to start the MobiLink server with the -rp option.

Run step3.bat to perform an initial synchronization so that the schema is cached
                 on the MobiLink server.

Run step4.bat to generate and load data for the synchronization to be replayed.

Run step5.bat to record the synchronization that is to be replayed by MLReplay.

Run step6.bat to restart the MobiLink server without the -rp option.

Run step7.bat to perform an initial synchronization so that the schema is cached
                 on the MobiLink server.

Run step8.bat to run MLReplay and replay the recorded protocol.

Run report.bat to run two queries to determine whether or not MLReplay was
                  successful.  The output of the queries will be in report.txt.
                  Both queries should have a result of 0.

Run clean.bat to delete all generated files.

