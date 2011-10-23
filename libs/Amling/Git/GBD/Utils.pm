package Amling::Git::GBD::Utils;

use strict;
use warnings;

use Data::Dumper;

sub save_object
{
    my $file = shift;
    my $object = shift;

    my $fh;
    if($file eq "-")
    {
        open($fh, ">&STDOUT") || die "Cannot open $file: $!";
    }
    else
    {
        open($fh, ">", $file) || die "Cannot open $file: $!";
    }
    my $d = Data::Dumper->new([$object]);
    $d->Purity(1);
    print $fh $d->Dump($object);

    close($fh) || die "Cannot close $file: $!";
}

sub load_object
{
    my $file = shift;

    my $fh;
    if($file eq "-")
    {
        open($fh, "<&STDIN") || die "Cannot open $file: $!";
    }
    else
    {
        open($fh, "<", $file) || die "Cannot open $file: $!";
    }
    my $s = join("", <$fh>);
    close($fh) || die "Cannot close $file: $!";
    my $r;
    {
        no warnings;
        no strict;
        $r = eval($s);
    }
    if($@)
    {
        die "While parsing state file: $@";
    }
    return $r;
}

sub choose_cutpoint
{
    my $state = shift;
    # clone state...

    my @minima = $state->find_bad_minima();
    if(!@minima)
    {
        die "No BAD?";
    }
    my $root_bad = $minima[0]->[0];
    my $gap_weight = 0;
    for my $upstream (@{_find_upstreams($state, {}, $root_bad)})
    {
        if($upstream ne $root_bad)
        {
            $gap_weight += $state->get_weight($upstream);
        }
    }
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

        # find all the upstreams between cut and GOOD (not block!) to see how cut does
        my $cut_upstreams = _find_upstreams($state, {}, $cut);
        my $cut_upstream_weight = 0;
        for my $upstream (@$cut_upstreams)
        {
            $cut_upstream_weight += $state->get_weight($upstream);
        }
        if($cut_upstream_weight >= $gap_weight / 2)
        {
            # too far, take it as new $bad
            $bad = $cut;
        }
        else
        {
            # not too far enough, put $cut's upstreams in %block
            for my $upstream (@$cut_upstreams)
            {
                $block{$upstream} = 1;
            }
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
        my $known = $state->get_known($commit);
        if(defined($known) && $known eq 'GOOD')
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
