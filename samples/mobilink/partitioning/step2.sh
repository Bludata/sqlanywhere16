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
#  Initial synchronization
dbmlsync -c "dsn=dsn_remote_1" -k -o remote_1.mlc -v -e "SendColumnNames=ON"
dbmlsync -c "dsn=dsn_remote_2" -k -o remote_2.mlc -v -e "SendColumnNames=ON"
dbisql -c "dsn=dsn_consol" read consol_inserts.sql
dbisql -c "dsn=dsn_remote_1" read remote_1_inserts.sql
dbisql -c "dsn=dsn_remote_2" read remote_2_inserts.sql
dbmlsync -c "dsn=dsn_remote_1" -k -o remote_1.mlc -v -e "SendColumnNames=ON"
dbmlsync -c "dsn=dsn_remote_2" -k -o remote_2.mlc -v -e "SendColumnNames=ON"
