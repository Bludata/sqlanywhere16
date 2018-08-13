# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# Makefile.PL for Perl in the database glue.

use ExtUtils::MakeMaker;
use Getopt::Long;

require 5.004;

use strict;

# This DBI must be installed before we can build a DBD.
# For those not using Dynamic loading this means building a
# new static perl in the DBI directory by saying 'make perl'
# and then using _that_ perl to make this one.
use DBI;
use DBI::DBD; # DBD creation tools
use Config;
if( $Config{osname} eq "MSWin32" ) {
    eval 'use Win32::Registry;';
}

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();
my $os = $^O;
my $osvers = $Config{osvers};
my $osarch = $Config{archname};
my $max_sqlanywhere_ver = 19;
my $min_sqlanywhere_ver = 11;
my $perl_bitness = $Config{ptrsize} * 8;

my $sdk_dir = 'sdk';
$sdk_dir = '../' . $sdk_dir if $^O eq 'darwin';


# This must always be compiled threaded, whether or not PERL was compiled
# with ithreads.  Otherwise, we would not be able to load libdbextenv_r, which
# is only available with threading.
my $threaded = 1; #$Config{useithreads};

my $threadext = '';
$threadext = '_r' if $threaded;

$osvers =~ s/^\s*(\d+\.\d+).*/$1/;	# drop sub-sub-version: 2.5.1 -> 2.5

my $so_ext = 'so';
$so_ext = 'dll' if $os eq 'MSWin32';
$so_ext = 'dylib' if $os eq 'darwin';
$so_ext = 'sl' if $os eq 'hpux' && $osarch =~ /^PA-RISC/;

my %opts = ( NAME => 'SAPerlGlue',
             VERSION_FROM => 'SAPerlGlue.pm',
             OBJECT => 'perlglue.o',
             dist  => {	DIST_DEFAULT => 'clean distcheck disttest ci tardist',
                        PREOP        => '$(MAKE) -f Makefile.old distdir',
                        COMPRESS     => 'gzip -v9', SUFFIX => 'gz',
                    },
             PM => { 'SAPerlGlue.pm' => '$(INST_LIBDIR)/SAPerlGlue.pm',
                     'SAExtEnvIO.pm' => 
                         '$(INST_LIBDIR)/PerlIO/via/SAExtEnvIO.pm',
                 },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR} = 'iAnywhere Solutions Inc.';
    $opts{ABSTRACT} = 'External Environment SDK glue';
    $opts{PREREQ_PM} = { 'DBD::SQLAnywhere' => 1.16 };
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$opts{LINKTYPE} = 'static' if $Config{dlsrc} =~ /dl_none/;

# Options (rarely needed)
$::opt_g = '';	# enable debugging (-g for compiler and linker)

GetOptions(qw(g!))
	or die "Invalid arguments";

$::opt_g &&= '-g';	# convert to actual string

# --- Introduction

print "\nConfiguring SAPerlGlue ...\n";

# --- Where is SQLAnywhere installed...

my $sqlpp_platform;

if( $Config{osname} eq "MSWin32" ) {
    $sqlpp_platform = "WINNT";
} elsif( $Config{ptrsize} == 8 ) {
    $sqlpp_platform = "UNIX64";
} else {
    $sqlpp_platform = "UNIX";
}

my @install_dirs;

if( defined $ENV{SADIR} ) {
    push( @install_dirs, $ENV{SADIR} );
}

