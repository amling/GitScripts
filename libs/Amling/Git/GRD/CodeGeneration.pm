package Amling::Git::GRD::CodeGeneration;

use strict;
use warnings;

use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

# TODO: eliminate strictly redundant parents in a merge...
# e.g.  if M is from A, B, and C and A <= C then drop A.
# This is actually fairly complicated because even if A is a merge of things in C we want to drop it.
# The rule should probably be drop A if there is a B present s.t.  all closest, non-merge ancestors of A are contained in B.
# Unfortunately there could be an A and a B that would eliminate each other with this definition, i.e.  it lacks anti-symmetry.
# TODO: well, maybe do something about stupid merges...

# TODO: think hard about whether or not peephole optimization will clean up this mess

# TODO: peephole optimizers need to understand comment branch comments (I think this only blocks load/save pair which is useless anyway)
# TODO: peephole optimization for load/save pair (alias, ugh, this is only for 1-parent-left merge, fuck it)
# Ugh, consider:
#
# ...
# save alias1
# ...
# load alias1
# <implicit merge of single useful branch>
# # branch xxx
# save alias2
# ...
# load alias1
# ...
# load alias2
# ...
# load alias2
# ...
#
# The xxx branch comment should probably get moved to above save alias1?  But
# that looks funny and we probably shouldn't rename alias1 due to use
# elsewhere...  Thankfully I think this is only screwed up in 1-parent merges.

# better "algorithm"?
#     given a DAG (has-parent)
#     produce total order to minimize {(i, j) | j != i + 1 && (x_i, x_j) \in edges}
#     will necessarily put root first
#     each multiple-children point contributes the same amount of half edges no matter the layout
#     each multiple-parent point contriubtes the same amount of half edges no matter the layout
#     and we needn't take any more
#     notably each single link is always rendered adjacent (parent can only be included via child and is thus immediate)
#     so we're actually optimal?
#
# yeah, we can maybe do better (simpler?) by building the DAG of
# actual picks themselves first and then laying that out?

sub generate
{
    my $head_options = shift;
    my $plus_options = shift;
    my $minus_options = shift;
    my $tree_options = shift;

    $head_options = process_HEAD($head_options);
    $plus_options = process_HEAD($plus_options);
    $minus_options = {%$minus_options};
    $tree_options = {%$tree_options};

    # convert trees to plusses
    {
        # First find all "maximal" commits in the tree (i.e.  where the tree branches off)
        my %maximal_tree_commits;
        for my $tree (keys(%$tree_options))
        {
            # dump out upstream section
            my @tree_commits;
            my %tree_commits;
            my $cb = sub
            {
                my $h = shift;
                push @tree_commits, $h;
                $tree_commits{$h->{'hash'}} = 1;
            };
            Amling::Git::Utils::log_commits([(map { "^$_" } keys(%$minus_options)), $tree], $cb);

            # now find those that have no parents in the upstream section (all i.e.  parents in the base)
            for my $h (@tree_commits)
            {
                my $maximal = 1;
                for my $p (@{$h->{'parents'}})
                {
                    if($tree_commits{$p})
                    {
                        $maximal = 0;
                        last;
                    }
                }
                if($maximal)
                {
                    $maximal_tree_commits{$h->{'hash'}} = 1;
                }
            }
        }

        # now iterate over branches that contain each maximal tree commit
        for my $commit (keys(%maximal_tree_commits))
        {
            open(my $fh, '-|', 'git', 'branch', '--contains', $commit) || die "Cannot open list branches containing $commit: $!";
            while(my $line = <$fh>)
            {
                chomp $line;

                $line =~ s/^..//;

                # this BS probably won't happen but let's be sure
                next if($line eq "(no branch)");

                my $branch = $line;

                if($head_options->{$branch})
                {
                    # already included as head
                }
                else
                {
                    $plus_options->{$branch} = 1;
                }
            }
            close($fh) || die "Cannot close list branches containing $commit: $!";
        }
    }

    my $commit_commands = {};
    {
        open(my $fh, '-|', 'git', 'show-ref') || die "Cannot open git show-ref: $!";
        while(my $line = <$fh>)
        {
            if($line =~ /^([0-9a-f]{40}) (.*)$/)
            {
                my ($commit, $ref) = ($1, $2);
                if($ref =~ /^refs\/heads\/(.*)$/)
                {
                    my $name = $1;
                    if(delete($head_options->{$name}))
                    {
                        push @{$commit_commands->{$commit} ||= []}, [$name, "head $name"];
                    }
                    elsif(delete($plus_options->{$name}))
                    {
                        push @{$commit_commands->{$commit} ||= []}, [$name, "branch $name"];
                    }
                    else
                    {
                        push @{$commit_commands->{$commit} ||= []}, [$name, "# branch $name"];
                    }
                }
            }
            else
            {
                die "Bad line: $line";
            }
        }
        close($fh) || die "Cannot close git show-ref: $!";
    }

    # we assume things that we couldn't name as branches are to become detached heads
    for my $head_option (keys(%$head_options))
    {
        my $commit = Amling::Git::Utils::convert_commitlike($head_option);
        my $command = [$head_option, "head # (?) from $head_option"];
        if($head_option eq 'HEAD')
        {
            $command = ["!", "head"];
        }
        push @{$commit_commands->{$commit} ||= []}, $command;
    }

    # we assume things that we couldn't name as branches are ... something
    for my $plus_option (keys(%$plus_options))
    {
        my $commit = Amling::Git::Utils::convert_commitlike($plus_option);
        my $command = [$plus_option, "# (?) branch $plus_option"];
        if($plus_option eq 'HEAD')
        {
            next;
        }
        push @{$commit_commands->{$commit} ||= []}, $command;
    }

    my @targets = sort(keys(%{{map { Amling::Git::Utils::convert_commitlike($_) => 1 } keys(%$head_options), keys(%$plus_options)}}));

    my %parents;
    my %subjects;
    my $cb = sub
    {
        my $h = shift;
        my $commit = $h->{'hash'};

        $parents{$commit} = $h->{'parents'};
        $subjects{$commit} = $h->{'msg'};
    };
    Amling::Git::Utils::log_commits([(map { "^$_" } keys(%$minus_options)), @targets], $cb);

    my %nodes =
    (
        'base' =>
        {
            'loads' => 0,
            'commands' => [],
            ...
        }
    );
    my %old_new;

    for my $target (@targets)
    {
        build_nodes($target, \%nodes, \%old_new, \%parents, \%subjects);
    }

    for my $commit (keys($commit_commands))
    {
        push @{$nodes{$old_new{$commit}}->{'commands'}}, @{$commit_commands->{$commit}};
    }

    for my $node (values(%nodes))
    {
        @{$node->{'commands'}} = map { $_->[1] } sort { ($a->[0] cmp $b->[0]) || ($a->[1] cmp $b->[1]) } @{$node->{'commands'}};
    }

    my @new_targets = sort(keys(%{{map { $old_new{$_} => 1 } @targets}}));

    for my $new_target (@new_targets)
    {
        # generate $node->{$new_target}
    }

    # return arrayref of lines
}

