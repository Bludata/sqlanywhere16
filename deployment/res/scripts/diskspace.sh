# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
get_mount()
###########
# $1 directory
{
   PARENT=`get_parent "$1"`

   case `plat_os` in 
    	solaris )
	    $DF -bk "$PARENT" | sed 1d | tr -s ' ' | cut -d" " -f6
	    ;;
	macos )
            $DF -k "$PARENT" | sed '$!d' | tr -s ' ' | cut -d" " -f 6
            ;;
	linux )
	    $DF -kP "$PARENT" | sed 1d | tr -s ' ' | cut -d" " -f6
	    ;;
	hpux )
	    $DF -b "$PARENT" | tr -s ' ' | cut -d" " -f1
	    ;;
    	aix )
	    $DF -k "$PARENT" | sed 1d | tr -s ' ' | cut -d" " -f7
	    ;;
    esac
}

get_freespace()
###############
# $1 directory
{
    if [ -z "${1:-}" ] ; then
    	echo "0"
    fi

    PARENT=`get_parent "$1"`

    case `plat_os` in 
    	solaris )
	    $DF -bk "$PARENT" | sed 1d |tr -s ' ' | cut -d" " -f4
	    ;;

	macos )
            $DF -k "$PARENT" | sed '$!d' | tr -s ' ' | cut -d" " -f 4
	    ;;

	linux )
	    $DF -kP "$PARENT" | sed 1d | tr -s ' ' | cut -d" " -f4
	    ;;

	hpux )
	    $DF -b "$PARENT" | tr -s ' ' | cut -d" " -f5
	    ;;

    	aix )
            $DF -k "$PARENT" | sed 1d | tr -s ' ' | cut -d" " -f3
	    ;;
    esac
}

check_disk_space()
##################
{
    OPTIONS=`generate_package_mask`
    
    TOTAL=0
    for pfx in SA ; do
	KEY=`get_registration_key`
	TIC_SIZE=`eval dbinstall space -k "$KEY" -o \""$OPTIONS"\" "$TICFILE"`
	
	# convert from bytes to kilobytes
	TIC_SIZE=`expr \( ${TIC_SIZE:-0} + 1023 \) / 1024`

	TOTAL=`expr ${TOTAL:-0} + ${TIC_SIZE:-0}`
	TOTAL=`expr ${TOTAL:-0} + ${HELP_SIZE:-0}`
    done

    DIR=`get_install_dir SA`
    MNT=`get_mount "$DIR"`
    FREE=`get_freespace "$MNT"`
    
    [ -n "${1:-}" ] && eval $1="${MNT}"
    [ -n "${2:-}" ] && eval $2="${TOTAL}"
    [ -n "${3:-}" ] && eval $3="${FREE}"
    
    [ $TOTAL -le $FREE ]
}
