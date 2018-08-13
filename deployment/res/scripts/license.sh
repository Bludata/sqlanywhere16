# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
get_license_file_name ()
########################
{
    case $1 in
	1) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_1" ;;
	2) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_2" ;;
	3) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_3" ;;
	4) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_4" ;;
	5) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_5" ;;
	6) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_6" ;;
	7) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_7" ;;
	8) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_8" ;;
	9) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_9" ;;
	10) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_10" ;;
	11) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_11" ;;
	12) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_12" ;;
	13) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_13" ;;
	14) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_14" ;;
	15) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_15" ;;
	16) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_16" ;;
	17) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_17" ;;
	18) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_18" ;;
	19) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_19" ;;
	20) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_20" ;;
	21) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_21" ;;
	22) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_22" ;;
	23) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_23" ;;
	24) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_24" ;;
	25) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_25" ;;
	26) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_26" ;;
	27) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_27" ;;
	28) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_28" ;;
	29) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_29" ;;
	30) LICENSE="$MSG_COUNTRY_LICENSE_TEXT_30" ;;
	* )
	    LICENSE="" ;;
    esac
}

get_clickwrap_license_file()
############################
{
    get_license_file_name "${1:-}"
    if [ -f "$MEDIA_ROOT/licenses/$LICENSE" ] ; then
	if [ "`get_target_charset`" != UTF8 ] ; then
            create_new_tmpfile
	    csconvert -s UTF8 "$MEDIA_ROOT/licenses/$LICENSE" "$TMPFILE"
	    echo "$TMPFILE"
	else
	    echo "$MEDIA_ROOT/licenses/$LICENSE"
	fi
    else
	echo ""
    fi
}

get_license_agreement()
##############*########
{
    if is_developer_key; then
        LICFILENAME=dev
    elif is_evaluation_key; then
        LICFILENAME=eval
    elif is_web_key; then
        LICFILENAME=web
    elif is_edu_key; then
        LICFILENAME=edu
    elif [ `get_install_type` = "DBCLOUD" ]; then 
	if [ -r "$MEDIA_ROOT/cloud_license.txt" ] ; then
	    LICFILENAME=cloud
	else
	    false
	    return
	fi
    else
        false
        return
    fi

    create_new_tmpfile
    if [ "$LANGCODE" = "ja" ]; then
	csconvert -s UTF8 "$MEDIA_ROOT/${LICFILENAME}_license_ja.txt" "$TMPFILE"
	cat "$TMPFILE"
        rm -f "$TMPFILE"
    else
	cat "$MEDIA_ROOT/${LICFILENAME}_license.txt"
    fi
}

get_license_info()
##################
{
    case "${1:-}" in
	NAME)
	    echo "${__CLI_NAME:-}"
	    ;;
	COMPANY)
	    echo "${__CLI_COMPANY:-}"
	    ;;
	TYPE)
	    if [ -n "${__CLI_SEAT_MODEL}" ]; then
		echo "${__CLI_SEAT_MODEL}"
	    else
		echo "${__DEFAULT_CLI_SEAT_MODEL:-}"
	    fi
	    ;;
	CPUCOUNT | CORECOUNT | SEATCOUNT | COUNT )
	    if [ -n "${__CLI_SEATS}" ]; then
		echo "${__CLI_SEATS}"
	    else
		echo "${__DEFAULT_CLI_SEATS:-}"
	    fi
	    ;;
    esac
}

set_license_info()
##################
{
    case "${1:-}" in
	NAME)
	    __CLI_NAME="${2:-}"
	    ;;
	COMPANY)
	    __CLI_COMPANY="${2:-}"
	    ;;
	TYPE)
	    if [ "${2:-}" = "percpu" ] || [ "${2:-}" = "processor" ] || [ "${2:-}" = "CPU" ] ; then
		__CLI_SEAT_MODEL="processor"
            elif [ "${2:-}" = "percore" ] || [ "${2:-}" = "core" ] || [ "${2:-}" = "CORE" ] ; then
		__CLI_SEAT_MODEL="core"
	    else
		__CLI_SEAT_MODEL="perseat"
	    fi
	    ;;
	CPUCOUNT | SEATCOUNT | CORECOUNT | COUNT)
	    __CLI_SEATS="${2:-}"
	    [ ${__CLI_SEATS:-0} -le 0 ] && __CLI_SEATS=1
	    ;;
	DEFAULT_TYPE)
	    __DEFAULT_CLI_SEAT_MODEL="${2:-}"
	    ;;
	DEFAULT_COUNT)
	    __DEFAULT_CLI_SEATS="${2:-}"
	    ;;
    esac
}

