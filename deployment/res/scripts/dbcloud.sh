# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# 
# Used by (silent) "cloud install type" panel
# 

get_dbcloud_install_type()
##############################
{
    if [ -z "${__DBCLOUD_INSTALL_INSTALLTYPE:-}" ]; then
	set_dbcloud_install_type "PRIMARY"
    fi

    echo ${__DBCLOUD_INSTALL_INSTALLTYPE:-}
}

is_dbcloud_primary_host()
#########################
{
    [ `get_dbcloud_install_type` = "PRIMARY" ] && not is_addon_key
}

is_dbcloud_secondary_host()
###########################
{
    [ `get_dbcloud_install_type` = "SECONDARY" ]
}

is_dbcloud_additional_install()
###############################
{
    [ `get_dbcloud_install_type` = "ADDITIONAL" ]
}

set_dbcloud_install_type()
##############################
{
    __DBCLOUD_INSTALL_INSTALLTYPE=`toupper ${1:-PRIMARY}`
}

# 
# Used by "cloud config" panels
# 

#get_dbcloud_config_responsefile_name()
########################################
#{
#    echo "`get_install_dir SA`/cloudconfig.ini"
#}
#
get_dbcloud_config_info()
#########################
{
    case "${1:-}" in
	CLOUDNAME)
	    echo "${__CLOUD_NAME:-}"
	    ;;
	CLOUDLANG)
	    echo "${__CLOUD_LANG:-}"
	    ;;
	COMPANY)
	    local default_company="`get_license_info COMPANY`"
	    echo "${__CLOUD_COMPANY:-$default_company}"
	    ;;
	USER_NAME)
	    echo "${__CLOUD_USER_NAME:-}"
	    ;;
	USER_PASSWORD)
	    echo "${__CLOUD_USER_PASSWORD:-}"
	    ;;
	USER_KEY)
	    echo "${__CLOUD_USER_KEY:-}"
	    ;;
	SECUREFEATURE_KEY)
	    echo "${__CLOUD_SECUREFEATURE_KEY:-}"
	    ;;
	FULLNAME)
	    local default_fullname="`get_license_info NAME`"
	    echo "${__CLOUD_FULLNAME:-$default_fullname}"
	    ;;
	EMAIL)
	    echo "${__CLOUD_EMAIL:-}"
	    ;;
	TCPIP_PORT)
	   echo "${__CLOUD_TCPIP_PORT:-}"
	    ;;
	HTTP_PORT)
	   echo "${__CLOUD_HTTP_PORT:-}"
	    ;;
	HTTPS_PORT)
	   echo "${__CLOUD_HTTPS_PORT:-}"
	    ;;
	IDENTITYFILE)
	   echo "${__CLOUD_IDENTITYFILE:-}"
	    ;;
	IDENTITYPWD)
	   echo "${__CLOUD_IDENTITYPWD:-}"
	    ;;
	DEFAULT_TCPIP_PORT)
	   echo "2638"
	    ;;
	DEFAULT_HTTP_PORT)
	   echo "80"
	    ;;
	DEFAULT_HTTPS_PORT)
	   echo "443"
	    ;;
	DEFAULT_CLOUDNAME)
	    echo "MyCloud"
	    ;;
	DEFAULT_CLOUDLANG)
	    echo "`get_lang_code`"
	    ;;
	DEFAULT_USER_NAME)
	    echo "admin"
	    ;;
	DEFAULT_USER_PASSWORD)
	    echo "admin"
	    ;;
	DEFAULT_USER_KEY)
	    echo "MyCloudEncryptionKey"
	    ;;
	DEFAULT_SECUREFEATURE_KEY)
	    echo "MySecureFeatureKey"
	    ;;
	SWVERFULL)
	   echo "${__CLOUD_SWVERFULL:-}"
	    ;;
	RUNAS)
	   echo "${__CLOUD_RUNAS:-}"
	    ;;
	CLOUDID)
	   echo "${__CLOUD_CLOUDID:-}"
	    ;;
    esac
}

