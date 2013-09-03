package Amling::Git::G3MD::Resolver::Ours;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['ours', '<'];
}

sub description
{
    return 'Accept LHS.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    return [map { ['LINE', $_] } @$lhs_lines];
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
