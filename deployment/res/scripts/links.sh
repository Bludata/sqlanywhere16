# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# 
# Procedures that deal with creating links can go here.
#

make_link( )
############
# $1 - the object to link to
# $2 - the name of the link to create
{
    if [ $# -lt 1 ]; then
	echo "Setup Internal error : not enough arguments passed to make_link"
    fi
    if [ -r "$1" ]; then
        rm -f "$2"
	ln -s "$1" "$2"
    fi
}

is_symbolic_link()
###################
# $1: filename
{
    case `plat_os` in
        solaris )
                [ -h "$1" ]
                ;;
        * )
                [ -L "$1" ]
                ;;
    esac
}

create_jre_fonts_fallback_link()
################################
{
    for bits in 32 64 ; do
	if [ -r "`get_jre_dir DIR $bits`" ]; then
	    # No special steps needed for Red Hat < 6
	    if is_redhat; then
		if [ -r /usr/share/fonts/cjkuni-ukai/ukai.ttc ]; then
		    mkdir -p  "`get_jre_dir DIR $bits`/lib/fonts/fallback" >/dev/null
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts/fallback"
		    make_link /usr/share/fonts/cjkuni-ukai/ukai.ttc ukai.ttc 
		fi
	    fi
	    if is_redflag; then
		if [ -r /usr/share/fonts/zh_CN/TrueType ]; then
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts"
		    make_link /usr/share/fonts/zh_CN/TrueType fallback
		    popd_quiet
		elif [ -r /usr/X11R6/lib/X11/fonts/TrueType ]; then
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts"
		    make_link /usr/X11R6/lib/X11/fonts/TrueType fallback
		    popd_quiet
		fi
	    fi
	    if is_suse; then
		# SuSE 10 location
		if [ -r /usr/X11R6/lib/X11/fonts/truetype ]; then
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts"
		    make_link /usr/X11R6/lib/X11/fonts/truetype fallback
		    popd_quiet
		# SuSE 11 location
		elif [ -r /usr/share/fonts/truetype ]; then
		    mkdir -p  "`get_jre_dir DIR $bits`/lib/fonts/fallback" >/dev/null
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts/fallback"
		    # Need to limit the number of links here because too many can cause Java a problem on some systems
		    LIST=`find /usr/share/fonts/truetype -name "*.ttf" | grep "FZ\|Un\|mincho\|sazanami\|ukai\|uming" | sed 127q` 
		    for item in $LIST; do
			make_link "$item" `basename $item`
		    done
		    popd_quiet
		fi
	    fi
	    if is_ubuntu; then
		if [ -r /usr/share/fonts ]; then
		    mkdir -p  "`get_jre_dir DIR $bits`/lib/fonts/fallback" >/dev/null
		    pushd_quiet "`get_jre_dir DIR $bits`/lib/fonts/fallback"
		    # Need to limit the number of links here because too many can cause Java a problem on some systems
		    LIST=`find /usr/share/fonts -name "*.tt?" | grep "kochi\|vlgothic\|takao\|arphic\|wqy\|unfonts" | sed 127q` 
		    for item in $LIST; do
			make_link "$item" `basename $item`
		    done
		    popd_quiet
		fi
	    fi
	fi
    done
}

