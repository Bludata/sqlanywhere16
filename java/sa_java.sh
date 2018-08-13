#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

# Get the platform on which we are running. This function returns either
# "UNKNOWN" if it cannot determine the platform or "OS.HW" if can where "OS"
# is a string representing the operating system (one of: Linux, HP-UX, AIX,
# SunOS, MacOS) and "HW" is a string representing the hardware architecture
# of the system.

get_platform( ) {
    OS_BASE=`uname`

    if [ "${OS_BASE:-}" = "Darwin" ] ; then
	OS_BASE="MacOS"
    fi

    if [ "${OS_BASE:-}" = "HP-UX" ] ; then
	OS_HW=`uname -m`
	if [ "${OS_HW:-}" != "ia64" ] ; then
	    OS_HW="parisc"
	fi
    else
	OS_HW=`uname -p`
    fi

    if [ -z "${OS_BASE:-}" ] || [ -z "${OS_HW:-}" ] ;
	then echo "UNKNOWN"
    else
	echo "${OS_BASE}.${OS_HW}"
    fi
}

# Change the options for your platform to run a different JVM
# or to pass extra options to the JVM
#
# The options are as follows
#
# JAVA_BITNESS -    The "bitness" of the java executable to run.
#		    You should specify 32 if you are running a 32
#		    bit JVM or 64 if you are running a 64 bit JVM
# JAVA_EXECUTABLE - The location of the actual java binary to be run
# JAVA_OPTIONS	  - Any extra options that you want passed to the JVM

case `get_platform` in
    AIX.powerpc )
	JAVA_EXECUTABLE=${JAVA_HOME}/bin/java
	JAVA_OPTIONS=""

	file $JAVA_EXECUTABLE 2>/dev/null | grep "64-bit XCOFF executable" >/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
	    JAVA_BITNESS=64
	else
	    JAVA_BITNESS=32
	fi
	;;

    HP-UX.* )
	JAVA_EXECUTABLE=${JAVA_HOME}/bin/java

	file $JAVA_EXECUTABLE 2>/dev/null | grep "IA64" >/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
	    JAVA_BITNESS=64
	    # on HP-UX we need to pass the -d64 flag to get a 64 bit JVM
	    JAVA_OPTIONS="-d${JAVA_BITNESS}"
	else
	    JAVA_BITNESS=32
	    JAVA_OPTIONS=""
	fi
	;;
    *)
	# We didn't match any of the platforms above, let's just do something
	# reasonable
	JAVA_BITNESS=64
	JAVA_EXECUTABLE=${JAVA_HOME}/bin/java
	JAVA_OPTIONS=""
	;;
esac

# Set up the correct environment for JAVA_BITNESS
. ${SQLANY12}/bin${JAVA_BITNESS}/sa_config.sh

# Each of the arguments should be quoted
args=''
while [ "$1" != '' ]; do args="$args '$1'"; shift; done

# Run the java command
eval ${JAVA_EXECUTABLE} ${JAVA_OPTIONS} ${args}
exit $?
