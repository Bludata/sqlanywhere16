# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
si_no_action()
##############
{
    NOOP=NOOP
}

si_handle_question_cb()
########################
{
    true
}

si_handle_message_cb()
#######################
{
    si_no_action
}

si_handle_error_cb()
#####################
{
    echo "$*"
    signal_handler
}

si_panel_welcome ()
###################
{
    si_no_action
}

si_panel_clickwrap()
####################
{
    if not has_accepted_license_agreement ; then
	echo "$MSG_SILENT_MUST_ACCEPT_LICENSE_1"
	echo "$MSG_SILENT_MUST_ACCEPT_LICENSE_2"
	signal_handler
    fi
}

si_panel_mode()
###############
{
    set_install_mode `get_install_mode`
    si_no_action
}

si_panel_dbcloud_installtype()
##############################
# currently unused
{
    set_dbcloud_install_type `get_dbcloud_install_type`
    si_no_action
}

si_panel_regkey()
#################
{
    si_no_action
}

si_panel_dbcloud_regkey()
#################
{
    si_no_action
}

si_panel_regkey_error()
#######################
{
    if not has_provided_registration_key ; then
	echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_1"
	echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_2"
    else
	echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_1"
	echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_2"
    fi
    signal_handler
}

si_panel_dbcloud_regkey_error()
###############################
{
    if not has_provided_registration_key ; then
	echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_1"
	echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_2"
    else
	echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_1"
	echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_2"
    fi
    signal_handler
}

si_panel_dbcloud_license_agreement()
############################
{
    si_no_action
}

si_panel_license_agreement()
############################
{
    if is_developer_key; then
        echo "$MSG_SILENT_CANNOT_USE_DEVELOPER_EDITION_1"
        echo "$MSG_SILENT_CANNOT_USE_DEVELOPER_EDITION_2"
    elif is_web_key; then
        echo "$MSG_SILENT_CANNOT_USE_WEB_EDITION_LICENSE_1"
        echo "$MSG_SILENT_CANNOT_USE_WEB_EDITION_LICENSE_2"
    elif is_edu_key; then
        echo "$MSG_SILENT_CANNOT_USE_EDUCATIONAL_EDITION_1"
        echo "$MSG_SILENT_CANNOT_USE_EDUCATIONAL_EDITION_2"
    elif [ `get_install_type` = "DBCLOUD" ]; then
         # let the key through
	 NOOP=NOOP
    else # is_evaluation_key
        echo "$MSG_SILENT_CANNOT_USE_EVAL_LICENSE_1"
        echo "$MSG_SILENT_CANNOT_USE_EVAL_LICENSE_2"
    fi

    signal_handler
}

si_panel_components_and_destination()
#####################################
{
    SADIR=`get_install_dir SA`
    case `check_directory_validity "${SADIR:-}"` in
	valid | will_cause_overwrite | upgrade_required)
	    ;;
	no_write_permissions)
	    msg_error_cannot_create_directory "${SADIR:-}"
	    msg_error_dont_have_write_permissions "`get_parent "${SADIR:-}"`"
	    signal_handler
	    ;;
	not_full_path)
	    msg_error_invalid_directory "${SADIR:-}"
	    echo "${MSG_ENTER_INSTALL_DIR_FULL_PATH:-}"
	    signal_handler
	    ;;
	not_a_directory)
	    msg_error_not_a_directory "${SADIR:-}"
	    signal_handler
	    ;;
    esac
}

si_panel_destination()
######################
{
    si_panel_components_and_destination
}

si_panel_dbcloud_prompt_for_datadir()
#####################################
{
    true
}

si_panel_non_updated_components()
#################################
{
    if is_upgrade; then
        UNAVAIL_PKGS=`get_unavailable_packages`
        if not is_ebf; then
            msg_components_not_in_upgrade "${UNAVAIL_PKGS}"
	    signal_handler
        fi
    fi
}

si_panel_samon_migration()
##########################
{
    si_no_action
}

si_panel_show_summary()
#######################
{
    generate_install_summary COUNT
    
    if [ $COUNT -le 0 ] ; then
	echo "$MSG_SILENT_NO_PACKAGES_SELECTED_1"
	echo "$MSG_SILENT_NO_PACKAGES_SELECTED_2"
	signal_handler
    fi
    
    if not check_disk_space MOUNT REQUIRED AVAILABLE ; then
	msg_error_insufficient_disk_space "$MOUNT" "$REQUIRED" "$AVAILABLE"
    fi
}

si_panel_server_license()
#########################
{
    NAME=`get_license_info NAME`
    
    if [ -z "${NAME:-}" ] ; then
	echo "$MSG_SILENT_NO_LICENSE_NAME_PROVIDED_1"
	echo "$MSG_SILENT_NO_LICENSE_NAME_PROVIDED_2"
	echo "$MSG_SILENT_NO_LICENSE_NAME_PROVIDED_3"
	signal_handler
    fi
}

si_panel_dbcloud_license()
#########################
{
    si_no_action
}

si_panel_ultralite()
####################
{
    si_no_action
}

si_panel_preferences()
######################
{
    si_no_action
}

si_panel_starting_install()
###########################
{
    if is_debug ; then
	echo "Packages to install:"
	generate_package_list TOP_LEVEL_COMPONENTS selected
    fi

    si_no_action
}

si_panel_running_install()
##########################
{
    set_install_callback ERROR si_handle_error_cb
    set_install_callback QUESTION si_handle_question_cb
    set_install_callback MESSAGE si_handle_message_cb
    set_install_callback STATUS si_handle_message_cb
    do_install
}

si_panel_dbcloud_doconfig_ask_y_n()
###################################
{   
    si_no_action
}

si_panel_dbcloud_config_run()
#############################
{
    dbcloud_config_enabled && configure_dbcloud

    true
}


si_panel_post_install_info()
############################
{
    si_no_action
}

si_panel_dbcloud_post_install_info()
############################
{
    si_no_action
}

si_panel_locate_existing_install()
##################################
{
    si_no_action
}

run_silent_mode()
#################
{
    PANEL=`next_panel`
    while [ -n "${PANEL:-}" ] ; do
	if is_debug ; then
	    echo ""
	    echo "--> RUNNING PANEL: $PANEL"
	    echo ""
	fi
	eval "si_$PANEL"
	PANEL=`next_panel "$PANEL"`
    done
}
