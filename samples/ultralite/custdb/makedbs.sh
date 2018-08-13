#!/bin/bash
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set -e
set -u

[ -z "${SQLANY16}" ] && echo "environment variable SQLANY16 is not set" && exit 1

SA_DIR=${SQLANY16}
SA_ISQL="dbisql -q -nogui"
SA_ENG=CustDB

make_sa_db() {
    # $1 db name
    # $2 creation_opts
    echo "----- create $1"
    [ -r "$1" ] && dberase -q -y $1
    set +u
    $SA_ISQL -c "UID=dba;PWD=sql;DBN=utility_db;ENG=${SA_ENG}" CREATE DATABASE \'$1\' $2
    set -u
    echo "----- grant permission to ml_server user"
    $SA_ISQL -c "DBF=$1;ENG=${SA_ENG};UID=dba;PWD=sql" read grant.sql
    echo "----- set up tables, procedures, etc. for the MobiLink synchronization server"
    $SA_ISQL -c "DBF=$1;ENG=${SA_ENG};UID=ml_server;PWD=sql" read "${SA_DIR}/mobilink/setup/syncsa.sql"
    echo "----- set up custdb tables + synchronization scripts for custdb tables"
    $SA_ISQL -c "DBF=$1;ENG=${SA_ENG};UID=dba;PWD=sql" read custdb.sql
}

make_sa_db custdb.db "COLLATION '1252LATIN1'"
echo "----- create UltraLite database from reference database"
ulinit -y -a "DBF=custdb.db;ENG=${SA_ENG};UID=dba;PWD=sql" --pub=custdb_tables --utf8=yes custdb.udb
echo "----- unload to create XML file"
ulunload -y -c "DBF=custdb.udb" custdb.xml
