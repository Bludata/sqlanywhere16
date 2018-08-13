# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
push_cleanup_callback()
########################
# $1 rollback function
# $* arguments
{
    __CLEANUP="$* ; ${__CLEANUP:-}"
}

valid_pid()
##########
{
    # $1 : pid
    kill -s 0 $1 > /dev/null 2>&1
    echo $?
}

clean_up_pre()
##############
{
    # erase any temporary files
    for file in $TMPPREFIX* ; do

        # modifying TMPPREFIX to be given as a regex to sed
        JUNK=`echo $TMPPREFIX |sed "s%\/%\\\\\/%g"`

        # removing the TMPPREFIX from the file name, getting the pid
        JUNK=`echo $file |sed "s%$JUNK%%g" `

        # checking if the pid is valid 0: valid, 1: not valid
        JUNK=`valid_pid $JUNK`
        
        if [ "$JUNK" = "1" ] ; then
            # can safely remove the file, if we're allowed to
            [ -w "$file" ] && rm -f "$file"
        fi
    done
}

clean_up_post()
###############
{
    eval `echo ${__CLEANUP:-}`
}
