# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
my $tee_file = shift();

open( TF, ">$tee_file" ) || die( "Unable to open $tee_file for write: $!" );
# enable autoflushing to TF
my $ofh = select TF;
$| = 1;
$ofh = select STDOUT;
$| = 1;
while( <STDIN> ) {
    print( $_ );
    print( TF $_ );
}
close( TF )
