package Amling::Git::G3MD::Utils;

use strict;
use warnings;

sub format_conflict
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my @ret;
    push @ret, "<<<<<<< $lhs_title";
    push @ret, @$lhs_lines;
    push @ret, "||||||| $mhs_title";
    push @ret, @$mhs_lines;
    push @ret, "=======";
    push @ret, @$rhs_lines;
    push @ret, ">>>>>>> $rhs_title";

    return \@ret;
}

1;
