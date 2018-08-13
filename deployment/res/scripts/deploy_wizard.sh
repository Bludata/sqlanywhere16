# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
deploy_wizard_mode()
####################
{
    echo "${DEPLOY_WIZARD_MODE:-LIST}"
}

set_deploy_wizard_mode()
########################
{
    case "$1" in
	LIST | TAR)
	    DEPLOY_WIZARD_MODE="$1"
	;;
    esac
}

generate_deployment_tar()
#########################
{
    pushd_quiet "`get_install_dir SA`"
    build_filelist
    tar cf "$1" -T "`get_filelist`"
    popd_quiet
}

save_deploy_file_list_to_file()
###############################
{
    build_filelist
    cp "`get_filelist`" "$1"
}
