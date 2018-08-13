# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# Use readline for input, if available
__READ_CMD=read
if [ `plat_os` != "aix" ]; then
    echo test | read -e 2>/dev/null
    if [ $? -eq 0 ]; then
	__READ_CMD="read -e"
    fi
fi

cui_clear_screen()
##################
{
    if not is_debug ; then
	[ -z "${QUIET:-}" ] && [ -z "${AUTOMATIC_MODE:-}" ] && clear
    fi
}

cui_display()
#############
{
    if [ -z "${QUIET:-}" ] ; then
	CMD="${1:-}"
	shift
    
	while [ -n "${1:-}" ] ; do
	    CMD="$CMD \"$1\""
	    shift
	done
	eval "$CMD"
    fi
}

cui_echo()
##########
{
    [ -z "${QUIET:-}" ] && echo "$*"
}

cui_cat()
#########
{
    [ -z "${QUIET:-}" ] && cat $*
}

cui_more()
##########
{
    if [ -n "${AUTOMATIC_MODE:-}" ] ; then
	[ -z "${QUIET:-}" ] && cat $*
    else
	more $*
    fi
}

cui_wait_for_input()
####################
{
    cui_echo "${1:-}"
    if [ -n "${AUTOMATIC_MODE:-}" ] && [ -n "${2:-}" ] ; then
	CUI_RESPONSE="${2:-}"
    else
	$__READ_CMD CUI_RESPONSE
	[ -z "${CUI_RESPONSE:-}" ] && CUI_RESPONSE="${2:-}"
    fi
}

cui_wait_for_password()
#######################
{
    cui_echo "${1:-}"
    if [ -n "${AUTOMATIC_MODE:-}" ] && [ -n "${2:-}" ] ; then
	CUI_RESPONSE="${2:-}"
    else
	$__READ_CMD -s CUI_RESPONSE
	[ -z "${CUI_RESPONSE:-}" ] && CUI_RESPONSE="${2:-}"
    fi
}

cui_ask_y_n()
#############
{
    if [ "${2:-N}" = "Y" ] ; then
        _PROMPT="${MSG_PROMPT_YES_NO}"
    else
        _PROMPT="${MSG_PROMPT_NO_YES}"
    fi
    
    cui_echo ""
    cui_wait_for_input "${1} ${_PROMPT}" "${2:-N}"

    case $CUI_RESPONSE in
        "${MSG_ANSWER_yes}" | "${MSG_ANSWER_Yes}" | "${MSG_ANSWER_y}" | "${MSG_ANSWER_Y}" )
	    true
            ;;
        * )
	    false
            ;;
    esac
}

cui_is_numeric()
################
{
    if [ "_$1" = "_" ]; then
        echo "false"
	return
    fi

    JUNK=`echo $1 |grep "[^0-9]"`
    if [ "_$JUNK" = "_" ]; then 
    	echo "true"
    else 
    	echo "false"
    fi	
}

#############
# UI PANELS #                  
#############

cui_handle_error_cb()
#####################
{
    cui_echo "$*"
}

cui_handle_question_cb()
########################
{
    cui_ask_y_n "${1:-}"
}

cui_handle_message_cb()
#######################
{
    cui_echo "$*"
}

run_welcome_panel()
####################
{
    cui_clear_screen
    cui_display "${1:-}" "${2:-}"
    cui_wait_for_input "${MSG_ENTER_TO_CONTINUE}" "NONE"
    true
}
cui_panel_welcome()
###################
{
    run_welcome_panel msg_welcome "`get_package_name`"
}

cui_panel_deploy_welcome()
##########################
{
    run_welcome_panel msg_deployment_wizard_welcome
}

cui_panel_clickwrap() # how does -q apply?
#####################
{
    while true ; do 
        cui_clear_screen
	cui_display msg_license_country_list
	cui_echo ""
	cui_wait_for_input "${MSG_LICENSE_COUNTRY_PROMPT_3}"

	LICFILE=`get_clickwrap_license_file ${CUI_RESPONSE:-}`
	if [ -z "${LICFILE:-}" ] ; then 
	    cui_display msg_error_unknown_region "${CUI_RESPONSE:-}"
	    cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"
	else
	    break
	fi
    done
    
    tr '\032' '?' < "$LICFILE" | more
    
    cui_echo ""
    cui_display msg_welcome_license_agreement

    if [ "`dirname ${LICFILE}`" != "$MEDIA_ROOT/licenses" ]; then
        rm -f "${LICFILE}"
    fi

    cui_echo ""
    
    if not cui_ask_y_n "${MSG_ASK_AGREE_LICENSE}" ; then
	cui_display msg_error_disagree_license "`get_package_name`"
	signal_handler
    fi
    true
}

