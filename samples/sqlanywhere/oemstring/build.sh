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

# Build script for UNIX SQL Anywhere examples
#
# USAGE: ./build.sh 
#
# NOTE: this script expects the following environment
#	variables to be set (see below for details):
#	COMPILER	compiler to be used
#	SQLANY16	location of the SQL Anywhere installation
#				(default: /opt/sqlanywhere16)
#	ODBC		location of the ODBC driver manager installation
#				(default: /opt/odbc)
#       PLATFORM	define this as: SUN if running on Solaris
#					HP if running on HP-UX
#					AIX if running on AIX
#					LINUX if running on Linux
#					MACOSX if running on MACOSX
#
#==============================================================
#
# COMPILER variable should be set in the environment,
#		otherwise, it defaults to gnu.
#	available compilers are:
#		gnu		for GNU gcc
#		sun_native	for SUN Workshop compiler C/C++ 4.2
#		hp_native	for HP
#		aix_native	for IBM AIX
#
#==============================================================
#
# Compiler defines:
#
#	CC		name of the C compiler
#	_COMMON_FLAGS	compiler flags common to both C and C++
#	_CFLAGS		user-definable flags for the C compiler
#	OBJDIR		directory where the object files are to be placed
#			(this variable can be passed in from the environment)
#	_LIBS		platform-specific libs
#
# The _CFLAGS macro is optional, and user-definable below.
#

SQLANYVER=16
SAVAR=`echo $`SQLANY${SQLANYVER}

DBVERSION=`/usr/bin/which dbversion`
NATIVE_SA_BITNESS=`dbversion -q $DBVERSION 2> /dev/null | cut -d ' ' -f12`
[ "${NATIVE_SA_BITNESS:-}" != "32" ] && NATIVE_SA_BITNESS=64

NATIVE_SA_LIBDIR=lib${NATIVE_SA_BITNESS}
NATIVE_SA_BINDIR=bin${NATIVE_SA_BITNESS}

# Normalize the platform names and decide whether to build 32-bit or 64-bit

if [ "${PLATFORM:-}" = "" ]; then
    PLATFORM=`uname`
    case $PLATFORM in
	SunOS )
	    PLATFORM=SUN
	    DEFAULT_SADIR=/opt/sqlanywhere${SQLANYVER}
	    DEFAULT_SAROOT=${DEFAULT_SADIR}
	    ;;
	HP-UX )
	    PLATFORM=HP
	    DEFAULT_SADIR=/opt/sqlanywhere${SQLANYVER}
	    DEFAULT_SAROOT=${DEFAULT_SADIR}
	    ;;
	Darwin )
	    PLATFORM=MACOSX
	    DEFAULT_SADIR=/Applications/SQLAnywhere${SQLANYVER}/System
	    DEFAULT_SAROOT=`dirname ${DEFAULT_SADIR}`
	    ;;
	AIX )
	    PLATFORM=AIX
	    DEFAULT_SADIR=/usr/lpp/sqlanywhere${SQLANYVER}
	    DEFAULT_SAROOT=${DEFAULT_SADIR}
	    ;;
	* )
	    # Linux
	    PLATFORM=LINUX
	    DEFAULT_SADIR=/opt/sqlanywhere${SQLANYVER}
	    DEFAULT_SAROOT=${DEFAULT_SADIR}
	    ;;
    esac
fi

PLATDEF=`echo ${PLATFORM} | tr "[a-z]" "[A-Z]"`

UNIX64=0
if [ "${NATIVE_SA_BITNESS:-}" = "64" ]; then
    UNIX64=1
fi

ARCH=`uname -m`

if [ "${COMPILER:-}" = "" ]; then
    COMPILER=gnu
fi

if [ "${PLATDEF:-}" = "HP" ] && [ "${ARCH:-}" = "ia64" ]; then
    # Always use the native compiler on HP-Itanium
    COMPILER=hp_native
fi

SADIR=`eval echo ${SAVAR}`
if [ "${PLATDEF:-}" = "MACOSX" ]; then
    SAROOT=`dirname $SADIR`
else
    SAROOT=$SADIR
fi

if [ "${SADIR:-}" = "" ]; then
    SADIR=${DEFAULT_SADIR}
    SAROOT=${DEFAULT_SAROOT}
fi

if [ "${ODBC:-}" = "" ]; then
    if [ "${PLATDEF:-}" = "MACOSX" ]; then
	ODBC=/usr
    else
	ODBC=/opt/odbc
    fi
fi

