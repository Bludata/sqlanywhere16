# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************


my $in_deleted_block = 0;

while( <> ) {
    chomp;

    if( $in_deleted_block ) {
	if( /<\/LocationMatch.*>/ ) {
	    $in_deleted_block = 0;
	}
    } elsif( /^\s*<LocationMatch.*\/cli\/iarelayserver\/.*>.*/ ) {
	$in_deleted_block = 1;
    } elsif( /^\s*<LocationMatch.*\/srv\/iarelayserver\/.*>.*/ ) {
	$in_deleted_block = 1;
    } elsif( /^\s*<LocationMatch.*\/admin\/iarelayserver.*>.*/ ) {
	$in_deleted_block = 1;
    } elsif( /^\s*<LocationMatch.*\/mon\/iarelayserver\/.*>.*/ ) {
	$in_deleted_block = 1;
    } elsif( /^\s*LoadModule.*iarelayserver_client_module*/ ) {
	# do nothing
    } elsif( /^\s*LoadModule.*iarelayserver_server_module*/ ) {
	# do nothing
    } elsif( /^\s*LoadModule.*iarelayserver_admin_module*/ ) {
	# do nothing
    } elsif( /^\s*LoadModule.*iarelayserver_monitor_module*/ ) {
	# do nothing
    } else {
	print "$_\n";
    }
}

