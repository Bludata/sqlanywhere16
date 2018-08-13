# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set_ui_type()
#############
{
    UI_TYPE="${1:-}"
}

get_ui_type()
#############
{
    echo "${UI_TYPE:-auto}"
}

try_gui_then_console()
######################
{
    if [ -f "${MEDIA_ROOT}/bin32/gsetup" ] || [ -f "${MEDIA_ROOT}/bin64/gsetup" ] ; then
	setsid gsetup ./`basename "$0"` "$@" 2>/dev/null
	if [ $? -eq 0 ] || [ $? -eq 139 ] ; then # a 139 return code indicates a crash
	    exit
	fi
    fi
    run_console_mode
}

start_ui()
##########
{
    case `get_ui_type` in
	interactive)
	    run_interactive_mode
	    ;;
	console)
	    run_console_mode
	    ;;
	silent)
	    run_silent_mode
	    ;;
	auto)
	    try_gui_then_console "$@"
	    ;;
	*)
	    echo "Internal error!"
	    ;;
    esac
}
