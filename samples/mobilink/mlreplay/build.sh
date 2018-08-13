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

dbinit remote.db
dbinit cons.db
dbdsn -w cons -v -c "uid=dba;pwd=sql;eng=cons;dbn=cons;dbf=cons.db;links=shmem" -y
dbdsn -w remote -v -c "uid=dba;pwd=sql;eng=remote;dbn=remote;dbf=remote.db;links=shmem" -y
dbisql -c "uid=dba;pwd=sql;dbf=remote.db" read remote.sql [MLReplayDemo]
dbisql -nogui -c "uid=dba;pwd=sql;eng=cons;dbf=cons.db;autostop=no;start=dbsrv16 -x tcpip" read "$__SA/mobilink/setup/syncsa.sql"
dbisql -c "uid=dba;pwd=sql;dbf=cons.db;autostop=no;start=dbsrv16 -x tcpip" read cons.sql
