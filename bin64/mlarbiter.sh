#!/bin/sh
# ************************************************************************
# Copyright 2013 SAP AG or an SAP affiliate company.  All rights reserved.
# ************************************************************************


# $1 - string to match in process list
getpid()
{
    PIDS=`ps -ef | sed -e 's@^[ \t]*@@' | tr -s ' ' | tr ' ' ':' | grep "$1" | grep -v grep | cut -d ':'  -f2`
    echo $PIDS
}


case "$1" in
    stop )
	kill -HUP `getpid MLArbiter` >/dev/null 2>/dev/null
    ;;

    start | * )
	# Start the SQL Anywhere MobiLink Arbiter

	MLARB_BINDIR=$SQLANY16/bin64
	MLARB_MLDIR=$SQLANY16/mobilink

	"$MLARB_BINDIR/mlarb16" -r -sb 0 -ch 5m -hs -x tcpip{port=4953} -n MLArbiter "$MLARB_MLDIR/mlarbiter.control" -ud
    ;;
esac

