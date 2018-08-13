# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
has_visible_children()
######################
{
    CHILD_LIST=`get_visible_children "$1"`
    [ "${CHILD_LIST:-}" != "" ]
}

has_children()
##############
{
    CHILD_LIST=`comp_children "$1"`
    if [ "$CHILD_LIST" = "" ] ; then
	false
    else
	true
    fi
}

is_toplevel_category ()
#######################
{
    case "$1" in
	TOP_LEVEL_COMPONENTS)
	    echo true
	    ;;
	*)
	    echo false
	    ;;
    esac
}

is_valid_option()
#################
{
    comp_in_list "$1"
}

is_visible()
############
{
    not comp_hidden "$1"
}

select_option_priv ()
#####################
{
    eval $1="\" X \""
}

unselect_option_priv ()
#######################
{
    eval $1="\"   \""
}

set_not_available ()
####################
{
    eval $1="\"NA\""
}

is_selected_option ()
#####################
{
    OPTION=`eval "echo \"\\$$1\""`
    if not is_installed_option "$1" && [ "$OPTION" = " X " ] ; then
	true
    else
	false
    fi
}

is_installed_option ()
######################
{
    comp_installed "$1"
}

is_exposed_option ()
####################
{
    comp_exposed "$1"
}

is_default_option ()
####################
{
    is_exposed_option "$1" && comp_default "$1"
}

is_unavailable_option ()
########################
{
    comp_unavailable "$1" || 
    ( is_installed_option "$c" && not is_exposed_option "$c" )
}

toggle_option ()
################
{
    CURRENT_VALUE=`eval "echo \"\\$$1\""`

    if [ "$CURRENT_VALUE" = " X " ] ; then
	unselect_option "$1"
    else
	select_option "$1"
    fi
}

set_category_state ()
#####################
{
    CHILDREN=`comp_children $1`
    if [ `count_selected "$CHILDREN"` != "0" ] ; then
	select_option_priv "$1"
    else
	unselect_option_priv "$1"
    fi
}

select_all ()
#############
{
     for _c in $* ; do
         if is_exposed_option "$_c" ; then
	     select_option_priv "$_c"
	     CHILDREN=`comp_children $_c`
	     if [ "$CHILDREN" != "" ] ; then
	         select_all "$CHILDREN"	     
	     fi
         else
             select_none "$_c"
         fi
     done
}

select_default ()
#################
{
     for _c in $* ; do
         if is_default_option "$_c" ; then
	     select_option_priv "$_c"
	     CHILDREN=`comp_children $_c`
	     if [ "$CHILDREN" != "" ] ; then
	         select_default "$CHILDREN"	     
	     fi
         else
             select_none "$_c"
         fi
     done
}

reset_category_state ()
#######################
{
     for _c in $* ; do
	 CHILDREN=`comp_children $_c`
	 if [ "$CHILDREN" != "" ] ; then
	     set_category_state $_c
	     reset_category_state "$CHILDREN"
	 fi
     done
}

select_none ()
##############
{
     for _c in $* ; do
	 unselect_option_priv "$_c"
	 CHILDREN=`comp_children $_c`
	 if [ "$CHILDREN" != "" ] ; then
	     select_none "$CHILDREN"	     
	 fi
     done
}

select_option()
###############
{
    select_all "$@"
}

unselect_option()
#################
{
    select_none "$@"
}

count_selected_recursive ()
###########################
{
    lcl_cnt=0
    for _c in $* ; do
	if not is_installed_option "$_c" && is_selected_option "$_c" ; then
            lcl_child_count=1

            CHILD_LIST=`get_visible_children "$_c"`
            if [ -n "${CHILD_LIST:-}" ] ; then
                lcl_child_count=`count_selected_recursive "${CHILD_LIST}"`
            fi

	    lcl_cnt=`expr $lcl_cnt + $lcl_child_count`
	fi
    done
    echo $lcl_cnt
}

count_selected ()
#################
{
    lcl_cnt=0
    for _c in $* ; do
	if not is_installed_option "$_c" && is_selected_option "$_c" ; then
	    lcl_cnt=`expr $lcl_cnt + 1`
	fi
    done
    echo $lcl_cnt
}

count_all_recursive ()
######################
{
    full=0
    if [ "$1" = "full" ]; then
        full=1
        shift
    fi
    lcl_cnt=0
    for c in $* ; do
        if [ "$full" = "1" ] || (
                is_exposed_option "$c" && not is_installed_option "$c" ) ; then
            lcl_child_count=1
            
            CHILD_LIST=`get_visible_children "$c"`
            if [ -n "${CHILD_LIST:-}" ] ; then
                lcl_child_count=`count_all "${CHILD_LIST}"`
            fi

	    lcl_cnt=`expr $lcl_cnt + $lcl_child_count`
        fi
    done
    echo $lcl_cnt
}

count_all ()
############
{
    full=0
    if [ "$1" = "full" ]; then
        full=1
        shift
    fi
    lcl_cnt=0
    for c in $* ; do
        if [ "$full" = "1" ] || (
                is_exposed_option "$c" && not is_installed_option "$c" ) ; then
	    lcl_cnt=`expr $lcl_cnt + 1`
        fi
    done
    echo $lcl_cnt
}

