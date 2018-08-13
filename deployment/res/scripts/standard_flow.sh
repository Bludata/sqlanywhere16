# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
panel_list()
############
{
    echo "panel_welcome panel_clickwrap panel_mode panel_regkey panel_regkey_error panel_license_agreement panel_locate_existing_install panel_components_and_destination panel_destination panel_non_updated_components panel_server_license panel_samon_migration panel_preferences panel_starting_install panel_running_install panel_ultralite panel_post_install_info"
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
	panel_mode)
	    true
	    ;;
	panel_regkey)
	    not is_upgrade
	    ;;
	panel_regkey_error)
	    not is_upgrade && not is_key_valid
	    ;;
	panel_license_agreement)
	    is_developer_key || is_evaluation_key || is_web_key || is_edu_key
	    ;;
	panel_locate_existing_install)
	    is_upgrade || is_modify
	    ;;
	panel_components_and_destination)
	    not is_upgrade && [ `get_num_available_packages` -gt 1 ]
	    ;;
	panel_destination)
	    not is_upgrade && not is_modify && [ `get_num_available_packages` =  1 ]
	    ;;
	panel_non_updated_components)
	    is_upgrade && [ -n "`get_unavailable_packages`" ]
	    ;;
	panel_server_license)
	    has_feature SERVER_LICENSE && not is_developer_key && not is_evaluation_key && not is_edu_key
	    ;;
	panel_samon_migration)
	    has_feature SAMON && is_upgrade
	    ;;
	panel_preferences)
	    not is_upgrade && not is_addon_key
	    ;;
	panel_starting_install)
	    true
	    ;;
	panel_running_install)
	    true
	    ;;
	panel_ultralite)
	    is_selected_option OPT_ULTRALITE && [ "`plat_os`" = "macos" ]
	    ;;
	panel_post_install_info)
	    true
	    ;;
	*)
	    echo "Internal Error"
	    signal_handler
	    ;;
    esac
}

standard_pre_install_actions()
##############################
{
    if has_feature SAMON ; then
	samon_pre_extract 0
    fi
}

standard_post_install_actions()
###############################
{
    if has_feature SAMON ; then
	samon_post_extract 0
    fi

    selinux_setup
    if has_feature SAMON ; then
	dbupdhlpr -sm "`get_install_dir SA`"
    else
	dbupdhlpr "`get_install_dir SA`"
    fi

    if has_feature ECLIPSE ; then
	create_eclipse_folders
	script_eclipse_ini_file
    fi

    license_server

    macos_app_setup

    if has_feature SAMON ; then
	script_samonitor_sh
    fi
    create_newdemo_scripts

    # These next couple of things we do are to accomodate the following:
    # 1. changes/fixes to icons (Application Menu items / shortcuts)
    # 2. changes/fixes to Asian font display issues for the Admin Tools
    if is_ebf; then
	if has_installed_icons; then
	    install_icons
	fi
	if has_feature ADMINTOOLS ; then
	    create_jre_fonts_fallback_link
	fi
    fi

    # At this point we think we have done everything that needs to be done in an EBF or AddOn
    if is_addon_key ; then
	return
    fi

    make_sa_config
    
    # This step should be after all files have been generated in bin32 (eg. samonitor.sh)
    make_shortcuts

    if has_installed_feature SYBASE_CENTRAL ; then
 	create_sybcentral_resfile
	if [ "`plat_os`" != "macos" ]; then
	    if [ -x "`get_install_dir BIN64S`/scjview" ] ; then
		"`get_install_dir BIN64S`/scjview" -register_sqlanywhere
	    elif [ -x "`get_install_dir BIN32S`/scjview" ] ; then
		"`get_install_dir BIN32S`/scjview" -register_sqlanywhere
	    fi
	else
	    # On Mac, try to register the normal way, if it fails 
	    # (eg. remotely connected on 10.6) fall back on previous method
	    if [ -x "`get_install_dir BIN64S`/scjview" ] ; then
		"`get_install_dir BIN64S`/scjview" -register_sqlanywhere  >/dev/null 2>&1
		[ $? -ne 0 ] && create_sybcentral_jprs
	    fi
	fi
    fi
    if has_installed_feature ADMINTOOLS ; then
	if [ -x "`get_install_dir BIN64S`/dbisql" ] ; then
	    "`get_install_dir BIN64S`/dbisql" -nogui -XRegister_SQLAnywhere
	elif [ -x "`get_install_dir BIN32S`/dbisql" ] ; then
	    "`get_install_dir BIN32S`/dbisql" -nogui -XRegister_SQLAnywhere
	fi
    fi

    if is_ebf; then
	return
    fi

    if is_upgrade; then
	install_icons
	return
    fi

    if has_feature ADMINTOOLS ; then
 	create_jre_fonts_fallback_link
    fi

    create_sh_samples_config_files
    create_start_mobilink_scripts
    generate_special_license_agreements

    # This step has to be after all files have been generated 
    # (eg. updchk.html, samonitor.sh)
    if get_install_icons ; then
	install_icons
    fi
    if get_install_sc_icon ; then
	create_sybase_central_icon
    fi
    apply_feature_tracking
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

set_pre_install_action_function standard_pre_install_actions
set_post_install_action_function standard_post_install_actions
set_default_install_dir_cb sa_default_install_dir
