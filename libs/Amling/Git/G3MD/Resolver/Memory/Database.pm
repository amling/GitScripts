package Amling::Git::G3MD::Resolver::Memory::Database;

use strict;
use warnings;

use Amling::Git::Utils;
use Digest;

sub _get_root
{
    my $dir = $ENV{'HOME'} . "/.gm3d/memory";
}

sub _get_lines
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my @r;
    push @r, "<<<<<<<";
    push @r, @$lhs_lines;
    push @r, "|||||||";
    push @r, @$mhs_lines;
    push @r, "=======";
    push @r, @$rhs_lines;
    push @r, ">>>>>>>";

    return \@r;
}

sub _get_id
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $sha1 = Digest->new("SHA-1");

    $sha1->add(map { "$_\n" } @{_get_lines($conflict)});

    return $sha1->hexdigest();
}

sub query
{
    my $conflict = shift;

    my $id = _get_id($conflict);
    my $fn = _get_root() . "/$id.out";

    if(-f $fn)
    {
        return Amling::Git::Utils::slurp($fn);
    }

    return undef;
}

sub record
{
    my $conflict = shift;
    my $result = shift;

    my $id = _get_id($conflict);
    Amling::Git::Utils::unslurp(_get_root() . "/$id.in", _get_lines($conflict));
    Amling::Git::Utils::unslurp(_get_root() . "/$id.out", $result);
}

1;
