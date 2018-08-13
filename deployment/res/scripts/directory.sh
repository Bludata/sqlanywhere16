# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
get_parent()
############
{
    if [ "_$1" = "_" ]; then
	echo ''
    fi 	

    JUNK=$1
    while [ ! -d "$JUNK" ]; do 
        JUNK=`dirname "$JUNK" 2> /dev/null`
    done
 
    echo "$JUNK"
}

escape_directory_path()
#######################
{
    echo "${1:-}" | sed "s/ /\\\\ /g"
}

directory_is_empty()
####################
{
    [ `ls -1 "${1:-}" | wc -l` = "0" ]
}

set_install_subdir_cb()
#######################
{
    __INSTALL_SUBDIR_DIR_CB=$1
}

get_install_subdir()
####################
{
    if [ -n "$__INSTALL_SUBDIR_DIR_CB" ] ; then
        $__INSTALL_SUBDIR_DIR_CB "${1:-}"
        return
    fi

    echo "${1:-}"
}

check_directory_validity()
##########################
{
    subdir="`get_install_subdir \"${1:-}\"`"

    if [ "`echo \"${1:-}\" | cut -b1 `" != "/" ] ; then
	echo "not_full_path"
    elif [ -f "${1:-}" ] || [ -f "${subdir:-}" ] ; then
	echo "not_a_directory"
    elif [ ! -w "`get_parent \"${1:-}\"`" ] && not is_deploy ; then
	echo "no_write_permissions"
    elif not is_doc_install && not is_upgrade && not is_modify && \
        not is_deploy && [ -d "${subdir:-}" ] && \
        not directory_is_empty "${subdir:-}" ; then
	echo "will_cause_overwrite"
    elif (is_upgrade || is_modify || is_deploy) && \
        [ ! -d  "${subdir:-}" ] ; then
	echo "does_not_exist"
    elif is_upgrade || is_modify || is_deploy ; then
        echo `verify_installed_sa_version "${subdir:-}"`
    else
	echo "valid"
    fi
}

check_file_validity()
#####################
{
    if [ ! -w "`get_parent \"${1:-}\"`" ] ; then
	echo "no_write_permissions"
    elif [ "`echo \"${1:-}\" | cut -b1 `" != "/" ] ; then
	echo "not_full_path"
    elif [ -f "${1:-}" ] ; then
	echo "will_cause_overwrite"
    else
	echo "valid"
    fi
}

get_directory_list()
####################
{
    echo "SA"
}

need_directory()
################
{
    case "${1:-}" in
	SA | ROOT )
	    true
	    ;;
	*)
	    false
	    ;;
    esac
}

set_install_dir()
#################
{
    COMPONENT="${1:-}"
    INSTALL_DIR="${2:-}"
    
    case "$COMPONENT" in
	SA | ROOT )
	    __SQLANY_DIR="$INSTALL_DIR"
	    if is_upgrade || is_modify || is_deploy ; then
		set_upgrade_dir "`get_install_dir SA`"
		initialize_package_list
	    fi
	    ;;
    esac
}

get_directory_display_name()
############################
{
    case "${1:-}" in
	SA | ROOT )
	    echo "${MSG_PRODUCT_NAME}"
	    ;;
    esac
}

set_default_install_dir_cb()
############################
{
    __DEFAULT_INSTALL_DIR_CB=$1
}

get_default_install_dir()
#########################
{
    SQLANYVAR=SQLANY`get_major_version`
    SQLANY_DIR_DEFAULT=`eval echo \\$$SQLANYVAR`
    if [ `plat_os` = "macos" ]; then
	# On Mac OS X, SQLANY environment variable will point to System;
	# this isn't what we want here
	SQLANY_DIR_DEFAULT=`echo $SQLANY_DIR_DEFAULT | sed 's/\/System$//'`
    fi
    if [ -r "$SQLANY_DIR_DEFAULT" ] && (is_upgrade || is_modify || is_deploy) ;
    then
	echo $SQLANY_DIR_DEFAULT
    else
	$__DEFAULT_INSTALL_DIR_CB
    fi
}

