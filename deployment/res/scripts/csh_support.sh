# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
shell_shebang()
##############
{
    echo "#!/bin/csh" > "$1"
}

shell_set()
###########
{
    VAR="$1"
    VALUE="$2"

    echo "setenv $VAR \"$VALUE\"" >> "$3"
}

shell_set_check()
#################
{
    VAR="$1"
    VALUE="$2"

    echo "if ( ! \$?$VAR ) then"	>> "$3"
    echo "    setenv $VAR \"$VALUE\""	>> "$3"
    echo "endif"			>> "$3"
}

shell_source_check()
####################
{
    FILE="$1"

    echo "[ -r \"$FILE\" ] && source \"$FILE\" " >> "$2"
}

shell_prepend_path()
####################
{
    VAR="$1"
    VALUE="$2"

    echo "if ( \$?$VAR ) then"		    >> "$3"
    echo "    setenv $VAR \"$VALUE:\$$VAR\"">> "$3"
    echo "else"				    >> "$3"
    echo "    setenv $VAR \"$VALUE\""	    >> "$3"
    echo "endif"			    >> "$3"
}

shell_export()
##############
{
    true
}

