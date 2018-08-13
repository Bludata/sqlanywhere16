#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

# Read in a y/n prompt reply. Filtered reply stored in __yn_ap__ env var.
# Preconditions:
# - appropriate prompt has been echoed to stdout/stderr before call
# Returns:
# - "y" if "y", "y....", "Y", "Y...", "" (i.e., <Enter> only) given
# - unaltered input otherwise
yn_read() {
    unset __yn_ap__
    read yn
    if [ -n "${yn}" ]; then
        yn=`echo ${yn} | cut -c1`
    fi
    if [ -z "${yn}" ] || [ "${yn}" == "Y" ]; then
        yn=y
    fi
    export __yn_ap__=${yn}
}

__funcs_unset() {
    unset __yn_ap__
}