get_install_dir()
#################
{
    BASE="${2:-}"

    case "${1:-}" in
	SA )
	    # The location where the user chose to install
            # appended with any appropriate subdirectory
	    if [ -n "$BASE" ]; then
		echo "$BASE"
	    elif [ -z "${__SQLANY_DIR}" ] ; then
		BASE="`get_default_install_dir`"
                echo "`get_install_subdir \"$BASE\"`"
	    else
		echo "`get_install_subdir \"$__SQLANY_DIR\"`"
	    fi
	    ;;
	ROOT )
	    # The location where the user chose to install
	    if [ -n "$BASE" ]; then
		echo "$BASE"
	    elif [ -z "${__SQLANY_DIR}" ] ; then
		get_default_install_dir
	    else
		echo "$__SQLANY_DIR"
	    fi
	    ;;
	SYSTEM )
	    if [ `plat_os` = "macos" ] ; then
		echo "`get_install_dir SA "$BASE"`/System"
	    else
		get_install_dir SA "$BASE"
	    fi
	    ;;
	CLOUDDATA )
	    if [ `get_install_type` = "DBCLOUD" ]; then 
		local default_datadir="`get_install_dir ROOT`/data"
		echo "${CLOUD_DATA_DIR:-$default_datadir}";
	    else
		get_install_dir ROOT "$BASE"
	    fi
	    ;;
	SUPPORT )
	    echo "`get_install_dir SA`/support"
	    ;;
	OCOS )
	    echo "`get_install_dir SYSTEM "$BASE"`/openserver"
	    ;;
	BIN )
	    NAME=BIN`plat_bitness`
	    echo "`get_install_dir $NAME`"
	    ;;
	BINS )
	    NAME=BIN`plat_bitness`S
	    echo "`get_install_dir $NAME`"
	    ;;
	BIN32 )
	    echo "`get_install_dir SYSTEM "$BASE"`/bin32"
	    ;;
	BIN32S )
	    echo "`get_install_dir SYSTEM "$BASE"`/bin32s"
	    ;;
	BIN64 )
	    echo "`get_install_dir SYSTEM "$BASE"`/bin64"
	    ;;
	BIN64S )
	    echo "`get_install_dir SYSTEM "$BASE"`/bin64s"
	    ;;
	JAVA )
	    echo "`get_install_dir SYSTEM "$BASE"`/java"
	    ;;
	LIB32 )
	    echo "`get_install_dir SYSTEM "$BASE"`/lib32"
	    ;;
	LIB64 )
	    echo "`get_install_dir SYSTEM "$BASE"`/lib64"
	    ;;
	DOCS )
	    echo "`get_install_dir SA "$BASE"`/documentation"
	    ;;
	SAMPLES )
	    echo "`get_install_dir SA "$BASE"`/samples"
	    ;;
	*)
	    echo ""
	    ;;
    esac
}

get_jre_dir()
#############
{
    case "${1:-}" in
	DIR )
	    if [ `plat_os` = "solaris" ] && [ "${2:-}" = "32" ]; then
	 	echo "`get_install_dir SA`/bin32/jre170"
	    elif [ `plat_os` = "solaris" ] && [ "${2:-}" = "64" ]; then
	 	echo "`get_install_dir SA`/bin64/jre170"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "32" ]; then
	 	echo "`get_install_dir SA`/bin32/jre170"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "64" ]; then
	 	echo "`get_install_dir SA`/bin64/jre170"
	    else
		echo "none"
	    fi
	    ;;
	LINK )
	    if [ `plat_os` = "solaris" ] && [ "${2:-}" = "32" ]; then
	 	echo "bin32/jre170"
	    elif [ `plat_os` = "solaris" ] && [ "${2:-}" = "64" ]; then
	 	echo "bin64/jre170"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "32" ]; then
	 	echo "bin32/jre170"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "64" ]; then
	 	echo "bin64/jre170"
	    else
		echo "none"
	    fi
	    ;;
	LIBDIR )
	    if [ `plat_os` = "solaris" ] && [ "${2:-}" = "32" ]; then
		echo "sparc"
	    elif [ `plat_os` = "solaris" ] && [ "${2:-}" = "64" ]; then
		echo "sparcv9"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "32" ]; then
	 	echo "i386"
	    elif [ `plat_os` = "linux" ] && [ "${2:-}" = "64" ]; then
	 	echo "amd64"
	    else
		echo "none"
	    fi
	    ;;
	* )
	    echo ""
	    ;;
    esac
}

create_directory()
#################
# 1: variable to check
# 2: directory to create if needed
{
    if [ ! -d "${1:-}" ] ; then
	mkdir -p "$1"  > /dev/null 2>&1 
    fi
    [ -d "$1" ]
}

create_user_directory()
#######################
# Handles the case where the user has "sudo'd":
# When "sudo'd", directories and files created will have user:group ownership of "root:root"
# This is not good when explicitly creating directories/files in the user's home directory,
# since later that user will not be able to read/write those files.
#
# 1: variable to check
# 2: directory to create if needed
{
    if [ ! -d "${1:-}" ] ; then
	mkdir -p "$1"  > /dev/null 2>&1 
    fi
    [ -n "$SUDO_USER" ] && chown "$SUDO_USER:" "$1"  > /dev/null 2>&1
    [ -d "$1" ]
}

create_user_file()
##################
# Handles the case where the user has "sudo'd":
# When "sudo'd", directories and files created will have user:group ownership of "root:root"
# This is not good when explicitly creating directories/files in the user's home directory,
# since later that user will not be able to read/write those files.
#
# 1: variable to check
# 2: directory to create if needed
{
    create_user_directory `dirname "$1" 2>/dev/null`
    rm -f "$1" > /dev/null 2>&1
    touch "$1"  > /dev/null 2>&1
    [ -n "$SUDO_USER" ] && chown "$SUDO_USER:" "$1"  > /dev/null 2>&1
    [ -r "$1" ]
}