my $location;
my $key;
my $type;
my $ver;
if( $Config{osname} eq "MSWin32" ) {
    for( $ver=$max_sqlanywhere_ver; $ver >= $min_sqlanywhere_ver; $ver-- ) {
	if( defined $ENV{"SQLANY${ver}"} ) {
	    push( @install_dirs, $ENV{"SQLANY${ver}"} );
	}
#	if( $main::HKEY_CURRENT_USER->Open( "Software\\Sybase\\SQL Anywhere\\${ver}.0", $key ) ) {
#	    if( $key->QueryValueEx( 'Location', $type, $location ) ) {
#		push( @install_dirs, $location );
#	    }
#	    $key->Close();
#	}
#	if( $main::HKEY_LOCAL_MACHINE->Open( "SOFTWARE\\Sybase\\SQL Anywhere\\${ver}.0", $key ) ) {
#	    if( $key->QueryValueEx( 'Location', $type, $location ) ) {
#		push( @install_dirs, $location );
#	    }
#	    $key->Close();
#	}
    }
} else {
    for( $ver=$max_sqlanywhere_ver; $ver >= $min_sqlanywhere_ver; $ver-- ) {
	if( defined $ENV{"SQLANY${ver}"} ) {
	    push( @install_dirs, $ENV{"SQLANY${ver}"} );
	}
    }
}

my $SQLAnywhere = "";
my $sqlanywhere_version_major = "";
my $dir;
my $found = 0;

foreach $dir ( @install_dirs ) {
    next if $dir eq "";

    print "searching $dir\n";

    if( $Config{osname} eq "MSWin32" ) {
        my $bitness_name = ${perl_bitness} == 64 ? 'X64' : 'X86';
	if( -d "${dir}/SDK/Lib/${bitness_name}" && -d "${dir}/SDK/Include" ) {
	    for( $ver=$max_sqlanywhere_ver; $ver >= $min_sqlanywhere_ver; $ver-- ) {
		if( -e "${dir}/SDK/Lib/${bitness_name}/dbextenv${ver}.lib" &&
                    -e "${dir}/SDK/Lib/${bitness_name}/dblibtm.lib" ) {
		    $SQLAnywhere = $dir;
		    $sqlanywhere_version_major = $ver;
		    $found = 1;
		    last;
		}
	    }
	}
    } else {
	print "searching $dir\n";

	if( -d "${dir}/lib${perl_bitness}" &&
	    -d "${dir}/bin${perl_bitness}" &&
	    -d "${dir}/${sdk_dir}/include" && 
	    ( -f "${dir}/bin64/sqlpp" || -f "${dir}/bin32/sqlpp" ) ) {

	    for( $ver=$max_sqlanywhere_ver; $ver >= $min_sqlanywhere_ver; $ver-- ) {
		if( -f "${dir}/lib${perl_bitness}/libdblib${ver}${threadext}.${so_ext}" &&
                    -f "${dir}/lib${perl_bitness}/libdbtasks${ver}${threadext}.${so_ext}" &&
                    -f "${dir}/lib${perl_bitness}/libdbextenv${ver}${threadext}.${so_ext}" &&
                    -f "${dir}/${sdk_dir}/include/sqlca.h" &&
                    -f "${dir}/${sdk_dir}/include/sqlda.h" &&
                    -f "${dir}/${sdk_dir}/include/sqldef.h" ) {
		    $SQLAnywhere = $dir;
		    $sqlanywhere_version_major = $ver;
		    $found = 1;
		    last;
		}
	    }
	}
    }
    last if $found;
}

if( !$found ) {
    die "** Unable to find SQL Anywhere installation\n\n** Please set the SQLANYxx environment variable (where xx is version number).\n";
}

print "Using SQLAnywhere version ${sqlanywhere_version_major} in $SQLAnywhere\n";

my $is_gcc;
if( "$Config{cc}" eq "gcc" ||
    "$Config{gccversion}" ne "" ) {
    $is_gcc = 1;
    printf( "Using GNU compiler\n" ); 
} else {
    $is_gcc = 0;
    printf( "Using non-GNU compiler %s\n", $Config{cc} ); 
}

my $perllib;
$perllib = $Config{libperl};
if( $Config{osname} ne "MSWin32" ) {
    $perllib =~ s/^lib//;
}
$perllib =~ s/\..*//;

