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

#  ***************************************************************************
#  Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
#  ***************************************************************************
#  This sample program contains a hard-coded userid and password
#  to connect to the demo database. This is done to simplify the
#  sample program. The use of hard-coded passwords is strongly
#  discouraged in production code. A best practice for production
#  code would be to prompt the user for the userid and password.

#  Initial synchronization
dbmlsync -c "dsn=dsn_remote_1;uid=sync_user;pwd=sync_pwd" -n Contact,Product -k -o remote_1.mlc -v -mp SSinger
dbmlsync -c "dsn=dsn_remote_2;uid=sync_user;pwd=sync_pwd" -n Contact,Product -k -o remote_2.mlc -v -mp PSavarino

#  Insert some rows in the remote database.
#  dbisql -c "dsn=test_remote" read remote_inserts.sql

#  Insert some rows in the consolidated database.
#  dbisql -c "dsn=test_consol" read consol_inserts.sql

#  Synchronize new data
#  dbmlsync -c "dsn=test_remote" -k -o dbmlsync.mlc -v -e "SendColumnNames=ON"