cui_panel_mode()
################
{
    cui_clear_screen

    while true ; do
        cui_echo "${MSG_INSTALL_MODE:-}"
        cui_echo ""
        cui_echo " 1. ${MSG_INSTALL_CREATE:-}"
        cui_echo " 2. ${MSG_INSTALL_MODIFY:-}"
        if allow_upgrade; then
            cui_echo " 3. ${MSG_INSTALL_UPGRADE:-}"
        fi
        cui_echo ""
        
        _default_selection=1
        if [ `get_install_mode` = "MODIFY" ]; then
            _default_selection=2
        elif allow_upgrade && [ `get_install_mode` = "UPGRADE" ]; then
            _default_selection=3
        fi

        cui_wait_for_input "${MSG_CHOICE:-} [${_default_selection}]:" ${_default_selection}
        
        unset _default_selection
        
        if [ ${CUI_RESPONSE:-} = "1" ]; then
            set_install_mode "CREATE"
            break
        elif [ ${CUI_RESPONSE:-} = "2" ]; then
            set_install_mode "MODIFY"
            break
        elif allow_upgrade && [ ${CUI_RESPONSE:-} = "3" ]; then
            set_install_mode "UPGRADE"
            break
        fi

        cui_echo "${MSG_ERROR_INVALID_OPTION:-}"
    done
}

cui_panel_dbcloud_installtype()
###############################
# currently unused panel
{
    cui_clear_screen

    while true ; do
        cui_echo "${MSG_INSTALL_DBCLOUD_INSTALLTYPE:-}"
        cui_echo ""
        cui_echo " 1. ${MSG_INSTALL_DBCLOUD_INSTALLTYPE_PRIMARY:-}"
        cui_echo " 2. ${MSG_INSTALL_DBCLOUD_INSTALLTYPE_SECONDARY:-}"
        cui_echo " 3. ${MSG_INSTALL_DBCLOUD_INSTALLTYPE_ADDITIONAL:-}"
        cui_echo ""
        
        _default_selection=1
	if is_dbcloud_secondary_host ; then
            _default_selection=2
        fi

        cui_wait_for_input "${MSG_CHOICE:-} [${_default_selection}]:" ${_default_selection}
        
        unset _default_selection
        
        if [ ${CUI_RESPONSE:-} = "1" ]; then
            set_dbcloud_install_type "PRIMARY"
            break
        elif [ ${CUI_RESPONSE:-} = "2" ]; then
            set_dbcloud_install_type "SECONDARY"
            break
        elif [ ${CUI_RESPONSE:-} = "3" ]; then
            set_dbcloud_install_type "ADDITIONAL"
            break
        fi

        cui_echo "${MSG_ERROR_INVALID_OPTION:-}"
    done
}

cui_panel_regkey()
##################
{
    cui_clear_screen
    
    cui_echo "${MSG_ENTER_REGISTRATION}"
    cui_echo ""
    cui_display msg_multiple_keys_prompt_console
    cui_display msg_dev_key_location

    cui_wait_for_input "" `get_registration_key`
    set_registration_key "${CUI_RESPONSE:-}"

    true
}

cui_panel_samon_regkey()
########################
{
    cui_clear_screen
    
    cui_echo "${MSG_ENTER_REGISTRATION}"
    cui_wait_for_input "" `get_registration_key`

    set_registration_key "${CUI_RESPONSE:-}"

    true
}

cui_panel_dbcloud_regkey()
########################
{
    cui_clear_screen
    
    cui_echo "${MSG_ENTER_REGISTRATION}"
    cui_echo ""
    cui_display msg_cloud_key_location
    cui_wait_for_input "" `get_registration_key`

    set_registration_key "${CUI_RESPONSE:-}"

    true
}

