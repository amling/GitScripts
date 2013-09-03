package Amling::Git::G3MD::Algo;

use strict;
use warnings;

sub dfs
{
    my $cb = shift;

    my $first = $cb->{'first'};
    my $last = $cb->{'last'};

    my %already = ($first => undef);
    my %q = (0 => [$first]);
    my $d = 0;
    SRCH:
    while(%q)
    {
        my $sqr = $q{$d};
        if(!defined($sqr))
        {
            ++$d;
            next;
        }
        if(!@$sqr)
        {
            delete $q{$d};
            ++$d;
            next;
        }

        my $e = shift @$sqr;

        for my $ne_pair (@{$cb->{'step'}->($e)})
        {
            my ($ne, $step) = @$ne_pair;

            next if($already{$ne});
            $already{$ne} = $e;

            last SRCH if($ne eq $last);

            my $d2 = $d + $step;
            push @{$q{$d} ||= []}, $ne;
        }
    }

    my $pos = $last;
    my @ret;
    while(1)
    {
        my $prev = $already{$pos};
        last unless(defined($prev));

        unshift @ret, $cb->{'result'}->($prev, $pos);

        $pos = $prev;
    }

    return \@ret;
}

1;
