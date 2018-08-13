# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
reverse_list()
##############
{
    unset RLIST
    for i in $1 ; do
	if [ -n "${RLIST:-}" ] ; then
	    RLIST="$i $RLIST"
	else
	    RLIST="$i"
	fi
    done
    echo "$RLIST"
}

next_panel()
############
{
    found_panel=0
    if [ -z "${1:-}" ] || [ "$1" = "FIRST" ] ; then
	found_panel=1
    fi

    for p in `panel_list` ; do
	if [ $found_panel -eq 0 ] ; then
	    if [ "$p" = "$1" ] ; then
		found_panel=1
	    fi
	elif need_panel $p ; then
	    echo $p
	    return
	fi
    done
}

previous_panel()
################
{
    found_panel=0
    LIST=`panel_list`
    for p in `reverse_list "$LIST"` ; do
	if [ $found_panel -eq 0 ] ; then
	    if [ "$p" = "$1" ] ; then
		found_panel=1
	    fi
	elif need_panel $p ; then
	    echo $p
	    return
	fi
    done
}

