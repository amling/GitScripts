package Amling::Git::GBD::Strategy;

use strict;
use warnings;

sub find
{
    my $strategy = shift;

    if(!defined($strategy))
    {
        $strategy = 'default';
    }

    $strategy =~ s/^(.)/\U$1/;

    if($strategy =~ /[^A-Za-z]/)
    {
        die "Bad strategy: $strategy";
    }

    require "Amling/Git/GBD/Strategy/$strategy.pm";

    return "Amling::Git::GBD::Strategy::$strategy"->new();
}

1;