cui_panel_regkey_error()
########################
{
    cui_echo ""
    case "`get_key_status`" in
	"invalid")
	    cui_echo "${ERR_INVALID_REGISTRATION:-}"
	    cui_echo "${MSG_REENTER_KEY:-}"
	    ;;
	"web")
	    cui_echo "${ERR_WEB_KEY:-}"
	    cui_echo "${MSG_ENTER_NEW_KEY:-}"
	    ;;
	"workgroup")
	    cui_echo "${ERR_WORKGROUP_KEY:-}"
	    cui_echo "${MSG_ENTER_NEW_KEY:-}"
	    ;;
	"unsupported")
	    cui_echo "${ERR_UNSUPPORTED_KEY:-}"
	    cui_echo "${MSG_ENTER_NEW_KEY:-}"
	    ;;
    esac
    cui_wait_for_input "${MSG_INSTALL_EVALUATION:-}"
    set_registration_key "${CUI_RESPONSE:-}"
    
    [ -z "${CUI_RESPONSE:-}" ] || is_key_valid
}

cui_panel_samon_regkey_error()
##############################
{
    cui_echo ""
    case "`get_key_status`" in
	"invalid")
	    cui_echo "${ERR_INVALID_REGISTRATION:-}"
	    cui_echo "${MSG_REENTER_KEY:-}"
	    ;;
	"unsupported")
	    cui_echo "${ERR_KEY_DOES_NOT_MATCH_PRODUCT}"
	    cui_echo "${MSG_ENTER_NEW_KEY:-}"
	    ;;
    esac
    cui_wait_for_input "" `get_registration_key`
    set_registration_key "${CUI_RESPONSE:-}"
    
    [ -z "${CUI_RESPONSE:-}" ] || is_key_valid
}

cui_panel_dbcloud_regkey_error()
##############################
{
    cui_echo ""
    case "`get_key_status`" in
	"invalid")
	    cui_echo "${ERR_INVALID_REGISTRATION:-}"
	    cui_echo "${MSG_REENTER_KEY:-}"
	    ;;
	"unsupported")
	    cui_echo "${ERR_KEY_DOES_NOT_MATCH_PRODUCT}"
	    cui_echo "${MSG_ENTER_NEW_KEY:-}"
	    ;;
    esac
    cui_wait_for_input "" `get_registration_key`
    set_registration_key "${CUI_RESPONSE:-}"
    
    [ -z "${CUI_RESPONSE:-}" ] || is_key_valid
}

cui_panel_license_agreement()
#############################
{
    cui_clear_screen
    get_license_agreement | more

    if not cui_ask_y_n "${MSG_Y_TO_ACCEPT_N_TO_REFUSE}" "N" ; then
 	cui_display msg_error_disagree_license "`get_package_name`"
 	signal_handler
    fi

    true
}

cui_panel_dbcloud_license_agreement()
#############################
{
    cui_clear_screen
    get_license_agreement | more

    if not cui_ask_y_n "${MSG_Y_TO_ACCEPT_N_TO_REFUSE}" "N" ; then
 	cui_display msg_error_disagree_license "`get_package_name`"
 	signal_handler
    fi

    true
}

cui_package_help()
##################
{
    cui_clear_screen
    for package in $1 ; do
	cui_echo `get_package_display_name $package`
	cui_echo "    `get_package_description $package`"
	cui_echo ""
    done
    cui_display msg_options_help
    cui_echo ""
    cui_wait_for_input "${MSG_HIT_ENTER_TO_RETURN_TO_MENU}" "NONE"	      
}

