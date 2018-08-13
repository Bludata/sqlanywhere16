# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
#####################################
# FUNCTIONS REQUIRING RETURN VALUES #
#####################################


# msg_main_option_selection_screen
# Output when a suboption is selected,
# i.e Tools, SCCentral, Documentation, ... to decide what should be installed
#
# NOTE: on exit, CHOICE must contain i.e do not translate :
# "All" - to select all options 
# "None" - to select no options
# "Help" - to show the help
# "Quit" - to exit setup
# "Start" - to start intalation
msg_main_option_selection_screen()
##################################
{
    echo "${MSG_MAIN_SCREEN_PROMPT_1}"
    echo "${MSG_MAIN_SCREEN_PROMPT_2}"
    echo "${MSG_MAIN_SCREEN_PROMPT_10}"
    echo "${MSG_MAIN_SCREEN_PROMPT_3}"
    echo "${MSG_MAIN_SCREEN_PROMPT_4}"
    echo "${MSG_MAIN_SCREEN_PROMPT_5}"
    echo "${MSG_MAIN_SCREEN_PROMPT_6}"
    echo "${MSG_MAIN_SCREEN_PROMPT_7}"
    echo "${MSG_MAIN_SCREEN_PROMPT_8}"
    echo "${MSG_MAIN_SCREEN_PROMPT_9}"
    
    read JUNK

    case $JUNK in

        "${MSG_MAIN_SCREEN_ANSWER_A}" | "${MSG_MAIN_SCREEN_ANSWER_a}" )
            CHOICE="All"
            ;;
        "${MSG_MAIN_SCREEN_ANSWER_D}" | "${MSG_MAIN_SCREEN_ANSWER_d}" )
            CHOICE="Default"
            ;;
        "${MSG_MAIN_SCREEN_ANSWER_N}" | "${MSG_MAIN_SCREEN_ANSWER_n}" )
            CHOICE="None"
            ;;
        "${MSG_MAIN_SCREEN_ANSWER_H}" | "${MSG_MAIN_SCREEN_ANSWER_h}" )
            CHOICE="Help"
            ;;
        "${MSG_MAIN_SCREEN_ANSWER_Q}" | "${MSG_MAIN_SCREEN_ANSWER_q}" )
            CHOICE="Quit"
            ;;
        "${MSG_MAIN_SCREEN_ANSWER_S}" | "${MSG_MAIN_SCREEN_ANSWER_s}" )
            CHOICE="Start"
            ;;
        * )
            CHOICE="${JUNK}"
            ;;
    esac
}

