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

JAVAC=""
for home in "$JDK_HOME" "$JDKHOME" "$JAVA_HOME" "$JAVAHOME" ; do
    if [ -x "$home/bin/javac" ] ; then
	JAVAC="$home/bin/javac"
	break
    fi
done
if [ -z "$JAVAC" ] ; then
    echo "Error: could not find the java compiler \"javac\"."
    echo "Please set JDK_HOME to your JDK installation directory"
    exit 0
fi
#  This sample program contains a hard-coded userid and password
#  to connect to the demo database. This is done to simplify the
#  sample program. The use of hard-coded passwords is strongly
#  discouraged in production code. A best practice for production
#  code would be to prompt the user for the userid and password.

#  Define the ODBC data sources
dbdsn -w dsn_consol -y -c "uid=dba;pwd=sql;dbf=./consol.db;eng=Consol"
dbdsn -w dsn_remote -y -c "uid=dba;pwd=sql;dbf=./remote.db;eng=Remote"

#  Construct the consolidated database
dbinit consol.db
dbisql -c "dsn=dsn_consol" read "$__SA/mobilink/setup/syncsa.sql"
dbisql -c "dsn=dsn_consol;autostop=no" read build_consol.sql
dbisql -c "dsn=dsn_consol" read add_data_consol.sql
dbstop -c "dsn=dsn_consol"

#  Construct the remote database
dbinit remote.db
dbisql -c "dsn=dsn_remote" read build_remote.sql


#  Compile the Java synchronization logic
__CLASSPATH=$__SA/java/mlscript.jar

$JAVAC -classpath "$__CLASSPATH" *.java

