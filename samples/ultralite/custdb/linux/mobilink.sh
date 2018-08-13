#!/bin/bash
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set -e
set -u

set -x
mlsrv16 -vcrs -c "dsn=SQL Anywhere 16 CustDB;uid=ml_server;pwd=sql"
