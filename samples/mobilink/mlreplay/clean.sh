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

mlstop -w -h mlreplay_svr
dbstop -y cons -c dsn=cons
dbstop -y remote -c dsn=remote
rm -f cons.db
rm -f remote.db

rm -f ml.txt
rm -f *.mle
rm -f *.log
rm -f *.mlr
rm -f data.sql
rm -f *.csv
rm -f remote.rid
rm -f report.txt

