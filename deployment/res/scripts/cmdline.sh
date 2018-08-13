# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
parse_cmdline_options()
#######################
{
    while [ ! -z "$1" ]; do

	case $1 in
	# nogui
	    -nogui )
		set_ui_type console
		;;

        # interactive
            -interactive )
                set_ui_type interactive
                ;;

	# sqlany directory
	    -sqlany-dir | -d )
		shift
		set_install_dir SA "${1:-}"
		;;

        # registration key
	    -regkey | -k )
                shift
                set_registration_key "${1:-}"
                set_install_dir SA `get_install_dir ROOT`
		;;

	# seat model
	    -seat-model | -m )
		shift
		# set_license_info TYPE "${1:-}"
		;;

        # number of seats
	    -seats | -s )
		shift
		set_license_info COUNT "${1:-}"
		;;

        # company name
	    -company | -c )
		shift
		set_license_info COMPANY "$1"
		;;

        # user name
	    -name | -n )
		shift
		set_license_info NAME "$1"
		;;
	    
	# silent
	    -silent | -ss )
		set_ui_type silent
		;;

	# type
	    -type | -t )
                shift
		set_install_mode "${1:-}"
                set_install_dir SA `get_install_dir ROOT`
		;;

        # accepting license agreement
	    -I_accept_the_license_agreement )
		set_accepted_license_agreement
		;;
	# specifying packages to install
	    -install)
		shift
		CMDLINE_PKGS=`echo $1 | sed -e s/,/" "/g`
		;;
	# list available packages
	    -list_packages)
		LIST_PACKAGES=1
		;;
	# cloud options
	    -cloud-noconfig | -cnc \
	    | -cloud-swdir \
	    | -cloud-runas \
	    | -cloud-id \
	    | -cloud-data | -cd \
	    | -cloud-secondary | -cs \
	    | -cloud-additional | -ca \
	    | -cloud-name | -cloud-company | -cloud-username | -cloud-password | -cloud-encryptkey \
	    | -cn | -cc | -cu | -cp | -ce \
	    | -cloud-language | -cl \
	    | -cloud-securefeaturekey | -csf \
	    | -cloud-userfullname | -cuf \
	    | -cloud-useremail | -cue \
	    | -cloud-tcpport | -cloud-httpport | -cloud-httpsport \
            | -cloud-identityfile | -cloud-identitypwd \
	    | -cloud-swverfull )
		if [ `get_install_type` = "DBCLOUD" ]; then 
		    case $1 in
		    -cloud-swdir )
			# alias for -d above
			shift
			set_install_dir SA "${1:-}"
			;;
		    -cloud-data | -cd )
			shift
			CLOUD_DATA_DIR="${1:-}"
			;;
		    -cloud-secondary | -cs )
			set_dbcloud_install_type SECONDARY
			;;
		    -cloud-additional | -ca )
			set_dbcloud_install_type ADDITIONAL
			;;
		    -cloud-noconfig | -cnc )
			set_dbcloud_doconfig 0
			;;
		    -cloud-name | -cn )
			shift
			set_dbcloud_config_info CLOUDNAME "${1:-}"
			;;
		    -cloud-language | -cl )
			shift
			set_dbcloud_config_info CLOUDLANG "${1:-}"
			;;
		    -cloud-company | -cc )
			shift
			set_dbcloud_config_info COMPANY "${1:-}"
			;;
		    -cloud-username | -cu )
			shift
			set_dbcloud_config_info USER_NAME "${1:-}"
			;;
		    -cloud-password | -cp )
			shift
			set_dbcloud_config_info USER_PASSWORD "${1:-}"
			;;
		    -cloud-userfullname | -cuf )
			shift
			set_dbcloud_config_info FULLNAME "${1:-}"
			;;
		    -cloud-useremail | -cue )
			shift
			set_dbcloud_config_info EMAIL "${1:-}"
			;;
		    -cloud-encryptkey | -ce )
			shift
			set_dbcloud_config_info USER_KEY "${1:-}"
			;;
		    -cloud-securefeaturekey | -csf )
			shift
			set_dbcloud_config_info SECUREFEATURE_KEY "${1:-}"
			;;
		     -cloud-tcpport )
			shift
			set_dbcloud_config_info TCPIP_PORT "${1:-}"
			;;
		     -cloud-httpport )
			shift
			set_dbcloud_config_info HTTP_PORT "${1:-}"
			;;
		     -cloud-httpsport )
			shift
			set_dbcloud_config_info HTTPS_PORT "${1:-}"
			;;
		     -cloud-swverfull )
			shift
			set_dbcloud_config_info SWVERFULL "${1:-}"
			;;
		     -cloud-identityfile )
			shift
			set_dbcloud_config_info IDENTITYFILE "${1:-}"
			;;
		     -cloud-identitypwd )
			shift
			set_dbcloud_config_info IDENTITYPWD "${1:-}"
			;;
		     -cloud-runas )
			shift
			set_dbcloud_config_info RUNAS "${1:-}"
			;;
		     -cloud-id )
			shift
			set_dbcloud_config_info CLOUDID "${1:-}"
			;;
		    esac
		else
		    msg_cl_options_usage
		    exit
		fi

		;;
	# display help screen
	    -help | -h | * )
		if [ `get_install_type` = "DBCLOUD" ]; then 
		    msg_cloud_cl_options_usage
		else
		    msg_cl_options_usage
		fi
		exit
		;;
	esac
	shift
    done
    
    if [ -n "${CMDLINE_PKGS:-}" ] ; then
	if not has_provided_registration_key ; then
	    echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_TO_SELECT_1"
	    echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_TO_SELECT_2"
	    exit
	fi
	
	if [ "`get_key_status`" != "valid" ] ; then
	    echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_1"
	    echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_2"
	    exit
	fi

	OPTS=`map_names_to_option_list "$CMDLINE_PKGS"`

	if [ $? -eq 0 ] ; then
	    select_options_from_list "$OPTS"
	else
	    echo "$MSG_SILENT_INVALID_PACKAGE_NAMES_1"
	    echo "$MSG_SILENT_INVALID_PACKAGE_NAMES_2"
	    for p in $OPTS ; do
		echo $p
	    done
	    exit
	fi
    fi

    if [ -n "${LIST_PACKAGES:-}" ] ; then
	if not has_provided_registration_key ; then
	    echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_TO_LIST_1"
	    echo "$MSG_SILENT_MUST_PROVIDE_REGISTRATION_KEY_TO_LIST_2"
	    exit
	fi
	
	if [ "`get_key_status`" != "valid" ] ; then
	    echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_1"
	    echo "$MSG_SILENT_REGISTRATION_KEY_INVALID_2"
	    exit
	fi

	echo "$MSG_SILENT_AVAILABLE_PACKAGES"
	for p in `list_available_packages` ; do
	    DISPLAY_NAME=`eval echo \\$MSG_$p`
	    OPT_NAME=`tolower $p | sed -e 's/^opt_//'`
	    echo "$OPT_NAME - $DISPLAY_NAME"
	done
	exit
    fi
}