get_package_display_name ()
###########################
{
    eval echo "\$MSG_$1"
}

get_package_description()
#########################
{
    eval echo "\$MSG_$1_DESC"
}

get_visible_children()
######################
{
    CHILD_LIST=`comp_children $1`
    for _c in $CHILD_LIST ; do
	if is_visible $_c ; then
	    echo $_c
	fi
    done
}

get_category_selected_count()
#############################
{
    # second parameter is variable name to store number selected
    # third parameter is variable name to store total count
    CHILD_LIST=`get_visible_children $1`
    if [ -n "${CHILD_LIST:-}" ] ; then
	eval $2=`count_selected_recursive "$CHILD_LIST"`
	eval $3=`count_all_recursive "$CHILD_LIST"`
    else
	eval $2=-1
	eval $3=-1
    fi
}

generate_package_list()
#######################
{
    CHILDREN=`comp_children "$1"`
    TYPE="${2:-}"
    HIDDEN="${3:-}"
    for c in $CHILDREN ; do
	if [ "$HIDDEN" = "show_hidden" ] && has_children "$c" ; then
	    generate_package_list "$c" "$TYPE" "$HIDDEN"
	elif has_visible_children "$c" ; then
	    generate_package_list "$c" "$TYPE" "$HIDDEN"
        elif [ "$TYPE" = "unavailable" ] ; then
            if is_unavailable_option "$c" ; then
                echo "$c"
            fi
        elif [ "$TYPE" = "exposed" ] ; then
            if is_exposed_option "$c" ; then
                echo "$c"
            fi
        elif [ "$TYPE" = "installed" ] ; then
            if is_installed_option "$c" ; then
                echo "$c"
            fi
	elif [ "$TYPE" = "available" ] || is_selected_option "$c" ; then
            if not is_installed_option "$c" ; then
	        echo "$c"
            fi
	fi
    done
}

generate_package_mask()
#######################
{
    pkg_mask=''
    for pkg in `generate_package_list TOP_LEVEL_COMPONENTS selected show_hidden`
    do
        if [ -n "${pkg_mask:-}" ]; then
            pkg_mask="${pkg_mask}|"
        fi
        pkg_mask="${pkg_mask}${pkg}"
    done
    echo "${pkg_mask}"
    unset pkg_mask
}

get_num_selected_packages()
###########################
{
    generate_package_list TOP_LEVEL_COMPONENTS selected | wc -w | sed -e 's/\ //g'
}

get_num_available_packages()
############################
{
    generate_package_list TOP_LEVEL_COMPONENTS available | wc -w | sed -e 's/\ //g'
}

get_num_exposed_packages()
##########################
{
    generate_package_list TOP_LEVEL_COMPONENTS exposed | wc -w | sed -e 's/\ //g'
}

get_package_status()
####################
{
    if is_deploy || is_upgrade || (
        is_modify && not has_provided_registration_key ) ; then
	eval dbinstall options -d \"`get_install_dir SA`\" "$TICFILE"
    elif is_modify ; then
	KEY=`get_registration_key`
	eval dbinstall options -k $KEY -d \"`get_install_dir SA`\" "$TICFILE"
    else
	KEY=`get_registration_key`
	eval dbinstall options -k $KEY "$TICFILE"
    fi
}

process_package_status ()
#########################
{
    OPT_NAME=
    for elem in "$@" ; do
	if [ -z "${OPT_NAME:-}" ]; then
	    OPT_NAME="$elem"
	else
	    comp_set_status "$OPT_NAME" "$elem"
	    OPT_NAME=
	fi
    done
}

initialize_package_list()
#########################
{
    clear_components_list
    process_package_status `get_package_status`
    . "${MEDIA_ROOT}/res/scripts/populate_menus.sh"
    select_default TOP_LEVEL_COMPONENTS
}

select_option_by_name ()
########################
# used to select packages by name when passed on the command line
{
    PKG=`toupper $1`
    OPT=`echo OPT_$PKG`

    if is_valid_option "$OPT" ; then
	select_option_priv "$OPT"
	true
    else
	false
    fi
}

map_names_to_option_list()
##########################
{
    VALID=""
    INVALID=""
    
    for p in $* ; do
	PKG=`toupper $p`
	OPT=`echo OPT_$PKG`
	
	if is_valid_option "$OPT" ; then
	    VALID="$OPT ${VALID:-}"
	else
	    INVALID="$p ${INVALID:-}"
	fi
    done
    
    if [ -n "${INVALID:-}" ] ; then
	echo "${INVALID:-}"
	false
    else
	echo "${VALID:-}"
	true
    fi
}

select_options_from_list()
##########################
{
    select_none TOP_LEVEL_COMPONENTS
    for p in $* ; do
	select_option "$p"
    done
}

list_available_packages_priv ()
###############################
{
    CHILDREN=`comp_children "$1"`
    for c in $CHILDREN ; do
	if has_visible_children "$c" ; then
	    list_available_packages_priv "$c"
	else
	    echo "$c"
	fi
    done
}

list_available_packages ()
##########################
{
    list_available_packages_priv TOP_LEVEL_COMPONENTS
}

