# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
make_sa_config()
################
{
    FORCE=$1
    for bits in 32 64 ; do
	    BINDIR1=bin${bits}
	    BINDIR2=bin`opposite_bitness ${bits}`

# Except on AIX, always want 32-bit libdir first since 64-bit loader
# will know to skip 32-bit libraries but 32-bit loader is not as
# smart.  On AIX, neither loader is smart enough, so just put the
# native LIBDIR in the library path.

	    if [ `plat_os` = "aix" ]; then
		LIBDIR1=lib${bits}
		LIBDIR2=lib`opposite_bitness ${bits}`
	    else
		LIBDIR1=lib32
		LIBDIR2=lib64
	    fi

	    SQLANY_DIR=`get_install_dir SYSTEM`
    
	    # generate both sa_config and sample_env here
	    if [ -d "$SQLANY_DIR/$BINDIR1" ] ; then
		if [ "$FORCE" = "1" ] || [ ! -f "$SQLANY_DIR/$BINDIR1/sa_config.sh" ] || ( not is_modify && not is_upgrade && installer_question `msg_prompt_file_exists_overwrite "$SQLANY_DIR/$BINDIR1/sa_config.sh"` ) ; then
		    . "$MEDIA_ROOT/res/scripts/sh_support.sh"
		    create_configfile "$SQLANY_DIR/$BINDIR1/sa_config.sh" $BINDIR1 $BINDIR2 $LIBDIR1 $LIBDIR2 $bits
		    SAMPLES_DESTDIR=`get_install_dir SAMPLES`
		    DSTFILE="$SAMPLES_DESTDIR/sample_env${bits}.sh"
		    create_sa_sample_env_for_bitness "$DSTFILE" $BINDIR1 $BINDIR2 $LIBDIR1 $LIBDIR2 $bits
		fi

		if [ "$FORCE" = "1" ] || [ ! -f "$SQLANY_DIR/$BINDIR1/sa_config.csh" ] || ( not is_modify && not is_upgrade && installer_question `msg_prompt_file_exists_overwrite "$SQLANY_DIR/$BINDIR1/sa_config.csh"` ) ; then
		    . "$MEDIA_ROOT/res/scripts/csh_support.sh"
		    create_configfile "$SQLANY_DIR/$BINDIR1/sa_config.csh" $BINDIR1 $BINDIR2 $LIBDIR1 $LIBDIR2 $bits
		    SAMPLES_DESTDIR=`get_install_dir SAMPLES`
		    DSTFILE="$SAMPLES_DESTDIR/sample_env${bits}.csh"
		    create_sa_sample_env_for_bitness "$DSTFILE" $BINDIR1 $BINDIR2 $LIBDIR1 $LIBDIR2 $bits
		fi
	    fi

    done
}

