# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
interactive_read_data( )
########################
{
    read result
    if [ $? -ne 0 ] ; then
	RUNNING_INTERACTIVE="false"
    fi
    echo "$result"
}

interactive_echo_boolean( )
###########################
{
    if eval "${1:-}" ; then
	echo "YES"
    else
	echo "NO"
    fi
}

interactive_multi_line( )
#########################
{
    RESULT=`eval $*`
    
    if [ -n "${RESULT:-}" ] ; then
	count_all full $RESULT
	for r in $RESULT ; do
	    echo "$r"
	done
    else
	echo "0"
    fi
}

gui_handle_error_cb()
#####################
{
    echo "UI_ERRR"
    echo "$*"
    echo "UI_DONE"
}

gui_handle_question_cb()
########################
{
    echo "UI_QUES"
    echo "$*"
    echo "UI_DONE"
    RESULT=`interactive_read_data`
    [ "$RESULT" = "YES" ]
}

gui_starting_install_cb()
#########################
{
    echo "UI_PROG"
}

gui_done_install_cb()
#####################
{
    echo "UI_DONE"
}

gui_handle_message_cb()
#######################
{
    echo "UI_STAT"
    echo "$*"
    echo "UI_DONE"
}

run_interactive_mode()
######################
{
    set_target_charset "UTF8"

    set_install_callback ERROR gui_handle_error_cb
    set_install_callback QUESTION gui_handle_question_cb
    set_install_callback START gui_starting_install_cb
    set_install_callback DONE gui_done_install_cb
    set_install_callback STATUS gui_handle_message_cb

    echo "Interactive Mode Started"
    RUNNING_INTERACTIVE="true"
    
    while [ "$RUNNING_INTERACTIVE" = "true" ] ; do
	cmd=`interactive_read_data`
	case $cmd in
	    iskeydeveloper)
		interactive_echo_boolean "is_developer_key"
		;;
	    iskeyevaluation)
		interactive_echo_boolean "is_evaluation_key"
		;;
	    iskeyaddon)
		interactive_echo_boolean "is_addon_key"
		;;
	    isupgradeallowed)
		interactive_echo_boolean "allow_upgrade"
		;;
	    iskeyvalid)
		get_key_status
		;;
	    getregkey)
		get_registration_key
		;;
	    setregkey)
		key=`interactive_read_data`
		set_registration_key "$key"
		;;
	    checkdirectoryvalidity)
		COMPONENT=`interactive_read_data`
		DIR=`interactive_read_data`
		VALIDITY=`check_directory_validity "$DIR"`
		echo "$VALIDITY"
		;;
	    checkfilevalidity)
		FILE=`interactive_read_data`
		VALIDITY=`check_file_validity "$FILE"`
		echo "$VALIDITY"
		;;
	    setinstalldir)
		COMPONENT=`interactive_read_data`
		DIR=`interactive_read_data`
		set_install_dir "$COMPONENT" "$DIR"
		;;
	    getinstalldir)
		COMPONENT=`interactive_read_data`
		get_install_dir "$COMPONENT"
		;;
	    dispinstalldirprompt)
		COMPONENT=`interactive_read_data`
		echo 1
		echo "${MSG_GUI_DEFAULT_INSTALL_DIRECTORY}"
		;;
	    getsetupfilepath)
		FILE=`interactive_read_data`
		echo 1
		get_install_file "$FILE"
		;;

	    dispcurrinstalldirprompt)
		COMPONENT=`interactive_read_data`
		echo 1
		msg_gui_current_install_directory "`get_package_name`"
		;;
	    checkdiskspace)
		check_disk_space MOUNT REQUIRED AVAILABLE
		echo "1"
		echo "$MOUNT"
		echo "$REQUIRED"
		echo "$AVAILABLE"
		;;
	    function)
		FNNAME=`interactive_read_data`
		$FNNAME | wc -l | sed -e "s/\ //g"
		eval $FNNAME
		;;
	    resource)
		echo 1
		RESNAME=`interactive_read_data`
		eval echo \${$RESNAME}
		;;
	    multivarresource)
		RESNAME=`interactive_read_data`
		RESNUM=`interactive_read_data`
		echo $RESNUM
		JUNK=1
		while [ $JUNK -le $RESNUM ]; do
		    eval echo \${${RESNAME}_${JUNK}}
		    JUNK=`expr $JUNK + 1`
		done
		;;
	    getcountrylist)
		echo "30"
		echo "${MSG_COUNTRY_1}"
		echo "${MSG_COUNTRY_2}"
		echo "${MSG_COUNTRY_3}"
		echo "${MSG_COUNTRY_4}"
		echo "${MSG_COUNTRY_5}"
		echo "${MSG_COUNTRY_6}"
		echo "${MSG_COUNTRY_7}"
		echo "${MSG_COUNTRY_8}"
		echo "${MSG_COUNTRY_9}"
		echo "${MSG_COUNTRY_10}"
		echo "${MSG_COUNTRY_11}"
		echo "${MSG_COUNTRY_12}"
		echo "${MSG_COUNTRY_13}"
		echo "${MSG_COUNTRY_14}"
		echo "${MSG_COUNTRY_15}"
		echo "${MSG_COUNTRY_16}"
		echo "${MSG_COUNTRY_17}"
		echo "${MSG_COUNTRY_18}"
		echo "${MSG_COUNTRY_19}"
		echo "${MSG_COUNTRY_20}"
		echo "${MSG_COUNTRY_21}"
		echo "${MSG_COUNTRY_22}"
		echo "${MSG_COUNTRY_23}"
		echo "${MSG_COUNTRY_24}"
		echo "${MSG_COUNTRY_25}"
		echo "${MSG_COUNTRY_26}"
		echo "${MSG_COUNTRY_27}"
		echo "${MSG_COUNTRY_28}"
		echo "${MSG_COUNTRY_29}"
		echo "${MSG_COUNTRY_30}"
		;;
	    getlicenseagreement)
		REGION=`interactive_read_data`
		FILENAME=`get_clickwrap_license_file "$REGION"`
		if [ -n "$FILENAME" ] ; then
		    cat "$FILENAME" | wc -l | sed -e "s/\ //g"
		    cat "$FILENAME"

                    if [ "`dirname \"${LICFILE}\" 2> /dev/null`" != "$MEDIA_ROOT/licenses" ]; then
                        rm -f "${LICFILE}"
                    fi
		else
		    echo "INVALID REGION"
		    signal_handler
		fi
		;;
	    getauxiliarylicenseagreement)
		LICENSE=`get_license_agreement`
		echo "$LICENSE" | wc -l | sed -e "s/\ //g"
		echo "$LICENSE"
		;;
	    gettoplevelpackages)
		interactive_multi_line "get_visible_children TOP_LEVEL_COMPONENTS"
		;;
	    getsubpackages)
		PKGNAME=`interactive_read_data`
		interactive_multi_line "get_visible_children $PKGNAME"
		;;
	    getpackagename)
		PKG=`interactive_read_data`
		eval echo "\$MSG_$PKG"
		;;
	    getpackagestatus)
		PKGNAME=`interactive_read_data`
		if has_visible_children "$PKGNAME" ; then
		    set_category_state "$PKGNAME"
		fi
                if is_installed_option "$PKGNAME" ; then
                    echo "INSTALLED"
                elif not is_exposed_option "$PKGNAME" ; then
                    echo "UNAVAILABLE"
                elif is_selected_option "$PKGNAME" ; then
                    lcl_sel=0
                    lcl_tot=0
                    get_category_selected_count "$PKGNAME" lcl_sel lcl_tot
                    
                    if [ "$lcl_sel" = "$lcl_tot" ]; then
		        interactive_echo_boolean true
                    else
                        echo "PARTIAL"
                    fi
                else
                    interactive_echo_boolean false
                fi
		;;
	    setpackagestatus)
		PKGNAME=`interactive_read_data`
		STATUS=`interactive_read_data`
		
		if [ "$STATUS" = "ON" ] ; then
		    select_all "$PKGNAME"
		else
		    select_none "$PKGNAME"
		fi
		echo "1"
		;;
	    getpackagedescription)
		PKGNAME=`interactive_read_data`
		echo `get_package_description $PKGNAME`
		;;
	    getnonupdatedpackages)
		get_unavailable_packages | wc -l | sed -e "s/\ //g"
		get_unavailable_packages
		;;
	    getinstalltype)
		get_install_type
		;;
	    getinstallmode)
                if is_ebf; then
                    echo "EBF"
                else
		    get_install_mode
                fi
		;;
	    setinstallmode)
		set_install_mode `interactive_read_data`
		;;
	    setserverlicenseinfo)
		NAME=`interactive_read_data`
		COMPANY=`interactive_read_data`
		COUNT=`interactive_read_data`
		TYPE=`interactive_read_data`
		set_license_info NAME "$NAME"
		set_license_info COMPANY "$COMPANY"
		set_license_info TYPE "$TYPE"
		set_license_info COUNT "$COUNT"
		;;
	    getserverlicenseinfo)
		get_license_info NAME
		get_license_info COMPANY
		get_license_info COUNT
		if [ `get_license_info TYPE` = "processor" ] ; then
		    echo "CPU"
		elif [ `get_license_info TYPE` = "cpu" ] ; then
		    echo "core"
		else
		    echo "seat"
		fi
		;;

	    licenseallcomponents)
		components=`license_all_components`
                if [ -z "$components" ] ; then
                    echo "0"
                else
                    echo "$components" | wc -l | sed -e "s/\ //g"
                    echo "$components"
                fi
		;;

	    get_installicons)
                interactive_echo_boolean "get_install_icons";
		;;

	    set_installicons)
		value=`interactive_read_data`
		set_install_icons ${value}
		;;

	    get_create_sybase_central_icon)
                if has_feature SYBASE_CENTRAL ; then
                    interactive_echo_boolean "get_install_sc_icon";
                else
                    echo "UNAVAILABLE";
                fi
		;;

	    set_create_sybase_central_icon)
		value=`interactive_read_data`
		set_install_sc_icon ${value}
		;;
            
	    get_enable_feature_tracking)
                interactive_echo_boolean "! get_enable_feature_tracking_specified || get_enable_feature_tracking";
		;;

	    set_enable_feature_tracking)
		value=`interactive_read_data`
		set_enable_feature_tracking ${value}
		;;

	    get_run_sybase_central_sample)
                if has_feature SYBASE_CENTRAL &&
                    has_feature SA_SERVER &&
                    has_feature SAMPLES ; then
                    echo "NO";
                else
                    echo "UNAVAILABLE";
                fi
		;;

	    set_run_sybase_central_sample)
		value=`interactive_read_data`
                if [ "${value}" = "TRUE" ]; then
		    run_sybase_central_sample
                fi
		;;

	    wait_check_for_updates)
		wait_check_for_updates 
		;;

	    start_check_for_updates)
		start_check_for_updates IN_BACKGROUND
		;;

	    get_updates_response)
		TMPFILE="`get_updates_tmpfile`"
                cat "$TMPFILE" | wc -l | sed -e "s/\ //g"
                cat "$TMPFILE"
		;;

	    stop_check_for_updates)
		stop_check_for_updates
		;;

	    getinstallsummary)
		generate_install_summary COUNT
                echo ${COUNT:-0}
		cat "$TMPFILE" | wc -l | sed -e "s/\ //g"
		cat "$TMPFILE"
                rm -f "$TMPFILE"
		;;
	    
	    getdeploymentfilelist)
                build_filelist
		TMPFILE="`get_filelist`"
		cat "$TMPFILE" | wc -l | sed -e "s/\ //g"
		cat "$TMPFILE"
		;;
	    
	    savedeploymentfilelist)
		FILE=`interactive_read_data`
		save_deploy_file_list_to_file "$FILE"
		;;

	    getsourceinstructions)
                generate_sourced_file_message_in_tmpfile
                cat "$TMPFILE" | wc -l | sed -e "s/\ //g"
                cat "$TMPFILE"
                rm -f "$TMPFILE"
		;;
	    
	    getreadme)
		INTERACTIVE="true"
		export INTERACTIVE
		"$MEDIA_ROOT/readme" | wc -l | sed -e "s/\ //g"
		"$MEDIA_ROOT/readme"
		unset INTERACTIVE
		;;
	    
	    isreadmeavailable)
		interactive_echo_boolean "not is_deploy"
		;;

	    getnextpanel)
		CURRENT=`interactive_read_data`
		NEXT=`next_panel $CURRENT`
		if [ -z "${NEXT:-}" ] ; then
		    NEXT="LAST"
		fi
		echo $NEXT
		;;
	    getpreviouspanel)
		CURRENT=`interactive_read_data`
		PREV=`previous_panel $CURRENT`
		if [ -z "${PREV:-}" ] ; then
		    PREV="FIRST"
		fi
		echo $PREV
		;;

	    getwelcome)
		msg_welcome "`get_package_name`" | wc -l | sed -e "s/\ //g"
		msg_welcome "`get_package_name`"
		;;

	    getdeploywelcome)
		msg_deployment_wizard_welcome | wc -l | sed -e "s/\ //g"
		msg_deployment_wizard_welcome
		;;

	    getinstalltitle)
		msg_install_title "`get_package_name`"
		;;

	    createsamonsvc)
		interactive_echo_boolean "install_samonitor_service"
		;;

	    samonmigrateresources)
		samon_set_migrate_resources 1
		;;
	    
	    getdeploywizardmode)
		deploy_wizard_mode
		;;

	    setdeploywizardmode)
		MODE=`interactive_read_data`
		set_deploy_wizard_mode "$MODE"
		;;

	    start)
		do_install
		echo "UI_FINI"
		;;
	    exit | x | quit | q )
                signal_handler
		;;
	    *)
		echo "ERROR $cmd" 1>&2
		signal_handler
	esac
    done
}
##########################################################################
#			    INTERACTIVE MODE				 #
##########################################################################

# Interactive strings / status messages... every interactive status message
# has the following form...
#
# ui_*
# message line 1
# ...
# message line n
# ui_done

ui_echo( )
##########
{
    echo "$1"
}

ui_install_progress( )
######################
{
    ui_echo "UI_PROG"
}

ui_install_status( )
####################
{
    ui_echo "UI_STAT"
}

ui_error( )
###########
{
    ui_echo "UI_ERRR"
}

ui_ask( )
#########
{
    ui_echo "UI_QUES"
}

ui_complete( )
##############
{
    ui_echo "UI_FINI"
}

ui_done( )
##########
{
    ui_echo "UI_DONE"
}

