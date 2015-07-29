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
    my @lhs;
    my @mhs;
    my @rhs;
    for my $line (@$lines)
    {
        my $marker = undef;
        my $marker_title = undef;
        if($line =~ /^([<|>=])\1{6}(?: (.*))?$/)
        {
            $marker = $1;
            $marker_title = $2;
        }

        if(0)
        {
        }
        elsif($s == 0)
        {
            if(defined($marker))
            {
                if($marker eq '<')
                {
                    $s = 1;
                    $lhs_title = $marker_title || 'LHS';
                }
                else
                {
                    die "Bad marker $marker found starting block?";
                }
            }
            else
            {
                push @blocks, ['LINE', $line];
            }
        }
        elsif($s == 1)
        {
            if(defined($marker))
            {
                if($marker eq '|')
                {
                    $s = 2;
                    $mhs_title = $marker_title || 'MHS';
                }
                else
                {
                    my $note = '';
                    if($marker eq '=')
                    {
                        $note = " are you sure your conflict blocks are in diff3 style";
                    }
                    die "Bad marker $marker found in LHS$note?";
                }
            }
            else
            {
                push @lhs, $line;
            }
        }
        elsif($s == 2)
        {
            if(defined($marker))
            {
                if($marker eq '=')
                {
                    $s = 3;
                }
                else
                {
                    die "Bad marker $marker found in MHS?";
                }
            }
            else
            {
                push @mhs, $line;
            }
        }
        elsif($s == 3)
        {
            if(defined($marker))
            {
                if($marker eq '>')
                {
                    my $rhs_title = $marker_title;

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
                    die "Bad marker $marker found in RHS?";
                }
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
        die "Block did not complete by EOF?";
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
