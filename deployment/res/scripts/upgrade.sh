# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# functions only used for upgrades

get_unavailable_packages()
##########################
{
    for PKG in `generate_package_list TOP_LEVEL_COMPONENTS unavailable` ; do
	echo `get_package_display_name $PKG`
    done
}

locate_dbtasks_library()
########################
{
    SADIR="$1"
    SUFXS="so.1 so sl.1 dylib"
    for DIR in "`get_install_dir LIB32 "$SADIR"`" "`get_install_dir LIB64 "$SADIR"`" ; do
	for SUF in $SUFXS ; do
	    if [ -r "$DIR/libdbtasks`get_major_version`_r.$SUF" ] ; then
		FILE="$DIR/libdbtasks`get_major_version`_r.$SUF"
	    fi
	done
    done
    echo "$FILE"
}

set_upgrade_dir()
#################
{
    unset __INSTALLED_MAJOR
    unset __INSTALLED_MINOR
    unset __INSTALLED_PATCH
    unset __UPGRADE_DBTASKS_FILE

    if [ -z "${1:-}" ] ; then
	return
    fi

    __UPGRADE_DBTASKS_FILE=`locate_dbtasks_library "$1"`
    export __UPGRADE_DBTASKS_FILE
    if [ -n "$__UPGRADE_DBTASKS_FILE" ] ; then
        __UPGRADE_VERSION_MAJOR=`dbinstall version VERSION_MAJOR "$__UPGRADE_DBTASKS_FILE"`
        export __UPGRADE_VERSION_MAJOR
        __UPGRADE_VERSION_MINOR=`dbinstall version VERSION_MINOR "$__UPGRADE_DBTASKS_FILE"`
        export __UPGRADE_VERSION_MINOR
        __UPGRADE_VERSION_PATCH=`dbinstall version VERSION_PATCH "$__UPGRADE_DBTASKS_FILE"`
        export __UPGRADE_VERSION_PATCH
        __UPGRADE_VERSION_BUILD=`dbinstall version BUILD_NUMBER "$__UPGRADE_DBTASKS_FILE"`
        export __UPGRADE_VERSION_BUILD
    fi
}

verify_installed_sa_version()
#############################
{

    SADIR="$1"

    set_upgrade_dir "${SADIR:-}"

    if [ -z "${__UPGRADE_DBTASKS_FILE:-}" ] ; then
	echo no_product
	return
    fi

    if is_upgrade || is_modify ; then
	if [ ! `get_major_version` -eq ${__UPGRADE_VERSION_MAJOR:--1} ] ||
            [ ! `get_minor_version` -eq ${__UPGRADE_VERSION_MINOR:--1} ] ||
	    ( is_modify &&
                [ ! `get_patch_version` -eq ${__UPGRADE_VERSION_PATCH:--1} ] );
        then
	    echo version_mismatch
	    return
	fi
    fi

    if is_maint ; then
        echo upgrade_required
        return
    fi
    
    echo valid
}

is_ebf()
########
{
    is_upgrade && [ `get_patch_version` -eq ${__UPGRADE_VERSION_PATCH:--1} ]
}

is_maint()
##########
{
    is_upgrade && [ `get_patch_version` -ne ${__UPGRADE_VERSION_PATCH:--1} ]
}

get_upgrade_version_display()
#############################
{
    SADIR="${1:-}"
    if [ -n "${SADIR:-}" ] ; then
        set_upgrade_dir "${SADIR:-}"
    fi

    echo ${__UPGRADE_VERSION_MAJOR:--1}.${__UPGRADE_VERSION_MINOR:--1}.${__UPGRADE_VERSION_PATCH:--1}
}

allow_upgrade()
###############
{
    [ `get_install_type` = "EBF" ] || [ `get_install_type` = "EBF_SAMON" ] ||
    ( ( [ `get_install_type` = "FULL" ] || [ `get_install_type` = "SAMON" ] ||
            [ `get_install_type` = "DOC" ] ) &&
        [ `get_patch_version` != "0" ] )
}

