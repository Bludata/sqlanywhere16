# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
generate_install_summary()
##########################
{
    show_status="${2:-selected}"
    create_new_tmpfile

    PKG_COUNT=0
    if is_modify ; then
        echo "$MSG_EXISTING_SETTINGS_AND_OPTIONS" >> "$TMPFILE" 
        echo  >> "$TMPFILE" 
    
        for pkg in `generate_package_list TOP_LEVEL_COMPONENTS installed` ; do
            if [ "${show_status}" = "installed" ] ; then
	        PKG_COUNT=`expr $PKG_COUNT + 1`
            fi
	    echo - `get_package_display_name "$pkg"` >> "$TMPFILE"
        done
        echo  >> "$TMPFILE" 
    fi

    if [ "${show_status}" != "installed" ] ; then
        echo "$MSG_CURRENT_SETTINGS_AND_OPTIONS" >> "$TMPFILE" 
        echo  >> "$TMPFILE" 
    
        for pkg in `generate_package_list TOP_LEVEL_COMPONENTS selected` ; do
	    PKG_COUNT=`expr $PKG_COUNT + 1`
	    echo - `get_package_display_name "$pkg"` >> "$TMPFILE"
        done
        echo  >> "$TMPFILE"
    fi
    
    if [ -n "${1:-}" ] ; then
	eval $1=$PKG_COUNT
    fi
    
    echo "${MSG_TARGET_DIR}" >> "$TMPFILE"
    echo  >> "$TMPFILE"
    
    for dir in `get_directory_list` ; do
	if need_directory $dir ; then
	    echo "-" `get_install_dir $dir` >> "$TMPFILE"
	fi
    done
    echo  >> "$TMPFILE"
}
