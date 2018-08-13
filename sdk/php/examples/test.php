<?php
    #*********************************************************************
    # Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
    #
    # This sample code is provided AS IS, without warranty or liability
    # of any kind.
    # 
    # You may use, reproduce, modify and distribute this sample code
    # without limitation, on the condition that you retain the foregoing
    # copyright notice and disclaimer as to the original code.
    # 
    #*********************************************************************
    #
    # This sample program contains a hard-coded userid and password
    # to connect to the demo database. This is done to simplify the
    # sample program. The use of hard-coded passwords is strongly
    # discouraged in production code.  A best practice for production
    # code would be to prompt the user for the userid and password.
    #

    # Find out which version of PHP is running
    $version = phpversion();
    $module_name = 'php-'.$version.'_sqlanywhere';
    if( strtoupper(substr(PHP_OS, 0, 3) == 'WIN' )) {
        $module_ext = '.dll';
    } else {
        $module_ext = '.so';
    }
    # Ensure that the SQL Anywhere PHP module is loaded
    if( extension_loaded('sqlanywhere') ) {
	echo "Installation successful\nUsing $module_name$module_ext\n";
    } else {
	echo "***Installation incomplete\n";
	echo "Attempting to load $module_name$module_ext\n";
	if( dl( $module_name.$module_ext ) ) {
	echo "\n***Missing 'extension=' line in php.ini file\n";
	} else {
	echo "\n***Missing 'extension_dir=' line in php.ini file\n";
	  die( "Module load failed\nCheck installation instructions\n" );
	}
    }
    # Connect using the default user ID and password
    $conn = sasql_connect( "UID=DBA;PWD=sql" );
    if( $conn ) {
        echo "Connected successfully\n";
        sasql_disconnect( $conn );
    } else {
        echo "Connection failed\n";
    }
?>
