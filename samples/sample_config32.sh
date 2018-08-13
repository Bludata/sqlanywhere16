#!/bin/sh	

# Get general environment settings for SA
. "/opt/sqlanywhere16/bin32/sa_config.sh"

# A single .db file cannot be started by multiple server processes.
# Each user should have their own copy of the sample databases
# This script creates the per-user copy and associated DSNs

DEFAULT_SAMPLES_DESTDIR="${HOME}/sa16_samples"
SAMPLES_DESTDIR=$DEFAULT_SAMPLES_DESTDIR

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


if [ $DOPROMPT -eq 1 ]; then
    echo "Enter destination directory for copy of the samples [$SAMPLES_DESTDIR]: " | tr -d '\12'
    read SAMPLES_DESTDIR
fi
if [ "$SAMPLES_DESTDIR" = "" ]; then
    SAMPLES_DESTDIR=$DEFAULT_SAMPLES_DESTDIR
fi

echo "Copying samples..."
rm -rf "${SAMPLES_DESTDIR}/sqlanywhere"
rm -rf "${SAMPLES_DESTDIR}/mobilink"
rm -rf "${SAMPLES_DESTDIR}/ultralite"
mkdir -p "$SAMPLES_DESTDIR"
cp -R "$SQLANYSAMP16"/* "${SAMPLES_DESTDIR}/"
rm -f "$SAMPLES_DESTDIR/sample_env64.sh"
if [ linux = "macos" ]; then
    cp "$SQLANYSAMP16/../System/demo."* "${SAMPLES_DESTDIR}/sqlanywhere"
else
    cp "$SQLANYSAMP16/../demo."* "${SAMPLES_DESTDIR}/sqlanywhere"
fi

chmod -R u+w "$SAMPLES_DESTDIR"
chown -R $USER "$SAMPLES_DESTDIR"
echo "Done"
echo

# Set up the ODBCINI environment variable if it is not set - assume ~/.odbc.ini for User DSNs
if [ -z "$ODBCINI" ]; then
    ODBCINI=${HOME}/.odbc.ini
    export ODBCINI
fi


echo "Done"
echo


echo "Setting up sample_env script... "

    #
    # generate sample_env script for this bitness 
    #

    echo "#!/bin/sh"	> "$SAMPLES_DESTDIR/sample_env32.sh"
    echo ""		>> "$SAMPLES_DESTDIR/sample_env32.sh"
    echo "# Set up the SQLANYSAMP16 env var for samples that may need"		    >> "$SAMPLES_DESTDIR/sample_env32.sh"
    echo "SQLANYSAMP16=$SAMPLES_DESTDIR"		>> "$SAMPLES_DESTDIR/sample_env32.sh"
    echo "export SQLANYSAMP16"		    >> "$SAMPLES_DESTDIR/sample_env32.sh"

# Get environment settings for samples
. "$SAMPLES_DESTDIR/sample_env32.sh"

echo "Done"
echo

