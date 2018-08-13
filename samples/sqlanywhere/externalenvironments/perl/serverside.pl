# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************
# This sample code is provided AS IS, without warranty or liability of
# any kind.
# 
# You may use, reproduce, modify and distribute this sample code without
# limitation, on the condition that you retain the foregoing copyright 
# notice and disclaimer as to the original code.  
# 
# *******************************************************************

# Subroutines for demonstrating server-side perl support

sub sperl_create_table
{
    # subroutine to create a table using server-side perl
    $sa_perl_default_connection->do( "CREATE TABLE sperl_Tab( c1 int, c2 char(128), c3 smallint, c4 double, c5 numeric(30,6) )" ) or die $DBI::errstr;
}

sub sperl_populate_table
{
    # subroutine to populate the above table using server-side perl
    # input variable is the number of rows to populate
    
    my $sth = $sa_perl_default_connection->prepare( "INSERT INTO sperl_Tab VALUES( ?, ?, ?, ?, ? )" );
    for( my $i = 1; $i <= $_[0]; $i++ )
    {
        $sth->bind_param( 1, $i );
	$sth->bind_param( 2, "This is row #$i" );
	$sth->bind_param( 3, 8000+$i );
	$sth->bind_param( 4, $i/0.03 );
	$sth->bind_param( 5, "0.0$i" );
	$sth->execute();
    }
    $sth = undef;
    $sa_perl_default_connection->commit();
}

sub sperl_update_table
{
    # subroutine to update the above table using server-side perl
    $sa_perl_default_connection->do( "UPDATE sperl_Tab SET c1 = c3" );
    $sa_perl_default_connection->commit();
}

sub sperl_delete_table
{
    # subroutine to delete from the above table using server-side perl
    $sa_perl_default_connection->do( "DELETE FROM sperl_Tab" );
    $sa_perl_default_connection->commit();
}

sub sperl_drop_table
{
    # subroutine to drop the above table using server-side perl
    $sa_perl_default_connection->do( "DROP TABLE sperl_Tab" ) or die $sa_perl_default_connection->errstr;
}

