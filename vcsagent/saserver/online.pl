# Start the SQL Anywhere server

# Expects ResourceName and command line

use ag_i18n_inc;

$resource_name = $ARGV[0];
$startline = $ARGV[1];
$startline = "dbspawn " . $startline;

VCSAG_SET_ENVS ($resource_name);

$dbg = 0;

if( $dbg eq 1 ) {
    open( TT, ">c:\\saserver_online.out" ) || die "unable to open file";
    printf( TT "saserver online.pl running\n" );
    printf( TT "Args:\n" );
    printf( TT "0: %s\n", $ARGV[0] );
    printf( TT "1: %s\n", $ARGV[1] );
    printf( TT "2: %s\n", $ARGV[2] );
    printf( TT "3: %s\n", $ARGV[3] );
    printf( TT "4: %s\n", $ARGV[4] );
    printf( TT "Startline is: %s\n", $startline );
    close( TT );
}

$rc = system( $startline );

if( $dbg eq 1 ) {
    printf( "system %s returned: %#04x", $startline, $rc );
}

# No need for exit code. Shell returns 0 if successful
# and 1 if not. Monitor will be called in either case.
# exit code indicates the number of seconds VCS should wait,
# after online entry point completes, before calling the monitor
# entry point to check the resource state.
 
exit 5;
