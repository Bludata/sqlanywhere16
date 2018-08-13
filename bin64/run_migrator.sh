#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

# $SQLANY16/Bin32 must be in the PATH so that jsyblib1600 and dbjdbc16 can be found
. "`dirname $0`/sa_config.sh" >/dev/null 2>&1
SABIN=$SQLANY16

PATH=$SABIN/bin32:$SABIN/bin64:$SABIN/sun/jre170_x86/bin:$SABIN/sun/jre170_x64/bin:$PATH
CLASSPATH=$SABIN/java/migrator.jar:$SABIN/java/jsyblib1600.jar:$SABIN/java/sajdbc4.jar
OTHERSWITCHES="-ea -Dsun.java2d.noddraw=true -Dsun.java2d.d3d=false -Duser.home=."
OTHERMIGRATORSWITCHES=""
if [ -z ${DISPLAY:-} ]; then
    OTHERMIGRATORSWITCHES="-n"
fi

java $OTHERSWITCHES -classpath "$CLASSPATH" com.ianywhere.serverMonitor.migrator.MonitorMigrator $OTHERMIGRATORSWITCHES $1 $2 $3 $4 $5