cui_components_menu ()
######################
{
    PACKAGES=`get_visible_children $1`
    DONE_OPTIONS="false"
    while [ "$DONE_OPTIONS" = "false" ] ; do
	cui_clear_screen
	
	if [ "$1" = "TOP_LEVEL_COMPONENTS" ] ; then
	    if is_deploy ; then
		cui_echo "${MSG_SELECT_DEPLOY_COMPONENTS}"
	    else
		cui_echo "${MSG_SELECT_INSTALL_COMPONENTS}"
	    fi
	else
	    cui_echo "${MSG_SELECT_OPTIONS}"
	fi

	cui_echo ""
	
	cnt=0
	for c in $PACKAGES ; do
            SELECTED=0
            TOTAL=0
 	    if has_visible_children "$c" ; then
 		set_category_state $c
                get_category_selected_count "$c" SELECTED TOTAL
                if [ "${TOTAL:-0}" = "0" ] ; then
                    continue
                fi
 	    fi
            
            if is_installed_option "$c" || not is_exposed_option "$c" ; then
                continue
            fi

  	    cnt=`expr $cnt + 1`
  	    eval "opt$cnt=$c"
  	    PKG_NAME=`get_package_display_name $c`
  	    OPT_LINE=`eval echo [\"\\$$c\"] $cnt. \"$PKG_NAME\"`
	    
	    if [ "${TOTAL:-0}" != "0" ] ; then
		OPT_LINE="$OPT_LINE (`msg_how_many_selected $SELECTED $TOTAL`)"
	    fi
  	    cui_echo "$OPT_LINE"
	done
	
	if [ "$1" = "TOP_LEVEL_COMPONENTS" ] ; then
	    if is_deploy ; then
		cui_display msg_deployment_option_selection_screen
	    else
		cui_display msg_main_option_selection_screen
	    fi
	else
	    cui_display msg_suboption_selection_screen
	fi
	
	case $CHOICE in
	    [1-9] | [1-9][0-9] )
	      if [ $CHOICE -gt $cnt ]; then
		  cui_display msg_error_invalid_option "${CHOICE}"
		  cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"
		  continue
	      fi
              SELECTION=`eval echo "\\$opt$CHOICE"`
	      if has_visible_children "$SELECTION" ; then
		  cui_components_menu "$SELECTION"
		  DONE_OPTIONS=false
		  PACKAGES=`get_visible_children $1`
	      else
		  toggle_option "$SELECTION"
	      fi
	      continue
            ;;
	    All ) 
	      select_all "$PACKAGES"
	    ;;
	    Default )
              select_none "$PACKAGES"
	      select_default "$PACKAGES"
	    ;;
	    None )
	      select_none "$PACKAGES"
	    ;;
	    Quit ) 
	    if cui_ask_y_n "${MSG_ASK_EXIT_SETUP}" "N" ; then
		signal_handler
	    else
		continue
	    fi
	    ;;
	    ShowFileList )
		set_deploy_wizard_mode LIST
		DONE_OPTIONS=true
		continue
	    ;;
	    DeployTar )
		set_deploy_wizard_mode TAR
		DONE_OPTIONS=true
		continue
		;;
	    Previous | Start )
	      DONE_OPTIONS=true
	      continue
	    ;;
	    Help )
	      cui_package_help "$PACKAGES"
	    ;;
	    * )
	      cui_display msg_error_invalid_option "${CHOICE}"
	      cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"	      
	      continue
	      ;;
	 esac
    done
}

cui_prompt_for_directory()
##########################
{
    VALID=invalid
    
    while true ; do
	cui_wait_for_input "${MSG_ENTER_INSTALL_DIR:-} [$1]: " "$1"
	DIRECTORY="${CUI_RESPONSE:-}"

	VALID=`check_directory_validity "${DIRECTORY:-}"`
	case $VALID in 
	    not_a_directory)
		cui_display msg_error_not_a_directory "${DIRECTORY:-}"
		cui_echo ""
		;;
	    not_full_path)
		cui_display msg_error_invalid_directory "${DIRECTORY:-}"
		cui_echo "${MSG_ENTER_INSTALL_DIR_FULL_PATH:-}"
		cui_echo ""
		;;
	    will_cause_overwrite)
		cui_display msg_directory_already_exists "${DIRECTORY:-}"
		if cui_ask_y_n "${MSG_ASK_OVERWRITE_FILES}" "N" ; then
		    break
		fi
		cui_echo ""
		;;
	    upgrade_required)
		cui_display msg_directory_requires_upgrade "${DIRECTORY:-}" "`get_upgrade_version_display \"${DIRECTORY:-}\"`" "`get_version_display`"
		if cui_ask_y_n "${MSG_ASK_CONTINUE}" "N" ; then
		    break
		fi
		cui_echo ""
		;;
	    does_not_exist)
		cui_display msg_error_directory_does_not_exist "${DIRECTORY:-}"
		cui_echo ""
		;;
	    no_write_permissions)
		cui_display msg_error_cannot_create_directory "${DIRECTORY:-}"
		cui_display msg_error_dont_have_write_permissions "`get_parent "${DIRECTORY:-}"`"
		cui_echo ""
		;;
	    version_mismatch)
		cui_display msg_version_mismatch "${DIRECTORY:-}"
		cui_echo ""
		;;
	    no_product)
		cui_display msg_no_components_installed "`get_install_dir ROOT`"
		cui_echo ""
		;;
	    valid)
		break
		;;
	esac
    done
    eval $2=\"${DIRECTORY:-}\"
}

