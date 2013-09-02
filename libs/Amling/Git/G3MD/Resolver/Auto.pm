package Amling::Git::G3MD::Resolver::Auto;

use strict;
use warnings;

sub get_resolvers
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_text = join("\n", @$lhs_lines);
    my $mhs_text = join("\n", @$mhs_lines);
    my $rhs_text = join("\n", @$rhs_lines);

    if($lhs_text eq $mhs_text && $mhs_text eq $rhs_text)
    {
        return [['a', 'Automatic matched', sub { return [map { ['LINE', $_] } @$mhs_lines]; }]];
    }
    if($lhs_text eq $rhs_text)
    {
        return [['a', 'Automatic double', sub { return [map { ['LINE', $_] } @$lhs_lines]; }]];
    }
    if($lhs_text eq $mhs_text)
    {
        return [['a', 'Automatic right', sub { return [map { ['LINE', $_] } @$rhs_lines]; }]];
    }
    if($mhs_text eq $rhs_text)
    {
        return [['a', 'Automatic left', sub { return [map { ['LINE', $_] } @$lhs_lines]; }]];
    }

    return [];
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