sub build_nodes
{
    my $target = shift;
    my $nodes = shift;
    my $old_new = shift;
    my $parents = shift;
    my $subjects = shift;

    if(!$parents->{$target})
    {
        # hit base
        return 'base';
    }

    my $new = $old_new->{$target};
    if(defined($new))
    {
        return $new;
    }

    my @mparents = @{$parents->{$target}};
    if(@mparents == 1)
    {
        my $parent = build_nodes($mparents[0], $nodes, $old_new, $parents, $subjects);

        # no matter what we load result (base or otherwise) and map to ourselves
        ++$nodes->{$parent}->{'loads'};
        $nodes->{$target} =
        {
            'loads' => 0,
            'commands' => [],
            ... # pick of $target over $parent
        };
        return $old_new->{$target} = $target;
    }
    else
    {
        my @new_parents;
        my %new_parents;

        for my $parent (@mparents)
        {
            my $new_parent = build_nodes($parent, $loads, $parents, $old_new);

            if($new_parent ne 'base')
            {
                if(!$new_parents{$new_parent})
                {
                    push @new_parents, $new_parent;
                    $new_parents{$new_parent} = 1;
                }
            }
        }

        if(@new_parents == 0)
        {
            return $old_new->{$target} = "base";
        }

        if(@new_parents == 1)
        {
            return $old_new->{$target} = $new_parents[0];
        }

        for my $new_parent (@new_parents)
        {
            # force a save
            $nodes->{$new_parent}->{'loads'} += 2;
        }
        $nodes->{$target} =
        {
            'loads' => 0,
            'commands' => [],
            ... # merge...
        };
        return $old_new->{$target} = $target;
    }
}

sub process_HEAD
{
    my $r = shift;

    my $head_branch = undef;
    {
        open(my $fh, '-|', 'git', 'symbolic-ref', '-q', 'HEAD') || die "Cannot open git symbolic-ref: $!";
        while(my $line = <$fh>)
        {
            chomp $line;
            if($line =~ /^refs\/heads\/(.*)$/)
            {
                $head_branch = $1;
            }
        }
        close($fh); # do not die, if HEAD is detached this fails, stupid fucking no good way to figure that out
    }

    my $r2 = {};
    for my $k (keys(%$r))
    {
        my $k2 = $k;
        if($k eq 'HEAD')
        {
            if(defined($head_branch))
            {
                $k2 = $head_branch;
            }
            else
            {
                $k2 = 'HEAD';
            }
        }
        $r2->{$k2} = 1;
    }

    return $r2;
}

1;
