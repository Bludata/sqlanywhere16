# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
ARRAY_DELIMITER=';'

# $1 - array
# $2 - index
#
# returns the element at index
array_at( )
{
    echo "$1" | cut -f "$2" -d $ARRAY_DELIMITER
}

# $1 - array
array_count( )
{
    COUNT=`echo "${1}" | tr -c -d $ARRAY_DELIMITER | wc -c`
    COUNT=`expr ${COUNT} + 1`
    [ -z "$1" ] && COUNT=0
    echo $COUNT
}

# $1 - array
# $2 - string
#
# returns the index of the first matching item 
array_find( )
{
    COUNT=`array_count "${1}"`
    INDEX=1
    
    while [ $INDEX -le $COUNT ] ; do
	ELEM=`array_at "${1}" $INDEX`
	[ "${ELEM}" = "${2}" ] && echo $INDEX && return
	INDEX=`expr $INDEX + 1`
    done
    
    echo "-1"
}

# $1 - array
# $2 - command
#
array_foreach( )
{
    COUNT=`array_count "${1}"`
    INDEX=1

    while [ $INDEX -le $COUNT ] ; do
	ELEM=`array_at "${1}" $INDEX`
	"$2" "$ELEM"
	INDEX=`expr $INDEX + 1`
    done
}

array_append( )
{
    if [ -z "${1}" ] ; then
	echo -n $2
    else
	echo -n "$1;$2"
    fi
}
