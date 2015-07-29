package Amling::Git::G3MD::Parser;

use strict;
use warnings;

sub parse_3way
{
    my $lines = shift;

    my @blocks;

    my $s = 0;
    my $lhs_title = undef;
    my $mhs_title = undef;
    my $rhs_title = undef;
    my @lhs;
    my @mhs;
    my @rhs;
    for my $line (@$lines)
    {
        if(0)
        {
        }
        elsif($s == 0)
        {
            if($line =~ /^<<<<<<< (.*)$/)
            {
                $s = 1;
                $lhs_title = $1;
            }
            else
            {
                push @blocks, ['LINE', $line];
            }
        }
        elsif($s == 1)
        {
            if($line =~ /^\|\|\|\|\|\|\| (.*)$/)
            {
                $s = 2;
                $mhs_title = $1;
            }
            else
            {
                push @lhs, $line;
            }
        }
        elsif($s == 2)
        {
            if($line =~ /^=======$/)
            {
                $s = 3;
            }
            else
            {
                push @mhs, $line;
            }
        }
        elsif($s == 3)
        {
            if($line =~ /^>>>>>>> (.*)$/)
            {
                $rhs_title = $1;

                push @blocks,
                [
                    'CONFLICT',
                    $lhs_title,
                    [@lhs],
                    $mhs_title,
                    [@mhs],
                    $rhs_title,
                    [@rhs],
                ];

                $s = 0;
                $lhs_title = undef;
                $mhs_title = undef;
                $rhs_title = undef;
                @lhs = ();
                @mhs = ();
                @rhs = ();
            }
            else
            {
                push @rhs, $line;
            }
        }
        else
        {
            die;
        }
    }

    if($s != 0)
    {
        die "Parser error, s=$s, is input in diff3 format?";
    }

    return \@blocks;
}

sub parse_2way
{
    my $lines = shift;

    my @blocks;

    my $s = 0;
    my $lhs_title = undef;
    my $rhs_title = undef;
    my @lhs;
    my @rhs;
    for my $line (@$lines)
    {
        if(0)
        {
        }
        elsif($s == 0)
        {
            if($line =~ /^<<<<<<< (.*)$/)
            {
                $s = 1;
                $lhs_title = $1;
            }
            else
            {
                push @blocks, ['LINE', $line];
            }
        }
        elsif($s == 1)
        {
            if($line =~ /^=======$/)
            {
                $s = 2;
            }
            else
            {
                push @lhs, $line;
            }
        }
        elsif($s == 2)
        {
            if($line =~ /^>>>>>>> (.*)$/)
            {
                $rhs_title = $1;

                push @blocks,
                [
                    'CONFLICT',
                    $lhs_title,
                    [@lhs],
                    $rhs_title,
                    [@rhs],
                ];

                $s = 0;
                $lhs_title = undef;
                $rhs_title = undef;
                @lhs = ();
                @rhs = ();
            }
            else
            {
                push @rhs, $line;
            }
        }
        else
        {
            die;
        }
    }

    if($s != 0)
    {
        die;
    }

    return \@blocks;
}

1;
