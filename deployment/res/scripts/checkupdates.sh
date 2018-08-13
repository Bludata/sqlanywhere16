# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
start_check_for_updates()
#########################
{
    if [ "$1" = "IN_BACKGROUND" ]; then
	START_IN_BACKGROUND=1
    else
	START_IN_BACKGROUND=
    fi
    CHECK_FOR_UPDATES_PID=

    create_new_tmpfile
    CHECK_FOR_UPDATES_RESPONSE_FILE=${TMPFILE}
    if [ -x "`get_install_dir BIN64S`/dbsupport" ] ; then
	[ -z "$START_IN_BACKGROUND" ] && "`get_install_dir BIN64S`/dbsupport" -cp autodetect -qh -iu -r1 > "$CHECK_FOR_UPDATES_RESPONSE_FILE" 2>&1
	[ -n "$START_IN_BACKGROUND" ] && "`get_install_dir BIN64S`/dbsupport" -cp autodetect -qh -iu -r1 > "$CHECK_FOR_UPDATES_RESPONSE_FILE" 2>&1 &
    elif [ -x "`get_install_dir BIN32S`/dbsupport" ] ; then
	[ -z "$START_IN_BACKGROUND" ] && "`get_install_dir BIN32S`/dbsupport" -cp autodetect -qh -iu -r1 > "$CHECK_FOR_UPDATES_RESPONSE_FILE" 2>&1
	[ -n "$START_IN_BACKGROUND" ] && "`get_install_dir BIN32S`/dbsupport" -cp autodetect -qh -iu -r1 > "$CHECK_FOR_UPDATES_RESPONSE_FILE" 2>&1 &
    else 
	echo $MSG_ERROR_CHECKING_FOR_UPDATES > "$CHECK_FOR_UPDATES_RESPONSE_FILE" &
    fi

    CHECK_FOR_UPDATES_PID=$!
}

get_updates_tmpfile()
#####################
{
    # Check if process still running
    kill -0 $CHECK_FOR_UPDATES_PID 2>/dev/null
    if [ "$?" != "0" ]; then
	# Process completed already
	CHECK_FOR_UPDATES_PID=
    else
	stop_check_for_updates
	echo $MSG_ERROR_CHECKING_FOR_UPDATES > "$CHECK_FOR_UPDATES_RESPONSE_FILE "
    fi
    echo "$CHECK_FOR_UPDATES_RESPONSE_FILE"
}

wait_check_for_updates()
########################
{
    if [ "$1" = "" ]; then
	DELAYTIME=4
    else
	DELAYTIME=$1
    fi

    until [ -z "$CHECK_FOR_UPDATES_PID" ] || [ $DELAYTIME -eq 0 ]; do
	kill -0 $CHECK_FOR_UPDATES_PID 2>/dev/null
	if [ "$?" != "0" ]; then
	    # Process completed already; break out
	    CHECK_FOR_UPDATES_PID=
	    break
	fi
	sleep 1
	DELAYTIME=`expr $DELAYTIME - 1`
    done
}

stop_check_for_updates()
########################
{
    kill -9 $CHECK_FOR_UPDATES_PID 2>/dev/null
    CHECK_FOR_UPDATES_PID=
    return $?
}
