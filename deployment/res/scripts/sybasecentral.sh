# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
set_install_sc_icon()
#####################
{
    INSTALL_SC_ICON=$1
}

get_install_sc_icon()
#####################
{
    [ "${INSTALL_SC_ICON:-FALSE}" = "TRUE" ]
}

create_sybase_central_icon()
############################
{
    INSTALLDIR=`get_install_dir SA`
    INSTALLDIR_UTF8=`convert_to_utf8 "$INSTALLDIR"`

    pre_install_icons

    for ICONBITNESS in 64 32; do
        BINsDIR="`get_install_dir BIN${ICONBITNESS}S`"
        BINsDIR_UTF8=`convert_to_utf8 "$BINsDIR"`
        writedesktopfile_scjview $XDG_DESKTOP_DIR
    done

    post_install_icons

    true
}


run_sybase_central_sample()
###########################
{
    sample_config="`get_install_dir SAMPLES`/sample_config64.sh"
    if [ ! -f "${sample_config}" ] ; then
        sample_config="`get_install_dir SAMPLES`/sample_config32.sh"
    fi
        
    if [ ! -f "${sample_config}" ] ; then
        false
        return
    fi

    if [ `plat_os` = "linux" ] ; then
        SETSID=setsid
    else
        SETSID=
    fi

    scjview="`get_install_dir BIN64S`/scjview"
    if [ ! -x "${scjview}" ] ; then
        scjview="`get_install_dir BIN32S`/scjview"
    fi

    if [ ! -x "${scjview}" ] ; then
        false
        return
    fi
    if [ -z "${DISPLAY}" ] ; then
        false
        return
    fi

    echo "#!/bin/sh" > "`get_install_dir SAMPLES`/sc.sh" ; echo "echo '' | . \"${sample_config}\" ;  "$SETSID" \"${scjview}\" -sqlanywhere1600:connect_to_demo &" >> "`get_install_dir SAMPLES`/sc.sh"
    /bin/sh "`get_install_dir SAMPLES`/sc.sh" > /dev/null
    rm "`get_install_dir SAMPLES`/sc.sh"

    true
}
