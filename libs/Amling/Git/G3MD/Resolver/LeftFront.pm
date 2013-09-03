package Amling::Git::G3MD::Resolver::LeftFront;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BasePeel;

use base ('Amling::Git::G3MD::Resolver::BasePeel');

sub hside
{
    return 'left';
}

sub vside
{
    return 'front';
}

sub peel_pair
{
    my $class = shift;
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    return [shift @$lhs_lines, shift @$mhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
