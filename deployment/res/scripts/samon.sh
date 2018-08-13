# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
samon_set_migrate_resources()
########################
{
    __SAMON_MIGRATE_RESOURCES=$1
}

samon_migrate_resources()
####################
{
    [ "${__SAMON_MIGRATE_RESOURCES:-}" = "1" ]
}

samon_run_migrator()
####################
# $1: 1 if we should treat a migration failure as fatal, default 1
{
    FATAL_ERRORS="${1:-1}"
    SADIR=`get_install_dir SA`
    BINDIR=`get_install_dir BIN`

    # Run migrator
    if [ "`get_ui_type`" = "interactive" ]; then
	SWITCHES=-i
    else
	SWITCHES=-n
    fi
    . "$BINDIR/sa_config.sh" >/dev/null 2>&1
    selinux_setup
    installer_status "$MSG_SAMON_MIGRATION"
    installer_starting_install

    if [ "${FATAL_ERRORS:-1}" -ne "1" ] ; then
        create_new_tmpfile
        SAMONTMP=${TMPFILE:-}
        if [ -n "${SAMONTMP:-}" ] && [ -f "$SADIR/samonitor.db" ]; then
            rm -f "${SAMONTMP-}"
            cp -f "$SADIR/samonitor.db" "${SAMONTMP-}"
        fi
    fi

    java -ea -Dsun.java2d.noddraw=true -Dsun.java2d.d3d=false -classpath "$SADIR/java/jodbc4.jar:$SADIR/java/sajdbc4.jar:$SADIR/java/jsyblib1600.jar:$MEDIA_ROOT/res/migrator.jar" com.ianywhere.serverMonitor.migrator.MonitorMigrator $SWITCHES "`samon_backup_dir`/samonitor.db" "$SADIR/samonitor.db"

    samon_set_migration_return_code $?

    if samon_migration_failed; then
        if [ "${FATAL_ERRORS:-1}" -eq "1" ] ; then
            #installer_error `msg_samonitor_failed`
            signal_handler
        elif [ -n "${SAMONTMP:-}" ] && [ -f "${SAMONTMP:-}" ]; then
            msg_samonitor_failed "`samon_backup_dir`"
            samon_set_keep_backup 1
            rm -f "$SADIR/samonitor.db"
            mv -f "${SAMONTMP-}" "$SADIR/samonitor.db"
        fi
    fi

    installer_done_install
}

samon_set_keep_backup()
#######################
{
    __SAMON_BACKUP_KEEP="${1:-1}"
}

samon_keep_backup()
###################
{
    [ "${__SAMON_BACKUP_KEEP:-1}" -eq "1" ]
}

samon_set_backup_dir()
######################
{
    __SAMON_BACKUP_DIR=$1
}

samon_backup_dir()
##################
{
    echo "${__SAMON_BACKUP_DIR:-}"
}

samon_set_migration_return_code()
#################################
{
    __SAMON_MIGRATION_RETCODE=$1
}

samon_migration_failed()
########################
{
    [ "${__SAMON_MIGRATION_RETCODE:-0}" -ne "0" ]
}

samon_set_stop_return_code()
############################
{
    samon_stop_failed && return
    __SAMON_STOP_RETCODE=$1
}

samon_stop_failed()
###################
{
    [ "${__SAMON_STOP_RETCODE:-0}" -ne "0" ]
}

samon_set_skip_restart()
########################
{
    [ "${__SAMON_SKIP_RESTART:-1}" -ne "0" ] && __SAMON_SKIP_RESTART=$1
}

samon_do_restart()
##################
{
    [ "${__SAMON_SKIP_RESTART:-1}" -eq "0" ]
}

samon_backup_db()
#################
# assumes all instances of the monitor have been stopped
# i.e. samon_stop_running_instances has already been called
{
    SADIR=`get_install_dir SA`
    if [ ! -r "$SADIR/samonitor.db" ]; then
	return
    fi

    if is_selected_option OPT_SAMON_DEPLOY ; then
	BINDIR=`get_install_dir BIN`
    else
	BINDIR=`get_install_dir BIN32`
    fi

    OLDDB="samonitor_old"
    CNT=1
    while [ -r "$SADIR/$OLDDB" ]; do
	CNT=`expr $CNT + 1`
	OLDDB="samonitor_old$CNT"
    done
    mkdir "$SADIR/$OLDDB"
    samon_set_backup_dir "$SADIR/$OLDDB"

    push_rollback_callback samon_rollback
    push_cleanup_callback samon_cleanup

    mv "$SADIR/samonitor.db" "$SADIR/$OLDDB"
    touch "$SADIR/samonitor.db"
    [ -f "$SADIR/samonitor.log" ] && mv "$SADIR/samonitor.log" "$SADIR/$OLDDB"
}

