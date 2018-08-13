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

$JAVAC -cp "$CLASSPATH" *.java

dbisql -c "dsn=SQL Anywhere 16 Demo" init.sql
