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

clear
echo
echo "You are about to execute the Relay Server setup testing script for"
echo "Apache. This script writes its output to rs-test-setup.log."
echo "Any existing rs-test-setup.logs will be backed up before proceeding."
echo
echo "Run rs-test-setup.sh? (Y/n)"
yn_read
wish_2_continue=${__yn_ap__}
if [ "${wish_2_continue}" != "y" ]; then
    echo "Abort running rs-test-setup.sh"
    __funcs_unset
    exit
fi
CURR_DATETIME=`date +"%F.%H-%M-%S"`
LOGHOME=.
SETUP_LOG=${LOGHOME}/rs-test-setup.log
SETUP_LOG_BACKUP=${LOGHOME}/rs-test-setup.log.${CURR_DATETIME}
if [ -f "${SETUP_LOG}" ]; then
    mv ${SETUP_LOG} ${SETUP_LOG_BACKUP}
    echo "The existing rs-test-setup.log has been backed up to:"
    echo "    ${SETUP_LOG_BACKUP}"
    echo
    echo "Press ENTER to continue."
    read
fi
touch rs-test-setup.log > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "WARNING!!! Directory"
    echo "    ${PWD}"
    echo "is not writable!!"
    echo "Setup testing log will be in `ls -d ~` instead."
    echo
    LOGHOME=~
    echo
    echo "Press ENTER to continue."
    read
fi
APROOTDIR=`grep ^APACHE_ROOT_DIRECTORY ${PWD}/ap-setup.env | cut -d= -f2`
AP_PORT=`grep "^\s*Listen " ${APROOTDIR}/conf/httpd.conf | cut -c8-100`
__rs-test-setup__.sh 2>&1 | perl tee.pl ${SETUP_LOG}
echo
echo "Output written to ${SETUP_LOG}"
echo "If you have any issues, please see"
echo "    http://`hostname`:${AP_PORT}/rs-quick-ref.htm"
echo "or post your issue to the SQL Anywhere help forum at"
echo "    http://sqlanywhere-forum.sybase.com"
echo