set_dbcloud_config_info()
#########################
{
    case "${1:-}" in
	CLOUDNAME)
	    __CLOUD_NAME="${2:-}"
	    # Cloud licensing info
	    set_license_info NAME "${2:-}"
	    ;;
	COMPANY)
	    __CLOUD_COMPANY="${2:-}"
	    # Cloud licensing info
	    set_license_info COMPANY "${2:-}"
	    ;;
	CLOUDLANG)
	    __CLOUD_LANG="${2:-}"
	    ;;
	USER_NAME)
	    __CLOUD_USER_NAME="${2:-}"
	    ;;
	USER_PASSWORD)
	    __CLOUD_USER_PASSWORD="${2:-}"
	    ;;
	USER_KEY)
	    __CLOUD_USER_KEY="${2:-}"
	    ;;
	SECUREFEATURE_KEY)
	    __CLOUD_SECUREFEATURE_KEY="${2:-}"
	    ;;
	FULLNAME)
	   __CLOUD_FULLNAME="${2:-}"
	    ;;
	EMAIL)
	   __CLOUD_EMAIL="${2:-}"
	    ;;
	TCPIP_PORT)
	   __CLOUD_TCPIP_PORT="${2:-}"
	    ;;
	HTTP_PORT)
	   __CLOUD_HTTP_PORT="${2:-}"
	    ;;
	HTTPS_PORT)
	   __CLOUD_HTTPS_PORT="${2:-}"
	    ;;
	IDENTITYFILE)
	   __CLOUD_IDENTITYFILE="${2:-}"
	    ;;
	IDENTITYPWD)
	   __CLOUD_IDENTITYPWD="${2:-}"
	    ;;
	SWVERFULL)
	   __CLOUD_SWVERFULL="${2:-}"
	    ;;
	RUNAS)
	   __CLOUD_RUNAS="${2:-}"
	    ;;
	CLOUDID)
	   __CLOUD_CLOUDID="${2:-}"
	    ;;
    esac
}

dbcloud_config_enabled()
#######################
{
    [ "${__DBCLOUD_DOCONFIG:-1}" = 1 ]
}

set_dbcloud_doconfig()
######################
{
    __DBCLOUD_DOCONFIG=${1:-1}
}

set_dbcloud_config_isvalid()
############################
# currently unused
{
    __DBCLOUD_CONFIG_VALID=1
}

get_dbcloud_config_isvalid()
############################
# currently unused
{
# TBD : no validation yet 
    [ "${__DBCLOUD_CONFIG_VALID:-1}" = 1 ]
}

write_install_ini()
###################
{
    local swroot="`get_install_dir ROOT`"
    local datadir="`get_install_dir CLOUDDATA`"

    echo "[`get_internal_dotted_version dbcloud`]" >> "${swroot}/install.ini"
    echo "license=`get_registration_key`" >> "${swroot}/install.ini"
    echo "installdir=${MEDIA_ROOT}" >> "${swroot}/install.ini"
}

write_cloudinstall_ini()
########################
{
    if is_dbcloud_additional_install; then
	return
    fi

    local swroot="`get_install_dir ROOT`"
    local datadir="`get_install_dir CLOUDDATA`"

    echo "[dirs]" > "${swroot}/cloudinstall.ini"
    echo "swroot=${swroot}" >> "${swroot}/cloudinstall.ini"
    echo "dataroot=${datadir}" >> "${swroot}/cloudinstall.ini"
}

