# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

my $sa_path_added = 0;
my $sa_lib_dir = $ARGV[1];
my $rs_ap_bin = $ARGV[2];

while( <> ) {
    chomp;

    if( /^\s*export.*LD_LIBRARY_PATH/ && ! $sa_path_added ) {
	print "LD_LIBRARY_PATH=\"$sa_lib_dir:$rs_ap_bin:\$LD_LIBRARY_PATH\"\n";
	print "$_\n";
	$sa_path_added = 1;
    } else {
	print "$_\n";
    }
}

