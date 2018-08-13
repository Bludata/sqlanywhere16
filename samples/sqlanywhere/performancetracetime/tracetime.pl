# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability
# of any kind.
# 
# You may use, reproduce, modify and distribute this sample code
# without limitation, on the condition that you retain the foregoing
# copyright notice and disclaimer as to the original code.  
# 
# *********************************************************************

# Convert request log output to a format with statement times.

# Usage:
#	perl tracetime.pl request-log-filename [format={sql | fixed}] [conn=nnn]
# If format=fixed, a file is produced with duration at the start of each line.
# This file can be sorted to show long-running statements.
# If format=sql, the statements are output so they can be run with DBISQL.
#
# If a connection is specified, only statements for that connection are output.

# Limitations:
# - statements containing host variable references cannot be re-executed
# - statements are output as they are encountered in the log. Statements
#   executed concurrently by several connections may not re-execute with
#   the same results.


sub getline
# Get one "line" from the request log file, handling newlines and long statements.
{
    my $partline;
    
    if( ! defined( $prevline ) ) {
	return( 0 );
    }
    $line = $prevline;
    for(;;) {
	$lineno++;
	if( ($lineno % 1000) == 0 ) {
	    printf( stderr "Processed $lineno lines...\r" );
	}
	if( !( $partline = <RL> ) ) {
	    undef $prevline;
	    return( 1 );
	}
	last if( ! ($partline =~ /^\t\t/) );
	$line .= $partline;
    }
    $prevline = $partline;
    $line =~ s/\n$//;
    $line =~ s/\r$//;
    return( 1 );
}

sub push_proc_stmt
{
    local( $conn ) = @_;

    $proclevel{$conn} += 1;
    $laststmt{$conn}[$proclevel{$conn}] = $sqlstmt{$conn};
}

sub pop_proc_stmt
{
    local( $conn ) = @_;

    if( $proclevel{$conn} > 0 ) {
	$sqlstmt{$conn} = $laststmt{$conn}[$proclevel{$conn}];
	$proclevel{$conn} -= 1;
    }
}

sub get_last_stmt_idx
{
    local( $c ) = @_;

    return( $sqlstmt{$c} );
}

sub add_connection
{
    local( $c ) = @_;
    
    $sqlstmt{$c} = 0;
    $proclevel{$c} = 0;
    &reset_hostvars( $c );
}

sub del_connection
{
    local( $c ) = @_;
    my $i, $last;

    $last = &get_last_stmt_idx($c);
    $i = 1;
    while( $i <= $last ) {
	&del_stmt( $c, $i );
	$i++;
    }
    $last = $proclevel{$c};
    $i = 1;
    while( $i <= $last ) {
	delete $laststmt{$c}[$i];
	$i++;
    }
    delete $sqlstmt{$c};
    delete $proclevel{$c};
    delete $recent_open{$c};
    delete $recent_desc{$c};
    delete $recent_close{$c};
    delete $recent_exec{$c};
    delete $recent_exec_start{$c};
    &reset_hostvars( $c );
    delete $hostvarcnt{$c};
    delete $hostvar{$c};
    delete $hostvartype{$c};
}

sub add_stmt
{
    local( $c, $s, $tm ) = @_;
    my $i;

    # Found a new statement.
    # Determine lowest unused statement index.
    $i = $sqlstmt{$c};
    while( $i > 0 && !defined( $starttime{$c}[$i] ) ) {
	$i--;
    }
    $i++;
    $sqlstmt{$c} = $i;
    $sql{$c}[$i] = $s;
    $starttime{$c}[$i] = $tm;
    $executions{$c}[$i] = 0;
    $cursor_opens{$c}[$i] = 0;
    $opentime{$c}[$i] = $tm;
    $desctime{$c}[$i] = $tm;
    $totalruntime{$c}[$i] = 0;
    $is_open{$c}[$i] = 0;
    $is_dropped{$c}[$i] = 0;
}

sub del_stmt
{
    local( $c, $i ) = @_;

    if( $i != -1 ) {
	undef $sql{$c}[$i];
	undef $stmtnum{$c}[$i];
	undef $starttime{$c}[$i];
	undef $executions{$c}[$i];
	undef $cursor_opens{$c}[$i];
	undef $crsrnum{$c}[$i];
	undef $opentime{$c}[$i];
	undef $desctime{$c}[$i];
	undef $totalruntime{$c}[$i];
	undef $is_open{$c}[$i];
	undef $is_dropped{$c}[$i];
    }
}

