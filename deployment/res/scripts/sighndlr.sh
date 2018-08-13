# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
signal_handler()
################
{
    rollback
    echo ${ERR_CLEANING_UP}
    clean_up_pre
    clean_up_post
    clear_signal_handler
    exit 1
}

set_signal_handler()
####################
{
    trap signal_handler HUP INT TERM
}

clear_signal_handler()
######################
{
    trap "" HUP INT TERM
}