cui_prompt_for_clouddata_directory()
####################################
{
    VALID=invalid
    
    while true ; do
	cui_wait_for_input "${MSG_ENTER_CLOUD_DATA_DIR:-} [$1]: " "$1"
	DIRECTORY="${CUI_RESPONSE:-}"

	VALID=`check_directory_validity "${DIRECTORY:-}"`
	case $VALID in 
	    not_a_directory)
		cui_display msg_error_not_a_directory "${DIRECTORY:-}"
		cui_echo ""
		;;
	    not_full_path)
		cui_display msg_error_invalid_directory "${DIRECTORY:-}"
		cui_echo "${MSG_ENTER_INSTALL_DIR_FULL_PATH:-}"
		cui_echo ""
		;;
	    will_cause_overwrite)
		cui_display msg_directory_already_exists "${DIRECTORY:-}"
		if cui_ask_y_n "${MSG_ASK_OVERWRITE_FILES}" "N" ; then
		    break
		fi
		cui_echo ""
		;;
	    does_not_exist)
		cui_display msg_error_directory_does_not_exist "${DIRECTORY:-}"
		cui_echo ""
		;;
	    no_write_permissions)
		cui_display msg_error_cannot_create_directory "${DIRECTORY:-}"
		cui_display msg_error_dont_have_write_permissions "`get_parent "${DIRECTORY:-}"`"
		cui_echo ""
		;;
	    version_mismatch)
		cui_display msg_version_mismatch "${DIRECTORY:-}"
		cui_echo ""
		;;
	    no_product)
		cui_display msg_no_components_installed "`get_install_dir ROOT`"
		cui_echo ""
		;;
	    valid)
		break
		;;
	esac
    done
    eval $2=\"${DIRECTORY:-}\"
}

cui_prompt_for_file()
#####################
{
    VALID=invalid
    while true ; do
	cui_wait_for_input "${MSG_ENTER_DEPLOY_TAR_DESTINATION} [$1]: " "$1"
	FILE="${CUI_RESPONSE:-}"

	VALID=`check_file_validity ${FILE:-}`
	case $VALID in 
	    will_cause_overwrite)
		cui_display msg_file_already_exists "${FILE:-}"
		if cui_ask_y_n "${MSG_ASK_OVERWRITE_FILES}" "N" ; then
		    break
		fi
		cui_echo ""
		;;
	    not_full_path)
		cui_display msg_error_not_a_full_path "${FILE:-}"
		cui_echo ""
		;;
	    no_write_permissions)
		cui_display msg_error_dont_have_write_permissions "`get_parent "${FILE:-}"`"
		cui_echo ""
		;;
	    valid)
		break
		;;
	esac
    done
    eval $2=\"${FILE}\"
}

cui_panel_destination()
#######################
{
    cui_clear_screen
    cui_echo ""
    cui_prompt_for_directory "`get_install_dir ROOT`" INSTALL_DIR
    set_install_dir SA "${INSTALL_DIR:-}"
    [ `get_install_type` = "DBCLOUD" ] || cui_show_summary
}

cui_panel_components()
######################
{
    cui_components_menu TOP_LEVEL_COMPONENTS
}

cui_panel_components_and_destination()
######################################
{
    cui_components_menu TOP_LEVEL_COMPONENTS
    if not is_modify ; then
        cui_panel_destination
    else
        cui_show_summary
    fi
}