samon_stop_db()
###############
{
    push_cleanup_callback samon_restart_db
    samon_stop_running_instances 
}

samon_restart_db()
##################
{
    if samon_do_restart; then
        samon_start_db
    fi
}

samon_start_db()
################
{
    if is_selected_option OPT_SAMON_DEPLOY ; then
	BINDIR=`get_install_dir BIN`
    else
	BINDIR=`get_install_dir BIN32`
    fi
    [ -x "$BINDIR/samonitor.sh" ] && "$BINDIR/samonitor.sh" start >/dev/null 2>&1
}

samon_pre_extract()
###################
# $1: 1 if we should treat a migration failure as fatal, default 1
{
    if not has_feature SAMON ; then
	return
    fi

    FATAL_ERRORS="${1:-1}"

    samon_stop_db
    if samon_stop_failed; then
	# Found an SAMonitor process but failed to shut it down
	# This is considered a fatal error for the Standalone install
	# For a Developer Edition install, starting/stopping is manual, so we don't care
        if [ "${FATAL_ERRORS:-1}" -eq "1" ] ; then
	    installer_error `msg_samonitor_stop_failed_fatal`
        fi
    fi

    if has_feature SAMON && is_upgrade ; then
        samon_backup_db
    fi
}

samon_post_extract()
###################
# $1: 1 if we should treat a migration failure as fatal, default 1
{
    if has_feature SAMON && is_upgrade && samon_migrate_resources; then
        samon_run_migrator "${1:-1}"
    fi
}

samon_rollback()
################
{
    SADIR=`get_install_dir SA`
    BACKUP_DIR=`samon_backup_dir`
    if [ -n "${BACKUP_DIR:-}" ] && [ -f "${BACKUP_DIR:-}/samonitor.db" ]; then
        rm -f ${SADIR:-}/samonitor.db
        mv "${BACKUP_DIR:-}/samonitor.db" ${SADIR:-}
    fi

    if [ -n "${BACKUP_DIR:-}" ] && [ -f "${BACKUP_DIR:-}/samonitor.log" ]; then
        rm -f ${SADIR:-}/samonitor.log
        mv "${BACKUP_DIR:-}/samonitor.log" ${SADIR:-}
    fi
}

samon_cleanup()
###############
{
    BACKUP_DIR=`samon_backup_dir`
    if ! samon_keep_backup && \
        [ -n "${BACKUP_DIR:-}" ] && [ -d "${BACKUP_DIR:-}" ]; then
        rm -rf "${BACKUP_DIR:-}"
    fi
}

# Old SAMonitor processes may be running, and we may not have 
# installed the samonitor.sh script to help us stop them,
# if we are installing a new major version.
#
# Need to look through the running processes and check the command line
# for instances of SAMonitor running.
# 
# The following finds the pid of the process with the command line that 
# matches the one we are looking for, and stops them.
#
samon_stop_running_instances()
##############################
{
    # get command line of each process from /proc/<pid>/cmdline,
    # and look for our sentinel string(s) in it
    local pcmdline
    local findmask="SAMonitor\|smstart.dat"
    local pid=$PROCID
    local found=0
    local skip_restart=1

      # need to check all of the /proc/.../ directories
      for i in `/bin/ls -1p /proc`; do
	PRFILE="/proc/"$i"cmdline"
	if [ -r $PRFILE ]; then 
	    pcmdline=`cat $PRFILE | sed 's/-//g' | sed 's/ //g' `
	    RET=`echo $pcmdline | grep $findmask | grep -v java 2>/dev/null`
	    if [ "$RET" != "" ]; then
		PROCID=`echo $i | awk -F "/" '{print $1}'`
		kill -HUP $PROCID >/dev/null 2>/dev/null
		samon_set_stop_return_code $?
		found=1
		skip_restart=0
	    fi
	fi
      done

    samon_set_skip_restart ${skip_restart}
} 
