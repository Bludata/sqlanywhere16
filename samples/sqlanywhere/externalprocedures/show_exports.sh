#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability of any kind.
# 
# You may use, reproduce, modify and distribute this sample code without limitation, 
# on the condition that you retain the foregoing copyright notice and disclaimer 
# as to the original code.  
# 
# *******************************************************************

ROOT=`dirname $0`
NM=`which nm`
OPTS=-g
if [ `uname` = "AIX" ]; then
    OPTS="$OPTS -X32_64"
fi
if [ "${NM:-}" = "" ]; then
    echo "nm(1) not installed."
else
    $NM $OPTS "$ROOT/libextproc.so"
fi

