# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
package PerlIO::via::SAExtEnvIO;

use strict;

use SAPerlGlue;

sub PUSHED
{
    my ($class, $mode, $fh) = @_;
    my $buf = '';
    return bless \$buf, $class;
}

sub OPEN
{
    # open is done by the SDK.  need this to trap any open requests.
    return 1;
}

sub FDOPEN
{
    # open is done by the SDK.  need this to trap any open requests.
    return 1;
}

sub SYSOPEN
{
    # open is done by the SDK.  need this to trap any open requests.
    return 1;
}

sub WRITE
{
    my ($obj, $buff, $fh ) = @_;
#    $$obj .= $buff;
    SAPerlGlue::write_string( $buff, length( $buff ) );
    return length( $buff );
}

sub FLUSH
{
    my ($obj, $fh) = @_;
#    print $fh $$obj or return -1;
    $$obj = '';
    return 0;
}
 
1;