set_accepted_license_agreement()
################################
{
    __LICENSE_ACCEPTED=1
}

has_accepted_license_agreement()
################################
{
    [ "${__LICENSE_ACCEPTED:-0}" = 1 ]
}

get_install_file()
##################
{
    case "$1" in
	dbsrv32)
	    echo "`get_install_dir BIN32`/dbsrv`get_major_version`"
	    ;;
	dbeng32)
	    echo "`get_install_dir BIN32`/dbeng`get_major_version`"
	    ;;
	mlsrv32)
	    echo "`get_install_dir BIN32`/mlsrv`get_major_version`"
	    ;;
	sa_config32.sh)
	    echo "`get_install_dir BIN32`/sa_config.sh"
	    ;;
	sa_config32.csh)
	    echo "`get_install_dir BIN32`/sa_config.csh"
	    ;;
	dbsrv64)
	    echo "`get_install_dir BIN64`/dbsrv`get_major_version`"
	    ;;
	dbeng64)
	    echo "`get_install_dir BIN64`/dbeng`get_major_version`"
	    ;;
	mlsrv64)
	    echo "`get_install_dir BIN64`/mlsrv`get_major_version`"
	    ;;
	sa_config64.sh)
	    echo "`get_install_dir BIN64`/sa_config.sh"
	    ;;
	sa_config64.csh)
	    echo "`get_install_dir BIN64`/sa_config.csh"
	    ;;
	sample_config32.sh)
	    echo "`get_install_dir SAMPLES`/sample_config32.sh"
	    ;;
	sample_config64.sh)
	    echo "`get_install_dir SAMPLES`/sample_config64.sh"
	    ;;
	updchk_html_en)
	    echo "`get_install_dir SUPPORT`/en/updchk.html"
	    ;;
	readme_txt_en)
	    echo "$MEDIA_ROOT/readme_en.txt"
	    ;;
	iphone_readme)
	    echo "`get_install_dir SA`/ultralite/iphone/readme.txt"
	    ;;
    esac
}

licensing_needed()
##################
{
    has_feature SERVER_LICENSE || has_feature HIGH_AVAIL || has_feature IN_MEMORY || has_feature SCALEOUT_NODES
}

license_server()
################
{
    if licensing_needed ; then
	for bin in dbsrv32 dbsrv64 dbeng32 dbeng64 mlsrv32 mlsrv64; do
	    file=`get_install_file $bin`
	    has_feature SERVER_LICENSE	&& cust_info="`get_license_info COUNT` '`get_license_info NAME`' '`get_license_info COMPANY`'"
	    has_feature HIGH_AVAIL	&& ha_switch="-a"
	    has_feature IN_MEMORY	&& im_switch="-i"
	    has_feature SCALEOUT_NODES  && so_switch="-s"
	    if [ -f "${file:-}" ] ; then
		eval dbinstall license ${ha_switch:-} ${im_switch:-} ${so_switch:-} \"$file\" `get_registration_key` ${cust_info:-}  >/dev/null 2>&1 
		chmod a+r "${file}.lic"
	    fi
	done
    fi
}

license_all_components()
########################
{
    L_DIR=`pwd`
    for bin in dbsrv32 dbsrv64 dbeng32 dbeng64 mlsrv32 mlsrv64; do
        file=`get_install_file $bin`
        dblic=`dirname $file`/dblic

        lic_info="-l `get_license_info TYPE` -u `get_license_info COUNT`"
        cust_info="'`get_license_info NAME`' '`get_license_info COMPANY`'"

        if [ -f "${file:-}.lic" ] ; then
            chmod +w ${file:-}.lic
            eval ${dblic} ${lic_info:-} ${file:-}.lic ${cust_info:-} >/dev/null 2>&1 && echo ${file:-} | eval sed -e 's#^${L_DIR}\/*##'
            chmod -w ${file:-}.lic
        fi
    done
}
