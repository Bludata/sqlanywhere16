<?php
#   *******************************************************************
#   Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
#   This sample code is provided AS IS, without warranty or liability of
#   any kind.
#  
#   You may use, reproduce, modify and distribute this sample code without
#   limitation, on the condition that you retain the foregoing copyright 
#   notice and disclaimer as to the original code.  
#   
#   *******************************************************************
?>

<?php
function fetch_bit( $in1 )
{
    return 1 - $in1;
}

function fetch_smallint( $in1 )
{
    return -16000 - $in1;
}

function fetch_usmallint( $in1 )
{
    return 32000 + $in1;
}

function fetch_int( $in1 )
{
    return -2000000000 - $in1;
}

function fetch_uint( $in1 )
{
    return 3000000000 + $in1;
}

function fetch_bigint( $in1 )
{
    return -17000000000000 - $in1;
}

function fetch_double( $in1 )
{
    return 3.14159 + $in1;
}

function fetch_string( $in1, $in2, $in3 )
{
    if( $in1 == 1 )
    {
	return $in2;
    }

    if( $in1 == 3 )
    {
        return $in2 . $in3;
    }

    return $in3;
}

?>