# msg_suboption_selection_screen
# Output when a suboption is selected,
# i.e Tools, SCCentral, Documentation, ... to decide what should be installed
#
# NOTE: on exit, CHOICE must contain:
# "All" - to select all options
# "None" - to select no options
# "Help" - to show the help
# "Previous" - to go to the previous menu
# "Quit" - to exit setup
msg_suboption_selection_screen()
################################
{
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_1}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_2}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_11}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_3}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_4}"
    if not is_deploy ; then
	echo "${MSG_SUBOPTION_SCREEN_PROMPT_5}"
    fi
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_6}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_7}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_8}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_9}"
    echo "${MSG_SUBOPTION_SCREEN_PROMPT_10}"

    read JUNK

    case $JUNK in
        
        "${MSG_SUBOPTION_SCREEN_ANSWER_A}" | "${MSG_SUBOPTION_SCREEN_ANSWER_a}" )
            CHOICE="All"
            ;;

        "${MSG_SUBOPTION_SCREEN_ANSWER_D}" | "${MSG_SUBOPTION_SCREEN_ANSWER_d}" )
            CHOICE="Default"
            ;;

        "${MSG_SUBOPTION_SCREEN_ANSWER_N}" | "${MSG_SUBOPTION_SCREEN_ANSWER_n}" )
            CHOICE="None"
            ;;

        "${MSG_SUBOPTION_SCREEN_ANSWER_H}" | "${MSG_SUBOPTION_SCREEN_ANSWER_h}" )
	    if is_deploy ; then
		CHOICE="${JUNK}"
	    else
		CHOICE="Help"
	    fi
            ;;

        "${MSG_SUBOPTION_SCREEN_ANSWER_P}" | "${MSG_SUBOPTION_SCREEN_ANSWER_p}" )
            CHOICE="Previous"
            ;;
        
        "${MSG_SUBOPTION_SCREEN_ANSWER_Q}" | "${MSG_SUBOPTION_SCREEN_ANSWER_q}" )
            CHOICE="Quit"
            ;;

        * )
            CHOICE="${JUNK}"
            ;;

    esac
}
# msg_main_option_selection_screen
# Output when a suboption is selected,
# i.e Tools, SCCentral, Documentation, ... to decide what should be installed
#
# NOTE: on exit, CHOICE must contain i.e do not translate :
# "All" - to select all options 
# "None" - to select no options
# "Help" - to show the help
# "Quit" - to exit setup
# "Start" - to start intalation
msg_deployment_option_selection_screen()
########################################
{
    echo "${MSG_DEPLOY_SCREEN_PROMPT_1}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_2}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_10}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_3}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_4}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_5}"
#    echo "${MSG_DEPLOY_SCREEN_PROMPT_6}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_7}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_8}"
    echo "${MSG_DEPLOY_SCREEN_PROMPT_9}"
    
    read JUNK

    case $JUNK in

        "${MSG_DEPLOY_SCREEN_ANSWER_A}" | "${MSG_DEPLOY_SCREEN_ANSWER_a}" )
            CHOICE="All"
            ;;
        "${MSG_DEPLOY_SCREEN_ANSWER_D}" | "${MSG_DEPLOY_SCREEN_ANSWER_d}" )
            CHOICE="Default"
            ;;
        "${MSG_DEPLOY_SCREEN_ANSWER_N}" | "${MSG_DEPLOY_SCREEN_ANSWER_n}" )
            CHOICE="None"
            ;;
        "${MSG_DEPLOY_SCREEN_ANSWER_Q}" | "${MSG_DEPLOY_SCREEN_ANSWER_q}" )
            CHOICE="Quit"
            ;;
        # "${MSG_DEPLOY_SCREEN_ANSWER_G}" | "${MSG_DEPLOY_SCREEN_ANSWER_g}" )
        #     CHOICE="DeployTar"
        #    ;;
        "${MSG_DEPLOY_SCREEN_ANSWER_S}" | "${MSG_DEPLOY_SCREEN_ANSWER_s}" )
            CHOICE="ShowFileList"
            ;;
        * )
            CHOICE="${JUNK}"
            ;;
    esac
}

# msg_deployment_filelist_selection_screen
# Output after displaying the list of files required for deployment
#
# NOTE: on exit, CHOICE must contain i.e do not translate :
# Save - to save the list of files to a file
# Modify - to allow the user to go back and modify their selection of components
msg_deployment_filelist_selection_screen()
##########################################
{
    echo "${MSG_FILELIST_SCREEN_PROMPT_1}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_2}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_3}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_4}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_5}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_6}"
    echo "${MSG_FILELIST_SCREEN_PROMPT_7}"

    read JUNK

    case $JUNK in
	"${MSG_FILELIST_SCREEN_ANSWER_S}" | "${MSG_FILELIST_SCREEN_ANSWER_s}" )
	    CHOICE="Save"
	    ;;
	"${MSG_FILELIST_SCREEN_ANSWER_M}" | "${MSG_FILELIST_SCREEN_ANSWER_m}" )
	    CHOICE="Modify"
	    ;;
	* )
	    CHOICE="${JUNK}"
	    ;;
    esac
}

###########################################
# FUNCTIONS REQUIRING STRING SUBSTITUTION #
###########################################

msg_need_to_source_for_environment_single_bitness()
###################################################
{
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_SINGLE_BITNESS_1}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_SINGLE_BITNESS_2}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_SINGLE_BITNESS_3}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_SINGLE_BITNESS_4}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_SINGLE_BITNESS_5}\""
}