cui_show_summary()
##################
{
    show_status=${1:-selected}
    
    cui_clear_screen
    generate_install_summary COUNT "${show_status}"

    if [ $COUNT -le 0 ]; then
	if is_upgrade ; then
	    cui_display msg_no_components_installed "`get_install_dir ROOT`"
	    cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"
	    false
	    return
	else
	    cui_display msg_no_options_selected
	    cui_wait_for_input "${MSG_HIT_ENTER_TO_RETURN_TO_MAIN_MENU}" "NONE"	    
	    false
	    return
	fi
    fi

    cui_more "$TMPFILE"
    rm -f "$TMPFILE"
    
    if cui_ask_y_n "${MSG_ASK_ARE_OPTIONS_SATISFACTORY}" "N" ; then
        if [ "${show_status}" != "installed" ]; then
 	    cui_echo "${MSG_CHECKING_FOR_AVAILABLE_DISK_SPACE}"
 	    if check_disk_space MOUNT REQUIRED AVAILABLE ; then
		sleep 1
	        true
 	    else
	        cui_display msg_error_insufficient_disk_space "$MOUNT" "$REQUIRED" "$AVAILABLE"
	        cui_echo ""
	        cui_wait_for_input "${MSG_HIT_ENTER_TO_RETURN_TO_MAIN_MENU}" "NONE"
	        false
 	    fi
        fi
    else
	false
    fi
}

cui_panel_server_license()
##########################
{
    while true ; do
	cui_clear_screen

	cui_echo "${MSG_ENTER_SERVER_LICENSE_INFO}"
	cui_echo ""
	
	while true ; do
	    cui_wait_for_input "$MSG_ENTER_NAME [`get_license_info NAME`]:" "`get_license_info NAME`"
	    cui_echo ""
	    
	    if [ -n "${CUI_RESPONSE:-}" ] ; then
		set_license_info NAME "${CUI_RESPONSE:-}"
		break
	    fi
	done
	
	cui_wait_for_input "$MSG_ENTER_COMPANY [`get_license_info COMPANY`]:" `get_license_info COMPANY`
	cui_echo ""

	if [ -n "${CUI_RESPONSE:-}" ] ; then
	    set_license_info COMPANY "${CUI_RESPONSE:-}"
	fi
	
        if [ `get_install_type` != "DBCLOUD" ]; then
            license_type=`get_license_info TYPE`
	    if [ ${license_type:-} = "processor" ] ; then
	        set_license_info TYPE percpu
	        cui_echo ""
	        cui_wait_for_input "${MSG_ASK_NUMBER_OF_LICENSE_CPUS:-} [`get_license_info CPUCOUNT`]:" `get_license_info CPUCOUNT`
	        set_license_info CPUCOUNT "${CUI_RESPONSE:-}"
	    elif [ ${license_type:-} = "core" ] ; then
	        set_license_info TYPE percore
	        cui_echo ""
	        cui_wait_for_input "${MSG_ASK_NUMBER_OF_LICENSE_CORES:-} [`get_license_info CORECOUNT`]:" `get_license_info CORECOUNT`
	        set_license_info CORECOUNT "${CUI_RESPONSE:-}"
	    else
	        set_license_info TYPE perseat
	        cui_echo ""
	        cui_wait_for_input "${MSG_ASK_NUMBER_OF_LICENSE_SEATS:-} [`get_license_info SEATCOUNT`]:" `get_license_info SEATCOUNT`
	        set_license_info SEATCOUNT "${CUI_RESPONSE:-}"
	    fi
        fi
	
	# Confimation Screen
	cui_clear_screen
	cui_echo "${MSG_SERVER_LICENSE_INFO:-}"
	cui_echo ""
	cui_echo "$MSG_NAME" `get_license_info NAME`
	cui_echo "$MSG_COMPANY" `get_license_info COMPANY`
	
        if [ `get_install_type` != "DBCLOUD" ]; then
	    if [ `get_license_info TYPE` = "perseat" ] ; then
	        cui_echo "$MSG_LICENSED_SEATS" `get_license_info COUNT`
	    elif [ `get_license_info TYPE` = "core" ] ; then
	        cui_echo "$MSG_LICENSED_CORES" `get_license_info COUNT`
	    else
	        cui_echo "$MSG_LICENSED_PROCESSORS" `get_license_info COUNT`
	    fi
        fi
	
	if cui_ask_y_n "$MSG_ASK_ARE_OPTIONS_SATISFACTORY" "N" ; then
	    break
	fi
    done
    true
}

