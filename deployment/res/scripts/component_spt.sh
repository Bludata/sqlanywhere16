# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set_parent()
############
{
    COMP_NAME="$1"
    COMP_PARENT="$2"
    eval ${COMP_NAME}_PARENT="$COMP_PARENT"
}

comp_parent()
#############
{
    eval echo \$${1}_PARENT
}

comp_children()
###############
{
    eval echo \$${1}_CHILDREN
}

comp_conflicts()
################
{
    eval echo \$${1}_CONFLICTS
}

comp_lang()
###########
{
    eval echo \$${1}_LANG
}

comp_default()
##############
{
    [ `eval echo \\${${1}_DEFAULT:-selected}` = "selected" ]
}

comp_hidden()
#############
{
    [ `eval echo \\${${1}_HIDDEN:-visible}` = "hidden" ]
}

comp_status()
#############
{
    if is_deploy ; then
        case `eval echo \\$${1}_STATUS` in
            9|11|13|15)
	        echo "okay"
	        ;;
            0|1|2|3|4|5|6|7|8|10|12|14)
	        echo "disallowed"
	        ;;
        esac
    elif is_modify && [ "${2:-}" != "exposed" ] ; then
        case `eval echo \\$${1}_STATUS` in
            8|9|10|11|12|13|14|15)
	        echo "installed"
	        ;;
            5|7)
	        echo "okay"
	        ;;
            1|3)
	        echo "unavailable"
	        ;;
            0|2|4|6)
	        echo "disallowed"
	        ;;
        esac
    elif is_upgrade ; then
        case `eval echo \\$${1}_STATUS` in
            11|15)
	        echo "okay"
	        ;;
            1|3|5|7|9|13)
	        echo "unavailable"
	        ;;
            0|2|4|6|8|10|12|14)
	        echo "disallowed"
	        ;;
        esac
    else
        case `eval echo \\$${1}_STATUS` in
            5|7|13|15)
	        echo "okay"
	        ;;
            1|3|9|11)
	        echo "unavailable"
	        ;;
            0|2|4|6|8|10|12|14)
	        echo "disallowed"
	        ;;
        esac
    fi
}

comp_in_list()
##############
{
    echo `comp_children \`comp_parent $1\`` | grep $1 > /dev/null
    test $? -eq 0 || test "$1" = "TOP_LEVEL_COMPONENTS"
}

comp_allowed()
##############
{
    CHILDREN=`comp_children $1`
    if [ -z "${CHILDREN:-}" ] ; then
	[ "`comp_status $1`" = "okay" ]
    else
	true
    fi
}

comp_installed()
################
{
    CHILDREN=`comp_children $1`
    if [ -z "${CHILDREN:-}" ] ; then
	[ "`comp_status $1`" = "installed" ]
    else
        for child in $CHILDREN; do
            if not comp_installed "$child" ; then
                return 1
            fi
        done
        true
    fi
}

comp_exposed()
##############
{
    CHILDREN=`comp_children $1`
    if [ -z "${CHILDREN:-}" ] ; then
	[ "`comp_status $1 exposed`" = "okay" ]
    else
        for child in $CHILDREN; do
            if comp_exposed "$child" ; then
                return 0
            fi
        done
        false
    fi
}

comp_unavailable()
##################
{
    CHILDREN=`comp_children $1`
    if [ -z "${CHILDREN:-}" ] ; then
	[ "`comp_status $1 exposed`" = "unavailable" ]
    else
        for child in $CHILDREN; do
            if comp_unavailable "$child"; then
                return 0
            fi
        done
        false
    fi
}

comp_set_status()
#################
{
    if [ -n "${1:-}" ]; then
	eval ${1}_STATUS=${2:-}
    fi
}

add_component()
###############
{
    COMP_PARENT="$1"
    COMP_NAME="$2"
    COMP_BITNESS="${3:-none}"
    COMP_DEFAULTBITNESS="${4:-none}"
    COMP_CONFLICTS="${5:-none}"
    COMP_HIDDEN="${6:-visible}"
    COMP_LANG="${7:-none}"

    if not can_install_bitness $COMP_BITNESS && (
            not is_upgrade || not comp_allowed $COMP_NAME ) ;
    then
	return
    fi
    
    if [ "${COMP_CONFLICTS}" != "none" ] &&
        ( [ `comp_status "${COMP_CONFLICTS}"` = "okay" ] ||
            [ `comp_status "${COMP_CONFLICTS}"` = "installed" ] ); then
	return
    fi

    COMP_DEFAULT="deselected"
    if [ "$COMP_DEFAULTBITNESS" = "none" ] ||
        [ "$COMP_DEFAULTBITNESS" = "`plat_bitness`" ]; then
        COMP_DEFAULT="selected"
    fi

    if [ "$COMP_PARENT" = "none" ]; then
	COMP_PARENT=TOP_LEVEL_COMPONENTS
    fi

    eval ${COMP_NAME}_PARENT="$COMP_PARENT"
    eval ${COMP_NAME}_CONFLICTS="$COMP_CONFLICTS"
    eval ${COMP_NAME}_PARENT="$COMP_PARENT"
    eval ${COMP_NAME}_HIDDEN="$COMP_HIDDEN"
    eval ${COMP_NAME}_LANG="$COMP_LANG"
    eval ${COMP_NAME}_DEFAULT="$COMP_DEFAULT"

    eval `echo ${COMP_PARENT}_CHILDREN=\"\\$${COMP_PARENT}_CHILDREN $COMP_NAME\"`

    if not comp_in_list $COMP_PARENT ; then
	add_component `comp_parent $COMP_PARENT` $COMP_PARENT
    fi
}

clear_components_list()
#######################
{
    NAME="${1:-TOP_LEVEL_COMPONENTS}"
    CHILDREN=`comp_children $NAME`
    
    if [ -n "${CHILDREN:-}" ] ; then
	for c in $CHILDREN ; do
	    clear_components_list "$c"
	done
	NAME="${1:-TOP_LEVEL_COMPONENTS}"	
	unset `echo ${NAME}_CHILDREN`
    fi
    
    COMP_PARENT=`eval echo \\$${NAME}_PARENT`
    COMP_CONFLICTS=`eval echo \\$${NAME}_CONFLICTS`
    COMP_CONTENTS=`eval echo \\$${NAME}`
    
    if [ -n "${COMP_PARENT:-}" ] ; then
	unset `echo ${NAME}_PARENT`
    fi
    if [ -n "${COMP_CONFLICTS:-}" ] ; then
	unset `echo ${NAME}_CONFLICTS`
    fi
    if [ -n "${COMP_CONTENTS:-}" ] ; then
	unset `echo ${NAME}`
    fi
}