msg_need_to_source_for_environment_multi_bitness()
##################################################
{
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_1}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_2}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_3}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_4}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_5}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_ENV_MULTI_BITNESS_6}\""
}

msg_need_to_source_for_samples_single_bitness()
###############################################
{
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_SINGLE_BITNESS_1}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_SINGLE_BITNESS_2}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_SINGLE_BITNESS_3}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_SINGLE_BITNESS_4}\""
}

msg_need_to_source_for_samples_multi_bitness()
##############################################
{
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_MULTI_BITNESS_1}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_MULTI_BITNESS_2}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_MULTI_BITNESS_3}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_MULTI_BITNESS_4}\""
    eval "echo \"${MSG_NEED_TO_SOURCE_FOR_SAMPLES_MULTI_BITNESS_5}\""
}

msg_scanning_directory()
########################
{
   eval "echo \"${MSG_SCANNING_DIR}\""
}

msg_installing_files_into()
###########################
{
    eval "echo \"${MSG_INSTALLING_FILES_INTO}\""
}

msg_error_extracting_files()
############################
{
    eval "echo \"${MSG_ERROR_EXTRACTING_FILES_1}\""
    eval "echo \"${MSG_ERROR_EXTRACTING_FILES_2}\""
    eval "echo \"${MSG_ERROR_EXTRACTING_FILES_3}\""
}

msg_reverting_files_into()
##########################
{
    eval "echo \"${MSG_REVERTING_FILES_INTO}\""
}

msg_prompt_file_exists_overwrite()
##################################
{
    eval "echo \"${MSG_PROMPT_FILE_EXISTS_OVERWRITE}\""
}

msg_extracted_files_location()
##############################
{
    eval "echo \"${MSG_EXTRACTED_FILES_LOCATION_1}\""
}

#
# $1: filename
#
msg_copyright_header()
######################
{
    cat <<-EOF  >> "$1"
echo "${MSG_HEADER_1}"
echo 
EOF
}

msg_default_install_directory()
###############################
{
    eval "echo"
    eval "echo \"${MSG_DEFAULT_INSTALL_DIRECTORY_1}\""
    eval "echo \"${MSG_DEFAULT_INSTALL_DIRECTORY_2}\""
}

msg_current_install_directory()
###############################
{
    eval "echo"
    eval "echo \"${MSG_CURRENT_INSTALL_DIRECTORY_1}\""
    eval "echo \"${MSG_CURRENT_INSTALL_DIRECTORY_2}\""
}

msg_gui_current_install_directory()
###################################
{
    if [ -z "${1:-}" ]; then
        msg_gui_current_install_directory "`get_package_name`"
    else
        eval "echo \"${MSG_CURRENT_INSTALL_DIRECTORY_1}\""
    fi
}

msg_optional_component()
########################
{
    eval "echo"
    eval "echo \"${MSG_OPTIONALLY_INSTALLED_COMPONENT}\""
    eval "echo \"${MSG_MAY_PRESS_ENTER_IF_OPTIONAL_COMPONENT_NOT_INSTALLED}\""
}

msg_error_os_version_too_low()
##############################
{
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_1}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_2}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_3}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_4}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_5}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_6}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_7}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_8}\""
    eval "echo \"${MSG_ERROR_OS_VERSION_TOO_LOW_9}\""
}

msg_error_version_mismatch()
############################
{
    eval "echo"
    eval "echo \"${MSG_ERROR_VERSION_MISMATCH_1}\""
    eval "echo \"${MSG_ERROR_VERSION_MISMATCH_2}\""
    eval "echo \"${MSG_ERROR_VERSION_MISMATCH_3}\""
}

msg_error_bitness_mismatch()
############################
{
    eval "echo"
    eval "echo \"${MSG_ERROR_BITNESS_MISMATCH_1}\""
    eval "echo \"${MSG_ERROR_BITNESS_MISMATCH_2}\""
    eval "echo \"${MSG_ERROR_BITNESS_MISMATCH_3}\""
}