create_configfile()
###################
# $1 file name
{
    # figure out which script we are creating
    if [ "`echo "$1" | grep \\.csh$`" != "" ]; then
	scripttype=csh
    else
	scripttype=sh
    fi 

    shell_shebang "$1"
    echo "#" >> "$1"

    # msg_copyright_header "$1"

    BIN="$2"
    BIN_OPP="$3"
    LIB="$4"
    LIB_OPP="$5"
    BIT="$6"

    SYSTEM=`get_install_dir SYSTEM`
    SAMPLES=`get_install_dir SAMPLES`
    JRE=`get_jre_dir DIR $BIT`
    JRELINK=`get_jre_dir LINK $BIT`
    SAVAR="SQLANY`get_major_version`"
    SASAMPVAR="SQLANYSAMP`get_major_version`"
    SASAMPENVFILE="\$HOME/.sqlanywhere`get_major_version`/sample_env${BIT}.${scripttype}"
    OCOS="`get_install_dir OCOS`"
    LDVAR=`plat_ld_var_name`

    # Setup SQLANY<ver>
    echo  >> "$1"
    echo "# $MSG_COMMENT_SA_LOCATION" >> "$1"
    shell_set $SAVAR "$SYSTEM" "$1"
    shell_export $SAVAR "$1"
    
    # Setup SQLANYSAMP<ver>
    echo >>  "$1"
    shell_source_check $SASAMPENVFILE "$1"
    shell_set_check $SASAMPVAR "$SAMPLES" "$1"
    shell_export $SASAMPVAR "$1"

    # Sybase Open Client / Open Server
    if [ -d "${OCOS}" ]; then
	echo >>  "$1"
	echo "# $MSG_ADDING_OCOS_TO_LIBPATH" >> "$1"
	shell_prepend_path $LDVAR "$OCOS/OCS-15_0/lib" "$1"
	shell_export $LDVAR "$1"

	echo  >> "$1"
	echo "# $MSG_COMMENT_OCOS_LOCATION." >> "$1"
	shell_prepend_path PATH "$OCOS/OCS-15_0/bin" "$1"
	shell_export PATH "$1"
	
	echo >> "$1"
	echo "# $MSG_OCOS_CHARSET_LIB_1" >> "$1" 
	echo "# $MSG_OCOS_CHARSET_LIB_2 " >> "$1"
	shell_set SYBASE "$OCOS" "$1"
	shell_export SYBASE "$1"
    fi
    
    # Setup PATH
    if [ -d "$SYSTEM/$BIN" ]; then
	echo  >> "$1"
	echo "# $MSG_COMMENT_SA_PATH" >> "$1"
	if [ -d "$SYSTEM/$BIN_OPP" ]; then
	    shell_prepend_path PATH "\$$SAVAR/$BINDIR1:\$$SAVAR/$BINDIR2" "$1"
	else
	    shell_prepend_path PATH "\$$SAVAR/$BINDIR1" "$1"
	fi
	shell_export PATH "$1"
    fi
    
    # Setup java related variables
    if [ -d "$JRE" ]; then 
	proc=`get_jre_dir LIBDIR $BIT`
	echo "" >> "$1"
	echo "# $MSG_DONT_COMMENT_SALIB" >> "$1"
	shell_prepend_path PATH "\$$SAVAR/$JRELINK/bin" "$1"
	shell_prepend_path $LDVAR "\$$SAVAR/$JRELINK/lib/${proc}/client:\$$SAVAR/$JRELINK/lib/${proc}/server:\$$SAVAR/$JRELINK/lib/${proc}:\$$SAVAR/$JRELINK/lib/${proc}/native_threads" "$1"
	shell_export PATH "$1"
	shell_set_check JAVA_HOME "\$$SAVAR/$JRELINK" "$1"
	shell_export JAVA_HOME "$1"
    fi

    # On platforms where both 32-bit and 64-bit are available to go into the library path,
    # it is cleaner to only add entries for the paths that were installed by the user
    [ -d "$SYSTEM/$LIB_OPP" ] && shell_prepend_path $LDVAR "\$$SAVAR/$LIB_OPP" "$1"
    [ -d "$SYSTEM/$LIB" ] && shell_prepend_path $LDVAR "\$$SAVAR/$LIB" "$1"
    shell_export $LDVAR "$1"

    # Mac OS X needs special environment variable for library loading
    if [ `plat_os` = "macos" ]; then
	echo  >> "$1"
	shell_set DYLD_BIND_AT_LAUNCH 1 "$1"
	shell_export DYLD_BIND_AT_LAUNCH "$1"
    fi
}

create_sh_samples_config_files()
################################
{
    if [ -d "`get_install_dir BIN32`" ] ; then
	create_sh_sample_config_for_bitness 32
    fi
    
    if [ -d "`get_install_dir BIN64`" ] ; then
	create_sh_sample_config_for_bitness 64
    fi
}

create_sh_sample_config_for_bitness()
#####################################
{
    BITS="${1}"
    OBITS=bin`opposite_bitness ${BITS}`
    SAMPLESDIR=`get_install_dir SAMPLES`    
    SA_CONFIGFILE="sa_config"
    SAMPLE_ENVFILE="sample_env${BITS}.sh"
    OSAMPLE_ENVFILE="sample_env`opposite_bitness ${BITS}`.sh"
    
    if [ ! -d "$SAMPLESDIR" ] ; then
        return;
    fi
    
    THISUSER=`whoami`
    THISUSER=${THISUSER:-user}
    HOMEDIR=\${HOME}
    
    SQLANY_VERSIONED="SQLANY`get_major_version`"
    SQLANYSAMP_VERSIONED="SQLANYSAMP`get_major_version`"
    DBENG_VERSIONED="dbeng`get_major_version`"
    SAMP_BINDIR="`get_install_dir BIN${BITS}`"

    SAMPLES_CONFIG="sample_config${BITS}.sh"
    
    # Put samples in $HOME/sa<ver>_samples
    DESTDIR_VERSIONED="$HOMEDIR/sa`get_major_version`_samples"
    
    # Figure out database / engine names
    SA_DBF_NAME="\$SAMPLES_DESTDIR/sqlanywhere/demo.db"
    SA_ENG_NAME=demo`get_major_version`_\$USER
    SA_DB_DESC="SQL Anywhere `get_major_version` Sample Database"
    UL_CUSTDB_DBF_NAME="\$SAMPLES_DESTDIR/ultralite/custdb/custdb.db"
    UL_CUSTDB_ENG_NAME=custdb`get_major_version`_\$USER
    UL_CUSTDB_DB_DESC="SQL Anywhere `get_major_version` CustDB"

    #
    # generate samples_config.sh
    #

    cat <<-EOF > "$SAMPLESDIR/$SAMPLES_CONFIG"
#!/bin/sh	

# Get general environment settings for SA
. "$SAMP_BINDIR/$SA_CONFIGFILE.sh"

# A single .db file cannot be started by multiple server processes.
# Each user should have their own copy of the sample databases
# This script creates the per-user copy and associated DSNs

DEFAULT_SAMPLES_DESTDIR="$DESTDIR_VERSIONED"
SAMPLES_DESTDIR=\$DEFAULT_SAMPLES_DESTDIR

EOF

    cat <<-'EOF' >> "$SAMPLESDIR/$SAMPLES_CONFIG"
# Override $HOME, $USER and $SAMPLES_DESTDIR if asked.  Support non-interactive mode.
# HOME is used for the DSNs
# USER is used for the Server names
# SAMPLES_DESTDIR is the location for the copy of the samples (defaults to be under $HOME)
DOPROMPT=1
while :
    do
    case $1 in
        "" )
            break
            ;;
        -home=* )
            HOME=`echo $1 | sed -e 's/^-home=//'`
            ;;
        -user=* )
            USER=`echo $1 | sed -e 's/^-user=//'`
            ;;
        -samples-destdir=* )
            SAMPLES_DESTDIR=`echo $1 | sed -e 's/^-samples-destdir=//'`
            ;;
        -noprompt )
            DOPROMPT=0
            ;;
    esac
    shift
