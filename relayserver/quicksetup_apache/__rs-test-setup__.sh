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

real_user()
##########
{
    echo "`who am i | cut -f1 -d' '`"
}

get_bitness()
{
    if [ "`uname -m`" = "ia64" ] || [ "`uname -m`" = "x86_64" ] ; then
        echo "64"
    else
        echo "32"
    fi
}

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
echo --------------------- [[ 1. Introduction ]] --------------------------
echo
echo rs-test-setup.sh for Relay Server on Apache web server 
echo -------------------------------------------------------
echo This is an interactive script that takes no arguments. Any arguments 
echo provided on the command line are siliently ignored.
echo
echo The purpose of this script is to set up RelayServer and Outbound Enabler
echo test services and validate the success of your RelayServer Apache
echo deployment performed by ap-setup.sh script.
echo
echo This script consists of the following sections:
echo     [[ 1. Introduction ]]
echo     [[ 2. Create and deploy Relay Server and Outbound Enabler test services ]]
echo     [[ 3. Start the Apache web server and the test services ]]
echo     [[ 4. Launch the SimpleTestApp ]]
echo     [[ 5. Launch the Relay Server status page ]]
echo     [[ 6. Generate and launch the Quick Reference guide ]]
echo     [[ 7. Shutdown ]]
echo
if [ ! -w / ]; then
    red
    echo -e "You must be logged in as \033[4msuper user\033[0;31m before you can continue." 
    echo -e "Please login as \033[4msuper user\033[0;31m then start rs-test-setup.sh again."
    reset_colour
    echo
    exit
fi
echo
echo "Continue? (Y/n)"
yn_read
wish_2_continue=${__yn_ap__}
if [ "${wish_2_continue}" != "y" ]; then
    red
    echo RelayServer test setup aborted.
    reset_colour
    echo
    __funcs_unset
    exit
fi
REAL_USER=`real_user`
. ./ap-setup.env
PATH="${SA_DIR}/bin`get_bitness`:${PATH:-}"
export PATH
LD_LIBRARY_PATH="${SA_DIR}/lib`get_bitness`:${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH

clear
echo
echo ---------------- [[ 2. Create and deploy the test services ]] ---------------
echo
echo This section creates Relay Server State Manager and Outbound Enabler
echo test services and deploys them.
echo
echo "Create and deploy the test services? (Y/n)"
yn_read
create_services=${__yn_ap__}
if [ "${create_services}" != "y" ]; then
    red
    echo Skip creating test services.
    reset_colour
else
    echo [2a] Create and deploy the Relay Server State Manager test service 
    dbsvc -x SimpleTestApp_rst > /dev/null 
    dbsvc -y -a ${REAL_USER} -t rshost -w SimpleTestApp_rst -q -qc -f ${SA_AP_BIN}/rs.config -ot ${SA_AP_BIN}/rs.log -os 100K
    echo
    green
    echo Created the Relay Server State Manager test service as SimpleTestApp_rst
    reset_colour
    echo
    echo [2b] Create and deploy the Outbound Enabler test service
    dbsvc -x SimpleTestApp_oe > /dev/null 
    dbsvc -y -a ${REAL_USER} -t rsoe -w SimpleTestApp_oe @${AP_SETUP_DIR}/oe.config
    echo
    green
    echo Created the Outbound Enabler test service as SimpleTestApp_oe
    reset_colour
    echo
fi
echo
echo Press ENTER to continue
read

clear
echo
echo ---------- [[ 3. Start the Apache web server and test services ]] ---------
echo
echo This section starts the Apache web server and the test services created
echo in the previous step.
echo
echo "Start the web server and test services? (Y/n)"
yn_read
start_services=${__yn_ap__}
if [ "${start_services}" != "y" ]; then
    red
    echo Relay Server test setup aborted.
    reset_colour
    __funcs_unset
    exit