msg_error_os_mismatch()
#######################
{
    eval "echo"
    eval "echo \"${MSG_ERROR_OS_MISMATCH_1}\""
    eval "echo \"${MSG_ERROR_OS_MISMATCH_2}\""
}

msg_error_need_df()
###################
{
    eval "echo"
    eval "echo \"${MSG_ERROR_NEED_DF_1}\""
    eval "echo \"${MSG_ERROR_NEED_DF_2}\""
}

msg_error_not_a_directory()
###########################
{
    eval "echo \"${MSG_ERROR_NOT_A_DIRECTORY}\""
}

msg_error_invalid_directory()
#############################
{
    eval "echo \"${MSG_ERROR_INVALID_DIRECTORY}\""
}

msg_error_not_a_directory()
###############################
{
    eval "echo \"${MSG_ERROR_NOT_A_DIRECTORY}\""
}

msg_directory_already_exists()
##############################
{
    eval "echo \"${MSG_DIRECTORY_ALREADY_EXISTS}\""
}

msg_directory_requires_upgrade()
################################
{
    eval "echo \"${MSG_DIRECTORY_REQUIRES_UPGRADE}\""
}

msg_file_already_exists()
#########################
{
    eval "echo \"${MSG_FILE_ALREADY_EXISTS}\""
}

msg_error_directory_does_not_exist()
####################################
{
    eval "echo \"${MSG_DIRECTORY_DOES_NOT_EXIST}\""
}

msg_directory_not_writable()
############################
{
    eval "echo \"${MSG_DIRECTORY_NOT_WRITABLE}\""
}

msg_error_cannot_create_directory()
###################################
{
    eval "echo \"${MSG_ERROR_CANNOT_CREATE_DIRECTORY}\""
}

msg_path_not_creatable()
########################
{
    eval "echo \"${MSG_ERROR_CANNOT_CREATE_DIRECTORY}\""
    echo "$MSG_ERROR_PATH_INVALID_OR_PERMISSIONS_LACKING"
}

msg_error_cannot_create_directory_aborting()
############################################
{
    eval "echo \"${MSG_ERROR_CANNOT_CREATE_DIRECTORY_ABORTING}\""
}

msg_error_dont_have_write_permissions()
#######################################
{
    eval "echo \"${MSG_ERR_DONT_HAVE_WRITE_PERMISSIONS}\""
}

msg_finished_installing()
#########################
{
    eval "echo \"${MSG_FINISHED_INSTALLING}\""
}

msg_error_disagree_license()
############################
{
    eval "echo \"${MSG_ERROR_DISAGREE_LICENSE_1}\""
    eval "echo \"${MSG_ERROR_DISAGREE_LICENSE_2}\""
}

msg_how_many_selected()
#######################
{
    eval "echo \"${MSG_HOW_MANY_SELECTED}\""
}

msg_error_invalid_option()
##########################
{
    eval "echo \"${MSG_ERROR_INVALID_OPTION}\""
}

msg_error_unknown_option()
##########################
{
    eval "echo \"${MSG_ERROR_UNKNOWN_OPTION}\""
}

msg_error_cl_options_unknown_argument()
#######################################
{
    eval "echo \"${MSG_ERROR_CL_OPTIONS_UNKNOWN_ARGUMENT}\""
}

msg_error_unknown_region()
##########################
{
    eval "echo \"${MSG_ERROR_UNKNOWN_REGION}\""
}

msg_error_insufficient_disk_space()
###################################
{
    eval "echo \"${MSG_ERROR_INSUFFICIENT_DISK_SPACE_1}\""
    eval "echo \"${MSG_ERROR_INSUFFICIENT_DISK_SPACE_2}\""
}

msg_error_corrupt_ticfile()
###########################
{
    eval "echo \"${MSG_ERROR_CORRUPT_TICFILE_1}\""
    eval "echo \"${MSG_ERROR_CORRUPT_TICFILE_2}\""
}

###############################################
# FUNCTIONS REPRESENTING LARGE BLOCKS OF TEXT #
###############################################

