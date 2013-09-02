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

sub slurp
{
    my $f = shift;

    my @lines;
    open(my $fh, '<', $f) || die "Cannot open $f for reading: $!";
    while(my $line = <$fh>)
    {
        chomp $line;
        push @lines, $line;
    }
    close($fh) || die "Cannot close $f for reading: $!";

    return \@lines;
}

sub unslurp
{
    my $f = shift;
    my $lines = shift;

    open(my $fh, '>', $f) || die "Cannot open $f for writing: $!";
    for my $line (@$lines)
    {
        print $fh "$line\n";
    }
    close($fh) || die "Cannot close $f for writing: $!";
}

1;
