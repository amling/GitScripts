package Amling::Git::GBD::Strategy::Default;

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
    # clone state...

    my @minima = $state->find_bad_minima();
    if(!@minima)
    {
        die "No BAD?";
    }
    my $root_bad = $minima[0]->[0];
    my $gap_weight = $state->get_cumulative_weight($root_bad);
    my $bad = $root_bad;
    my %block;
    while(1)
    {
        # find all the upstreams between $bad and %block to pick our random cut point
        my $upstreams = _find_upstreams($state, \%block, $bad);
        # don't include $bad itself
        $upstreams = [grep { $_ ne $bad } @$upstreams];
        if(!@$upstreams)
        {
            # hmm, bad is as good as it gets (all its upstreams are blocked)
            if($bad ne $root_bad)
            {
                # it's in the middle of the tree, good
                return $bad;
            }
            else
            {
                # ballz, none of our parents meet it, we should take whichever has the most above them
                return _choose_best_parent($state, $bad);
            }
        }
        my $cut = $upstreams->[int(rand() * @$upstreams)];

        # see how cut does
        if($state->get_cumulative_weight($cut) >= $gap_weight / 2)
        {
            # too far, take it as new $bad
            $bad = $cut;
        }
        else
        {
            # not too far enough, block $cut
            $block{$cut} = 1;
        }
    }
}

sub _choose_best_parent
{
    my $state = shift;
    my $bad = shift;

    my $best = undef;
    my $best_weight = undef;
    for my $parent ($state->get_parents($bad))
    {
        my $parent_upstreams = _find_upstreams($state, {}, $parent);
        if(!@$parent_upstreams)
        {
            next;
        }
        my $parent_upstream_weight = 0;
        for my $upstream (@$parent_upstreams)
        {
            $parent_upstream_weight += $state->get_weight($upstream);
        }
        if(!defined($best) || $parent_upstream_weight > $best_weight)
        {
            $best = $parent;
            $best_weight = $parent_upstream_weight;
        }
    }

    if(defined($best))
    {
        return $best;
    }
    else
    {
        # OK, parents are actually all good, we're solved but we "checkout"
        # $bad anyway
        return $bad;
    }
}

sub _find_upstreams
{
    my $state = shift;
    my $blockr = shift;
    my $bad = shift;

    my @upstreams;
    my $cb = sub
    {
        my $commit = shift;
        if($blockr->{$commit})
        {
            return 0;
        }
        if($state->is_good($commit))
        {
            return 0;
        }
        push @upstreams, $commit;
        return 1;
    };
    $state->traverse_up($bad, $cb);

    return \@upstreams;
}

1;