cui_panel_dbcloud_prompt_for_datadir()
######################################
{
    cui_echo ""
    cui_prompt_for_clouddata_directory "`get_install_dir CLOUDDATA`" CLOUD_DATA_DIR

    true
}

cui_panel_preferences()
#######################
{
    cui_clear_screen
    cui_echo ""

    if has_feature ICONS ; then
        L_PKG_NAME=`get_menu_name`

        default_value="N"
        if get_install_icons ; then
            default_value="Y"
        fi

        if cui_ask_y_n "`msg_icon_prompt "$L_PKG_NAME"`" "${default_value}" ;
        then
	    set_install_icons TRUE
        fi

        cui_echo ""
        
        default_value="N"
        if get_install_sc_icon ; then
            default_value="Y"
        fi

        if has_feature SYBASE_CENTRAL ; then
            if cui_ask_y_n "$MSG_ASK_SYBCENTRAL_SHORTCUT" "${default_value}" ;
            then
	        set_install_sc_icon TRUE
            fi
        fi
        
        cui_echo ""
    fi

    default_value="Y"
    if get_enable_feature_tracking_specified && ! get_enable_feature_tracking ; then
        default_value="N"
    fi

    if cui_ask_y_n "`msg_feature_tracking_prompt "$L_PKG_NAME"`" "${default_value}" ;
    then
	set_enable_feature_tracking TRUE
    else
        set_enable_feature_tracking FALSE
    fi

    cui_echo ""

    true
}

cui_panel_starting_install()
############################
{
    cui_clear_screen

    cui_echo ""
    cui_echo "$MSG_STARTING_INSTALL_1"
    cui_echo ""
    cui_wait_for_input "$MSG_STARTING_INSTALL_2" "NONE"
    true
}

cui_panel_running_install()
###########################
{
    set_install_callback ERROR cui_handle_error_cb
    set_install_callback QUESTION cui_handle_question_cb
    set_install_callback MESSAGE cui_handle_message_cb
    set_install_callback STATUS cui_handle_message_cb
    do_install
    true
}

cui_panel_post_install_info()
#############################
{
    cui_echo ""

    generate_sourced_file_message_in_tmpfile
    cui_cat "${TMPFILE}"
    rm -f "${TMPFILE}"
    
    cui_echo ""

    if cui_ask_y_n "$MSG_ASK_CHECK_FOR_UPDATES" "N" ; then
	cui_echo ""
	start_check_for_updates
	wait_check_for_updates
	JUNK=`get_updates_tmpfile`
	more "$JUNK"
	cui_echo ""
    fi

    cui_echo ""

    if cui_ask_y_n "$MSG_ASK_REVIEW_README" "Y" ; then
	$MEDIA_ROOT/readme
    fi
    
    cui_echo ""

    if has_feature SYBASE_CENTRAL && [ -n "${DISPLAY:-}" ]; then
        if cui_ask_y_n "$MSG_ASK_STARTSYBCENTRAL" "N" ; then
	    cui_echo ""
	    run_sybase_central_sample
	    cui_echo ""
        fi
    fi

    cui_echo ""

    true
}

cui_prompt_for_directory_and_scan_install()
###########################################
{
    cui_clear_screen
    cui_prompt_for_directory "`get_install_dir ROOT`" INSTALL_DIR
    cui_display msg_scanning_directory "${INSTALL_DIR:-}"
    set_install_dir SA "${INSTALL_DIR:-}"
}

cui_panel_locate_existing_install_for_deployment()
##################################################
{
    cui_prompt_for_directory_and_scan_install
}

cui_panel_locate_existing_install()
###################################
{
    cui_prompt_for_directory_and_scan_install
    if is_modify && [ `get_num_available_packages` -gt 1 ]; then
        cui_show_summary "installed"
    else
        cui_show_summary
    fi
}

cui_panel_samon_migration()
###########################
{
    if cui_ask_y_n "$MSG_SAMON_MIGRATE_RESOURCES_CLI_Q" "N" ; then
	samon_set_migrate_resources 1
    fi
    true
}