sub find_stmt
{
    local( $c, $snum ) = @_;
    my $i;

    $snum =~ s/ *$//;    
    if( $snum eq "-1" ) {
	$i = &get_last_stmt_idx($c);
    } else {
	$i = 1;
	$last = &get_last_stmt_idx( $c );
	while( $i <= $last ) {
	    if( $stmtnum{$c}[$i] =~ $snum ) {
		return( $i );
	    }
	    $i += 1;
	}
	# die "Statement $snum not found for connection $c\n";
	# This can happen for statements started before logging enabled.
	return( -1 );
    }
    return( $i );
}

sub find_crsr
{
    local( $c, $cnum ) = @_;
    my $i;
    
    $snum =~ s/ *$//;    
    $i = 1;
    $last = &get_last_stmt_idx( $c );
    while( $i <= $last ) {
	if( $crsrnum{$c}[$i] eq $cnum ) {
	    return( $i );
	}
	$i += 1;
    }
    # die "Cursor $cnum not found for connection $c\n";
    return( -1 );
}

sub reset_hostvars
{
    local( $c ) = @_;
    my $i, $last;

    $last = $hostvarcnt{$c};
    $i = 0;
    while( $i < $last ) {
	undef $hostvar{$c}[$i];
	undef $hostvartype{$c}[$i];
	$i = $i + 1;
    }
    $hostvarcnt{$c} = 0;
}

sub add_hostvar
{
    local( $c, $hvnum, $type, $val ) = @_;
    
    $hostvarcnt{$c} = $hvnum + 1;
    $hostvar{$c}[$hvnum] = $val;
    $hostvartype{$c}[$hvnum] = $type;
}

sub output_hostvars
{
    local( $c ) = @_;

    if( $hostvarcnt{$c} > 0 ) {
	my $i;
	printf( "// HOSTVARS: %d\n", $hostvarcnt{$c} );
	$i = 0;
	while( $i < $hostvarcnt{$c} ) {
	    printf( "// %d %s: %s\n", $i, $hostvartype{$c}[$i], $hostvar{$c}[$i] );
	    $i = $i + 1;
	}
	$hostvarcnt{$c} = 0;
    }
}

sub exec_time
{
    local( $strt, $end ) = @_;

    if( !defined( $strt ) ) {
	# Probably the result of statements started before logging enabled.
	return( 0 );
    }
    substr($strt,8,1) = ':';
    substr($end,8,1) = ':';
    ($hour1,$min1,$sec1,$milli1) = split( /:/, $strt );
    ($hour2,$min2,$sec2,$milli2) = split( /:/, $end );
    return( ((($hour2-$hour1)*60 + ($min2-$min1))*60 + ($sec2-$sec1))*1000 + ($milli2-$milli1) );
}

sub addtime
{
    local( $prevtime, $incr ) = @_;

    substr($prevtime,8,1) = ':';
    ($hour,$min,$sec,$msec) = split( /:/, $prevtime );
    $msecs = (($hour*60+$min)*60+$sec)*1000+$msec;
    $msecs = $msecs + $incr;
    $secs = int( $msecs / 1000 );
    $msec = $msecs - ($secs * 1000);
    $mins = int( $secs / 60 );
    $sec = $secs - ($mins * 60);
    $hours = int( $mins / 60 );
    $min = $mins - ($hours * 60 );
    $hour = $hours;
    $tm = sprintf( "%2.2d:%2.2d:%2.2d.%3.3d", $hour, $min, $sec, $msec );
    return( $tm );
}