msg_install_completed()
#######################
{
    echo 
    echo "${MSG_INSTALL_COMPLETED_1}"
    echo 
    echo "${MSG_INSTALL_COMPLETED_2}"
    echo 
}

msg_install_title()
###################
{
    eval "echo \"${MSG_INSTALL_TITLE}\""
}

msg_welcome()
#############
{
    eval "echo \"${MSG_WELCOME_MESSAGE_1}\""
    echo
    eval "echo \"${MSG_WELCOME_MESSAGE_2}\""
    echo "${MSG_WELCOME_MESSAGE_3}"
    echo
    
    if [ "`get_install_type`" = "SAMON" ]; then
	echo "${MSG_SAMON_WELCOME_MESSAGE_1}"
	echo "${MSG_SAMON_WELCOME_MESSAGE_2}"
	echo "${MSG_SAMON_WELCOME_MESSAGE_3}"
	echo "${MSG_SAMON_WELCOME_MESSAGE_4}"
	echo "${MSG_SAMON_WELCOME_MESSAGE_5}"
	echo
    fi
}

msg_deployment_wizard_welcome()
###############################
{
    echo "${MSG_DEPLOY_WELCOME_1}"
    echo "${MSG_DEPLOY_WELCOME_2}"
    echo "${MSG_DEPLOY_WELCOME_3}"
    echo "${MSG_DEPLOY_WELCOME_4}"
}

msg_deployment_wizard_complete()
################################
{
    echo "${MSG_DEPLOYMENT_WIZARD_COMPLETE_1}"
    echo "${MSG_DEPLOYMENT_WIZARD_COMPLETE_2}"
    echo "${MSG_DEPLOYMENT_WIZARD_COMPLETE_3}"
    echo "${MSG_DEPLOYMENT_WIZARD_COMPLETE_4}"
}

msg_welcome_license_agreement()
###############################
{
    echo "${MSG_WELCOME_LICENSE_AGREEMENT_1}"
    echo "${MSG_WELCOME_LICENSE_AGREEMENT_2}"
}

msg_license_country_list()
##########################
{
    echo "${MSG_LICENSE_COUNTRY_PROMPT_1}"
    echo "${MSG_LICENSE_COUNTRY_PROMPT_2}"
    echo ""
    echo "1)  ${MSG_COUNTRY_1}  2)  ${MSG_COUNTRY_2}"
    echo "3)  ${MSG_COUNTRY_3}  4)  ${MSG_COUNTRY_4}"
    echo "5)  ${MSG_COUNTRY_5}  6)  ${MSG_COUNTRY_6}"
    echo "7)  ${MSG_COUNTRY_7}  8)  ${MSG_COUNTRY_8}"
    echo "9)  ${MSG_COUNTRY_9}  10) ${MSG_COUNTRY_10}"
    echo "11) ${MSG_COUNTRY_11}  12) ${MSG_COUNTRY_12}"
    echo "13) ${MSG_COUNTRY_13}  14) ${MSG_COUNTRY_14}"
    echo "15) ${MSG_COUNTRY_15}  16) ${MSG_COUNTRY_16}"
    echo "17) ${MSG_COUNTRY_17}  18) ${MSG_COUNTRY_18}"
    echo "19) ${MSG_COUNTRY_19}  20) ${MSG_COUNTRY_20}"
    echo "21) ${MSG_COUNTRY_21}  22) ${MSG_COUNTRY_22}"
    echo "23) ${MSG_COUNTRY_23}  24) ${MSG_COUNTRY_24}"
    echo "25) ${MSG_COUNTRY_25}  26) ${MSG_COUNTRY_26}"
    echo "27) ${MSG_COUNTRY_27}  28) ${MSG_COUNTRY_28}"
    echo "29) ${MSG_COUNTRY_29}"
    echo "30) ${MSG_COUNTRY_30}"
}

msg_no_options_selected()
#########################
{
    echo  
    echo "${MSG_NO_OPTIONS_SELECTED_1}"
    echo "${MSG_NO_OPTIONS_SELECTED_2}"
    echo 
}