my $sysliblist;
my $libdir;
$sysliblist = "";
if( $Config{osname} eq "MSWin32" ) {
    if( $Config{archname} =~ /-x64-/ ) {
	$sysliblist .= qq( -L"$SQLAnywhere/SDK/Lib/X64" );
    } else {
	$sysliblist .= qq( -L"$SQLAnywhere/SDK/Lib/X86" );
    }
    $sysliblist .= qq( -L"$Config{archlibexp}/CORE" );
    foreach $libdir ( split( /;/, $ENV{LIB} ) ) {
	$sysliblist .= qq( -L"$libdir" );
    }
    $sysliblist .= " -ldblibtm";
    $sysliblist .= " -lpsapi";
    $sysliblist .= " -ldbextenv${sqlanywhere_version_major}";
} else {
    $sysliblist .= "-L$SQLAnywhere/lib${perl_bitness} ";
    $sysliblist .= "-L$Config{archlibexp}/CORE ";
    if( $threaded ) {
	$sysliblist .= " -ldbextenv${sqlanywhere_version_major}_r -ldblib${sqlanywhere_version_major}_r -ldbtasks${sqlanywhere_version_major}_r";
    } else {
	$sysliblist .= " -ldbextenv${sqlanywhere_version_major} -ldblib${sqlanywhere_version_major} -ldbtasks${sqlanywhere_version_major}";
    }
    $sysliblist .= " -ldbodm${sqlanywhere_version_major}" if $^O eq 'darwin';
}

# On UNIX platforms, leave the perllib symbols unresolved and
# get them from the perl executable at runtime. Libperl.a is not
# built as relocatable code so linking against it now will leave
# relocations in a shared object which is forbidden on some
# platforms.
$opts{CCFLAGS} = $Config{ccflags};	
if( $Config{osname} eq "MSWin32" ) {
    $sysliblist .= " -l${perllib}";
#    $opts{CCFLAGS} =~ s/-O1//;
     $opts{CCFLAGS} =~ s/-Gf\s*/-GF /;
} elsif( "$Config{osname}" eq "solaris" ) {
    $sysliblist .= " -lsocket -lnsl -lm -lc";
    if( $is_gcc ) {
#	$opts{dynamic_lib}{OTHERLDFLAGS} .= " -Wl,-z,defs";
    } else {
	$opts{CCFLAGS} .= " -xCC -g";
#	$opts{dynamic_lib}{OTHERLDFLAGS} .= " -z defs";
    }
} elsif( "$Config{osname}" eq "hpux" ) {
    if( ! $is_gcc ) {
	$opts{CCFLAGS} =~ s/-Aa\s*//;
    }
} elsif( "$Config{osname}" eq "aix" ) {
    if( ! $is_gcc ) {
	$opts{CCFLAGS} .= " -qcpluscmt"
    }
} 

if( $is_gcc ) {
#    $opts{dynamic_lib}{OTHERLDFLAGS} .= ' -shared';
}

$opts{LIBS} = [ $sysliblist ];
if( $Config{osname} eq "MSWin32" ) {
    $opts{INC}  = qq( -I"$SQLAnywhere/${sdk_dir}/include" );
    $opts{INC}  .= qq( -I"$Config{sitearchexp}/auto/DBI" );
    $opts{DEFINE} .= ' -DWINNT -D_CRT_SECURE_NO_DEPRECATE';
    $opts{LD} = "\$(PERL) dolink.pl \$@";
} else {
    $opts{INC}  = "-I$SQLAnywhere/${sdk_dir}/include ";
    $opts{INC}  .= "-I$dbi_arch_dir ";
    $opts{DEFINE} .= ' -DUNIX';
}
$opts{INC} .= qq{ -I$SQLAnywhere/${sdk_dir}/include -I$SQLAnywhere/${sdk_dir}/perlenv };
# $opts{OPTIMIZE}="-Zi";
# $opts{dynamic_lib}{OTHERLDFLAGS} .= ' -debug';

# uncomment log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

WriteMakefile(%opts);

exit 0;


__END__