configure_dbcloud()
###################
{
    if is_dbcloud_additional_install; then
	return
    fi

    BINDIR=`get_install_dir BIN`
    BINsDIR=`get_install_dir BINS`

    local swroot="`get_install_dir ROOT`"
    local datadir="`get_install_dir CLOUDDATA`"

    echo ""
    echo "${MSG_DBCLOUD_CONFIGURING}"
    echo ""

    true
    if [ $? -eq 0 ]; then
	local action=""
	local sadir="`get_install_dir BIN`"
        local license="`get_registration_key`"
        local install="${MEDIA_ROOT:-.}"

	# get these from the command line switches, if they are passed in
	local fullname="`get_dbcloud_config_info FULLNAME`"
	local email="`get_dbcloud_config_info EMAIL`"
	local username="`get_dbcloud_config_info USER_NAME`"
	local password="`get_dbcloud_config_info USER_PASSWORD`"
	local enckey="`get_dbcloud_config_info USER_KEY`"
	local seckey="`get_dbcloud_config_info SECUREFEATURE_KEY`"
        local primaryhost=""
	local cloudname="`get_dbcloud_config_info CLOUDNAME`"       
	local cloudlang="`get_dbcloud_config_info CLOUDLANG`"       

	local tcpport="`get_dbcloud_config_info TCPIP_PORT`"
	local httpport="`get_dbcloud_config_info HTTP_PORT`"
	local httpsport="`get_dbcloud_config_info HTTPS_PORT`"

        local identityfile="`get_dbcloud_config_info IDENTITYFILE`"
        local identitypwd="`get_dbcloud_config_info IDENTITYPWD`"

        local runas="`get_dbcloud_config_info RUNAS`"
        local cloudid="`get_dbcloud_config_info CLOUDID`"

        if is_dbcloud_secondary_host; then
	    action="-join"
	    primaryhost="`get_dbcloud_config_info CLOUDNAME`"
	fi

        local args="$action"

	if [ "`get_ui_type`" = "silent" ]; then
	    args="$args -noprompt"
	fi
        if [ -n "$datadir" ]; then
            args="$args -data \"$datadir\""
        fi
        if [ -n "$swroot" ]; then
            args="$args -swroot \"$swroot\""
        fi
        if [ -n "$sadir" ]; then
            args="$args -swdir \"$sadir\""
            args="$args -template \"`dirname "$sadir"`/dbcloud.db\""
        fi
        if [ -n "$license" ]; then
            args="$args -license \"$license\""
        fi
        if [ -n "$install" ]; then
            args="$args -install \"$install\""
        fi
        if [ -n "$enckey" ]; then
            args="$args -ek \"$enckey\""
        fi
        if [ -n "$seckey" ]; then
            args="$args -sk \"$seckey\""
        fi
        if [ -n "$username" ]; then
            args="$args -uid \"$username\""
        fi
        if [ -n "$password" ]; then
            args="$args -pwd \"$password\""
        fi
        if [ -n "$fullname" ]; then
            args="$args -name \"$fullname\""
        fi
        if [ -n "$email" ]; then
            args="$args -email \"$email\""
        fi
        if [ -n "$tcpport" ]; then
            args="$args -tcpport \"$tcpport\""
        fi
        if [ -n "$httpport" ]; then
            args="$args -httpport \"$httpport\""
        fi
        if [ -n "$httpsport" ]; then
            args="$args -httpsport \"$httpsport\""
        fi
        if [ -n "$identityfile" ]; then
            args="$args -identityfile \"$identityfile\""
        fi
        if [ -n "$identitypwd" ]; then
            args="$args -identitypwd \"$identitypwd\""
        fi
        if [ -n "$runas" ]; then
            args="$args -runas \"$runas\""
        fi
        if [ -n "$primaryhost" ]; then
            args="$args -primary \"$primaryhost\""
        fi
        if [ -n "$cloudlang" ]; then
            args="$args -language \"$cloudlang\""
        fi
        if [ -n "$cloudid" ]; then
            args="$args -cloudid \"$cloudid\""
        fi
        if [ -n "$cloudname" ]; then
            args="$args \"$cloudname\""
        fi

        eval "${BINsDIR}/dbcloudinit" "$args"
    else
	false
    fi
}

