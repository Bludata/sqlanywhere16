#!/bin/sh
#  *******************************************************************
#  Copyright (c) 2013 SAP AG or an SAP affiliate company.
#  All rights reserved. All unpublished rights reserved.
#  *******************************************************************
#  This sample code is provided AS IS, without warranty or liability
#  of any kind.
#  
#  You may use, reproduce, modify and distribute this sample code
#  without limitation, on the condition that you retain the foregoing
#  copyright notice and disclaimer as to the original code.  
#  
#  *******************************************************************
if [ "_$SQLANY16"  = "_" ]; then
   echo "Error: SQLANY16 environment variable is not set."
   echo "Source the sa_config.sh or sa_config.csh script."
   exit 0
fi
__SA=$SQLANY16

if [ "_$SASAMPLES" = "_" ]; then
    __SASAMPLES=$__SA/samples
fi

#  This sample program contains a hard-coded userid and password
#  to connect to the demo database. This is done to simplify the
#  sample program. The use of hard-coded passwords is strongly
#  discouraged in production code. A best practice for production
#  code would be to prompt the user for the userid and password.

#  Define the ODBC data sources

dbdsn -w dsn_consol -y -c "uid=dba;pwd=sql;dbf=./consol.db;eng=consol"
dbdsn -w dsn_remote_1 -y -c "uid=dba;pwd=sql;dbf=./remote_1.db;eng=remote_1"
dbdsn -w dsn_remote_2 -y -c "uid=dba;pwd=sql;dbf=./remote_2.db;eng=remote_2"

#  Construct the consolidated database
dbinit consol.db
dbisql -c "dsn=dsn_consol" read "$__SA/mobilink/setup/syncsa.sql"
dbisql -c "dsn=dsn_consol" read build_consol.sql

#  Construct the remote database
dbinit remote_1.db
dbinit remote_2.db
dbisql -c "dsn=dsn_remote_1" read build_remote.sql [user1] [2]
dbisql -c "dsn=dsn_remote_2" read build_remote.sql [user2] [3]

