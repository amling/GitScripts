package Amling::Git::G3MD::Resolver::Sort;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['sort', 's'];
}

sub description
{
    return 'Process conflict as a sorted list.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my %lhs_lines;
    my %mhs_lines;
    my %rhs_lines;
    my %all_lines;

    for my $pair ([\%lhs_lines, $lhs_lines], [\%mhs_lines, $mhs_lines], [\%rhs_lines, $rhs_lines])
    {
        my ($hr, $ar) = @$pair;

        for my $line (@$ar)
        {
            return undef if($hr->{$line});
            $hr->{$line} = 1;
            $all_lines{$line} = 1;
        }
    }

    my @ret;
    for my $line (sort(keys(%all_lines)))
    {
        my $lhs_present = $lhs_lines{$line} || 0;
        my $mhs_present = $mhs_lines{$line} || 0;
        my $rhs_present = $rhs_lines{$line} || 0;

        my $present;
        if($lhs_present == $rhs_present)
        {
            $present = $lhs_present;
        }
        elsif($lhs_present == $mhs_present)
        {
            $present = $rhs_present;
        }
        elsif($mhs_present == $rhs_present)
        {
            $present = $lhs_present;
        }
        else
        {
            die;
        }

        push @ret, ['LINE', $line] if($present);
    }

    return \@ret;
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