sub stmt_complete
{
    local( $c, $i, $endtime ) = @_;
    
    # Calculate duration
    if( defined( $chosen_conn ) && $c != $chosen_conn ) {
	return;
    }
    if( $cursor_opens{$c}[$i] > 0 ) {
	# Assume statement used for a cursor (i.e. with OPEN, ..., CLOSE )
	# $duration = &exec_time( $starttime{$c}[$i], $endtime );
	# Use total of all times between OPEN and CLOSE (excludes times
	# for PREPARE and DROP).
	$duration = $totalruntime{$c}[$i];
    } else {
	$duration = $totalruntime{$c}[$i];
    }
    if( $fmt eq "sql" ) {
	printf( "// Start: %s, Stop: %s, Duration=%s, StmtNum=%s\n",
		$starttime{$c}[$i], $endtime, $duration, $stmtnum{$c}[$i] );
	printf( "// Executions=%s, Opens=%s\n", $executions{$c}[$i],
			$cursor_opens{$c}[$i] );
	printf( "%s\n", $sql{$c}[$i] );
	&output_hostvars( $c );
	printf( "go\n\n" );
    } else {  # "fixed"
	printf( "%10s %s\n", $duration, $sql{$c}[$i] );
    }
}

sub complete_last_statement
{
    local( $conn, $time ) = @_;
    my $i;
    
    # Assume statement is latest one executed.
    $i = &get_last_stmt_idx($conn);
    $executions{$conn}[$i] = 1;
    $totalruntime{$conn}[$i] += &exec_time( $starttime{$conn}[$i], $time );
    &stmt_complete( $conn, $i, $time );
    &del_stmt( $conn, $i );
}

sub set_line_type_mappings
{
    $linetypemap{"<"} = "REQUEST";
    $linetypemap{">"} = "DONE";
    $linetypemap{">."}= "FINI";
    $linetypemap{"C"} = "CONNECT";
    $linetypemap{"H"} = "HOSTVAR";
    $linetypemap{"E"} = "ERROR";
    $linetypemap{"W"} = "WARNING";
    $linetypemap{"P"} = "PLAN";
    $linetypemap{"I"} = "INFO";
    $linetypemap{"X"} = "EXTRA";
    $linetypemap{'['} = "PROCBEG";
    $linetypemap{']'} = "PROCEND";
}

sub map_line_type
{
    local( $linetype ) = @_;
    my $result;

    $result = $linetypemap{ $linetype };
    if( !defined( $result ) ) {
	die $badfmt_msg;
    }
    return( $result );
}

sub set_request_type_mappings
{
    $reqtypemap{"STMT_PREPARE"} = "PREPARE";
    $reqtypemap{"STMT_DROP"} = "DROP_STMT";
    $reqtypemap{"STMT_EXECUTE_ANY_IMM"} = "EXEC_ANY_IMM";
    $reqtypemap{"STMT_EXECUTE_IMM"} = "EXEC_IMM";
    $reqtypemap{"STMT_EXECUTE"} = "EXEC";
    $reqtypemap{"CURSOR_OPEN"} = "OPEN";
    $reqtypemap{"CURSOR_CLOSE"} = "CLOSE";
}

sub map_request_type
{
    local( $otype ) = @_;
    my $result;

    $result = $reqtypemap{ $otype };
    if( defined( $result ) ) {
	return( $result );
    } else {
	return( $otype );
    }
}

sub get_number
{
    local( $s ) = @_;

    if( $filefmt == 1 ) {
	($junk1,$num) = split( /\=/, $s );
    } else {
	($num) = split( /,/, $s );
    }
    $num =~ s/ +//g;
    return( $num );
}


# Mainline:

{
    $request_log_file = shift @ARGV;
    $usage = "Usage: perl tracetime.pl request-log-filename [format={sql | fixed}] [conn=nnn]\n";
    $badfmt_msg = "Unrecognized request log file format";
    if( !defined( $request_log_file ) ) {
	die $usage;
    }
    
    # Defaults:
    $fmt = "fixed";
    
    $an_arg = shift @ARGV;
    while( defined( $an_arg ) ) {
	($parmtype,$parmvalue) = split( /=/, $an_arg );
	if( !defined( $parmtype ) ) {
	    die $usage;
	}
	if( $parmtype eq "format" ) {
	    $fmt = $parmvalue;
	    if( $fmt != "fixed" && $fmt != "sql" ) {
		die $usage;
	    }
	} elsif( $parmtype eq "conn" ) {
	    $chosen_conn = $parmvalue;
	} else {
	    die $usage;
	}
	$an_arg = shift @ARGV;
    }

    $lineno = 0;
    $lastday = "";
    $lasttime = "";

    &set_line_type_mappings();
    &set_request_type_mappings();

    open( RL, $request_log_file ) || die "Can't open $request_log_file: $!";
    $prevline = <RL>;
    while( &getline() ) {
	# printf( "line %d\n", $lineno );
	if( !defined( $filefmt ) ) {
	    if( substr( $line, 8, 1 ) eq ":" ) {
		$filefmt = 1;
	    } elsif( substr( $line, 15, 1 ) eq "," ) {
		$filefmt = 2;
	    } else {
		die $badfmt_msg;
	    }
	}
	if( $filefmt == 1 ) {
	    ($day,$time,$junk1,$linetype,$junk2,$conn,$reqtype) = split( /\s+/, $line );
	    # Strip off the fixed-format part at the start of the line.
	    # Then strip the connection number, which can be variable-length.
	    $linesuff = substr($line,36);
	    $linesuff =~ s/^[0-9]* *//;
	    $stmt = $linesuff;
	    # Strip request type.
	    $stmt =~ s/^[^ ]* *//;
	    $stmt =~ tr/\n/ /;
	    $stmt =~ s/\t+/ /g;
	    $stmt =~ s/ +/ /g;
	    $stmt =~ s/^ *" *//;
	    $stmt =~ s/ *"$//;
	    $reqtype = &map_request_type( $reqtype );
	} else {
	    ($daytime,$linetype,$conn,$rest) = split( /,/, $line, 4 );
	    if( $daytime eq '=' ) {
		$day = $lastday;
		$time = $lasttime;
	    } elsif( substr($daytime,0,1) eq '+' ) {
		$day = $lastday;
		$time = &addtime( $lasttime, substr( $daytime, 1 ) );
	    } else {
		($day,$time) = split( /\s/, $daytime );
		$time = substr($time,0,2 ) . ":" .
			substr($time,2,2 ) . ":" .
			substr($time,4,6 );
	    }
	    $lastday = $day;
	    $lasttime = $time;
	    $reqtype = "";
	    if( $rest ne "" ) {
		($reqtype,$stmt) = split( /,/, $rest, 2 );
	    }
	    $stmt =~ tr/\n/ /;
	    $stmt =~ s/\t+/ /g;
	    $stmt =~ s/ +/ /g;
	    $linetype = &map_line_type( $linetype );
	}
	
	if( $linetype eq "REQUEST" ) {
	    if( $reqtype eq "CONNECT" ) {
		&add_connection( $conn );
	    } elsif( $reqtype eq "DISCONNECT" ) {
		&del_connection( $conn );
	    } elsif( $reqtype eq "PREPARE" ) {
		&reset_hostvars( $conn );
		&add_stmt( $conn, $stmt, $time );
	    } elsif( $reqtype eq "DROP_STMT" ) {
		# find stmt with this stmtno and set end time; then print info
		$snum = &get_number( $stmt );
		$i = &find_stmt( $conn, $snum );
		if( $i != -1 ) {
		    if( $is_open{$conn}[$i] eq 1 ) {
			$is_dropped{$conn}[$i] = 1;
		    } else {
			&stmt_complete( $conn, $i, $time );
		    }
		}
	    } elsif( $reqtype eq "EXEC_IMM" || $reqtype eq "EXEC_ANY_IMM" ) {
		&reset_hostvars( $conn );
		&add_stmt( $conn, $stmt, $time );
		$stmtnum{$conn}[&get_last_stmt_idx($conn)] = -1;
	    } elsif( $reqtype eq "EXEC" ) {
		&reset_hostvars( $conn );
		$snum = &get_number( $stmt );
		$recent_exec{$conn} = &find_stmt( $conn, $snum );
		$recent_exec_start{$conn} = $time;
	    } elsif( $reqtype eq "DESC_IN" || $reqtype eq "DESC_OUT" ) {
		$snum = &get_number( $stmt );
		$tmpstmt = &find_stmt( $conn, $snum );
		if( $tmpstmt != -1 ) {
		    $desctime{$conn}[$tmpstmt] = $time;
		    $recent_desc{$conn} = $tmpstmt;
		}
	    } elsif( $reqtype eq "OPEN" ) {
		&reset_hostvars( $conn );
		$snum = &get_number( $stmt );
		$tmpstmt = &find_stmt( $conn, $snum );
		if( $tmpstmt != -1 ) {
		    $cursor_opens{$conn}[$tmpstmt] += 1;
		    $opentime{$conn}[$tmpstmt] = $time;
		    $recent_open{$conn} = $tmpstmt;
		    $is_open{$conn}[$tmpstmt] = 1;
		}
	    } elsif( $reqtype eq "CLOSE" ) {
		$cnum = &get_number( $stmt );
		$i = &find_crsr( $conn, $cnum );
		if( $i != -1 ) {
		    $recent_close{$conn} = $i;
		    $is_open{$conn}[$i] = 0;
		}
	    } elsif( $reqtype eq "COMMIT" || $reqtype eq "ROLLBACK" ) {
		&add_stmt( $conn, $reqtype, $time );
	    }
	} elsif( $linetype eq "CONNECT" ) {
	    &add_connection( $conn );
	} elsif( $linetype eq "FINI" ) {
	    &complete_last_statement( $conn, $time );
	} elsif( $linetype eq "DONE" ) {
	    if( $reqtype eq "PREPARE" ) {
		$snum = &get_number( $stmt );
		$tmpstmt = &get_last_stmt_idx($conn);
		$stmtnum{$conn}[$tmpstmt] = $snum;
		$totalruntime{$conn}[$tmpstmt] +=
		    &exec_time( $starttime{$conn}[$tmpstmt], $time );
	    } elsif( $reqtype eq "EXEC_IMM"
		  || $reqtype eq "EXEC_ANY_IMM"
		  || $reqtype eq "COMMIT"
		  || $reqtype eq "ROLLBACK" ) {
		&complete_last_statement( $conn, $time );
	    } elsif( $reqtype eq "EXEC" ) {
		$executions{$conn}[$recent_exec{$conn}] += 1;
		$totalruntime{$conn}[$recent_exec{$conn}] += 
		    &exec_time( $recent_exec_start{$conn}, $time );
	    } elsif( $reqtype eq "OPEN" ) {
		$cnum = &get_number( $stmt );
		$crsrnum{$conn}[$recent_open{$conn}] = $cnum;
	    } elsif( $reqtype eq "DESC_IN" || $reqtype eq "DESC_OUT" ) {
		$tmpstmt = $recent_desc{$conn};
		$totalruntime{$conn}[$tmpstmt] += 
		    &exec_time( $desctime{$conn}[$tmpstmt], $time );
	    } elsif( $reqtype eq "CLOSE" ) {
		$tmpstmt = $recent_close{$conn};
		$totalruntime{$conn}[$tmpstmt] += 
		    &exec_time( $opentime{$conn}[$tmpstmt], $time );
		if( $tmpstmt != -1 ) {
		    if( $is_dropped{$conn}[$tmpstmt] eq 1 ) {
			&stmt_complete( $conn, $tmpstmt, $time );
		    }
		}
	    } elsif( $reqtype eq "DROP_STMT" ) {
		my $i;
		$i = &get_last_stmt_idx($conn);
		&del_stmt( $conn, $i );
	    }
	} elsif( $linetype eq "HOSTVAR" ) {
	    $hvnum = $reqtype;
	    if( $filefmt == 1 ) {
		($hvtype,$hvval) = split( /\s+/, $stmt );
	    } else {
		($hvtype,$hvval) = split( /,/, $stmt, 2 );
	    }
	    &add_hostvar( $conn, $hvnum, $hvtype, $hvval );
	} elsif( $linetype eq "EXTRA" ) {
	    # This string is the SQL statement for the previous PREPARE.
	    # (only used for filefmt 1)
	    $sql{$conn}[&get_last_stmt_idx($conn)] = $linesuff;
	} elsif( $linetype eq "PROCBEG" ) {
	    &push_proc_stmt( $conn );
	    &add_stmt( $conn, $stmt, $time );
	} elsif( $linetype eq "PROCEND" ) {
	    &complete_last_statement( $conn, $time );
	    &pop_proc_stmt( $conn );
	} elsif( $linetype eq "ERROR" ||
		 $linetype eq "WARNING" ||
		 $linetype eq "INFO" ||
		 $linetype eq "PLAN" ) {
	    # Ignore this line
	} else {
	    printf( "Line: %s\n", $lineno );
	    die $badfmt_msg;
	}
    }
    close( RL );
}
