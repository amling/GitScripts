package Amling::Git::G3MD::Resolver::Auto;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['automatic', 'auto', 'a'];
}

sub description
{
    return 'Do the right thing if two or more sides match.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_text = join("\n", @$lhs_lines);
    my $mhs_text = join("\n", @$mhs_lines);
    my $rhs_text = join("\n", @$rhs_lines);

    if($lhs_text eq $mhs_text && $mhs_text eq $rhs_text)
    {
        return [map { ['LINE', $_] } @$mhs_lines];
    }
    if($lhs_text eq $rhs_text)
    {
        return [map { ['LINE', $_] } @$lhs_lines];
    }
    if($lhs_text eq $mhs_text)
    {
        return [map { ['LINE', $_] } @$rhs_lines];
    }
    if($mhs_text eq $rhs_text)
    {
        return [map { ['LINE', $_] } @$lhs_lines];
    }

    return undef;
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
