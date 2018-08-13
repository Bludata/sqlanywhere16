# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
create_new_tmpfile()
####################
# PRE : none
# POST: new empty file $TMPFILE created.
{
    if [ -z "${__TMPFILENUM:-0}" ] ; then
        push_cleanup_callback clean_up_tmpfiles
        __TMPFILENUM=0
    fi

    __TMPFILENUM=`expr ${__TMPFILENUM:-0} + 1`

    TMPFILE="${TMPPREFIX}$$.${__TMPFILENUM}"

    rm -f "${TMPFILE}"
    touch "${TMPFILE}"
    chmod 0600 "${TMPFILE}"

    __TMPFILES="\"${TMPFILE}\" ${__TMPFILES:-}"
}

clean_up_tmpfiles()
###################
{
    rm -f ${__TMPFILES:-}
}

get_var()
#########
{
    eval echo \$$1
}

set_var()
#########
# $1 : Name of variable
# $2 : New value
{
    eval $1=\"$2\"
}

stack_push()
############
# $1 : Stack name
# $2 : Element to push
{
    L_OLD_VAL=`get_var $1`
    if [ -z "$L_OLD_VAL" ]; then
	set_var "$1" "$2"
    else
	set_var "$1" "$2|$L_OLD_VAL"
    fi
}

stack_pop()
###########
# $1 : Stack name
# Returns old head
{
    L_VAL=`get_var $1`
    L_HEAD=`echo $L_VAL | sed -e 's/|.*$//'`
    if [ "$L_HEAD" != "$L_VAL" ]; then
	L_REST=`echo $L_VAL | sed -e 's/^[^|]*|//'`
    else
	L_REST=
    fi
    set_var $1 "$L_REST"
    echo "$L_HEAD"
}

pushd_quiet()
#############
{
    stack_push __DIR_STACK "`pwd`"
    cd "$1"
}

popd_quiet()
#############
{
    L_OLD_DIR=`stack_pop __DIR_STACK`
    cd "$L_OLD_DIR"
}

toupper()
#########
{
    if [ `plat_os` = "solaris" ] ; then
	echo "$*" | tr [:lower:] [:upper:]
    else
	echo "$*" | tr a-z A-Z
    fi
}

tolower()
#########
{
    if [ `plat_os` = "solaris" ] ; then
	echo "$*" | tr [:upper:] [:lower:]
    else
	echo "$*" | tr A-Z a-z
    fi
}

not()
#####
{
    CMD=""
    while [ -n "${1:-}" ] ; do
        CMD="$CMD \"$1\""
        shift
    done

    if eval "$CMD" ; then
        false
    else
        true
    fi
}

opposite_bitness()
##################
{
    if [ "${1:-}" = "32" ]; then
	echo 64
    elif [ "${1:-}" = "64" ]; then
	echo 32
    else
	echo ""
    fi
}

can_install_bitness()
#####################
{
    [ "$1" = "none" ] || [ "$1" = "`plat_bitness`" ]
}

is_debug()
##########
{
    [ -n "${SA_DEBUG_SETUP:-}" ]
}

is_running_dash_shell()
#######################
{
    [ -z "${BASH:-}" ] && [ -h "/bin/sh" ] && [ -r "/bin/dash" ] && [ -r "/bin/bash" ]
}

is_doc_install()
################
{
    [ `get_install_type` = "DOC" ] 
}

is_deploy()
###########
{
    [ `get_install_type` = "DEPLOY" ]
}

is_world_readable()
###################
{
    TESTDIR=$1
    BOTTOMDIR=$TESTDIR
    retval=0

    while true; do
	ls -ald "$BOTTOMDIR"  2>/dev/null | grep "^.r..r..r.." >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
	    retval=0
	    break
	else
	    retval=1
	    [ "$BOTTOMDIR" = "/" ] && break;
	    BOTTOMDIR="`dirname "$BOTTOMDIR"`"
	fi
    done

    echo $retval
}