done

EOF

    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

if [ \$DOPROMPT -eq 1 ]; then
    echo "$MSG_SAMPLES_DEST_DIR [\$SAMPLES_DESTDIR]: " | tr -d '\12'
    read SAMPLES_DESTDIR
fi
if [ "\$SAMPLES_DESTDIR" = "" ]; then
    SAMPLES_DESTDIR=\$DEFAULT_SAMPLES_DESTDIR
fi

echo "$MSG_SAMPLES_COPYING"
rm -rf "\${SAMPLES_DESTDIR}/sqlanywhere"
rm -rf "\${SAMPLES_DESTDIR}/mobilink"
rm -rf "\${SAMPLES_DESTDIR}/ultralite"
mkdir -p "\$SAMPLES_DESTDIR"
cp -R "\$${SQLANYSAMP_VERSIONED}"/* "\${SAMPLES_DESTDIR}/"
rm -f "\$SAMPLES_DESTDIR/$OSAMPLE_ENVFILE"
if [ `plat_os` = "macos" ]; then
    cp "\$${SQLANYSAMP_VERSIONED}/../System/demo."* "\${SAMPLES_DESTDIR}/sqlanywhere"
else
    cp "\$${SQLANYSAMP_VERSIONED}/../demo."* "\${SAMPLES_DESTDIR}/sqlanywhere"
fi

chmod -R u+w "\$SAMPLES_DESTDIR"
chown -R \$USER "\$SAMPLES_DESTDIR"
echo "$MSG_DONE"
echo

# Set up the ODBCINI environment variable if it is not set - assume ~/.odbc.ini for User DSNs
if [ -z "\$ODBCINI" ]; then
    ODBCINI=\${HOME}/.odbc.ini
    export ODBCINI
fi

EOF

# Special case Mac OS X since we only have 32-bit SA server there
if [ `plat_os` = "macos" ] ; then
    if has_feature SA_SERVER_32 ; then

    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

# Set up the Demo ODBC data sources

echo "$MSG_DATA_SOURCES"
echo

dbdsn -y -w "SQL Anywhere `get_major_version` Demo" -c "UID=DBA;PWD=sql;DBF="$SA_DBF_NAME";SERVERNAME=$SA_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin32/$DBENG_VERSIONED";Description=$SA_DB_DESC"

dbdsn -y -w "SQL Anywhere `get_major_version` CustDB" -c "UID=ml_server;PWD=sql;DBF="$UL_CUSTDB_DBF_NAME";SERVERNAME=$UL_CUSTDB_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin32/$DBENG_VERSIONED";Description=$UL_CUSTDB_DB_DESC"

EOF

    fi

elif has_feature SA_SERVER_`echo $BITS` ; then
    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

# Set up the Demo ODBC data sources

echo "$MSG_DATA_SOURCES"
echo

dbdsn -y -w "SQL Anywhere `get_major_version` Demo" -c "UID=DBA;PWD=sql;DBF="$SA_DBF_NAME";SERVERNAME=$SA_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin${BITS}/$DBENG_VERSIONED";Description=$SA_DB_DESC"

dbdsn -y -w "SQL Anywhere `get_major_version` CustDB" -c "UID=ml_server;PWD=sql;DBF="$UL_CUSTDB_DBF_NAME";SERVERNAME=$UL_CUSTDB_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin${BITS}/$DBENG_VERSIONED";Description=$UL_CUSTDB_DB_DESC"

EOF

elif has_feature SA_SERVER_`echo $OBITS` ; then
    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

# Set up the Demo ODBC data sources

echo "$MSG_DATA_SOURCES"
echo

dbdsn -y -w "SQL Anywhere `get_major_version` Demo" -c "UID=DBA;PWD=sql;DBF="$SA_DBF_NAME";SERVERNAME=$SA_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin${OBITS}/$DBENG_VERSIONED";Description=$SA_DB_DESC"

dbdsn -y -w "SQL Anywhere `get_major_version` CustDB" -c "UID=ml_server;PWD=sql;DBF="$UL_CUSTDB_DBF_NAME";SERVERNAME=$UL_CUSTDB_ENG_NAME;START="\$${SQLANY_VERSIONED}/bin${OBITS}/$DBENG_VERSIONED";Description=$UL_CUSTDB_DB_DESC"

EOF

fi

    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

echo "$MSG_DONE"
echo

EOF

    cat <<-EOF >> "$SAMPLESDIR/$SAMPLES_CONFIG"

echo "$MSG_SAMPLE_ENV"

    #
    # generate sample_env script for this bitness 
    #

    echo "#!/bin/sh"	> "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"
    echo ""		>> "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"
    echo "# Set up the SQLANYSAMP`get_major_version` env var for samples that may need"		    >> "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"
    echo "SQLANYSAMP`get_major_version`=\$SAMPLES_DESTDIR"		>> "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"
    echo "export SQLANYSAMP`get_major_version`"		    >> "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"

# Get environment settings for samples
. "\$SAMPLES_DESTDIR/$SAMPLE_ENVFILE"

echo "$MSG_DONE"
echo

EOF

    chmod a+x "$SAMPLESDIR/$SAMPLES_CONFIG"

}

create_sa_sample_env_for_bitness()
###################################
{
    SAMPLE_ENVFILE="$1"
    BIN="$2"
    BIN_OPP="$3"
    LIB="$4"
    LIB_OPP="$5"
    BIT="$6"

    #
    # generate the template/master copy of sample_env in the samples/ directory
    #
    
    MAJORVER=`get_major_version`
    SAMPLES_DESTDIR=`get_install_dir SAMPLES`
    SASAMPVAR="SQLANYSAMP${MAJORVER}"

    if [ ! -d "$SAMPLES_DESTDIR" ] ; then
        return;
    fi

    shell_shebang "$1"
    echo "#" >> "$1"
    echo "# Set up the $SASAMPVAR env var for samples that may need it" >> "$1"
    shell_set $SASAMPVAR "$SAMPLES_DESTDIR" "$1"
    shell_export $SASAMPVAR "$1"

    chmod a+wx "$SAMPLE_ENVFILE"

    if [ -r "$HOME" ] ; then
	mkdir -p "$HOME/.sqlanywhere${MAJORVER}"
	cp -fp "$SAMPLE_ENVFILE" "$HOME/.sqlanywhere${MAJORVER}"
    fi
}

create_start_mobilink_scripts()
###############################
{
    if has_feature MOBILINK_SERVER_32 ; then
	create_start_mobilink_script_for_bitness 32
    fi
    
    if has_feature MOBILINK_SERVER_64 ; then
	create_start_mobilink_script_for_bitness 64
    fi
}

create_start_mobilink_script_for_bitness()
##########################################
{
    #
    # generate "Start MobiLink with Messaging" shortcut (script)
    #
    # use UID=ml_server;PWD=sql together with dsn= so that the sample
    # will keep working even if the user has set SQLCONNECT 
    #
    BITS="${1}"
    
}

generate_java_launcher_stub()
#############################
{
    TOOL=$1

    SADIR=`get_install_dir SA`
    SYSTEMDIR=`get_install_dir SYSTEM`
    STUB_LAUNCHER="$TOOL/Contents/MacOS/sa_java_stub_launcher.sh"
    local tool_launcher

    case $TOOL in
        DBConsole.app )
            tool_launcher=dbconsole
            ;;
        InteractiveSQL.app )
            tool_launcher=dbisql
            ;;
        MobiLinkProfiler.app )
            tool_launcher=mlprof
            ;;
        SybaseCentral.app )
            tool_launcher=scjview
            ;;
    esac

    cat <<-EOF > "$STUB_LAUNCHER"
#!/bin/sh

. "$SYSTEMDIR/bin64/sa_config.sh"
exec "$SYSTEMDIR/bin64/${tool_launcher}"

EOF
    chmod +x "$STUB_LAUNCHER"
}

macos_app_setup() 
#################
{
    if [ `plat_os` = "macos" ] ; then
	SQLANY_DIR=`get_install_dir SA`
	SAMPLESDIR=`get_install_dir SAMPLES`

	defaults write com.ianywhere.sqlanywhere`get_version`.dblauncher SQLAnyLocation -string "$SQLANY_DIR"
	defaults write com.ianywhere.sqlanywhere`get_version`.syncconsole SQLAnyLocation -string "$SQLANY_DIR"

	JAVA_TOOLS="DBConsole.app InteractiveSQL.app MobiLinkProfiler.app SybaseCentral.app"
	pushd_quiet "$SQLANY_DIR" 
    	for JAVA_TOOL in $JAVA_TOOLS; do
	    info_plist_file="$JAVA_TOOL/Contents/Info.plist"
	    if [ -r $info_plist_file ]; then
		chmod u+w $info_plist_file
		cp -p $info_plist_file "$info_plist_file".template
		cat "$info_plist_file".template | sed -e "s@\$SQLANY@${SQLANY_DIR}/System@g" -e "s@SAVER@`get_version`@g"> "$info_plist_file"
	    fi

	    if [ -r "$JAVA_TOOL" ]; then
		generate_java_launcher_stub "$JAVA_TOOL"
	    fi
	done
	popd_quiet

	pushd_quiet "$SAMPLESDIR" 
	sed -i "" -e "s@\$(SQLANY..)/..@${SQLANY_DIR}@g" ultralite/custdb/iphone/CustDB.xcodeproj/project.pbxproj >/dev/null 2>&1 
	sed -i "" -e "s@\$(SQLANY..)/..@${SQLANY_DIR}@g" ultralite/names/Names.xcodeproj/project.pbxproj >/dev/null 2>&1 
	popd_quiet
    fi
}

create_sybcentral_resfile()
###########################
{
    # We should only ever have one "bitness" of Java Tools at a time
    # (at time of writing)

    NN=`get_major_version`
    NNNN=`get_major_version`00

    for bits in 32 64 ; do

    BINDIR=bin${bits}
    BINPATH="`get_install_dir BIN${bits}`"

    if [ -f "${BINPATH}/scjview" ]; then
	RESFILE="${BINPATH}/.scRepository${NNNN}_${bits}"
    else 
	continue
    fi
    
    if [ -f "$RESFILE" ] ; then
	if is_modify || is_upgrade || not installer_question `msg_prompt_file_exists_overwrite "$RESFILE"` ; then
	    continue
	fi
    fi

    cat <<-SYBCENTRAL_RES_FILE  > "$RESFILE"
#
#
SCRepositoryInfo/Version=4
#
#
ConnectionProfiles/SQL Anywhere $NN Demo/FirstTimeStart=false
ConnectionProfiles/SQL Anywhere $NN Demo/Name=SQL Anywhere $NN Demo
ConnectionProfiles/SQL Anywhere $NN Demo/ProviderId=sqlanywhere${NNNN}
ConnectionProfiles/SQL Anywhere $NN Demo/Provider=SQL Anywhere $NN
ConnectionProfiles/SQL Anywhere $NN Demo/Description=Connection Profile for SQL Anywhere $NN Demo database
ConnectionProfiles/SQL Anywhere $NN Demo/Data/ConnectionProfileSettings=DSN\eSQL^0020Anywhere^0020`get_major_version`^0020Demo;UID\eDBA;PWD\e35c624d517fb
ConnectionProfiles/SQL Anywhere $NN Demo/Data/ConnectionProfileName=SQL Anywhere $NN Demo
ConnectionProfiles/SQL Anywhere $NN Demo/Data/ConnectionProfileType=SQL Anywhere
#
SYBCENTRAL_RES_FILE

    done
}

create_sybcentral_jprs()
########################
{
    BIN32S=`get_install_dir BIN32S`
    BIN64S=`get_install_dir BIN64S`
    JAVA=`get_install_dir JAVA`
    if [ -f "$BIN64S/scjview" ]; then
	BIN_S=$BIN64S
    else
	BIN_S=$BIN32S
    fi
  
    BATIK_JARS="batik-anim.jar batik-awt-util.jar batik-bridge.jar"
    BATIK_JARS="$BATIK_JARS batik-codec.jar batik-css.jar batik-dom.jar"
    BATIK_JARS="$BATIK_JARS batik-ext.jar batik-extension.jar"
    BATIK_JARS="$BATIK_JARS batik-gui-util.jar batik-gvt.jar batik-parser.jar"
    BATIK_JARS="$BATIK_JARS batik-script.jar batik-svg-dom.jar"
    BATIK_JARS="$BATIK_JARS batik-svggen.jar batik-swing.jar"
    BATIK_JARS="$BATIK_JARS batik-transcoder.jar batik-util.jar batik-xml.jar"
    BATIK_JARS="$BATIK_JARS js.jar pdf-transcoder.jar xalan-2.6.0.jar"
    BATIK_JARS="$BATIK_JARS xerces_2_5_0.jar xml-apis-ext.jar xml-apis.jar"

    BATIK_CLASS_PATH=
    for BATIK_JAR in $BATIK_JARS; do
	if [ -z "$BATIK_CLASS_PATH" ]; then
	    BATIK_CLASS_PATH="$JAVA/$BATIK_JAR"
	else
	    BATIK_CLASS_PATH="$BATIK_CLASS_PATH":"$JAVA/$BATIK_JAR"
	fi
    done

    if [ -f "$JAVA/saplugin.jar" ]; then
	ADD_CLASS_PATH="$JAVA/isql.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/salib.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/JComponents`get_version`.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jlogon.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/debugger.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jodbc4.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/dbdiff.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/diffutils-1.2.1.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$BATIK_CLASS_PATH"

	CLASS_PATH="$JAVA/saplugin.jar"

	# Always need to unregister before registering.
	"$BIN_S/scjview" -unregister "$JAVA/sqlanywhere.jpr" > /dev/null 2>&1

	cat <<-SA_JPR_FILE > "$JAVA/sqlanywhere.jpr"
PluginName=SQL Anywhere `get_major_version`
PluginId=sqlanywhere`get_version`
PluginClass=ianywhere.sa.plugin.SAPlugin
PluginFile=$CLASS_PATH
AdditionalClasspath=$ADD_CLASS_PATH
ClassloaderId=SA`get_version`
InitialLoadOrder=0
SA_JPR_FILE

	# translate file contents to UTF8 (different from parms below)
	SRC="$JAVA/sqlanywhere.jpr"
	
        create_new_tmpfile
	DST="${TMPFILE}"
	csconvert -t UTF8 "$SRC" "$DST" > /dev/null 2>&1
	rm -f "$SRC"
	cp -p "$DST" "$SRC" > /dev/null 2>&1
	rm -f "$DST"

	# avoid having to translate parms to UTF8
	pushd_quiet "$JAVA"
	"$BIN_S/scjview" -register "sqlanywhere.jpr" > /dev/null 2>&1
	popd_quiet
    fi

    if [ -f "$JAVA/mlplugin.jar" ]; then 
	CLASS_PATH="$JAVA/mlplugin.jar"

	ADD_CLASS_PATH="$JAVA/salib.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/isql.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jlogon.jar"
	ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jodbc4.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/log4j.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/mldesign.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/velocity.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/velocity-dep.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/stax-api-1.0.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/wstx-asl-3.2.6.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/JComponents`get_version`.jar"

        # Always need to unregister before registering.  Especially affects Maintenance Release / Patch installs.
	"$BIN_S/scjview" -unregister "$JAVA/mobilink.jpr" > /dev/null 2>&1
	
        cat <<-ML_JPR_FILE > "$JAVA/mobilink.jpr"
PluginName=MobiLink `get_major_version`
PluginId=mobilink`get_version`
PluginClass=com.sybase.mobilink.plugin.MLPlugin
PluginFile=$CLASS_PATH
AdditionalClasspath=$ADD_CLASS_PATH
ClassloaderId=SA`get_version`
InitialLoadOrder=1
ML_JPR_FILE

	# translate file contents to UTF8 (different from parms below)
	SRC="$JAVA/mobilink.jpr"
        create_new_tmpfile
	DST="${TMPFILE}"
	csconvert -t UTF8 "$SRC" "$DST" > /dev/null 2>&1
	rm -f "$SRC"
	cp -p "$DST" "$SRC" > /dev/null 2>&1
	rm -f "$DST"

	# avoid having to translate parms to UTF8
	pushd_quiet "$JAVA"
	"$BIN_S/scjview" -register "mobilink.jpr" > /dev/null 2>&1
	popd_quiet
    fi

    if [ -f "$JAVA/ulplugin.jar" ]; then 
	CLASS_PATH="$JAVA/ulplugin.jar"

	ADD_CLASS_PATH="$JAVA/salib.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/JComponents`get_version`.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/isql.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jlogon.jar"
	ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jodbc4.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$BATIK_CLASS_PATH"

        # Always need to unregister before registering.  Especially affects Maintenance Release / Patch installs.
	"$BIN_S/scjview" -unregister "$JAVA/ultralite.jpr" > /dev/null 2>&1
	
        cat <<-UL_JPR_FILE > "$JAVA/ultralite.jpr"
PluginName=UltraLite `get_major_version`
PluginId=ultralite`get_version`
PluginClass=ianywhere.ultralite.plugin.ULPlugin
PluginFile=$CLASS_PATH
AdditionalClasspath=$ADD_CLASS_PATH
ClassloaderId=SA`get_version`
InitialLoadOrder=3
UL_JPR_FILE

	# translate file contents to UTF8 (different from parms below)
	SRC="$JAVA/ultralite.jpr"
        create_new_tmpfile
	DST="${TMPFILE}"
	csconvert -t UTF8 "$SRC" "$DST" > /dev/null 2>&1
	rm -f "$SRC"
	cp -p "$DST" "$SRC" > /dev/null 2>&1
	rm -f "$DST"

	# avoid having to translate parms to UTF8
	pushd_quiet "$JAVA"
	"$BIN_S/scjview" -register "ultralite.jpr" > /dev/null 2>&1
	popd_quiet
    fi

    if [ -f "$JAVA/rsplugin.jar" ]; then 
	CLASS_PATH="$JAVA/rsplugin.jar"

	ADD_CLASS_PATH="$JAVA/salib.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/JComponents`get_version`.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/jlogon.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$JAVA/rstool.jar"
        ADD_CLASS_PATH="$ADD_CLASS_PATH":"$BATIK_CLASS_PATH"

        # Always need to unregister before registering.  Especially affects Maintenance Release / Patch installs.
	"$BIN_S/scjview" -unregister "$JAVA/relayserver.jpr" > /dev/null 2>&1
	
        cat <<-RS_JPR_FILE > "$JAVA/relayserver.jpr"
PluginName=RelayServer `get_major_version`
PluginId=relayserver`get_version`
PluginClass=com.sybase.relayserver.plugin.RSPlugin
PluginFile=$CLASS_PATH
AdditionalClasspath=$ADD_CLASS_PATH
ClassloaderId=SA`get_version`
InitialLoadOrder=4
RS_JPR_FILE

	# translate file contents to UTF8 (different from parms below)
	SRC="$JAVA/relayserver.jpr"
        create_new_tmpfile
	DST="${TMPFILE}"
	csconvert -t UTF8 "$SRC" "$DST" > /dev/null 2>&1
	rm -f "$SRC"
	cp -p "$DST" "$SRC" > /dev/null 2>&1
	rm -f "$DST"

	# avoid having to translate parms to UTF8
	pushd_quiet "$JAVA"
	"$BIN_S/scjview" -register "relayserver.jpr" > /dev/null 2>&1
	popd_quiet
    fi

}

generate_sourced_file_message_in_tmpfile()
##########################################
{
    create_new_tmpfile

    if [ `get_install_type` = "DOC" ] ; then
	echo "" >> "$TMPFILE"
	return
    fi

    SA_CONFIG64="`get_install_file sa_config64.sh`"
    SA_CONFIG32="`get_install_file sa_config32.sh`"
    SAMPLE_CONFIG32="`get_install_file sample_config32.sh`"
    SAMPLE_CONFIG64="`get_install_file sample_config64.sh`"

    if [ -r "$SA_CONFIG32" ] && [ -r "$SA_CONFIG64" ] ; then
	msg_need_to_source_for_environment_multi_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SA_CONFIG32" > "$TMPFILE"
    elif [ -r "$SA_CONFIG32" ] ; then
	msg_need_to_source_for_environment_single_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SA_CONFIG32" > "$TMPFILE"
    elif [ -r "$SA_CONFIG64" ] ; then
	msg_need_to_source_for_environment_single_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SA_CONFIG64" > "$TMPFILE"
    fi
    
    if [ -r "$SAMPLE_CONFIG32" ] && [ -r "$SAMPLE_CONFIG64" ] ; then
	echo "" >> "$TMPFILE"
	msg_need_to_source_for_samples_multi_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SAMPLE_CONFIG32" >> "$TMPFILE"
    elif [ -r "$SAMPLE_CONFIG32" ] ; then
	echo "" >> "$TMPFILE"
	msg_need_to_source_for_samples_single_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SAMPLE_CONFIG32" >> "$TMPFILE"
    elif [ -r "$SAMPLE_CONFIG64" ] ; then
	echo "" >> "$TMPFILE"
	msg_need_to_source_for_samples_single_bitness "${MSG_PRODUCT_NAME}" "`get_major_version`" "$SAMPLE_CONFIG64" >> "$TMPFILE"
    fi
}

script_eclipse_ini_file()
#########################
{
    SAROOT=`get_install_dir SYSTEM`
    SAJRE=`get_jre_dir DIR 32`

    if [ `plat_os` = "aix" ]; then
	VMARG=/usr/java6/jre/bin
    else
	VMARG=$SAJRE/bin
    fi

    L_ECLIPSE_DIR="$SAROOT/eclipse"
    if [ "`plat_os`" = "macos" ]; then
	L_ECLIPSE_DIR="$L_ECLIPSE_DIR/Eclipse.app/Contents/MacOS"
    fi
    rm -f "$L_ECLIPSE_DIR/eclipse.ini"

cat <<-EOD > "$L_ECLIPSE_DIR/eclipse.ini"
-data
$SAROOT/sa_help_launcher/workspace
EOD

    if [ "`plat_os`" = "macos" ]; then
	# We will use the system JRE and browser on Mac OS
cat <<-EOD >> "$L_ECLIPSE_DIR/eclipse.ini"
-use_external_browser
-vmargs
-Dfile.encoding=UTF-8
EOD
    else
cat <<-EOD >> "$L_ECLIPSE_DIR/eclipse.ini"
-vm
$VMARG
EOD
    fi

}

create_eclipse_folders()
########################
{
    SYSROOT=`get_install_dir SYSTEM`

    rm -rf "$SYSROOT/sa_help_launcher"
    rm -rf "$HOME/.sybase/sa_help_launcher"
    
    create_directory "$SYSROOT/sa_help_launcher/workspace/.metadata"

    chmod 777 "$SYSROOT/sa_help_launcher"
    chmod 777 "$SYSROOT/sa_help_launcher/workspace"
    chmod 777 "$SYSROOT/sa_help_launcher/workspace/.metadata"

    touch "$SYSROOT/sa_help_launcher/workspace/.metadata/.applicationlock"
    touch "$SYSROOT/sa_help_launcher/workspace/.metadata/.helplock"

    chmod 666 "$SYSROOT/sa_help_launcher/workspace/.metadata/.applicationlock"
    chmod 666 "$SYSROOT/sa_help_launcher/workspace/.metadata/.helplock"

    if [ `plat_os` = "macos" ] ; then
	SAROOT=`get_install_dir SA`
    fi
}

copy_file_overwrite()
#####################
{
    if [ -f "$1" ] ; then
	rm -f "$2"
	cp "$1" "$2"
    elif is_debug ; then
	echo "** WARNING file $1 does not exist"
    fi
}

copy_file_to_install_root()
###########################
{
    ROOT=`get_install_dir SA`
    copy_file_overwrite "$1" "$ROOT/${2:-$1}"
}

generate_special_license_agreements()
#####################################
{
    # Copy developer and evaluation license agreements if appropriate
    INSTALL_DIR=`get_install_dir SA`
    
    if is_developer_key || is_evaluation_key || is_web_key ; then
	LF=`get_license_agreement`
	copy_file_to_install_root "$LF" "license.txt"
    fi
}

script_samonitor_sh()
#####################
{
    if is_selected_option OPT_SAMON_DEPLOY ; then
	BINDIR=`get_install_dir BIN`
	create_samonitor_sh "$BINDIR"
    else
        if has_feature SAMON_32 ; then
	    BINDIR=`get_install_dir BIN32`
	    create_samonitor_sh "$BINDIR"
        fi
        if has_feature SAMON_64 ; then
	    BINDIR=`get_install_dir BIN64`
	    create_samonitor_sh "$BINDIR"
        fi
    fi
}

create_samonitor_sh()
#####################
{
    if [ -r "$1/samonitor.template" ]; then
        sed -e "s@BINDIR@$1@g" -e "s/SAMAJOR/`get_major_version`/g" -e "s/SAVER/`get_version`/g" "$1/samonitor.template" > "$1/samonitor.sh"
        chmod +x "$1/samonitor.sh"
    fi
}

create_newdemo_scripts()
########################
{
    if has_feature SA_SERVER_32 ; then
	create_newdemo_script_for_bitness 32
    fi
    
    if has_feature SA_SERVER_64 ; then
	create_newdemo_script_for_bitness 64
    fi
}

create_newdemo_script_for_bitness()
###################################
{
    SQLANY_VERSIONED="SQLANY`get_major_version`"
    DBENG_VERSIONED="dbeng`get_major_version`"
    BINDIR="`get_install_dir BIN${1}`"

cat <<-EOD > "$BINDIR/newdemo.sh"
#!/bin/sh	

. "$BINDIR/sa_config.sh"

if [ "\$1" = "" ]; then
    __new=demo.db
fi

__new=demo.db
if [ "\$1" != "" ]; then
    __new=\$1.db

    __new=\`echo \$__new | sed -e s/\.db\.db\$/.db/\`
fi
dberase \$__new
if [ ! -r \$__new ]; then
    dbinit \$__new
    dbspawn -q -f ${DBENG_VERSIONED} -n newdemo \$__new
    cd "\$${SQLANY_VERSIONED}/scripts"
    dbisql -c "UID=DBA;PWD=sql;SERVERNAME=newdemo" -q mkdemo.sql
    dbstop -c "UID=DBA;PWD=sql;SERVERNAME=newdemo" -q
fi

EOD

    chmod +x "$BINDIR/newdemo.sh"
}
