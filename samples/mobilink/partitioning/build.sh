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

dbinit consol.db
dbinit remote_1.db
dbinit remote_2.db
dbdsn -y -w dsn_consol -c "uid=dba;pwd=sql;dbf=./consol.db;eng=Consol"
dbdsn -y -w dsn_remote_1 -c "uid=dba;pwd=sql;dbf=./remote_1.db;eng=remote_1"
dbdsn -y -w dsn_remote_2 -c "uid=dba;pwd=sql;dbf=./remote_2.db;eng=remote_2"
dbisql -c "dsn=dsn_consol" read "$__SA/mobilink/setup/syncsa.sql"
dbisql -c "dsn=dsn_consol" read build_consol.sql
dbisql -c "dsn=dsn_remote_1" read build_remote.sql [emp1] [2]
dbisql -c "dsn=dsn_remote_2" read build_remote.sql [emp2] [3]
