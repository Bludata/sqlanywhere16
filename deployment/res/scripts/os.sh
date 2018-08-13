# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
check_os_version()
##################
{
    case `plat_os` in
	aix)	
            OS_REL=`oslevel`
            OS_REL_COMP=`oslevel | sed 's?\.??' | sed 's?\.??' | sed 's?\.??'`
	    
            OS_MIN_REL="5.3.0.0"
            OS_MIN_COMP="5300"
            ;;

	macos) 
	    OS_REL=`uname -r`
	    OS_REL_1=`echo $OS_REL | cut -d. -f 1`
	    OS_REL_2=`echo $OS_REL | cut -d. -f 2`
	    OS_REL_COMP=`expr $OS_REL_1 \* 100 + $OS_REL_2`

	    OS_MIN_REL="8.0"
	    OS_MIN_COMP="800"
	    ;;

	hpux)	
            OS_REL=`uname -r`
	    OS_REL_1=`echo $OS_REL | cut -d. -f2`
	    OS_REL_2=`echo $OS_REL | cut -d. -f3`
            OS_REL_COMP=`expr $OS_REL_1 \* 100 + $OS_REL_2`

            OS_MIN_REL="1123"
            OS_MIN_COMP="1123"
            ;;

	solaris)	
            OS_REL=`uname -r`
            OS_REL_COMP=`echo $OS_REL |sed 's?\.??'`
	    
	    if [ `plat_hw` = "sparc" ]; then
		OS_MIN_REL="5.8"
		OS_MIN_COMP="58"
	    else
		OS_MIN_REL="5.10"
		OS_MIN_COMP="510"
	    fi
            ;;

       linux)  
            OS_REL=`uname -r`
            OS_REL_1=`echo $OS_REL | cut -d. -f1`
            OS_REL_2=`echo $OS_REL | cut -d. -f2`
            OS_REL_3=`echo $OS_REL | sed 's?\-.*??' | cut -d. -f3`
	
	    # remove text as in "17pre18"
	    OS_REL_3=`echo $OS_REL_3 | sed "s/[a-zA-Z].*$//g"`
            OS_REL_COMP=`expr $OS_REL_1 \* 1000 + $OS_REL_2 \* 100 + $OS_REL_3`

            OS_MIN_REL="2.6.0"
            OS_MIN_COMP="2600"
            ;;

       *)   echo "${ERR_OS_UNSUPPORTED}"
            exit 1
            ;;
    esac			

    if [ "$OS_REL_COMP" -lt "$OS_MIN_COMP" ] ; then
        msg_error_os_version_too_low "`get_package_name`" "${OS_REL}" "${OS_MIN_REL}"
	exit 1
    fi

    OS="`get_intended_os`"
    HW="`get_intended_hw`"
    if [ "`plat_os_hw`" != "`plat_os_hw \"${OS:-}\" \"${HW:-}\"`" ]; then
	msg_error_os_mismatch "`plat_os_display \"${OS:-}\" \"${HW:-}\"`" "`plat_os_display`"
	exit 1
    fi
}

check_hp_system_requirements()
##############################
{
    result=0

    os_version_major=`uname -r | sed -e 's/B\.\(..\)\..*/\1/'`
    os_version_minor=`uname -r | sed -e 's/B\..*\.//'`
    
    if [ "$os_version_major" -gt 11 ] ; then
	result=1
    fi

    if [ "$result" = 0 ] && [ "$os_version_major" -eq 11 ] ; then

	if [ "$os_version_minor" -ge 11 ] && [ "$os_version_minor" -lt 23 ] ; then

	    # OS version between 11.11 and 11.22, need TOUR

	    tour_result=`swlist -l product -a revision TOUR_PRODUCT 2>&1`
	    tour_installed_cmd=`echo $tour_result | grep "ERROR:"`
	    tour_installed=$?

	    if [ "$tour_installed" -eq 1 ] ; then
		result=1
	    fi
	fi

	if [ "$os_version_minor" -ge 23 ] ; then
	    # 11.23 or greater don't need TOUR
	    result=1
	fi
    fi

    echo $result
}

check_system_requirements( )
############################
{
    check_os_version

    case "`plat_os`" in
	hpux)
	    ok=`check_hp_system_requirements`
	;;
	*)
	    ok=1
	;;
    esac

    if [ $ok -eq 0 ] ; then 
	msg_system_requirements_too_low
	exit 0
    fi
}
