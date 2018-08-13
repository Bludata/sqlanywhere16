# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

my $modules_added = 0;
my $sa_ap_bin = $ARGV[1];

while( <> ) {
    chomp;


    if( /^#\s*LoadModule.*/ && ! $modules_added ) {
	print "$_\n";
	print "LoadModule iarelayserver_client_module $sa_ap_bin/mod_rs_ap_client.so\n";
	print "LoadModule iarelayserver_server_module $sa_ap_bin/mod_rs_ap_server.so\n";
	print "LoadModule iarelayserver_admin_module $sa_ap_bin/mod_rs_ap_admin.so\n";
	print "LoadModule iarelayserver_monitor_module $sa_ap_bin/mod_rs_ap_monitor.so\n";
	$modules_added = 1;
    } else {
	print "$_\n";
    }
}

print "<LocationMatch /cli/iarelayserver/* >\n";
print "    SetHandler iarelayserver-client-handler\n";
print "</LocationMatch>\n";
print "<LocationMatch /srv/iarelayserver/* >\n";
print "    SetHandler iarelayserver-server-handler\n";
print "    RSConfigFile \"$sa_ap_bin/rs.config\"\n";
print "</LocationMatch>\n";
print "<LocationMatch /admin/iarelayserver/* >\n";
print "    SetHandler iarelayserver-admin-handler\n";
print "</LocationMatch>\n";
print "<LocationMatch  /mon/iarelayserver/* >\n";
print "    SetHandler iarelayserver-monitor-handler\n";
print "</LocationMatch>\n";

