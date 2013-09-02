package Amling::Git::G3MD::Resolver::LeftBack;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BasePeel;

use base ('Amling::Git::G3MD::Resolver::BasePeel');

sub label
{
    return 'lb';
}

sub description
{
    my $class = shift;
    my $nbr = shift;

    return "Peel $nbr matching left-back line(s)";
}

sub peel_pair
{
    my $class = shift;
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    return [pop @$lhs_lines, pop @$mhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver_source(sub { return __PACKAGE__->get_resolvers(@_); });

1;
