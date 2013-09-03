package Amling::Git::G3MD::Resolver::BasePeel;

use strict;
use warnings;

sub _names
{
    my $class = shift;

    my $hside = $class->hside();
    my $vside = $class->vside();

    return [substr($hside, 0, 1) . substr($vside, 0, 1), "$hside$vside"];
}

sub handle
{
    my $class = shift;
    my $line = shift;
    my $conflict = shift;

    for my $name (@{$class->_names()})
    {
        if($line =~ /^\s*\Q$name\E\s*$/)
        {
            return $class->_handle2(1, $conflict);
        }
        if($line =~ /^\s*\Q$name\E\s+(\d+)\s*$/)
        {
            return $class->_handle2($1, $conflict);
        }
        if($line =~ /^\s*\Q$name\E\s+(?:\*|ALL)\s*$/)
        {
            return $class->_handle2(undef, $conflict);
        }
    }

    return undef;
}

sub _handle2
{
    my $class = shift;
    my $depth = shift;
    my $conflict = shift;

    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_lines1 = [@$lhs_lines];
    my $mhs_lines1 = [@$mhs_lines];
    my $rhs_lines1 = [@$rhs_lines];

    my @ret;
    for(my $d = 0; !defined($depth) || $d < $depth; ++$d)
    {
        my ($one, $two) = @{$class->peel_pair($lhs_lines1, $mhs_lines1, $rhs_lines1)};
        if(!defined($one) || !defined($two) || $one ne $two)
        {
            last if(!defined($depth));
            return undef;
        }

        push @ret, ['LINE', $one];
    }

    if(@$lhs_lines1 || @$mhs_lines1 || @$rhs_lines1)
    {
        push @ret,
        [
            'CONFLICT',
            $lhs_title,
            $lhs_lines1,
            $mhs_title,
            $mhs_lines1,
            $rhs_title,
            $rhs_lines1,
        ];
    }

    return \@ret;
}

sub help
{
    my $class = shift;

    my $hside = $class->hside();
    my $vside = $class->vside();

    return [$class->_names()->[0], "{" . join("|", @{$class->_names()}) . "} [<N> | * | ALL] - Peel matching line(s) (defaults 1) from $hside $vside."];
}

1;
