# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set_enable_feature_tracking()
#############################
{
    ENABLE_FEATURE_TRACKING=$1
}

get_enable_feature_tracking()
#############################
{
    [ "${ENABLE_FEATURE_TRACKING:-FALSE}" = "TRUE" ]
}

get_enable_feature_tracking_specified()
#######################################
{
    [ -n "${ENABLE_FEATURE_TRACKING:-}" ]
}

apply_feature_tracking()
########################
{
    if not get_enable_feature_tracking_specified ; then
        return
    fi

    ccoption=promptDefN
    if get_enable_feature_tracking ; then
        ccoption=autosubmit
    fi

    if [ -x "`get_install_dir BIN64S`/dbsupport" ] ; then
	"`get_install_dir BIN64S`/dbsupport" -cp autodetect -cc ${ccoption} >/dev/null 2>&1 &
    elif [ -x "`get_install_dir BIN32S`/dbsupport" ] ; then
	"`get_install_dir BIN32S`/dbsupport" -cp autodetect -cc ${ccoption} >/dev/null 2>&1 &
    fi
}
