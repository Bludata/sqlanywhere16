# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
has_feature()
############
{
    case "${1:-}" in
	SERVER_LICENSE)
	    (is_selected_option OPT_SQLANY64 || is_selected_option OPT_SQLANY32 || has_feature MOBILINK_SERVER || has_feature SAMON || is_selected_option OPT_DBCLOUD ) && not is_upgrade
	    ;;
	HIGH_AVAIL)
	    is_selected_option OPT_HIGH_AVAIL && not is_upgrade
	    ;;
	IN_MEMORY)
	    is_selected_option OPT_IN_MEMORY && not is_upgrade
	    ;;
	SCALEOUT_NODES)
	    is_selected_option OPT_SCALEOUTNODES && not is_upgrade
	    ;;
	SELINUX)
	    is_selected_option OPT_SELINUX
	    ;;
	ICONS)
	    test `plat_os` = "linux"
	    ;;
	ADMINTOOLS)
	    has_feature ADMINTOOLS_64 || has_feature ADMINTOOLS_32
            ;;
	ADMINTOOLS_32)
	    is_selected_option OPT_ADMINTOOLS32
	    ;;
	ADMINTOOLS_64)
	    is_selected_option OPT_ADMINTOOLS64
	    ;;
	SYBASE_CENTRAL)
	    has_feature ADMINTOOLS
	    ;;
	MOBILINK_SERVER)
	    has_feature MOBILINK_SERVER_32 || has_feature MOBILINK_SERVER_64
	    ;;
	MOBILINK_SERVER_32)
	    is_selected_option OPT_MLSRV32 || is_selected_option OPT_ML32
	    ;;
	MOBILINK_SERVER_64)
	    is_selected_option OPT_MLSRV64 || is_selected_option OPT_ML64
	    ;;
	SA_SERVER)
	    has_feature SA_SERVER_32 || has_feature SA_SERVER_64
	    ;;
	SA_SERVER_32)
	    is_selected_option OPT_SQLANY32
	    ;;
	SA_SERVER_64)
	    is_selected_option OPT_SQLANY64
	    ;;
	SAMPLES)
	    is_selected_option OPT_SAMPLES
	    ;;
	SAMON)
	    has_feature SAMON_64 || has_feature SAMON_32 || is_selected_option OPT_SAMON_DEPLOY
	    ;;
	SAMON_32)
	    is_selected_option OPT_SAMON32
	    ;;
	SAMON_64)
	    is_selected_option OPT_SAMON64
	    ;;
	ECLIPSE)
	    is_selected_option OPT_ECLIPSE_EN_DOC || is_selected_option OPT_ECLIPSE_DE_DOC || is_selected_option OPT_ECLIPSE_JA_DOC || is_selected_option OPT_ECLIPSE_ZH_DOC
	    ;;
	DBCLOUD)
	    is_selected_option OPT_DBCLOUD
	    ;;
	DBCLOUD32)
	    is_selected_option OPT_DBCLOUD32
	    ;;
	DBCLOUD64)
	    is_selected_option OPT_DBCLOUD64
	    ;;
	*)
	    false
	    ;;
    esac
}

has_installed_feature()
#######################
{
    if has_feature "${1:-}"; then
        return 0
    fi

    case "${1:-}" in
	SERVER_LICENSE)
	    (is_installed_option OPT_SQLANY64 || is_installed_option OPT_SQLANY32 || has_installed_feature MOBILINK_SERVER || has_installed_feature SAMON ) && not is_upgrade
	    ;;
	HIGH_AVAIL)
	    is_installed_option OPT_HIGH_AVAIL && not is_upgrade
	    ;;
	IN_MEMORY)
	    is_installed_option OPT_IN_MEMORY && not is_upgrade
	    ;;
	SCALEOUT_NODES)
	    is_installed_option OPT_SCALEOUTNODES && not is_upgrade
	    ;;
	SELINUX)
	    is_installed_option OPT_SELINUX
	    ;;
	ICONS)
	    test `plat_os` = "linux"
	    ;;
	ADMINTOOLS)
	    has_installed_feature ADMINTOOLS_64 || has_installed_feature ADMINTOOLS_32
            ;;
	ADMINTOOLS_32)
	    is_installed_option OPT_ADMINTOOLS32
	    ;;
	ADMINTOOLS_64)
	    is_installed_option OPT_ADMINTOOLS64
	    ;;
	SYBASE_CENTRAL)
	    is_installed_option OPT_ADMINTOOLS
	    ;;
	MOBILINK_SERVER)
	    has_installed_feature MOBILINK_SERVER_32 || has_installed_feature MOBILINK_SERVER_64
	    ;;
	MOBILINK_SERVER_32)
	    is_installed_option OPT_MLSRV32 || is_installed_option OPT_ML32
	    ;;
	MOBILINK_SERVER_64)
	    is_installed_option OPT_MLSRV64 || is_installed_option OPT_ML64
	    ;;
	SA_SERVER)
	    has_installed_feature SA_SERVER_32 || has_installed_feature SA_SERVER_64
	    ;;
	SA_SERVER_32)
	    is_installed_option OPT_SQLANY32
	    ;;
	SA_SERVER_64)
	    is_installed_option OPT_SQLANY64
	    ;;
	SAMPLES)
	    is_installed_option OPT_SAMPLES
	    ;;
	SAMON)
	    has_installed_feature SAMON_32 || has_installed_feature SAMON_64 || is_installed_option OPT_SAMON_DEPLOY
	    ;;
	SAMON_32)
	    is_installed_option OPT_SAMON32
	    ;;
	SAMON_64)
	    is_installed_option OPT_SAMON64
	    ;;
	ECLIPSE)
	    is_installed_option OPT_ECLIPSE_EN_DOC || is_installed_option OPT_ECLIPSE_DE_DOC || is_installed_option OPT_ECLIPSE_JA_DOC || is_installed_option OPT_ECLIPSE_ZH_DOC
	    ;;
	*)
	    false
	    ;;
    esac
}
