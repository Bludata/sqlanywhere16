#!/bin/bash
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set -e
set -u

SQLANY=${SQLANY16}
case `uname` in
Linux)
    LIB=${SQLANY}/ultralite/linux/x64/lib
    SW='-m64'
    SYSLIBS='-lpthread'
    ;;
Darwin)
    SQLANY=`dirname ${SQLANY}`
    LIB=${SQLANY}/ultralite/macosx/x86_64
    SW='-arch x86_64 -framework CoreFoundation -framework CoreServices -framework Security'
    SYSLIBS=''
    ;;
esac
NAME=custdb
FILES='-DCUSTDB_CPP ../custdbcpp.cpp custio.c'
INCLUDE="-I${SQLANY}/sdk/include -I.."

set -x
g++ ${SW} -g ${INCLUDE} ${FILES} -L${LIB} -lulrt ${SYSLIBS} -o ${NAME}
cp ../custdb.udb .
