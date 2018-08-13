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

. step1.sh
echo \*\*\*
echo \*\*\* Replay the second recorded synchronization $NUM_SIMULATED_CLIENTS times
echo \*\*\*
i=0
while [ $i != $NUM_SIMULATED_CLIENTS ];
do
    i=`expr $i + 1`
    echo mlreplay$i,,$i, >> mlreplay.csv
done
mlreplay -x tcpip -ot mlreplay.log -sci mlreplay.csv recorded_protocol_mlreplay_svr_2.mlr
