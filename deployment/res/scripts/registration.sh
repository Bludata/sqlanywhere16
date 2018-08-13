# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
get_key_status()
################
{
    if [ "${__SQLANY_INSTALL}" = "EVAL" ]; then
	echo "invalid"
    elif [ "${__SQLANY_INSTALL:-}" = "MULTIPLEBASE" ]; then
	echo "multiplebase"
    elif [ "${__SQLANY_INSTALL:-}" = "WEB" ] &&
	 [ "`plat_os`" != "linux" ] && [ "`plat_os`" != "macos" ]; then
	echo "web"
    elif [ "${__SQLANY_INSTALL:-}" = "WORKGROUP" ]; then
	echo "workgroup"
    elif [ `get_num_exposed_packages` -eq 0 ]; then
	echo "unsupported"
    else
	echo "valid"
    fi
}

is_key_valid()
##############
{
    [ `get_key_status` = "valid" ] || ( 
        [ "${__SQLANY_INSTALL}" = "EVAL" ] &&
        [ `dbinstall keyvalid "${__SQLANY_REGKEY:-}"` = "VALID" ] )
}

get_evaluation_key()
####################
{
    echo "evaluation"
}

is_developer_key()
##################
{
    [ "${__SQLANY_INSTALL:-}" = "DEV" ]
}

is_web_key()
############
{
    [ "${__SQLANY_INSTALL:-}" = "WEB" ]
}

is_evaluation_key()
###################
{
    [ "${__SQLANY_INSTALL:-}" = "EVAL" ]
}

is_edu_key()
############
{
    [ "${__SQLANY_INSTALL:-}" = "EDU" ]
}

get_registration_key()
######################
{
    echo "${__SQLANY_REGKEY}"
}

has_provided_registration_key()
###############################
{
    [ -n "${__SQLANY_REGKEY:-}" ]
}

set_key_info()
##############
{
    __SQLANY_INSTALL="${1:-}"
    set_license_info DEFAULT_TYPE "${2:-}"
    set_license_info DEFAULT_COUNT "${3:-}"
    shift
    shift
    shift
    if [ -n "${*:-}" ]; then
	__SQLANY_REGKEY=$*
    fi
}

set_registration_key()
######################
{
    if [ "${1:-}" != "${__SQLANY_REGKEY:-}" ] ||
       [ -z "${SQLANY_REGKEY:-}" ]; then
	__SQLANY_REGKEY="${1:-}"
	if is_key_empty "${__SQLANY_REGKEY}" ; then
	    __SQLANY_REGKEY=`get_evaluation_key`
	fi
	set_key_info `dbinstall keyinfo $__SQLANY_REGKEY`
	initialize_package_list
    fi
}

is_key_empty()
##############
{
    [ -z "`echo "${1:-}" | tr -d ,`" ]
}

is_addon_key()
##############
{
    [ "${__SQLANY_INSTALL:-}" = "ADDON" ]
}

