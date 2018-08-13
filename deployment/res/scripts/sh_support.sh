# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
shell_shebang()
##############
{
    echo "#!/bin/sh" > "$1"
}

shell_set()
###########
{
    VAR="$1"
    VALUE="$2"

    echo "$VAR=\"$VALUE\"" >> "$3"
}

shell_set_check()
#################
{
    VAR="$1"
    VALUE="$2"

    echo "[ -z \"\${$VAR:-}\" ] && $VAR=\"$VALUE\"" >> "$3"
}

shell_source_check()
####################
{
    FILE="$1"

    echo "[ -r \"$FILE\" ] && . \"$FILE\" " >> "$2"
}

shell_prepend_path()
####################
{
    VAR="$1"
    VALUE="$2"

    echo "$VAR=\"$VALUE:\${$VAR:-}\"" >> "$3"
}

shell_export()
##############
{
    VAR="$1"

    echo "export $VAR" >> "$2"
}


