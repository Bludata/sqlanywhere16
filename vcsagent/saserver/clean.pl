# Stop a SQL Anywhere server

# Expects ResourceName and command line

use ag_i18n_inc;

$resource_name = $ARGV[0];
$stop_cmd = $ARGV[3];

VCSAG_SET_ENVS ($resource_name);

$dbg = 0;

if( $dbg eq 1 ) {
    open( TT, ">c:\\saserver_offline.out" ) || die "unable to open file";
    printf( TT "saserver offline.pl running\n" );
    printf( TT "Args:\n" );
    printf( TT "0: %s\n", $ARGV[0] );
    printf( TT "1: %s\n", $ARGV[1] );
    printf( TT "2: %s\n", $ARGV[2] );
    printf( TT "3: %s\n", $ARGV[3] );
    printf( TT "4: %s\n", $ARGV[4] );
    close( TT );
}

$rc = 0xffff & system( $stop_cmd );

if( $dbg eq 1 ) {
    printf( "system %s returned: %#04x", $stop_cmd, $rc );
}

exit 0;

