# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
plat_os()
#########
{
    OS="${1:-}"

    if [ -z "${OS:-}" ]; then
        OS="`uname -s`"
    fi

    case "${OS}" in
	Linux)
	    echo "linux"
	    ;;
	AIX)
	    echo "aix"
	    ;;
	HP-UX)
	    echo "hpux"
	    ;;
	Darwin)
	    echo "macos"
	    ;;
	SunOS)
	    echo "solaris"
	    ;;
    esac
}

plat_hw()
#########
{
## will return one of ( "x86", "ia64", "parisc", "ppc", "sparc" )
    ARCH="${1:-}"
    if [ -z "${ARCH:-}" ]; then
        case `plat_os ${2:-}` in
	    linux )
	        ARCH=`uname -m`
	        ;;
	    hpux)
	        ARCH=`uname -m`
	        if [ "$ARCH" != "ia64" ] ; then
		    ARCH="parisc"
	        fi
	        ;;
	    *)
	        ARCH=`uname -p`
	        ;;
        esac
    fi
    
    if [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ] || [ "$ARCH" = "i586" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "X86_64" ] ; then
	ARCH="x86"
    elif [ "$ARCH" = "powerpc" ] ; then
        ARCH="ppc"
    fi

    echo "$ARCH"
}

plat_os_hw()
############
{
    echo "`plat_os ${1:-}`_`plat_hw ${2:-} ${1:-}`"
}

plat_os_display()
#################
{
    OS_DISPLAY="${1:-}"
    HW_DISPLAY="${2:-}"

    if [ -z "${OS_DISPLAY:-}" ]; then
        OS_DISPLAY=`uname -s`
    fi

    if [ -z "${HW_DISPLAY:-}" ]; then
        HW_DISPLAY=`uname -p`
    fi

    case "${OS_DISPLAY:-}" in
	SunOS)
	    OS_DISPLAY="Solaris"
	    ;;
	Darwin)
	    OS_DISPLAY="Mac OS X"
	    ;;
    esac

    echo ${OS_DISPLAY:-} ${HW_DISPLAY:-}
}

plat_ld_var_name()
##################
{
    case `plat_os` in
	aix)
	    echo "LIBPATH"
	    ;;
	macos)
	    echo "DYLD_LIBRARY_PATH"
	    ;;
	hpux)
	    if [ `plat_hw` = "ia64" ] ; then
		echo "LD_LIBRARY_PATH"
		else
		echo "SHLIB_PATH"
	    fi
	    ;;
	solaris | linux )
	    echo "LD_LIBRARY_PATH"
	    ;;
    esac
}

plat_bitness()
##############
{
    case `plat_os` in
	macos)
	    if [ "`sysctl -n hw.cpu64bit_capable 2>/dev/null`" = "1" ]; then
		echo "64"
	    else
		echo "32"
	    fi
	    ;;
	aix)
	    if [ -x "/usr/bin/getconf" ] ; then
		/usr/bin/getconf HARDWARE_BITMODE
	    else
		echo "32"
	    fi
	    ;;
	hpux)
	    if [ -x "/usr/bin/getconf" ] ; then
		/usr/bin/getconf KERNEL_BITS
	    else
		echo "32"
	    fi
	    ;;
	solaris)
	    if [ -x "/bin/isainfo" ] ; then
		/bin/isainfo -b
	    else
		echo "32"
	    fi
	    ;;
	linux)
	    if [ "`uname -m`" = "ia64" ] || [ "`uname -m`" = "x86_64" ] ; then
		echo "64"
	    else
		echo "32"
	    fi
    esac
}
