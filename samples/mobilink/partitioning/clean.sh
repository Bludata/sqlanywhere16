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

mlstop
dbstop -y -c "dsn=dsn_consol"
dbstop -y -c "dsn=dsn_remote_1"
dbstop -y -c "dsn=dsn_remote_2"

#  Delete the output and report files.
rm -f report.txt
rm -f *.mlc
rm -f *.mle
rm -f *.mls
rm -f *.out
rm -f *.rid

#  Deletes all files except the source from the directory
dberase -y consol.db
dberase -y remote_1.db
dberase -y remote_2.db

#  Deletes the ODBC data sources.
dbdsn -y -d dsn_consol
dbdsn -y -d dsn_remote_1
dbdsn -y -d dsn_remote_2
