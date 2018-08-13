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

echo \*\*\*
echo \*\*\* Generate data to insert into the remote database
echo \*\*\*
. step1.sh
i=0
while [ $i != $NUM_ROWS ];
do
    i=`expr $i + 1`
    echo INSERT INTO T1\(pk1,pk2,c1\) values \(0,$i,\'$i:$i\'\)\; >> data.sql
done
echo Load data to sync.
dbisql -c dsn=remote read data.sql [MLReplayDemo]
