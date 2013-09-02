package Amling::Git::G3MD::Resolver::BasePeel;

use strict;
use warnings;

sub get_resolvers
{
    my $class = shift;
    my $conflict = shift;

    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_lines1 = [@$lhs_lines];
    my $mhs_lines1 = [@$mhs_lines];
    my $rhs_lines1 = [@$rhs_lines];

    my $depth = 0;
    while(1)
    {
        my ($one, $two) = @{$class->peel_pair($lhs_lines1, $mhs_lines1, $rhs_lines1)};
        if(!defined($one) || !defined($two) || $one ne $two)
        {
            last;
        }
        ++$depth;
    }

    my @ret;

    if($depth >= 1)
    {
        push @ret, [$class->label(), $class->description(1), sub { return $class->_handle($conflict, 1); }];
    }
    for(my $d = 1; $d < $depth; ++$d)
    {
        my $d_copy = $d;
        push @ret, ["#$d" . $class->label(), $class->description($d), sub { return $class->_handle($conflict, $d_copy); }];
    }
    if($depth > 1)
    {
        push @ret, [$depth . $class->label(), $class->description($depth), sub { return $class->_handle($conflict, $depth); }];
    }
    push @ret, [($depth > 1 ? "" : "#") . "*" . $class->label(), $class->description('ALL'), sub { return $class->_handle($conflict, $depth); }];

    return \@ret;
}

sub _handle
{
    my $class = shift;
    my $conflict = shift;
    my $depth = shift;

    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_lines1 = [@$lhs_lines];
    my $mhs_lines1 = [@$mhs_lines];
    my $rhs_lines1 = [@$rhs_lines];

    my @ret;
    for(my $i = 0; $i < $depth; ++$i)
    {
        my $pair = $class->peel_pair($lhs_lines1, $mhs_lines1, $rhs_lines1);
        die unless($pair->[0] eq $pair->[1]);
        push @ret, ['LINE', $pair->[0]];
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

1;
