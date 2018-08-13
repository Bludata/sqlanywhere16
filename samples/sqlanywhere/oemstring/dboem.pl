#!perl
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability
# of any kind.
# 
# You may use, reproduce, modify and distribute this sample code
# without limitation, on the condition that you retain the foregoing
# copyright notice and disclaimer as to the original code.  
# 
# *********************************************************************

######################################################################
# DBOEM
######################################################################
# This script can be used to extract the oem_string option from a
# database file without starting the database on a server/engine.
#
use strict;

my $usage = "Usage: $0 <options> [--] <filename>...\n"
    . "Options:\n"
    . "\t-h     This usage information\n"
    . "\t-x     Print the oem string as hex (default)\n"
    . "\t-t     Print the oem string as a single line of text\n"
    . "\t--     Last option, rest of command line are filename(s)\n"
    . "One or more filenames must be specified\n"
    ;

my $form  = '-x';

for( ; $#ARGV >= 0; ) {
    if( $ARGV[0] eq '-h' ) {
	die( $usage );
    } elsif( $ARGV[0] =~ /^-(x|t)$/ ) {
	$form = shift @ARGV;
    } elsif( $ARGV[0] eq '--' ) {
	shift @ARGV;
	last;
    } else {
	last;
    }
}
if( $#ARGV < 0 ) {
    # must specify a filename
    die( $usage );
}

my $numf = 1 + $#ARGV;

foreach( @ARGV ) {
    print( "__ $_ __\n" )
	if $numf > 1;
    my $oem = &Extract_SQLAnywhere_Database_OEM_Data( $_ );
    if( !defined( $oem ) ) {
	print( "*** UNABLE TO FIND OEM STRING IN FILE $_ ***\n" );
    } elsif( $form eq '-x' ) {
	# print oem string as hex
	for( my $x=0; $oem ne ''; $oem=substr($oem,16) ) {
	    my( $buf ) = substr( $oem, 0, 16 );
	    my( $len ) = length( $buf );
	    printf( "%.4x:", $x );
	    print( map( sprintf( (++$x%4==1)?'  %.2x':' %.2x', ord ), split( //, $buf ) ) );
	    print( ' ' x int( 3.25*( 16 - $len ) ) . ' |' );
	    print( map( ( ( $_ =~ /[ -~]/ ) ? $_ : "." ), split( //, $buf ) ) );
	    print( ( ' ' x ( 16 - $len ) ) . "|\n" );
	} #for
    } elsif( $form eq '-t' ) {
	# print oem string as text
	$oem =~ s/\00+//g;
	print( $oem );
	print( "\n" )
	    if $oem !~ /\n$/;
    } else {
	die( "Oops, unknown form !\n" );
    }
} #foreach filename

sub Extract_SQLAnywhere_Database_OEM_Data {
    my( $fname ) = @_;

    # Note: it would be better to query the sqldef.h file for these constants,
    # but to simplify this example, we'll hard-code the values here
    my( $db_oem_string_prefix ) = "\xDA\x7A\xBA\x5E\x00EM=";
    my( $db_oem_string_suffix ) = "=ME\x00\x5E\xBA\x7A\xDA";

    # convert the strings into regular-expressions acceptable by PERL
    $db_oem_string_prefix =~ s/(.)/sprintf( '\\x%.2x', ord($1) )/ge;
    $db_oem_string_suffix =~ s/(.)/sprintf( '\\x%.2x', ord($1) )/ge;

    if( ! open( FOO, $fname ) ) {
	print( STDERR "***ERROR: Failed to open file: $fname\n" );
    } else {
	my $buf;
	binmode( FOO );
	read( FOO, $buf, 1024 );
	close FOO;
	if( $buf =~ /($db_oem_string_prefix)(.*)($db_oem_string_suffix)/ ) {
	    return $2;
	}
    }
    return undef;
}
