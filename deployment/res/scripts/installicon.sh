# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
. "${MEDIA_ROOT}/res/scripts/links.sh"
. "${MEDIA_ROOT}/res/scripts/directory.sh"
. "${MEDIA_ROOT}/res/scripts/language.sh"
. "${MEDIA_ROOT}/res/language/all_langs_icon_resources_utf8.txt"

set_install_icons()
###################
{
    INSTALL_ICONS=$1
}

get_install_icons()
###################
{
    [ "${INSTALL_ICONS:-FALSE}" = "TRUE" ]
}

has_installed_icons()
#####################
{
    # Get XDG_CONFIG_HOME, etc.
    pre_install_icons

    # Check to see if our submenu file is already there
    PRODNAME=`get_menu_name`
    [ -r "$XDG_CONFIG_HOME/menus/applications-merged/${VENDORID}-${PRODNAME}.menu" ] 
}

convert_to_utf8()
#################
{
    create_new_tmpfile
    SRC="$TMPFILE"
    create_new_tmpfile
    DST="$TMPFILE"

    echo "$*" > "$SRC"
    csconvert -t UTF8 "$SRC" "$DST"
    rm -f "$SRC"

    cat "$DST"
    rm -f "$DST"
}

find_viewer_app()
#################
{
    VIEWER=
    if ! is_redflag; then
	VIEWER="${BINDIR_UTF8}/htmlview"
    else
	TRY_VIEWER_LIST=
	# path locations
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which firefox 2>/dev/null`"    # desktop-independent 
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which mozilla 2>/dev/null`"    # desktop-independent 
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which netscape 2>/dev/null`"    # desktop-independent
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which opera 2>/dev/null`"    # desktop-independent
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which epiphany 2>/dev/null`"    # Gnome
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which galeon 2>/dev/null`"    # Gnome
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which kfmclient 2>/dev/null`"  # KDE standard
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST `/usr/bin/which konqueror 2>/dev/null`"  # KDE standard
	# hard-coded locations
#   TRY_VIEWER_LIST="$TRY_VIEWER_LIST /opt/kde3/share/applications/kfmclient"    # KDE standard - picks default viewer for you
#   eg. kfmclient openProfile webbrowsing
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/firefox"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/mozilla"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/netscape"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/opera"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/epiphany"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /usr/bin/galeon"    
	TRY_VIEWER_LIST="$TRY_VIEWER_LIST /opt/kde3/konqueror"    # KDE standard 

	for viewer in $TRY_VIEWER_LIST; do
	    if [ -x "${viewer}" ]; then
		VIEWER=${viewer}
		break
	    fi
	done
	if [ `basename "${viewer}"` = "kfmclient" ]; then
	    VIEWER="${VIEWER} exec"
	fi

        VIEWER=`convert_to_utf8 "${VIEWER}"`
    fi

    echo $VIEWER
}

writealldesktopfiles()
######################
# Called once for each bitness
{
    # The executables we're interested in are dbeng, dbsrv, dbisql, scjview, dbconsole, mlprof
    # Put codes for each of these in a list.  Use the codes to specify the name and switches
    # (if any) below. (${CODE}_NAME and ${CODE}_SWITCHES).
    # This allows us to use loops instead of case statements everywhere.

    DT_LIST=
    if has_feature SA_SERVER ; then
	DT_LIST="$DT_LIST kde_dbeng"
	DT_LIST="$DT_LIST gnome_dbeng"
	DT_LIST="$DT_LIST kde_dbsrv"
	DT_LIST="$DT_LIST gnome_dbsrv"
    fi
    if has_feature SAMON_64 || has_feature SAMON_32 ; then
	DT_LIST="$DT_LIST kde_samonitor"
	DT_LIST="$DT_LIST gnome_samonitor"
    fi
    if is_selected_option OPT_SAMON_DEPLOY ; then
	DT_LIST="$DT_LIST kde_samonitor_service"
	DT_LIST="$DT_LIST gnome_samonitor_service"
    fi
    if has_feature ADMINTOOLS ; then
	DT_LIST="$DT_LIST dbisql"
	DT_LIST="$DT_LIST scjview"
	DT_LIST="$DT_LIST dbconsole"
	DT_LIST="$DT_LIST mlprof"
    fi

    # Everybody except SAMonitor standalone has the following
    if not is_selected_option OPT_SAMON_DEPLOY ; then
	DT_LIST="$DT_LIST check_for_updates"
	DT_LIST="$DT_LIST dcx"
	DT_LIST="$DT_LIST download_documentation"
	DT_LIST="$DT_LIST online_resources"
    fi

    # Everybody has the following
    DT_LIST="$DT_LIST readme"
    DT_LIST="$DT_LIST html_contents"
    DT_LIST="$DT_LIST pdf_contents"

    # We decided to set these down to be activated later by the doc installer
    DT_LIST="$DT_LIST kde_sqlany_documentation"
    DT_LIST="$DT_LIST gnome_sqlany_documentation"

    for item in $DT_LIST; do
	if [ -n "${item:-}" ] ; then
	    eval `echo writedesktopfile_$item`
	fi
    done
}

create_SA_menu_descriptor()
###########################
# The .directory file for a menu is similar to a .desktop file for a menu item.
# It is a descriptor that allows you to specify an Icon, Name and Tooltip.
# For the top-level SA menu, we provide one so we can change the icon
{
    DESKTOP_FILEPATH="$XDG_DATA_HOME/desktop-directories/${VENDORID}-${PRODNAME}.directory"
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/SQLAnywhere.png"

    create_user_directory `dirname "$DESKTOP_FILEPATH"`
    create_user_file "$DESKTOP_FILEPATH"

    echo "[Desktop Entry]" > "$DESKTOP_FILEPATH"
    echo "Encoding=UTF-8">> "$DESKTOP_FILEPATH"
    echo "Version=1.0">> "$DESKTOP_FILEPATH"
    echo "Type=Directory">> "$DESKTOP_FILEPATH"

    echo "Name=${PRODNAME}">> "$DESKTOP_FILEPATH"
    # This controls what is shown in the ToolTip
    echo "Comment=${PRODNAME}">> "$DESKTOP_FILEPATH"
    echo "Icon=${DT_ENTRY_ICON_PATH}">> "$DESKTOP_FILEPATH"
}

create_AT_menu_descriptor()
###########################
# The .directory file for a menu is similar to a .desktop file for a menu item.
# It is a descriptor that allows you to specify an Icon, Name and Tooltip.
# For the Admin Tools sub-menu, we provide one so we can change the icon and localize its name
# Note that this one is localized whereas the SA menu is not.
{
    DESKTOP_FILEPATH="$XDG_DATA_HOME/desktop-directories/${VENDORID}-${PRODNAME}-Administration Tools.directory"
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/SQLAnywhere.png"

    create_user_directory `dirname "$DESKTOP_FILEPATH"`
    create_user_file "$DESKTOP_FILEPATH"

    echo "[Desktop Entry]" > "$DESKTOP_FILEPATH"
    echo "Encoding=UTF-8">> "$DESKTOP_FILEPATH"
    echo "Version=1.0">> "$DESKTOP_FILEPATH"
    echo "Type=Directory">> "$DESKTOP_FILEPATH"

    echo "Name=${MSG_ICON_ADMINTOOLS}">> "$DESKTOP_FILEPATH"
    # This controls what is shown in the ToolTip

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_ADMINTOOLS
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_ADMINTOOLS
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_ADMINTOOLS
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_ADMINTOOLS
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_ADMINTOOLS
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_ADMINTOOLS
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
cat <<-EOD > "$DESKTOP_FILEPATH"
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Directory
Name=${DESC_UTF8}
Comment=${DESC_UTF8}
EOD
    echo "Name[en]=$EN_DESC_UTF8"				>> "$DESKTOP_FILEPATH"
    [ -n "$DE_DESC_UTF8" ] && echo "Name[de]=$DE_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$JA_DESC_UTF8" ] && echo "Name[ja]=$JA_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$ZH_DESC_UTF8" ] && echo "Name[zh_CN]=$ZH_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$FR_DESC_UTF8" ] && echo "Name[fr]=$FR_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    echo "Comment=${DESC_UTF8}"					    >> "$DESKTOP_FILEPATH"
    echo "Comment[en]=$EN_DESC_UTF8"				    >> "$DESKTOP_FILEPATH"
    [ -n "$DE_DESC_UTF8" ] && echo "Comment[de]=$DE_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    [ -n "$JA_DESC_UTF8" ] && echo "Comment[ja]=$JA_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    [ -n "$ZH_DESC_UTF8" ] && echo "Comment[zh_CN]=$ZH_DESC_UTF8"   >> "$DESKTOP_FILEPATH"
    [ -n "$FR_DESC_UTF8" ] && echo "Comment[fr]=$FR_DESC_UTF8"   >> "$DESKTOP_FILEPATH"
}

create_DOC_menu_descriptor()
############################
# The .directory file for a menu is similar to a .desktop file for a menu item.
# It is a descriptor that allows you to specify an Icon, Name and Tooltip.
# For the "Documentation" sub-menu, we provide one so we can change the icon and localize its name
# Note that this one is localized whereas the SA menu is not.
{
    DESKTOP_FILEPATH="$XDG_DATA_HOME/desktop-directories/${VENDORID}-${PRODNAME}-Documentation.directory"
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/SQLAnywhere.png"

    create_user_directory `dirname "$DESKTOP_FILEPATH"`
    create_user_file "$DESKTOP_FILEPATH"

    echo "[Desktop Entry]" > "$DESKTOP_FILEPATH"
    echo "Encoding=UTF-8">> "$DESKTOP_FILEPATH"
    echo "Version=1.0">> "$DESKTOP_FILEPATH"
    echo "Type=Directory">> "$DESKTOP_FILEPATH"

    echo "Name=${MSG_ICON_DOCUMENTATION}">> "$DESKTOP_FILEPATH"
    # This controls what is shown in the ToolTip

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_DOCUMENTATION
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_DOCUMENTATION
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_DOCUMENTATION
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_DOCUMENTATION
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_DOCUMENTATION
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_DOCUMENTATION
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
cat <<-EOD > "$DESKTOP_FILEPATH"
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Directory
Name=${DESC_UTF8}
Comment=${DESC_UTF8}
EOD
    echo "Name[en]=$EN_DESC_UTF8"				>> "$DESKTOP_FILEPATH"
    [ -n "$DE_DESC_UTF8" ] && echo "Name[de]=$DE_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$JA_DESC_UTF8" ] && echo "Name[ja]=$JA_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$ZH_DESC_UTF8" ] && echo "Name[zh_CN]=$ZH_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    [ -n "$FR_DESC_UTF8" ] && echo "Name[fr]=$FR_DESC_UTF8"	>> "$DESKTOP_FILEPATH"
    echo "Comment=${DESC_UTF8}"					    >> "$DESKTOP_FILEPATH"
    echo "Comment[en]=$EN_DESC_UTF8"				    >> "$DESKTOP_FILEPATH"
    [ -n "$DE_DESC_UTF8" ] && echo "Comment[de]=$DE_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    [ -n "$JA_DESC_UTF8" ] && echo "Comment[ja]=$JA_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    [ -n "$ZH_DESC_UTF8" ] && echo "Comment[zh_CN]=$ZH_DESC_UTF8"   >> "$DESKTOP_FILEPATH"
    [ -n "$FR_DESC_UTF8" ] && echo "Comment[fr]=$FR_DESC_UTF8"   >> "$DESKTOP_FILEPATH"
}

create_SA_menu_file()
#####################
# $* -> list of .desktop files
{
    MENU_FILEPATH="$XDG_CONFIG_HOME/menus/applications-merged/${VENDORID}-${PRODNAME}.menu"

    create_user_directory `dirname "$MENU_FILEPATH"`
    create_user_file "$MENU_FILEPATH"

    cat <<-EOD > "$MENU_FILEPATH"
<!DOCTYPE Menu
  PUBLIC '-//freedesktop//DTD Menu 1.0//EN'
  'http://standards.freedesktop.org/menu-spec/menu-1.0.dtd'>
<Menu>
  <Name>Applications</Name>
  <Menu>
	<Name>${PRODNAME}</Name>
	<Directory>${VENDORID}-${PRODNAME}.directory</Directory>
	<DirectoryDir>$XDG_DATA_HOME/desktop-directories</DirectoryDir>
	<Include>
	    <Filename>${VENDORID}-Check for Updates.desktop</Filename>
	    <Filename>${VENDORID}-Read Me.desktop</Filename>
EOD
    if is_selected_option OPT_SAMON_DEPLOY ; then
    cat <<-EOD >> "$MENU_FILEPATH"
	    <Filename>${VENDORID}-SQL Anywhere Monitor-GNOME.desktop</Filename>
	    <Filename>${VENDORID}-SQL Anywhere Monitor-KDE.desktop</Filename>
EOD
    else
    cat <<-EOD >> "$MENU_FILEPATH"
	    <Filename>${VENDORID}-Network Server (32-bit)-GNOME.desktop</Filename>
	    <Filename>${VENDORID}-Network Server (32-bit)-KDE.desktop</Filename>
	    <Filename>${VENDORID}-Network Server (64-bit)-GNOME.desktop</Filename>
	    <Filename>${VENDORID}-Network Server (64-bit)-KDE.desktop</Filename>
	    <Filename>${VENDORID}-Personal Server (32-bit)-GNOME.desktop</Filename>
	    <Filename>${VENDORID}-Personal Server (32-bit)-KDE.desktop</Filename>
	    <Filename>${VENDORID}-Personal Server (64-bit)-GNOME.desktop</Filename>
	    <Filename>${VENDORID}-Personal Server (64-bit)-KDE.desktop</Filename>
EOD
    fi
    cat <<-EOD >> "$MENU_FILEPATH"
	</Include>

EOD

    if not is_selected_option OPT_SAMON_DEPLOY ; then
    cat <<-EOD >> "$MENU_FILEPATH"
	<Menu>
	    <Name>Administration Tools</Name>
	    <Directory>${VENDORID}-${PRODNAME}-Administration Tools.directory</Directory>
	    <DirectoryDir>$XDG_DATA_HOME/desktop-directories</DirectoryDir>
            <Include>
		<Filename>${VENDORID}-Sybase Central (32-bit).desktop</Filename>
		<Filename>${VENDORID}-Sybase Central (64-bit).desktop</Filename>
		<Filename>${VENDORID}-Interactive SQL (32-bit).desktop</Filename>
		<Filename>${VENDORID}-Interactive SQL (64-bit).desktop</Filename>
		<Filename>${VENDORID}-MobiLink Profiler (32-bit).desktop</Filename>
		<Filename>${VENDORID}-MobiLink Profiler (64-bit).desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Console (32-bit).desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Console (64-bit).desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Monitor (32-bit)-GNOME.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Monitor (64-bit)-GNOME.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Monitor (32-bit)-KDE.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Monitor (64-bit)-KDE.desktop</Filename>
            </Include>
	</Menu>
	<Menu>
	    <Name>Documentation</Name>
	    <Directory>${VENDORID}-${PRODNAME}-Documentation.directory</Directory>
	    <DirectoryDir>$XDG_DATA_HOME/desktop-directories</DirectoryDir>
            <Include>
		<Filename>${VENDORID}-DocCommentXchange.desktop</Filename>
		<Filename>${VENDORID}-Download Documentation.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Online Resources.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Documentation-GNOME.desktop</Filename>
		<Filename>${VENDORID}-SQL Anywhere Documentation-KDE.desktop</Filename>
            </Include>
	</Menu>
EOD

    fi

    cat <<-EOD >> "$MENU_FILEPATH"
    </Menu>
</Menu>
EOD
}

pre_install_icons()
###################
{
    MENUITEM_INSTALLED=0
    DESKTOP_FILELIST=

    INSTALLDIR=`get_install_dir SA`
    if [ `is_world_readable "$INSTALLDIR"` = "1" ]; then
	WANT_ALL_USERS_ICONS=yes
    else
	WANT_ALL_USERS_ICONS=no
    fi
    
    #
    # Initialize XDG variables
    #
    # See http://standards.freedesktop.org/basedir-spec/latest/index.html
    if [ "$XDG_DATA_HOME" = "" ]; then
	if [ -w /usr/share ] && [ "$WANT_ALL_USERS_ICONS" = "yes" ]; then
	    XDG_DATA_HOME=/usr/share
	else
	    XDG_DATA_HOME=`real_user_homedir`/.local/share
	fi
    fi
    if [ "$XDG_CONFIG_HOME" = "" ]; then
	if [ -w /etc/xdg ] && [ "$WANT_ALL_USERS_ICONS" = "yes" ]; then
	    XDG_CONFIG_HOME=/etc/xdg
	else
	    XDG_CONFIG_HOME=`real_user_homedir`/.config
	fi
    fi
    # If "Desktop" and "Documents" are localized, (eg. on RedHat) their translations should be here
    # see http://www.freedesktop.org/wiki/Software/xdg-user-dirs
    test -f ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs && source ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs
    XDG_DESKTOP_DIR=${XDG_DESKTOP_DIR:-$HOME/Desktop}
    XDG_DOWNLOAD_DIR=${XDG_DOWNLOAD_DIR:-$HOME}
    
    PRODNAME=`get_menu_name`
    PRODUCTID=
    [ "`get_install_type`" = "SAMON" ] && PRODUCTID=samon-
    VENDORID=ianywhere-$PRODUCTID`get_major_version`
    if [ -d "$XDG_DATA_HOME"/applications ] ; then
        pushd_quiet "$XDG_DATA_HOME"/applications
        for oi in `/bin/ls -1F | grep "${VENDORID}-" | sed 's/ /_/g'` ; do
	    oi="`echo ${oi} | sed 's/_/ /g'`"
	    DESKTOP_FILELIST="${DESKTOP_FILELIST} '${oi}'"
        done
        popd_quiet
    fi
}

post_install_icons()
####################
{
    true
}

install_icons()
###############
{
    if not has_feature ICONS; then
	return
    fi

    INSTALLDIR=`get_install_dir SA`
    INSTALLDIR_UTF8=`convert_to_utf8 "$INSTALLDIR"`

    pre_install_icons

    # For the case where this is called during upgrade installs, 
    # we will not have prompted them about creating icons.
    # Check to see if our submenu file is already there; if it is there,
    # allow writing icons.  If it was not already there, do not write new icons
    if is_upgrade; then
	[ ! -r "$XDG_CONFIG_HOME/menus/applications-merged/${VENDORID}-${PRODNAME}.menu" ] && return;
    fi

    for ICONBITNESS in 64 32; do
	BINDIR="$INSTALLDIR/bin${ICONBITNESS}"
	BINDIR_UTF8=`convert_to_utf8 "$BINDIR"`
	BINsDIR="$INSTALLDIR/bin${ICONBITNESS}s"
	BINsDIR_UTF8=`convert_to_utf8 "$BINsDIR"`
	if [ ! -d "$BINsDIR" ] ; then
	    continue
	fi
	writealldesktopfiles
    done

    if [ "$MENUITEM_INSTALLED" = "1" ]; then
	eval create_SA_menu_file $DESKTOP_FILELIST

	create_SA_menu_descriptor
	if has_feature ADMINTOOLS ; then
	    create_AT_menu_descriptor
	fi
	create_DOC_menu_descriptor
    fi

    post_install_icons
}

enable_doc_icons()
##################
{
    if not has_feature ICONS; then
	return
    fi

    INSTALLDIR=`get_install_dir SA`
    INSTALLDIR_UTF8=`convert_to_utf8 "$INSTALLDIR"`

    # get XDG_CONFIG_HOME, XDG_DATA_HOME, VENDORID etc.
    pre_install_icons

    # We decided that the Doc installer will not prompt about creating icons.
    # It will check to see if the SA submenu file is already there; if it is there,
    # it will turn on the dormant doc icons that are in it.  
    # If the SA menu is not already there, return without doing anything
    SA_PRODNAME="SQL Anywhere `get_major_version`"
    [ ! -r "$XDG_CONFIG_HOME/menus/applications-merged/${VENDORID}-${SA_PRODNAME}.menu" ] && return;

    if [ -d "$XDG_DATA_HOME"/applications ] ; then
	pushd_quiet "$XDG_DATA_HOME"/applications
	    sed -i '/NoDisplay/d' "${VENDORID}-SQL Anywhere Documentation-KDE.desktop"
	    sed -i '/NoDisplay/d' "${VENDORID}-SQL Anywhere Documentation-GNOME.desktop"
	popd_quiet
    fi

    post_install_icons
}

# Note: "Comment" controls what is shown in the ToolTip
# Note: "Path" sets the Working directory ...
writedesktopfile_kde_dbeng()
{
    KEYFILE=dbeng`get_major_version`
    SWITCHES=-ui

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    if is_redflag; then
	DT_ENTRY_TERMINAL=false
    else
	DT_ENTRY_TERMINAL=true
    fi
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SQLAnywhere.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_gnome_dbeng()
{
    KEYFILE=dbeng`get_major_version`
    SWITCHES=-ui

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SQLAnywhere.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_PERSONAL_SERVER_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_kde_dbsrv()
{
    KEYFILE=dbsrv`get_major_version`
    SWITCHES=-ui

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    if is_redflag; then
	DT_ENTRY_TERMINAL=false
    else
	DT_ENTRY_TERMINAL=true
    fi
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SQLAnywhereServer.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_gnome_dbsrv()
{
    KEYFILE=dbsrv`get_major_version`
    SWITCHES=-ui

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SQLAnywhereServer.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_NETWORK_SERVER_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_kde_srvmon_start()
{
    KEYFILE=samonitor.sh
    SWITCHES="start"

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    if is_redflag; then
	DT_ENTRY_TERMINAL=false
    else
	DT_ENTRY_TERMINAL=true
    fi
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_START_SERVER_MONITOR
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_START_SERVER_MONITOR
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_START_SERVER_MONITOR
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_START_SERVER_MONITOR
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_START_SERVER_MONITOR
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_START_SERVER_MONITOR
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_gnome_srvmon_start()
{
    KEYFILE=samonitor.sh
    SWITCHES="start"

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_START_SERVER_MONITOR
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_START_SERVER_MONITOR
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_START_SERVER_MONITOR
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_START_SERVER_MONITOR
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_START_SERVER_MONITOR
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_START_SERVER_MONITOR
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_kde_samonitor()
{
    KEYFILE=samonitor
    SWITCHES="-d \"${INSTALLDIR_UTF8}/samonitor.db\""

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    if is_redflag; then
        DT_ENTRY_TERMINAL=false
    else
        DT_ENTRY_TERMINAL=true
    fi
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_gnome_samonitor()
{
    KEYFILE=samonitor
    SWITCHES="-d \"${INSTALLDIR_UTF8}/samonitor.db\""

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SERVER_MONITOR_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_kde_samonitor_service()
{
    KEYFILE=samonitor
    SWITCHES="-s SAMonitor`get_version`"

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=true
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SERVER_MONITOR
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SERVER_MONITOR
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SERVER_MONITOR
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SERVER_MONITOR
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SERVER_MONITOR
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SERVER_MONITOR
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_gnome_samonitor_service()
{
    KEYFILE=samonitor
    SWITCHES="-s SAMonitor`get_version`"

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SERVER_MONITOR
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SERVER_MONITOR
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SERVER_MONITOR
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SERVER_MONITOR
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SERVER_MONITOR
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SERVER_MONITOR
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
}

writedesktopfile_start_srvmon_app()
{
    #
    # Start Server Monitoring Application
    # 
    DOCFILE="http://localhost:4950"

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" $DOCFILE"
    DT_WORKING_DIRECTORY=

    ICN=SAMonitor16.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_SERVER_MONITOR_CONSOLE
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SERVER_MONITOR_CONSOLE
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SERVER_MONITOR_CONSOLE
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SERVER_MONITOR_CONSOLE
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SERVER_MONITOR_CONSOLE
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_SERVER_MONITOR_CONSOLE
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_dbisql()
{
    KEYFILE=dbisql
    SWITCHES=

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=InteractiveSQL.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_DBISQL_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_scjview()
{
    KEYFILE=scjview
    SWITCHES=
    # Note this is also called from sybasecentral.sh for desktop icon
    DESKTOP_FILEDIR="${1:-${XDG_DATA_HOME}/applications}"

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=SybaseCentral.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_SCENTRAL_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$DESKTOP_FILEDIR/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_dbconsole()
{
    KEYFILE=dbconsole
    SWITCHES=

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=DBConsole.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_DBCONSOLE_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_mlprof()
{
    KEYFILE=mlprof
    SWITCHES=

    if [ ! -r "${BINsDIR}/$KEYFILE" ]; then
	return
    fi

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${BINsDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINsDIR_UTF8}"

    ICN=MobiLinkMonitor.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_MLPROF_${ICONBITNESS}BIT
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_MLPROF_${ICONBITNESS}BIT
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_MLPROF_${ICONBITNESS}BIT
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_MLPROF_${ICONBITNESS}BIT
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_MLPROF_${ICONBITNESS}BIT
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_MLMON_${ICONBITNESS}BIT
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_readme()
{
    # 
    # Readme
    # 
    LANGCODE=`get_lang_code`
    if [ -r "$INSTALLDIR/readme_$LANGCODE.txt" ]; then
	DOCFILE="$INSTALLDIR/readme_$LANGCODE.txt" 
    elif [ -r "$INSTALLDIR/readme.txt" ]; then
	DOCFILE="$INSTALLDIR/readme.txt" 
    else
	DOCFILE=
    fi
    if [ ! -r "$DOCFILE"  ]; then
	return
    fi
    DOCFILE_UTF8=`convert_to_utf8 "$DOCFILE"`

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"${DOCFILE_UTF8}\""
    DT_WORKING_DIRECTORY=`dirname "${DOCFILE_UTF8}"`

#    ICN=SQLAnywhere.png
#    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"
    DT_ENTRY_ICON_PATH=

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_READ_ME
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_READ_ME
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_READ_ME
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_READ_ME
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_READ_ME
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_READ_ME
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_online_resources()
{
    #
    # iAnywhere Online Resources
    # 
    LANGCODE=`get_lang_code`
    if [ -r "$INSTALLDIR/support/$LANGCODE/OnlineResources.html" ]; then
	DOCFILE="$INSTALLDIR/support/$LANGCODE/OnlineResources.html" 
    elif [ -r "$INSTALLDIR/support/en/OnlineResources.html" ]; then
	DOCFILE="$INSTALLDIR/support/en/OnlineResources.html" 
    else
	DOCFILE=
    fi
    if [ ! -r "$DOCFILE"  ]; then
	return
    fi
    DOCFILE_UTF8=`convert_to_utf8 "$DOCFILE"`

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"${DOCFILE_UTF8}\""
    DT_WORKING_DIRECTORY=`dirname "${DOCFILE_UTF8}"`

#    ICN=SQLAnywhere.png
#    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"
    DT_ENTRY_ICON_PATH=

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_ONLINE_RESOURCES
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_ONLINE_RESOURCES
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_ONLINE_RESOURCES
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_ONLINE_RESOURCES
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_ONLINE_RESOURCES
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_ONLINE_RESOURCES
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_html_contents()
{
    #
    # HTML contents.htm
    # 
    LANGCODE=`get_lang_code`
    if [ -r "`get_install_dir DOCS`/$LANGCODE/html/contents.htm"  ]; then
	DOCFILE="`get_install_dir DOCS`/$LANGCODE/html/contents.htm"
    elif [ -r "`get_install_dir DOCS`/en/html/contents.htm" ]; then
	DOCFILE="`get_install_dir DOCS`/en/html/contents.htm" 
    else
	DOCFILE=
    fi
    if [ ! -r "$DOCFILE"  ]; then
	return
    fi
    DOCFILE_UTF8=`convert_to_utf8 "$DOCFILE"`

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"${DOCFILE_UTF8}\""
    DT_WORKING_DIRECTORY=`dirname "${DOCFILE_UTF8}"`

    ICN=SQLAnywhere.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_HELP_HTML
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_HELP_HTML
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_HELP_HTML
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_HELP_HTML
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_HELP_HTML
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_HELP_HTML
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_pdf_contents()
{
    #
    # PDF contents.htm
    # 
    LANGCODE=`get_lang_code`
    if [ -r "`get_install_dir DOCS`/$LANGCODE/pdf/contents.htm" ]; then
	DOCFILE="`get_install_dir DOCS`/$LANGCODE/pdf/contents.htm" 
    elif [ -r "`get_install_dir DOCS`/en/pdf/contents.htm" ]; then
	DOCFILE="`get_install_dir DOCS`/en/pdf/contents.htm" 
    else
	DOCFILE=
    fi
    if [ ! -r "$DOCFILE"  ]; then
	return
    fi
    DOCFILE_UTF8=`convert_to_utf8 "$DOCFILE"`

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"${DOCFILE_UTF8}\""
    DT_WORKING_DIRECTORY=`dirname "${DOCFILE_UTF8}"`

    ICN=SQLAnywhere.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_HELP_PDF
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_HELP_PDF
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_HELP_PDF
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_HELP_PDF
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_HELP_PDF
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_HELP_PDF
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_kde_sqlany_documentation()
{
    KEYFILE=sadoc
    SWITCHES=

    # in this case we want to plant the shortcut in the SA install even though sadoc is not there yet
    # i.e. we do not want to skip this code just because sadoc is not there yet

    DT_ENTRY_TERMINAL=false	    # sadoc script Does not use 'exec'
    DT_ENTRY_NOTSHOWIN="GNOME;"
    DT_ENTRY_ONLYSHOWIN="KDE;"
    DT_ENTRY_NODISPLAY="true"
    # Note: sadoc has no "binXXs" shortcut - just run it straight
    DT_ENTRY_EXEC="\"${BINDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINDIR_UTF8}"

    ICN=icon.xpm
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/eclipse/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SQLANY_DOCUMENTATION
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SQLANY_DOCUMENTATION
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SQLANY_DOCUMENTATION
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SQLANY_DOCUMENTATION
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SQLANY_DOCUMENTATION
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SQLANY_DOCUMENTATION
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-KDE.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_NODISPLAY=
}

writedesktopfile_gnome_sqlany_documentation()
{
    KEYFILE=sadoc
    SWITCHES=

    # in this case we want to plant the shortcut in the SA install even though sadoc is not there yet
    # i.e. we do not want to skip this code just because sadoc is not there yet

    DT_ENTRY_TERMINAL=false	    # sadoc script Does not use 'exec'
    DT_ENTRY_NOTSHOWIN="KDE;"
    DT_ENTRY_ONLYSHOWIN="GNOME;"
    DT_ENTRY_NODISPLAY="true"
    # Note: sadoc has no "binXXs" shortcut - just run it straight
    DT_ENTRY_EXEC="\"${BINDIR_UTF8}/$KEYFILE\" $SWITCHES"
    DT_WORKING_DIRECTORY="${BINDIR_UTF8}"

    ICN=icon.xpm
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/eclipse/$ICN"

    # Use the english description as the .desktop's filename
    BIT_SUFFIX=`eval echo ${ICONBITNESS}BIT`
    RESKEY=\$EN_MSG_ICON_SQLANY_DOCUMENTATION
    DESC=`eval echo $RESKEY`
    DESC=`eval echo $DESC`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_SQLANY_DOCUMENTATION
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`
    EN_DESC_UTF8=`eval echo $EN_DESC_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_SQLANY_DOCUMENTATION
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`
    DE_DESC_UTF8=`eval echo $DE_DESC_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_SQLANY_DOCUMENTATION
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`
    JA_DESC_UTF8=`eval echo $JA_DESC_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_SQLANY_DOCUMENTATION
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    ZH_DESC_UTF8=`eval echo $ZH_DESC_UTF8`

    FR_RESKEY_UTF8=\$FR_MSG_ICON_SQLANY_DOCUMENTATION
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`
    FR_DESC_UTF8=`eval echo $FR_DESC_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}-GNOME.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common

    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_NODISPLAY=
}

writedesktopfile_check_for_updates()
{
    #
    # Check for Updates
    # 
    LANGCODE=`get_lang_code`
    if [ -r "$INSTALLDIR/support/$LANGCODE/updchk.html" ]; then
	DOCFILE="$INSTALLDIR/support/$LANGCODE/updchk.html" 
    elif [ -r "$INSTALLDIR/support/en/updchk.html" ]; then
	DOCFILE="$INSTALLDIR/support/en/updchk.html" 
    else
	DOCFILE=
    fi
    if [ ! -r "$DOCFILE"  ]; then
	return
    fi
    DOCFILE_UTF8=`convert_to_utf8 "$DOCFILE"`

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"${DOCFILE_UTF8}\""
    DT_WORKING_DIRECTORY=`dirname "${DOCFILE_UTF8}"`

#    ICN=SQLAnywhere.png
#    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"
    DT_ENTRY_ICON_PATH=

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_UPSA
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_UPSA
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_UPSA
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_UPSA
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_UPSA
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_UPSA
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_dcx()
{
    #
    # DocCommentXchange
    # 
    LANGCODE=`get_lang_code`
    VERSION=`get_version`

    DOCFILE="http://dcx.sybase.com/sa${VERSION}/${LANGCODE}"

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"$DOCFILE\""
    DT_WORKING_DIRECTORY=

    ICN=SQLAnywhere.png
    DT_ENTRY_ICON_PATH="${INSTALLDIR_UTF8}/res/$ICN"

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_DCX
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_DCX
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_DCX
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_DCX
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_DCX
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_DCX
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

writedesktopfile_download_documentation()
{
    #
    # Download Documentation
    # 
    LANGCODE=`get_lang_code`
    VERSION=`get_version`

    if [ "$LANGCODE" = "ja" ]; then
	DOCFILE="http://www.ianywhere.jp/developers/product_manuals/sqlanywhere/index.html"
    else
	DOCFILE="http://www.sybase.com/detail?id=1099306"
    fi

    VIEWER=`find_viewer_app`

    # Don't create a shortcut to something that isn't there
    [ ! -r "${VIEWER}" ] && return

    DT_ENTRY_TERMINAL=false
    DT_ENTRY_NOTSHOWIN=
    DT_ENTRY_ONLYSHOWIN=
    DT_ENTRY_EXEC="\"${VIEWER}\" \"$DOCFILE\""
    DT_WORKING_DIRECTORY=

    ICN=
    DT_ENTRY_ICON_PATH=

    # Use the english description as the .desktop's filename
    RESKEY=\$EN_MSG_ICON_DOWNLOAD_DOCUMENTATION
    DESC=`eval echo $RESKEY`
    DESC_UTF8=`convert_to_utf8 "$DESC"`

    EN_RESKEY_UTF8=\$EN_MSG_ICON_DOWNLOAD_DOCUMENTATION
    EN_DESC_UTF8=`eval echo $EN_RESKEY_UTF8`

    DE_RESKEY_UTF8=\$DE_MSG_ICON_DOWNLOAD_DOCUMENTATION
    DE_DESC_UTF8=`eval echo $DE_RESKEY_UTF8`

    JA_RESKEY_UTF8=\$JA_MSG_ICON_DOWNLOAD_DOCUMENTATION
    JA_DESC_UTF8=`eval echo $JA_RESKEY_UTF8`

    ZH_RESKEY_UTF8=\$ZH_MSG_ICON_DOWNLOAD_DOCUMENTATION
    ZH_DESC_UTF8=`eval echo $ZH_RESKEY_UTF8`
    
    FR_RESKEY_UTF8=\$FR_MSG_ICON_DOWNLOAD_DOCUMENTATION
    FR_DESC_UTF8=`eval echo $FR_RESKEY_UTF8`

    DESKTOP_FILENAME="${VENDORID}-${DESC}.desktop"
    DESKTOP_FILEPATH="$XDG_DATA_HOME/applications/$DESKTOP_FILENAME"

    writedesktopfile_common
}

# Relies on variables being set up first by a writedesktopfile_* routine
writedesktopfile_common()
{
    # See http://standards.freedesktop.org/desktop-entry-spec/latest/ar01s05.html
    # for Standard Keys

    create_user_directory `dirname "$DESKTOP_FILEPATH"`
    create_user_file "$DESKTOP_FILEPATH"
    chmod +x "$DESKTOP_FILEPATH"

cat <<-EOD > "$DESKTOP_FILEPATH"
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Name=${DESC_UTF8}
EOD
    echo "Name[en]=$EN_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    if [ -n "$DE_DESC_UTF8" ]; then
	echo "Name[de]=$DE_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$JA_DESC_UTF8" ]; then
	echo "Name[ja]=$JA_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$ZH_DESC_UTF8" ]; then
	echo "Name[zh_CN]=$ZH_DESC_UTF8"    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$FR_DESC_UTF8" ]; then
	echo "Name[fr]=$FR_DESC_UTF8"    >> "$DESKTOP_FILEPATH"
    fi
    echo "Comment=${DESC_UTF8}"		    >> "$DESKTOP_FILEPATH"
    echo "Comment[en]=$EN_DESC_UTF8"	    >> "$DESKTOP_FILEPATH"
    if [ -n "$DE_DESC_UTF8" ]; then
	echo "Comment[de]=$DE_DESC_UTF8"    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$JA_DESC_UTF8" ]; then
	echo "Comment[ja]=$JA_DESC_UTF8"    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$ZH_DESC_UTF8" ]; then
	echo "Comment[zh_CN]=$ZH_DESC_UTF8" >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "$FR_DESC_UTF8" ]; then
	echo "Comment[fr]=$FR_DESC_UTF8" >> "$DESKTOP_FILEPATH"
    fi
cat <<-EOD >> "$DESKTOP_FILEPATH"
Icon=${DT_ENTRY_ICON_PATH}
Exec=${DT_ENTRY_EXEC}
Path=${DT_WORKING_DIRECTORY}
Terminal=${DT_ENTRY_TERMINAL}
EOD
    if [ -n "${DT_ENTRY_NOTSHOWIN}" ]; then
	echo "NotShowIn=${DT_ENTRY_NOTSHOWIN}"    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "${DT_ENTRY_ONLYSHOWIN}" ]; then
	echo "OnlyShowIn=${DT_ENTRY_ONLYSHOWIN}"    >> "$DESKTOP_FILEPATH"
    fi
    if [ -n "${DT_ENTRY_NODISPLAY}" ]; then
	echo "NoDisplay=${DT_ENTRY_NODISPLAY}"    >> "$DESKTOP_FILEPATH"
    fi

    MENUITEM_INSTALLED=1
    DESKTOP_FILELIST="$DESKTOP_FILELIST '${DESKTOP_FILENAME}'"
}