if [ "${COMPILER:-}" = "gnu" ]; then
    CC=gcc
    CXX=g++

    _COMMON_FLAGS=-Wall
    _CFLAGS=
    _LDFLAGS=
    _LIBS= 

    if [ "${PLATDEF:-}" = "MACOSX" ]; then
	_SOFLAGS=-dynamiclib
    else
	_SOFLAGS="-shared -fPIC"
    fi

    if [ "${PLATDEF:-}" = "HP" ]; then
        _LDFLAGS="$_LDFLAGS -Wl,+s -Wl,-a,shared_archive,-lcl"
    fi

    if [ "${ARCH:-}" = "x86_64" ] || [ "${NATIVE_SA_BITNESS:-}" = "64" ]; then
	if [ "${PLATDEF:-}" != "HP" ] &&
	    ( [ "${PLATDEF:-}" != "LINUX" ] || [ "${ARCH:-}" != "ia64" ] ); then
	    _CFLAGS="$_CFLAGS -m${NATIVE_SA_BITNESS}"
	fi
    fi
elif [ "${COMPILER:-}" = "sun_native" ]; then
    CC="cc -xCC"
    CXX=CC

    _COMMON_FLAGS=-xildoff
    _CFLAGS=
    _CXXFLAGS=-erroff=badargtypel2w,wbadinitl,wbadasgl
    _LDFLAGS=
    _SOFLAGS=-G

    if [ "${NATIVE_SA_BITNESS:-}" = "64" ]; then
	_COMMON_FLAGS="$_COMMON_FLAGS -m64"
    fi
elif [ "${COMPILER:-}" = "hp_native" ]; then
    CC=aCC
    CXX=aCC

    _COMMON_FLAGS="-g -z +W749,829"
    if [ "${UNIX64:-}" = "1" ]; then
        _COMMON_FLAGS="$_COMMON_FLAGS +DD64"
    elif [ "${ARCH:-}" = "ia64" ]; then
        _COMMON_FLAGS="$_COMMON_FLAGS +DD32 "
    else
        _COMMON_FLAGS="$_COMMON_FLAGS +DA1.1 +DS2.0"
    fi
    _CFLAGS=
    _LIBS= 
    _LDFLAGS="$_LDFLAGS -Wl,+s -Wl,-a,shared_archive"
    _SOFLAGS=-b
elif [ "${COMPILER:-}" = "aix_native" ]; then
    CC="xlC -qcpluscmt"
    CXX=xlC

    _COMMON_FLAGS="-ma -qarch=com -qdebug=useabsi -brtl"
    _COMMON_FLAGS="$_COMMON_FLAGS -qmaxmem=-1 -qhalt=e -qnoansialias -qtbtable=full"
    if [ "${UNIX64:-}" = "1" ]; then
        _COMMON_FLAGS="$_COMMON_FLAGS -q64"
    else
        _COMMON_FLAGS="$_COMMON_FLAGS -qtune=604"
    fi
    _CFLAGS=
    _LDFLAGS=
    _LIBS=-lC 
    _SOFLAGS=-qmkshrobj
fi

CFLAGS="$CFLAGS ${_CFLAGS} ${_COMMON_FLAGS}"
LDFLAGS="$_LDFLAGS"
SOFLAGS="$_SOFLAGS"

SOEXT=so
if [ "${PLATDEF:-}" = "HP" ] && [ "${ARCH:-}" != "ia64" ]; then
    SOEXT=sl
fi

PPFLAGS="-n -q"

if [ "${UNIX64:-}" = "1" ]; then
    PPFLAGS="$PPFLAGS -o UNIX64"
else
    PPFLAGS="$PPFLAGS -o UNIX"
fi

if [ "${OBJDIR:-}" = "" ]; then
    OBJDIR=.
else
    mkdir -p $OBJDIR
fi

INCDIR="${SAROOT}/sdk/include"
CFLAGS="$CFLAGS -I. -I${INCDIR}"
CXXFLAGS="${_CXXFLAGS:-}"

LIBDIRS="-L${SADIR}/${NATIVE_SA_LIBDIR}"
ODBC_LIBDIRS="-L. -L${ODBC}/lib"

sqc_to_c() {
    sqlpp $PPFLAGS $1.sqc $1.c
}

sqc_to_cpp() {
    sqlpp $PPFLAGS $1.sqc $1.cpp
}

c_to_o() {
    $CC $CFLAGS -c $1.c -o $OBJDIR/`basename $1.o`
}

cpp_to_o() {
    $CXX $CXXFLAGS $CFLAGS -c $1.cpp -o $OBJDIR/`basename $1.o`
}

# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
$CXX $CFLAGS $LDFLAGS dboem.cpp -g -o $OBJDIR/dboem

