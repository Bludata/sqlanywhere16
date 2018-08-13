#! /bin/sh 
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

# In case we are being run by a Linux service, append some stock paths for Linux
PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/opt/usr/bin:/opt/usr/sbin:/usr/local/bin:/usr/local/sbin"

load_language_file()
####################
{
    . "$MEDIA_ROOT/res/language/en/messages.txt"
    LANGCODE=`get_lang_code`

    if [ -f "$MEDIA_ROOT/res/language/$LANGCODE/messages.txt" ] ; then
	create_new_tmpfile
	csconvert -s UTF8 "$MEDIA_ROOT/res/language/$LANGCODE/messages.txt" "$TMPFILE"
	. "$TMPFILE"
        rm -f "$TMPFILE"
    fi
    . "$MEDIA_ROOT/res/language/common.sh"
    PACKAGE_NAME=`eval echo ${PACKAGE_NAME}`
}

set_ticfiles()
##############
{
    for file in "`pwd`"/*.tic ; do
	TICFILE="$TICFILE \"$file\""
    done

    for file in "$TICFILE" ; do
	eval dbinstall validate "$file"

	if [ "$?" != "0" ]; then
	    echo
	    which dbinstall
	    msg_error_corrupt_ticfile "${file}"
	    exit 1
	fi
    done

    # pre-cache the SA version numbers here
    get_major_version > /dev/null
    get_minor_version > /dev/null
    get_patch_version > /dev/null
    get_build_number > /dev/null

}

check_for_required_system_tools()
#################################
{
    DF="/bin/df"
    if [ ! -x "$DF" ]; then
        msg_error_need_df $DF
	exit 1
    fi
}

installer_run_bitness()
#######################
{
    if [ "`plat_bitness`" = "64" ] && [ -f "$MEDIA_ROOT/bin64/dbinstall" ] && `"$MEDIA_ROOT/bin64/dbinstall" 2>/dev/null` ; then
	echo 64
    else
	if `"$MEDIA_ROOT/bin32/dbinstall" 2>/dev/null` ; then
	    echo 32
	else
	    echo "Internal error: Unable to execute dbinstall"
	    exit
	fi
    fi
}

bootstrap()
###########
{
    TMPPREFIX="/tmp/SqlAnySetup."

    L_DIR=`pwd`
    MEDIA_ROOT=`dirname "$0"`
    case _$MEDIA_ROOT in
	_/* )
	    true
	    ;;

	* )
	    MEDIA_ROOT=`dirname "$L_DIR/$0"`
	    ;;
    esac
}

init_variables()
################
{
    BITNESS=`installer_run_bitness`
    if [ `plat_os` = "solaris" ] ; then
	PATH="$MEDIA_ROOT/bin$BITNESS:/usr/xpg4/bin:/bin:/usr/bin:$PATH"
    else
	PATH="$MEDIA_ROOT/bin$BITNESS:/bin:/usr/bin:$PATH"
    fi
    
    LDPATH_VARNAME=`plat_ld_var_name`
    eval "$LDPATH_VARNAME='$MEDIA_ROOT/lib$BITNESS':'$MEDIA_ROOT/res':\"\$$LDPATH_VARNAME\""

    eval "export $LDPATH_VARNAME"
    export PATH

    cd "$MEDIA_ROOT"
    MEDIA_ROOT=`pwd`

}

set_flow()
##########
{
    case "`get_install_type`" in
    DOC )
	. "$MEDIA_ROOT/res/scripts/doc_flow.sh"
	;;
    *SAMON* )
	. "$MEDIA_ROOT/res/scripts/samon_flow.sh"
	;;
    CLIENT )
	. "$MEDIA_ROOT/res/scripts/client_flow.sh"
	;;
    DEPLOY )
	. "$MEDIA_ROOT/res/scripts/deploy_flow.sh"
	;;
    DBCLOUD )
	. "$MEDIA_ROOT/res/scripts/dbcloud_flow.sh"
	;;
    * )
	. "$MEDIA_ROOT/res/scripts/standard_flow.sh"
	;;
    esac
}

initialize_setup_script()
#########################
{
    clean_up_pre
    set_signal_handler
    load_language_file
    check_for_required_system_tools
    set_ticfiles
    set_flow
}

########################
# mainline
########################

# do not allow this script to run under dash (Ubuntu 8.0.4) due to a bug
# with redirection when the path contains japanese characters
if [ -z "${BASH:-}" ] && [ -h "/bin/sh" ] && [ -r "/bin/dash" ] && [ -r "/bin/bash" ] ; then
    /bin/bash "$0" "$@"
    exit
fi

bootstrap

. "$MEDIA_ROOT/res/scripts/config.sh"
. "$MEDIA_ROOT/res/scripts/versioning.sh"
. "$MEDIA_ROOT/res/scripts/cleanup.sh"
. "$MEDIA_ROOT/res/scripts/sighndlr.sh"
. "$MEDIA_ROOT/res/scripts/platform.sh"
. "$MEDIA_ROOT/res/scripts/component_spt.sh"
. "$MEDIA_ROOT/res/scripts/package.sh"
. "$MEDIA_ROOT/res/scripts/registration.sh"
. "$MEDIA_ROOT/res/scripts/generated.sh"
. "$MEDIA_ROOT/res/scripts/shortcuts.sh"
. "$MEDIA_ROOT/res/scripts/directory.sh"
. "$MEDIA_ROOT/res/scripts/summary.sh"
. "$MEDIA_ROOT/res/scripts/utility.sh"
. "$MEDIA_ROOT/res/scripts/upgrade.sh"
. "$MEDIA_ROOT/res/scripts/runinstall.sh"
. "$MEDIA_ROOT/res/scripts/license.sh"
. "$MEDIA_ROOT/res/scripts/links.sh"
. "$MEDIA_ROOT/res/scripts/options.sh"
. "$MEDIA_ROOT/res/scripts/diskspace.sh"
. "$MEDIA_ROOT/res/scripts/panel.sh"
. "$MEDIA_ROOT/res/scripts/csconvert.sh"
. "$MEDIA_ROOT/res/scripts/checkupdates.sh"
. "$MEDIA_ROOT/res/scripts/sybasecentral.sh"
. "$MEDIA_ROOT/res/scripts/cmdline.sh"
. "$MEDIA_ROOT/res/scripts/os.sh"
. "$MEDIA_ROOT/res/scripts/ui.sh"
. "$MEDIA_ROOT/res/scripts/distro.sh"
. "$MEDIA_ROOT/res/scripts/console_ui.sh"
. "$MEDIA_ROOT/res/scripts/interactive_ui.sh"
. "$MEDIA_ROOT/res/scripts/silent_ui.sh"
. "$MEDIA_ROOT/res/scripts/installicon.sh"
. "$MEDIA_ROOT/res/scripts/feature_tracking.sh"
. "$MEDIA_ROOT/res/scripts/deploy_wizard.sh"
. "$MEDIA_ROOT/res/scripts/samon.sh"
. "$MEDIA_ROOT/res/scripts/dbcloud.sh"
. "$MEDIA_ROOT/res/scripts/rollback.sh"
. "$MEDIA_ROOT/res/scripts/user.sh"

init_variables

initialize_setup_script
check_system_requirements
parse_cmdline_options "$@"
start_ui "$@"
clean_up_post
