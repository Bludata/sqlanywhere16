# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
panel_list()
############
{
    echo "panel_deploy_welcome panel_locate_existing_install_for_deployment panel_components panel_list_deployment_files panel_deploy_post_install_info"
}

need_panel()
############
{
    case "$1" in 
	panel_list_deployment_files)
	    [ `deploy_wizard_mode` = "LIST" ]
	    ;;
	panel_generate_deployment_tar)
	    [ `deploy_wizard_mode` = "TAR" ]
	    ;;
	*)
	    true
	    ;;
    esac
}

deploy_post_install_actions()
#############################
{
    true
}

sa_default_install_dir()
########################
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
    eval echo "$MSG_PACKAGE_NAME"
}

get_menu_name()
###############
{
    echo "${MSG_PRODUCT_NAME_AND_VERSION}"
}

set_post_install_action_function deploy_post_install_actions
set_default_install_dir_cb sa_default_install_dir
