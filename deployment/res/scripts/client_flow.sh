# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
panel_list()
############
{
    echo "panel_welcome panel_clickwrap panel_components_and_destination panel_starting_install panel_running_install panel_post_install_info"
}

need_panel()
############
{
    case "$1" in
	panel_welcome)
	    true
	    ;;
	panel_clickwrap)
	    true
	    ;;
	panel_components_and_destination)
	    true
	    ;;
	panel_starting_install)
	    true
	    ;;
	panel_running_install)
	    true
	    ;;
	panel_post_install_info)
	    true
	    ;;
	*)
	    echo "Internal Error"
	    exit 1
	    ;;
    esac
}

client_post_install_actions()
#############################
{
    selinux_setup
    dbupdhlpr "`get_install_dir SA`"

    make_sa_config
    make_shortcuts
}

client_default_install_dir()
############################
{
    if [ `plat_os` = "macos" ] ; then
	echo "/Applications/SQLAnywhere`get_major_version`"
    elif [ `plat_os` = "aix" ] ; then
	echo "/usr/lpp/sqlanywhere`get_major_version`"
    else
	echo "/opt/sqlanywhere`get_major_version`"
    fi
}

get_package_name()
##################
{
    echo "$MSG_CLIENT_PACKAGE_NAME"
}

get_menu_name()
###############
{
    echo "${MSG_CLIENT_PACKAGE_NAME} `get_major_version`"
}

set_post_install_action_function client_post_install_actions
set_default_install_dir_cb client_default_install_dir

set_registration_key client