msg_no_components_installed()
#############################
{
    echo  
    eval "echo \"${MSG_NO_COMPONENTS_INSTALLED_1}\""
    eval "echo \"${MSG_NO_COMPONENTS_INSTALLED_2}\""
    echo 
}

msg_version_mismatch()
######################
{
    echo
    eval "echo \"${MSG_VERSION_TOO_NEW_1}\""
    eval "echo \"${MSG_VERSION_TOO_NEW_2}\""
    echo
}

msg_cloud_cl_options_usage()
############################
{
    eval "echo \"${MSG_CLOUD_CL_OPTIONS_USAGE_1}\""
    echo 
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_2}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_3}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_4}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_5}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_6}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_7}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_8}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_9}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_10}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_11}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_12}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_13}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_14}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_15}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_16}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_17}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_18}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_19}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_20}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_21}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_22}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_23}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_24}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_25}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_26}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_27}"
    echo "${MSG_CLOUD_CL_OPTIONS_USAGE_28}"
}

msg_cl_options_usage()
######################
{
    eval "echo \"${MSG_CL_OPTIONS_USAGE_1}\""
    echo 
    echo "${MSG_CL_OPTIONS_USAGE_2}"
    echo "${MSG_CL_OPTIONS_USAGE_3}"
    echo "${MSG_CL_OPTIONS_USAGE_4}"
    echo "${MSG_CL_OPTIONS_USAGE_5}"
    echo "${MSG_CL_OPTIONS_USAGE_6}"
    echo "${MSG_CL_OPTIONS_USAGE_7}"
    echo "${MSG_CL_OPTIONS_USAGE_8}"
    echo "${MSG_CL_OPTIONS_USAGE_9}"
    echo "${MSG_CL_OPTIONS_USAGE_10}"
    echo "${MSG_CL_OPTIONS_USAGE_11}"
    echo "${MSG_CL_OPTIONS_USAGE_12}"
    echo "${MSG_CL_OPTIONS_USAGE_13}"
    echo "${MSG_CL_OPTIONS_USAGE_14}"
    echo "${MSG_CL_OPTIONS_USAGE_15}"
    echo "${MSG_CL_OPTIONS_USAGE_16}"
}

msg_icon_prompt()
#################
{
    eval "echo \"${MSG_QUESTION_ICONS}\""
}

msg_gui_icon_prompt()
#####################
{
    eval "echo \"${MSG_GUI_ICONS}\""
}

msg_icon_removal_instructions()
###############################
{
    eval "echo \"${MSG_ICON_REMOVAL_INSTRUCTIONS}\""
}

msg_feature_tracking_prompt()
#############################
{
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_1}\""
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_2}\""
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_3}\""
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_4}\""
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_5}\""
}

msg_gui_feature_tracking_prompt()
#################################
{
    eval "echo \"${MSG_GUI_FEATURE_TRACKING_1}\""
    eval "echo \"${MSG_GUI_FEATURE_TRACKING_2}\""
    if [ -n "${MSG_GUI_FEATURE_TRACKING_3}" ]; then
        eval "echo \"${MSG_GUI_FEATURE_TRACKING_3}\""
    fi
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_3}\""
    eval "echo \"${MSG_QUESTION_FEATURE_TRACKING_4}\""
}

msg_mac_feature_tracking_prompt()
#################################
{
    eval "echo \"${MSG_MAC_FEATURE_TRACKING_1}\""
    eval "echo \"${MSG_MAC_FEATURE_TRACKING_2}\""
    eval "echo \"${MSG_MAC_FEATURE_TRACKING_3}\""
}

msg_dev_key_location()
######################
{
    echo "${MSG_OBTAIN_DEV_KEY_1}"
    echo "${MSG_OBTAIN_DEV_KEY_2}"
    echo "${MSG_OBTAIN_DEV_KEY_3}"
}

msg_cloud_key_location()
######################
{
    echo "${MSG_OBTAIN_CLOUD_KEY_1}"
    echo "${MSG_OBTAIN_CLOUD_KEY_2}"
    echo "${MSG_OBTAIN_CLOUD_KEY_3}"
}