cui_panel_non_updated_components()
##################################
{
    UNAVAIL_PKGS=`get_unavailable_packages`
    cui_echo ""
    if is_ebf; then
        cui_display msg_components_not_in_ebf "${UNAVAIL_PKGS}"
        if not cui_ask_y_n "${MSG_ASK_CONTINUE}" "N" ; then
	    signal_handler
        fi
    else
        cui_display msg_components_not_in_upgrade "${UNAVAIL_PKGS}"
        cui_echo ""
	cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"
        rewind_to_panel panel_locate_existing_install
    fi
}

cui_panel_ultralite()
#####################
{
    cui_echo ""
    cui_display msg_ultralite
}

rewind_to_panel()
#################
{
    NEXT_PANEL="$1"
}

run_console_mode()
##################
{
    PANEL=`next_panel`
    while [ -n "${PANEL:-}" ] ; do
	if is_debug ; then
	    echo ""
	    echo "--> DISPLAYING PANEL: $PANEL"
	    echo ""
	fi
	if eval `echo "cui_$PANEL"` ; then
	    if [ -n "${NEXT_PANEL:-}" ] ; then
		PANEL="$NEXT_PANEL"
		NEXT_PANEL=
	    else
		PANEL=`next_panel $PANEL`
	    fi
	fi
    done
}

cui_panel_apply_license()
#########################
{
    cui_echo ""

    licensed_files=`license_all_components`

    if [ -z "${licensed_files:-}" ] ; then
        cui_echo $MSG_LICENSED_FILES_NONE
    else
        cui_echo $MSG_LICENSED_FILES
        for file in $licensed_files; do
            cui_echo " - $file"
        done
    fi

    if cui_ask_y_n "$MSG_ASK_REVIEW_README" "Y" ; then
	$MEDIA_ROOT/readme
    fi
    
    true
}

cui_panel_samonitor_service()
#############################
{
    cui_echo ""
    cui_display msg_samonitor_service
    if cui_ask_y_n "$MSG_SAMON_SERVICE_CLI_Q" "Y" ; then
	if not install_samonitor_service ; then
	    cui_echo "$MSG_SAMON_SERVICE_ERROR"
	fi
    fi

    true
}

cui_panel_dbcloud_doconfig_ask_y_n()
####################################
{
    cui_echo ""
    cui_display msg_dbcloud_ask_config
    if cui_ask_y_n "$MSG_DBCLOUD_CONFIG_CLI_Q" "Y" ; then
	set_dbcloud_doconfig 1
    else
	set_dbcloud_doconfig 0
    fi

    true
}

cui_panel_dbcloud_config_run()
##############################
{
    cui_clear_screen

    dbcloud_config_enabled && configure_dbcloud

    true
}

cui_panel_samon_post_install_info()
###################################
{
    cui_echo ""

    cui_display msg_finished_installing "`get_package_name`"
}

cui_panel_dbcloud_post_install_info()
###################################
{
    cui_echo ""

    cui_display msg_finished_installing "`get_package_name`"
}

cui_panel_deploy_post_install_info()
####################################
{
    true
}

cui_panel_generate_deployment_tar()
###################################
{
    cui_prompt_for_file "/tmp/sadeploy.tar" FILE
    cui_clear_screen
    cui_echo "${MSG_GENERATING_DEPLOYMENT_TAR}"
    generate_deployment_tar "$FILE"
}

cui_panel_list_deployment_files()
#################################
{
    cui_clear_screen

    build_filelist
    cui_more `get_filelist`

    while [ 1 = 1 ] ; do
	cui_display msg_deployment_filelist_selection_screen

	case "${CHOICE:-}" in
	    Save)
		cui_prompt_for_file "/tmp/sadeploy.txt" FILE
		save_deploy_file_list_to_file "$FILE"
		break;
		;;
	    Modify)
		rewind_to_panel panel_components
		break;
		;;
	    *)
		cui_display msg_error_invalid_option "${CHOICE}"
		cui_wait_for_input "${MSG_HIT_ENTER_TO_TRY_AGAIN}" "NONE"
		;;
	esac
    done

}
