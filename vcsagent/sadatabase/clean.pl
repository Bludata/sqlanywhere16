# Stop a SQL Anywhere server as part of a failover

# Expects ResourceName and command line

use ag_i18n_inc;

$resource_name = $ARGV[0];
$DatabaseFile = $ARGV[1];
$DatabaseName = $ARGV[2];
$ServerName = $ARGV[3];
$UtilDBpwd = $ARGV[4];

VCSAG_SET_ENVS ($resource_name);

$stop_cmd = "STOP DATABASE ";
if( length($ARGV[2]) > 0 ) {
    $stop_cmd .= $DatabaseName;
}
$stop_cmd .= " ON " . $ServerName . " UNCONDITIONALLY;";


$dbg = 0;

if( $dbg eq 1 ) {
    open( TT, ">c:\\sadatabase_offline.out" ) || die "unable to open file";
    printf( TT "sadatabase offline.pl running\n" );
    printf( TT "Args:\n" );
    printf( TT "0: %s\n", $ARGV[0] );
    printf( TT "1: %s\n", $ARGV[1] );
    printf( TT "2: %s\n", $ARGV[2] );
    printf( TT "3: %s\n", $ARGV[3] );
    printf( TT "4: %s\n", $ARGV[4] );
    close( TT );
}

$stopLine = "dbisqlc -Q -c \"eng=".$ServerName.";dbn=utility_db;uid=dba;pwd=".$UtilDBpwd."\" ".$stop_cmd;
$rc = system( $stopLine );

if( $rc <>  0 ) {
	VCSAG_LOG_MSG ("W", "Start failed - error $rc.", 12501);
	exit 1;
} 

if( $dbg eq 1 ) {
    printf( "system %s returned: %#04x", $stop_cmd, $rc );
}

exit 0;

