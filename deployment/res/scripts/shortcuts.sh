# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
write_shortcut()
################
{
    BINNAME="$1"
    FLNAME="$2"
    BIT="$3"

    rm -f "$FLNAME" >/dev/null 2>&1
    echo "#!/bin/sh" > "$FLNAME"

    echo 'SAROOT=`dirname "$0"`/..'             >> "$FLNAME"
    echo ". \"\$SAROOT/bin$BIT/sa_config.sh\" >/dev/null 2>&1">> "$FLNAME"
    echo "exec \"\$SAROOT/bin$BIT/$BINNAME\" \"\$@\"" >> "$FLNAME"

    chmod a+x "$FLNAME"
    chmod a-w "$FLNAME"
}

make_shortcuts()
################
{
    for bit in 32 64 ; do
	BINDIR="`get_install_dir BIN${bit}`"
	if [ -r "$BINDIR" ]; then
	    BINSDIR="`get_install_dir BIN${bit}S`"
	    mkdir -p "$BINSDIR"
	    for file in `ls "$BINDIR"` ; do
		if [ -x "$BINDIR/$file" ] && [ ! -d "$BINDIR/$file" ]; then
		    write_shortcut "$file" "$BINSDIR/$file" $bit
		fi
	    done
	fi
    done
}

