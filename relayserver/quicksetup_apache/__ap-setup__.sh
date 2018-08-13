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

get_bitness()
{
    if [ "`uname -m`" = "ia64" ] || [ "`uname -m`" = "x86_64" ] ; then
	echo "64"
    else
	echo "32"
    fi
}

lib_exists()
{
    sa_str=${1}
    [ "`grep -n "${sa_str}" ${ENVVARS_BACKUP}`" != "" ]
}

rs_module_exists()
{
    test_str="^\s*LoadModule\s*${1}"
    [ "`grep -n "${test_str}" ${HTTPD_CONF}`" != "" ]
}

extract_port()
{
    conf_file=${1}
    test_str="^\s*Listen "
    result=`grep -n "${test_str}" ${conf_file}`
    if [ "${result}" != "" ]; then
	line=`echo ${result} | cut -f2 -d' '`
    fi
    echo ${line}
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

###################################################################
# Start here. 
# Prompt for required user input.
###################################################################

clear
echo
echo --------------------- [[ 1. Introduction ]] --------------------------
echo
echo ap-setup.sh for Relay Server Apache web server quick setup
echo ----------------------------------------------------------------------
echo This is an interactive script that takes no arguments. Any arguments 
echo provided on the commandline are silently ignored.
echo
echo The purpose of this script is to demonstrate automated Relay Server
echo deployment on Apache.
echo
echo "This script consists of the following sections:"
echo "    [[ 1. Introduction ]]"
echo "    [[ 2. Validation ]]"
echo "    [[ 3. Create Backup ]]"
echo "    [[ 4. Deploy the Relay Server ]]"
echo "    [[ 5. Deploy the SimpleTestApp page and Quick Reference ]]"
echo "    [[ 6. Introduction to the test setup script ]]"
echo
echo You are about to configure the Apache web server for the Relay Server.
echo Existing Apache and Relay Server configuration files will be
echo backed up before updating.
echo
red
echo The following prerequisites are required before proceeding:
echo "  a) An Apache webserver installed on your machine."
echo "     Please refer to this page for RelayServer supported web servers:"
echo "         http://www.sybase.com/detail?id=1095591"
echo "  b) Perl is installed on your machine and is also in your PATH."
reset_colour
echo
echo Are the prerequisites met and are you ready to proceed \(Y/n\)?
yn_read
wish_2_continue=${__yn_ap__}
if [ "${wish_2_continue}" != "y" ]; then
    red
    echo Setup aborted.
    reset_colour
    __funcs_unset
    exit
fi
clear 
echo
echo --------------------- [[ 2. Validation ]] --------------------------
echo
echo This section validates your Apache web server installation, confirms
echo that the required Apache root directory is specified correctly and that
echo the required configuration files exist.
echo
is_valid=0
for i in 1 2 3
do
echo
echo "Enter the root directory of your Apache web server installation:"
read apache_dir

# use eval to handle '~/' in the specified directory
APACHE_ROOT_DIR=`eval echo ${apache_dir}`
if [ ! -d "${APACHE_ROOT_DIR}" ];
then
    red
    echo "The directory you entered does not exist."
    reset_colour
elif [ ! -d "${APACHE_ROOT_DIR}/conf" ] || [ ! -d "${APACHE_ROOT_DIR}/modules" ]; then
    red
    echo "You have not specified the root directory of the Apache web server installation."
    red
    reset_colour
elif [ ! -f "${APACHE_ROOT_DIR}/conf/httpd.conf" ]; then
    red
    echo "Could not find ${APACHE_ROOT_DIR}/conf/httpd.conf file."
    reset_colour
elif [ ! -f "${APACHE_ROOT_DIR}/bin/envvars" ]; then
    red
    echo "Could not find ${APACHE_ROOT_DIR}/bin/envvars file."
    reset_colour
else
    is_valid=1
    break
fi
done

if [ ${is_valid} -eq 0 ]; then
    echo
    red
    echo "The Apache web server root directory you specified is invalid."
    echo "Please verify your Apache web server installation location and enter it again."
    reset_colour
    echo 
    exit
else
    echo
    green
    echo "Successfully verified Apache web server root directory and required"
    echo "configuration files."
    reset_colour
    echo 
    echo 
    echo This setup script supports Apache version 2.2.x or 2.4.x.
    echo Is your Apache web server version 2.2.x? \(Y/n\)?
    yn_read
    ap22_yn=${__yn_ap__}
    if [ "${ap22_yn}" != "y" ]; then
        AP_VER="24"
        echo Press ENTER to continue setup for Apache 2.4.x web server
        read
    else
        AP_VER="22"
        echo Press ENTER to continue setup for Apache 2.2.x web server
        read
    fi
fi

############################
# Setup script variables
############################

CURR_DATETIME=`date +"%F.%H-%M-%S"`
echo `dirname ${0}`
cd `dirname ${0}`
AP_SETUP_DIR=${PWD}
SA_RS_DIR=`dirname ${AP_SETUP_DIR}`
SA_AP_BIN=${SA_RS_DIR}/apache${AP_VER}/bin`get_bitness`
SA_DIR=`dirname ${SA_RS_DIR}`
SA_LIB=${SA_DIR}/lib`get_bitness`
HTTPD_CONF=${APACHE_ROOT_DIR}/conf/httpd.conf
HTTPD_CONF_BACKUP=${APACHE_ROOT_DIR}/conf/httpd.conf.${CURR_DATETIME}
ENVVARS=${APACHE_ROOT_DIR}/bin/envvars
ENVVARS_BACKUP=${APACHE_ROOT_DIR}/bin/envvars.${CURR_DATETIME}
RS_CONFIG=${SA_AP_BIN}/rs.config
OE_CONFIG=${AP_SETUP_DIR}/oe.config
OE_CONFIG_BACKUP=${AP_SETUP_DIR}/oe.config.${CURR_DATETIME}
RS_CONFIG_BACKUP=${SA_AP_BIN}/rs.config.${CURR_DATETIME}
cd ${SA_LIB}
MAJOR_VER=`/bin/ls -1 libdbtasks*_r.so.1 | cut -c11,12`
cd ${AP_SETUP_DIR}
CUR_SQLANY_VER=SQLANY${MAJOR_VER}

############################
# Backup existing files
############################

clear
echo --------------------- [[ 3. Create Backup ]] -------------------------
echo
echo This section backs up the Apache and Relay Server configuration files
echo generated by previous runs of this quick setup \(if applicable\).
echo
echo
echo "Do you want to back up the configuration files? (Y/n)"
yn_read
create_backup=${__yn_ap__}
if [ "${create_backup}" == "y" ]; then
    echo "Backing up existing files as: "
    echo
    cp ${HTTPD_CONF} ${HTTPD_CONF_BACKUP}
    echo "#!/bin/sh" > ap-uninstall.sh
    echo "echo" >> ap-uninstall.sh
    echo "mv ${HTTPD_CONF_BACKUP} ${HTTPD_CONF}" >> ap-uninstall.sh
    echo "echo \"Restored: ${HTTPD_CONF}\"" >> ap-uninstall.sh
    echo "echo \"From: ${HTTPD_CONF_BACKUP}\"" >> ap-uninstall.sh
    echo "echo" >> ap-uninstall.sh
    cp ${ENVVARS} ${ENVVARS_BACKUP}
    echo "mv ${ENVVARS_BACKUP} ${ENVVARS}" >> ap-uninstall.sh
    echo "echo \"Restored: ${ENVVARS}\"" >> ap-uninstall.sh
    echo "echo \"Restored: ${ENVVARS_BACKUP}\"" >> ap-uninstall.sh
    echo "echo" >> ap-uninstall.sh
    green
    echo "${HTTPD_CONF_BACKUP}"
    echo "${ENVVARS_BACKUP}"
    if [ -f "${RS_CONFIG}" ]; then
	mv ${RS_CONFIG} ${RS_CONFIG_BACKUP}
        echo "mv ${RS_CONFIG_BACKUP} ${RS_CONFIG}" >> ap-uninstall.sh
        echo "echo \"Restored: ${RS_CONFIG}\"" >> ap-uninstall.sh
        echo "echo \"From: ${RS_CONFIG_BACKUP}\"" >> ap-uninstall.sh
        echo "echo" >> ap-uninstall.sh
	echo "${RS_CONFIG_BACKUP}"
    fi
    if [ -f "${OE_CONFIG}" ]; then
	mv ${OE_CONFIG} ${OE_CONFIG_BACKUP}
        echo "mv ${OE_CONFIG_BACKUP} ${OE_CONFIG}" >> ap-uninstall.sh
        echo "echo \"Restored: ${OE_CONFIG}\"" >> ap-uninstall.sh
        echo "echo \"From: ${OE_CONFIG_BACKUP}\"" >> ap-uninstall.sh
        echo "echo" >> ap-uninstall.sh
	echo "${OE_CONFIG_BACKUP}"
    fi
    chmod +x ap-uninstall.sh
    reset_colour
    echo
    echo Press ENTER to continue.
    read
fi

#######################################################
# Remove old RelayServer configurations if they exist
# Add new RelayServer configurations
#######################################################

clear
echo
echo -------------- [[ 4. Deploy the Relay Server ]] ---------------
echo
echo This section consist of the following automated steps:
echo [4a] Remove old Relay Server configuration lines in httpd.conf
echo [4b] Set up and configure Relay Server module lines in httpd.conf 
echo "[4c] Set up and configure Relay Server <LocationMatch> tags in httpd.conf file"
echo [4d] Add Relay Server libraries to LD_LIBRARY_PATH in envvars
echo [4e] Generate a Relay Server configuration file
echo [4f] Generate an Outbound Enabler configuration file
echo 
echo "Proceed? (Y/n)"
yn_read
proceed=${__yn_ap__}
if [ "${proceed}" != "y" ]; then
    red
    echo Operation aborted. No changes have been made to Apache configuration.
    reset_colour
    echo
    __funcs_unset
    exit
fi

echo
echo [4a] Remove old Relay Server configurations in httpd.conf
perl ${AP_SETUP_DIR}/remove_rs_config.pl ${HTTPD_CONF_BACKUP} > ${APACHE_ROOT_DIR}/conf/httpd.conf.1
green
echo "    Completed."
reset_colour
echo
echo [4b] Setup and configure Relay Server modules in httpd.conf 
echo "[4c] Setup and configure Relay Server <LocationMatch> tags in httpd.conf file"
perl ${AP_SETUP_DIR}/add_rs_config.pl ${APACHE_ROOT_DIR}/conf/httpd.conf.1 ${SA_AP_BIN} > ${HTTPD_CONF}
rm -f ${APACHE_ROOT_DIR}/conf/httpd.conf.1
green
echo "    Completed."
reset_colour

#######################################################
# Add RelayServer binaries to LD_LIBRARY_PATH
#######################################################

echo
echo [4d] Add Relay Server libraries to LD_LIBRARY_PATH in envvars
perl ${AP_SETUP_DIR}/add_envvars_path.pl ${ENVVARS_BACKUP} ${SA_LIB} ${SA_AP_BIN} > ${ENVVARS}
green
echo "    Completed."
reset_colour
echo 

RS_HOST=`hostname`
RS_HTTP_PORT=`extract_port ${HTTPD_CONF}`
HTTPD_SSL_CONF=${APACHE_ROOT_DIR}/conf/extra/httpd-ssl.conf
RS_HTTPS_PORT=`extract_port ${HTTPD_SSL_CONF}`
APACHE_URL=http://${RS_HOST}:${RS_HTTP_PORT}

echo [4e] Generate a Relay Server configuration file 
echo "##############################################" > ${RS_CONFIG}
echo "# Sample rs.config generated by ap-setup.sh" >> ${RS_CONFIG}
echo "#    ${CURR_DATETIME}" >> ${RS_CONFIG}
echo "##############################################" >> ${RS_CONFIG}
echo "[options]" >> ${RS_CONFIG}
echo "description = Email <a href="mailto:changeit@changeit.com">RS administrator</a> in case of Relay Server issues" >> ${RS_CONFIG}
echo "shared_mem = 50M" >> ${RS_CONFIG}
echo "verbosity = 1" >> ${RS_CONFIG}
echo "status_refresh_sec = 0" >> ${RS_CONFIG}
echo >> ${RS_CONFIG}
echo "[relay_server]" >> ${RS_CONFIG}
echo "host = ${RS_HOST}" >> ${RS_CONFIG}
echo "http_port = ${RS_HTTP_PORT}" >> ${RS_CONFIG}
echo "https_port = ${RS_HTTPS_PORT}" >> ${RS_CONFIG}
echo "description = rs peer" >> ${RS_CONFIG}
echo "enable = yes" >> ${RS_CONFIG}
echo >> ${RS_CONFIG}
echo "[backend_farm]" >> ${RS_CONFIG}
echo "enable = yes" >> ${RS_CONFIG}
echo "id = SimpleTestApp-farm" >> ${RS_CONFIG}
echo "description = A farm for loopback demo" >> ${RS_CONFIG}
echo "verbosity = 5" >> ${RS_CONFIG}
echo "client_security =" >> ${RS_CONFIG}
echo "backend_security =" >> ${RS_CONFIG}
echo "active_cookie = no" >> ${RS_CONFIG}
echo "active_header = no" >> ${RS_CONFIG}
echo >> ${RS_CONFIG}
echo "[backend_server]" >> ${RS_CONFIG}
echo "enable = yes" >> ${RS_CONFIG}
echo "farm = SimpleTestApp-farm" >> ${RS_CONFIG}
echo "id = SimpleTestApp-server" >> ${RS_CONFIG}
echo "description = Using the local Apache server as a backend server for loopback demo using browsers" >> ${RS_CONFIG}
echo "mac = !" >> ${RS_CONFIG}
echo "token = !" >> ${RS_CONFIG}
echo "verbosity = inherit" >> ${RS_CONFIG}
green
echo "    File written to ${RS_CONFIG}"
reset_colour
echo

OE_OUTPUT_FILE=${APACHE_ROOT_DIR}/modules/oe.log
echo [4f] Generate an Outbound Enabler configuration file 
echo "-v 5" >> ${OE_CONFIG}
echo "-q" >> ${OE_CONFIG}
echo "-f SimpleTestApp-farm" >> ${OE_CONFIG}
echo "-id SimpleTestApp-server" >> ${OE_CONFIG}
echo "-ot ${OE_OUTPUT_FILE}" >> ${OE_CONFIG}
echo "-cr \"host=${RS_HOST};port=${RS_HTTP_PORT};url_suffix=/srv/iarelayserver/\"" >> ${OE_CONFIG}
echo "-cs \"host=${RS_HOST};port=${RS_HTTP_PORT};\"" >> ${OE_CONFIG}
green
echo "    File written to ${OE_CONFIG}"
reset_colour
echo 
echo Press ENTER to continue.
read

clear
echo
echo ---------- [[ 5. Deploy the SimpleTestApp page and Quick Reference ]] ----------
echo
echo The SimpleTestApp page helps you test your Relay Server deployment.
echo
echo The Quick Reference is a brief guide for the Relay Server that includes:
echo "    - Introduction"
echo "    - Editing and Deploying a Relay Server Configuration"
echo "    - Starting and Stopping the Relay Server"
echo "    - Providing the Backend Service"
echo "    - Client Accessing Backend Service via Relay Server"
echo "    - Monitoring the Relay Server"
echo "    - Troubleshooting Resources"
echo
echo Press ENTER to start the deployment:
read
echo
cp -f ./SimpleTestApp.htm ${APACHE_ROOT_DIR}/htdocs
echo "rm -f ${APACHE_ROOT_DIR}/htdocs/SimpleTestApp.htm" >> ap-uninstall.sh
echo "echo \"Removed: ${APACHE_ROOT_DIR}/htdocs/SimpleTestApp.htm\"" >> ap-uninstall.sh
echo "echo" >> ap-uninstall.sh
echo The SimpleTestApp page has been deployed to:
green
echo "   ${APACHE_ROOT_DIR}/htdocs/SimpleTestApp.htm"
reset_colour
echo
DCX_BRANCH="sa160"
sed -e "s@AP_SETUP_DIR@${AP_SETUP_DIR}@g" \
    -e "s@RS_CONFIG@${RS_CONFIG}@g" \
    -e "s@SA_AP_BIN@${SA_AP_BIN}@g" \
    -e "s@APACHE_URL@${APACHE_URL}@g" \
    -e "s@DCX_BRANCH@${DCX_BRANCH}@g" \
    -e "s@APACHE_ROOT_DIRECTORY@${APACHE_ROOT_DIR}@g" quick-ref.template.htm > ${APACHE_ROOT_DIR}/htdocs/rs-quick-ref.htm
echo "rm -f ${APACHE_ROOT_DIR}/htdocs/rs-quick-ref.htm" >> ap-uninstall.sh
echo "echo \"Removed: ${APACHE_ROOT_DIR}/htdocs/rs-quick-ref.htm\"" >> ap-uninstall.sh
echo "echo" >> ap-uninstall.sh
echo The Quick Reference has been deployed to:
green
echo "   ${APACHE_ROOT_DIR}/htdocs/rs-quick-ref.htm"
reset_colour
echo
echo Press ENTER to continue.
read




clear
echo
echo "------------ [[ 6. Introduction to the test setup script ]] ------------"
echo
echo The second part of Apache Relay Server setup is to test the success of
echo this deployment. This is accomplished by setting up test services and running
echo a simple test application.
echo
red
echo Before running the test setup script, you will need to:
echo
echo -e "    [6a] Login as \033[4msuper user\033[0;31m, then"
red
echo "    [6b] Run rs-test-setup.sh from the current directory:"
echo "         ${PWD}"
reset_colour
echo

echo "AP_SETUP_DIR=${AP_SETUP_DIR}" > ./ap-setup.env
echo "RS_CONFIG=${RS_CONFIG}" >> ./ap-setup.env
echo "SA_AP_BIN=${SA_AP_BIN}" >>./ap-setup.env
echo "APACHE_URL=${APACHE_URL}" >> ./ap-setup.env
echo "APACHE_ROOT_DIRECTORY=${APACHE_ROOT_DIR}" >> ./ap-setup.env
echo "SA_DIR=${SA_DIR}" >> ./ap-setup.env
echo "SQLANY=${SA_DIR}" >> ./ap-setup.env
echo "${CUR_SQLANY_VER}=${SA_DIR}" >> ./ap-setup.env
echo "export ${CUR_SQLANY_VER}" >> ./ap-setup.env