msg_system_requirements_too_low()
#################################
{
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_1}"
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_2}"
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_3}"
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_4}"
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_5}"
    echo "${MSG_SYSTEM_REQUIREMENTS_NOT_MET_6}"
}

msg_ensure_you_have_latest_patches()
####################################
{
    echo "${MSG_ENSURE_YOU_HAVE_LATEST_PATCHES_1}"
    echo "${MSG_ENSURE_YOU_HAVE_LATEST_PATCHES_2}"
    echo "${MSG_ENSURE_YOU_HAVE_LATEST_PATCHES_3}"
}

msg_components_not_in_ebf()
###########################
{
    echo "${MSG_INSTALLED_COMPONENTS_NOT_IN_EBF}"
    echo ""
    echo "${1:-}"
}

msg_components_not_in_upgrade()
###############################
{
    echo "${MSG_INSTALLED_COMPONENTS_NOT_IN_UPGRADE}"
    echo ""
    echo "${1:-}"
}

msg_options_help()
##################
{
    echo "${MSG_OPTIONS_HELP_1}"
    echo "${MSG_OPTIONS_HELP_2}"
}

msg_samonitor_service()
#######################
{
    echo "$MSG_SAMON_SERVICE_1"
    echo "$MSG_SAMON_SERVICE_2"
    echo "$MSG_SAMON_SERVICE_3"
    [ -n "$MSG_SAMON_SERVICE_4" ] && echo "$MSG_SAMON_SERVICE_4"
    [ -n "$MSG_SAMON_SERVICE_5" ] && echo "$MSG_SAMON_SERVICE_5"
}

msg_samonitor_failed()
######################
{
    echo "$MSG_SAMON_MIGRATION_FAILED_1"
    if [ -n "${1:-}" ]; then
        msg_samonitor_backup_copy "${1:-}"
        echo "$MSG_SAMON_MIGRATION_FAILED_2"
    fi
}

msg_samonitor_stop_failed_fatal()
#################################
{
    echo "$MSG_SAMON_STOP_FAILED_FATAL_1"
    echo "$MSG_SAMON_STOP_FAILED_FATAL_2"
}

msg_samonitor_stop_failed_nonfatal()
####################################
{
    echo "$MSG_SAMON_STOP_FAILED_NONFATAL_1"
    echo "$MSG_SAMON_STOP_FAILED_NONFATAL_2"
}

msg_samonitor_backup_copy()
###########################
{
    eval "echo \"${MSG_SAMON_BACKUP_COPY}\""
}

msg_error_not_a_full_path()
###########################
{
    eval "echo \"${MSG_ERROR_NOT_A_FULL_PATH}\""
}

msg_multiple_keys_prompt_console()
##################################
{
    echo "$MSG_MULTIPLE_KEYS_PROMPT_CONSOLE_1"
    echo "$MSG_MULTIPLE_KEYS_PROMPT_CONSOLE_2"
    echo "$MSG_MULTIPLE_KEYS_PROMPT_CONSOLE_3"
    echo ""
}

msg_ultralite()
###############
{
    echo "$MSG_ULTRALITE_1"
    echo "$MSG_ULTRALITE_2"
    echo "$MSG_ULTRALITE_3"
}

msg_dbcloud_ask_config()
#######################
{
    echo "$MSG_DBCLOUD_ASK_CONFIG_1"
    [ -n "$MSG_DBCLOUD_ASK_CONFIG_2" ] && echo "$MSG_DBCLOUD_ASK_CONFIG_2"
    [ -n "$MSG_DBCLOUD_ASK_CONFIG_3" ] && echo "$MSG_DBCLOUD_ASK_CONFIG_3"
    [ -n "$MSG_DBCLOUD_ASK_CONFIG_4" ] && echo "$MSG_DBCLOUD_ASK_CONFIG_4"
    [ -n "$MSG_DBCLOUD_ASK_CONFIG_5" ] && echo "$MSG_DBCLOUD_ASK_CONFIG_5"
}

