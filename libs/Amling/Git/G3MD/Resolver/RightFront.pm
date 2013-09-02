package Amling::Git::G3MD::Resolver::RightFront;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BasePeel;

use base ('Amling::Git::G3MD::Resolver::BasePeel');

sub label
{
    return 'rf';
}

sub description
{
    my $class = shift;
    my $nbr = shift;

    return "Peel $nbr matching right-front line(s)";
}

sub peel_pair
{
    my $class = shift;
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    return [shift @$mhs_lines, shift @$rhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver_source(sub { return __PACKAGE__->get_resolvers(@_); });

1;
