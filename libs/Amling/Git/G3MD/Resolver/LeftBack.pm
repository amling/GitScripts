package Amling::Git::G3MD::Resolver::LeftBack;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BasePeel;

use base ('Amling::Git::G3MD::Resolver::BasePeel');

sub names
{
    return ['lb', 'leftback'];
}

sub peel_pair
{
    my $class = shift;
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    return [pop @$lhs_lines, pop @$mhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver(sub { return __PACKAGE__->handle(@_); });

1;
