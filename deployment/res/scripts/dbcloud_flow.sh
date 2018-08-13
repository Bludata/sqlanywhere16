# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
panel_list()
############
{
    echo "panel_welcome panel_clickwrap panel_dbcloud_regkey panel_dbcloud_regkey_error panel_dbcloud_license_agreement panel_components_and_destination panel_destination panel_dbcloud_prompt_for_datadir panel_server_license panel_starting_install panel_running_install panel_dbcloud_post_install_info panel_dbcloud_doconfig_ask_y_n panel_dbcloud_config_run"
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
	panel_dbcloud_regkey)
	    not is_upgrade
	    ;;
	panel_dbcloud_regkey_error)
	    not is_upgrade && not is_key_valid
	    ;;
	panel_dbcloud_license_agreement)
	    [ "beta" = "beta" ] || is_developer_key || is_evaluation_key || is_web_key || is_edu_key
	    ;;
	panel_components_and_destination)
	    false && not is_upgrade && [ `get_num_available_packages` -gt 1 ]
	    ;;
	panel_destination)
	    not is_upgrade && not is_modify 
	    ;;
	panel_server_license)
	    true
	    ;;
	panel_starting_install)
	    true
	    ;;
	panel_running_install)
	    true
	    ;;
	panel_dbcloud_post_install_info)
	    true
	    ;;
	panel_dbcloud_doconfig_ask_y_n)
	    dbcloud_config_enabled && not is_dbcloud_additional_install 
	    ;;
	panel_dbcloud_prompt_for_datadir)
	    true
	    ;;
	panel_dbcloud_config_run)
	    dbcloud_config_enabled && true
	    ;;
	*)
	    echo "Internal Error"
	    signal_handler
	    ;;
    esac
}

dbcloud_pre_install_actions()
###########################
{
    true
}

dbcloud_post_install_actions()
############################
{
    selinux_setup
    # TBD dbupdhlpr -sm "`get_install_dir SA`"

    license_server
    make_sa_config 1

    # This step should be after all files have been generated in binXX (generates binXX's')
    make_shortcuts

    write_install_ini
    write_cloudinstall_ini

    cp -f "`get_install_dir SA`/uninstall_cloud.sh" "`get_install_dir ROOT`/uninstall.sh"
    cp -f "`get_install_dir SA`/readme_en.txt" "`get_install_dir ROOT`/readme_en.txt"
}

dbcloud_default_install_dir()
###########################
{
    echo "/opt/saondemand`get_version dbcloud`"0
}

get_package_name()
##################
{
    echo "$MSG_DBCLOUD_PACKAGE_NAME" `get_version_display dbcloud`
}

get_menu_name()
###############
{
    echo "${MSG_DBCLOUD_PACKAGE_NAME} `get_major_version`"
}

dbcloud_install_subdir()
########################
{
    hw=`plat_hw`
    if [ "${hw}" = "x86" ] && [ "`plat_bitness`" = "64" ] ; then
        hw=x64
    fi

    subdir="sa-`plat_os``plat_bitness`-${hw}-`get_internal_dotted_version`-`get_internal_dotted_version dbcloud`"
    if [ -r "$MEDIA_ROOT/annotated.txt" ]; then
	annotation=`cat "$MEDIA_ROOT/annotated.txt"`
	if [ -n "${annotation:-}" ]; then
	    subdir=$subdir-${annotation}
	fi
    fi

    echo "${1:-.}/${subdir}"
}

set_pre_install_action_function dbcloud_pre_install_actions
set_post_install_action_function dbcloud_post_install_actions
set_default_install_dir_cb dbcloud_default_install_dir
set_install_subdir_cb dbcloud_install_subdir

# pre-cache the cloud version numbers here
get_major_version dbcloud > /dev/null
get_minor_version dbcloud > /dev/null
get_patch_version dbcloud > /dev/null
get_build_number dbcloud > /dev/null