fi
echo
echo [3a] Start the Apache web server
echo
${APACHE_ROOT_DIRECTORY}/bin/apachectl start
#if [ $? != "0" ]; then
#    echo "Failed to start the Apache web server. Exiting."
#    exit
#else
#    echo "Apache web server started successfully"
#fi
echo
echo [3b] Start the Relay Server State Manager test service
echo
dbsvc -u SimpleTestApp_rst
echo
echo [3c] Start the Outbound Enabler test service
echo
dbsvc -u SimpleTestApp_oe
echo
echo Press ENTER to continue.
read

clear
echo
echo ----------- [[ 4. Launch the SimpleTestApp page ]] -----------
echo
echo The SimpleTestApp page helps you test your Relay Server deployment.
echo If you can view the SimpleTestApp page through the
echo Relay Server then your deployment is successful.
echo
echo You will need to launch your browser and browse to this page.
echo
echo You can browse the SimpleTestApp page at this URL:
echo 
green
echo ${APACHE_URL}/SimpleTestApp.htm
reset_colour
echo
echo OR you can browse the page via the Relay Server at this URL:
echo 
green
echo ${APACHE_URL}/cli/iarelayserver/SimpleTestApp-farm/SimpleTestApp.htm
reset_colour
echo 
echo "Upon completing the test, press ENTER to continue."
read 

clear
echo -------------- [[ 5. Launch the Relay Server status page ]] --------------
echo
echo The Relay Server status page provides basic status information
echo for the entire Relay Service.
echo
echo You will need to launch your browser and open this URL:
echo
green
echo "    ${APACHE_URL}/admin/iarelayserver?ias-rs-status-refresh-sec=10"
reset_colour
echo
echo "When you are finished, press ENTER to continue."
read 

clear
echo -------- [[ 6. Generate and launch the Quick Reference guide ]] -----------
echo
echo The Quick Reference guide includes:
echo "    - Introduction"
echo "    - Editing and Deploying the Relay Server configuration file"
echo "    - Starting and Stopping the Relay Server"
echo "    - Providing Backend Service"
echo "    - Client Accessing Backend Service via Relay Server"
echo "    - Monitoring the Relay Server"
echo "    - Troubleshooting Resources"
echo
echo To view the Quick Reference guide, launch your browser and open this URL:
echo
green
echo "    ${APACHE_URL}/rs-quick-ref.htm"
reset_colour
echo
echo "When you are finished, press ENTER to continue."
read 

clear
echo
echo Setup finished at `date +"%F.%H-%M-%S"`
echo
echo ------------------------- [[ 7. Shutdown ]] --------------------------
echo
echo This section stops these three services:
echo     - the Outbound Enabler test service for the SimpleTestApp
echo     - the Relay Server State Manager test service for the SimpleTestApp
echo     - the web server
echo
echo If any one of these services is stopped, both the SimpleTestApp page 
echo and the status page stop functioning. If you stop only the Outbound Enabler
echo Service, the status page will still function and be able to detect
echo status changes of the backend service.
echo
echo Press ENTER to continue.
read

echo Stop the Outbound Enabler test service for the SimpleTestApp
dbsvc -x SimpleTestApp_oe
green
echo "    Completed."
reset_colour
echo

echo Stop the Relay Server State Manager test service for the SimpleTestApp
dbsvc -x SimpleTestApp_rst
green
echo "    Completed."
reset_colour
echo 

echo Stop the web server
${APACHE_ROOT_DIRECTORY}/bin/apachectl stop
green
echo
echo "    Completed."
reset_colour
echo

green
echo "The recommended order in which to start these services on your own is:"
echo "1) Start the web server, if not already running as a service."
echo "2) Start the Relay Server State Manager test service:"
echo "    -> dbsvc -u SimpleTestApp_rst"
echo "3) Start the Outbound Enabler test service:"
echo "    -> dbsvc -u SimpleTestApp_oe"
reset_colour
echo
