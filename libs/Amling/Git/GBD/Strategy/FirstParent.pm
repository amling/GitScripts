package Amling::Git::GBD::Strategy::FirstParent;

sub new
{
    my $class = shift;

    my $self =
    {
    };

    bless $self, $class;

    return $self;
}

sub choose_cutpoint
{
    my $this = shift;
    my $state = shift;

    my @minima = $state->find_bad_minima();
    if(!@minima)
    {
        die "No BAD?";
    }
    my $bad = $minima[0]->[0];

    # build the search range (doesn't include $bad, doesn't include anything GOOD)
    my @range;
    {
        my $c = $bad;
        while(1)
        {
            my @parents = $state->get_parents($c);
            if(!@parents)
            {
                last;
            }
            $c = $parents[0];
            if($state->is_good($c))
            {
                last;
            }
            push @range, $c;
        }
    }

    if(!@range)
    {
        # we're done bisecting this tier

        # search for an unknown parent (first parent is known good but code is
        # cleaner with recheck)
        for my $parent ($state->get_parents($bad))
        {
            if(!$state->is_good($parent))
            {
                # this parent is unknown, test it
                return $parent;
            }
        }

        # actually, all parents were good, we're done
        return $bad;
    }

    # weight to $bad is "too much" since we're not eliglble to check any of the
    # other parents
    my $gap_weight = $state->get_cumulative_weight($range[0]);

    my $l = 0; # $l is known to be sufficient weight
    my $h = @range; # $h is known to be insufficient weight
    while(1)
    {
        if($l + 1 == $h)
        {
            return $range[$l];
        }
        my $m = $l + int(($h - $l) / 2);
        my $w = $state->get_cumulative_weight($range[$m]);
        if($w >= $gap_weight / 2)
        {
            $l = $m;
        }
        else
        {
            $h = $m;
        }
    }
}

1;
