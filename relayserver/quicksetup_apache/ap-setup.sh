#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

#*******************************************************************
# You may use, reproduce, modify and distribute this sample code without
# limitation, on the condition that you retain the foregoing copyright
# notice and disclaimer as to the original iAnywhere code.
#*******************************************************************

source ./__funcs__.sh

green()
{
    echo -en "\033[0;32m"
}

red()
{
    echo -en "\033[0;31m"
}

reset_colour()
{
    echo -en "\033[0m"
}

clear
echo
echo You are about to execute the Relay Server quick setup script for
echo Apache. Output of this setup script will be captured in ap-setup.log.
echo The existing ap-setup.log will automatically be backed up before
echo proceeding \(if applicable\).
echo
red
echo "Make sure that the Apache worker (see User/Group lines in httpd.conf)"
echo "has read permissions for files created by the current user, `whoami`."
echo
reset_colour
echo This setup script will also generate an uninstall script should you choose
echo to undo the setup. The uninstall script will be located at:
echo
echo "${PWD}/ap-uninstall.sh"
echo
echo "Ready to run ap-setup.bat? (Y/n)"
yn_read
wish_2_continue=${__yn_ap__}
if [ "${wish_2_continue}" != "y" ]; then
    red
    echo Abort running ap-setup.sh
    reset_colour
    __funcs_unset
    exit
fi
CURR_DATETIME=`date +"%F.%H-%M-%S"`
SETUP_LOG=${PWD}/ap-setup.log
SETUP_LOG_BACKUP=${PWD}/ap-setup.log.${CURR_DATETIME}
if [ -f "${SETUP_LOG}" ]; then
    mv ${SETUP_LOG} ${SETUP_LOG_BACKUP}
    green
    echo "Existing ap-setup.log has been backed up to:"
    echo "    ${SETUP_LOG_BACKUP}"
    reset_colour
    echo
    echo Press ENTER to continue.
    read
fi
__ap-setup__.sh 2>&1 | perl tee.pl ap-setup.log
echo
green
echo "Output has been captured in ${PWD}/ap-setup.log"
reset_colour
BASE_URL=`hostname`
grep "APACHE_ROOT_DIRECTORY=[/\.0-9a-zA-Z]" ${PWD}/ap-setup.env > /dev/null 2>&1
if [ ${?} -eq 0 ]; then
    APROOTDIR=`grep -n ^APACHE_ROOT_DIRECTORY ${PWD}/ap-setup.env | cut -d= -f2`
    AP_PORT=`grep "^\s*Listen " ${APROOTDIR}/conf/httpd.conf | cut -c8-100`
    BASE_URL=${BASE_URL}:${AP_PORT}
fi
echo "If you have any issues, please see"
echo "    http://${BASE_URL}/rs-quick-ref.htm"
echo "or post your issue to the SQL Anywhere help forum at"
echo "    http://sqlanywhere-forum.sybase.com"
echo
