# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability of
# any kind.
# 
# You may use, reproduce, modify and distribute this sample code without
# limitation, on the condition that you retain the foregoing copyright 
# notice and disclaimer as to the original code.  
# 
# *******************************************************************

sub fetch_bit
{
    #returns a bit
    $_[0] = 1 + $_[0];
}

sub fetch_smallint
{
    #returns a smallint
    $_[0] = -16000 - $_[0];
}

sub fetch_usmallint
{
    #returns an unsinged smallint
    $_[0] = 32000 + $_[0];
}

sub fetch_int
{
    #returns an integer
    $_[0] = -2000000000 - $_[0];
}

sub fetch_uint
{
    #returns an unsigned integer
    $_[0] = 3000000000 + $_[0];
}

sub fetch_string
{
    #takes an integer and two strings as input and returns the first
    #string if the integer input is 1, otherwise returns the second string
    if( $_[0] == 1 )
    {
	$_[1];
    }
    else
    {
	$_[2];
    }
}

sub fetch_outputs
{
    #returns 6 output variables of type bit, smallint, unsigned smallint,
    #integer, unsigned integer, string
    $_[0] = 0;
    $_[1] = -16020;
    $_[2] = 32300;
    $_[3] = -2000000001;
    $_[4] = 3009000000;
    $_[5] = "this is a string returned in an output variable";
}

