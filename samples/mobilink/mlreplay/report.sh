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
echo \*\*\* Query for missing clients
echo \*\*\*
. step1.sh
echo Query \#1: >> report.txt
dbisql -c dsn=cons "select ( count(distinct pk1) - $NUM_SIMULATED_CLIENTS ) * -1 from T1 where pk1>0; output to 'report.txt' format ascii delimited by ' ' quote '' append"
echo \*\*\*
echo \*\*\* Query for missing rows
echo \*\*\*
echo Query \#2: >> report.txt
dbisql -c dsn=cons "select count(*) from ( select pk1 from T1 where pk1>0 group by pk1 having count(*) <> $NUM_ROWS ) as t; output to 'report.txt' format ascii delimited by ' ' quote '' append"
