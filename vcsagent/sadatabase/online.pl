# Start the SQL Anywhere server

# Expects ResourceName and command line

use ag_i18n_inc;

$resource_name = $ARGV[0];
$DatabaseFile = $ARGV[1];
$DatabaseName = $ARGV[2];
$ServerName = $ARGV[3];
$UtilDBpwd = $ARGV[4];

VCSAG_SET_ENVS ($resource_name);

$Startcmd = "START DATABASE '" . $DatabaseFile . "'";
if( length($ARGV[2]) > 0 ) {
    $Startcmd .= " AS " . $DatabaseName;
}
$Startcmd .= " ON " . $ServerName . " AUTOSTOP OFF;";


$dbg = 0;

if( $dbg eq 1 ) {
    open( TT, ">c:\\sadatabase_online.out" ) || die "unable to open file";
    printf( TT "sadatabase online.pl running\n" );
    printf( TT "Args:\n" );
    printf( TT "0: %s\n", $ARGV[0] );
    printf( TT "1: %s\n", $ARGV[1] );
    printf( TT "2: %s\n", $ARGV[2] );
    printf( TT "3: %s\n", $ARGV[3] );
    printf( TT "4: %s\n", $ARGV[4] );
    printf( TT "Startline is: %s\n", $Startcmd );
    close( TT );
}

# execute start database command
$startline = "dbisqlc -Q -c \"eng=".$ServerName.";dbn=utility_db;uid=dba;pwd=".$UtilDBpwd."\" ".$Startcmd;
$rc = system( $startline );
if( $dbg eq 1 ) {
    printf( "system %s returned: %#04x", $startline, $rc );
}

# No need for exit code. Shell returns 0 if successful
# and 1 if not. Monitor will be called in either case.
# exit code indicates the number of seconds VCS should wait,
# after online entry point completes, before calling the monitor
# entry point to check the resource state.
if( $rc == 0 ) {
	exit 5;
} else {
	VCSAG_LOG_MSG ("W", "Start failed - error $rc.", 12501);
	exit 0;
    } 


