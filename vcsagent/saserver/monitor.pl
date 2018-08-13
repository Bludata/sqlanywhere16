# Monitor a SQL Anywhere server

# Expects ResourceName and command line

use ag_i18n_inc;

$resource_name = $ARGV[0];
$monitor_cmd = $ARGV[2];

VCSAG_SET_ENVS ($resource_name);

$dbg = 0;

if( $dbg eq 1 ) {
    open( TT, ">c:\\saserver_monitor.out" ) || die "unable to open file";
    printf( TT "saserver monitor.pl running\n" );
    printf( TT "Args:\n" );
    printf( TT "0: %s\n", $ARGV[0] );
    printf( TT "1: %s\n", $ARGV[1] );
    printf( TT "2: %s\n", $ARGV[2] );
    printf( TT "3: %s\n", $ARGV[3] );
    printf( TT "4: %s\n", $ARGV[4] );
    close( TT );
}

if( $dbg eq 1 ) {
    VCSAG_LOG_MSG ("W", "executing monitor script", 12501);
}

$rc = 0xffff & system( $monitor_cmd );

if( $dbg eq 1 ) {
    VCSAG_LOG_MSG ("W", "done executing monitor command", 12501);
    printf( "system %s returned: %#04x", $monitor_cmd, $rc );
}

# Exit values:
#   110 = online
#   100 = offline
#     0 = unknown

if( $rc eq 0 ) {
    exit 110;
} else {
    exit 100;  
}
