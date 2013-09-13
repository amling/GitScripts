package Amling::Git::GRD::CodeGeneration;

use strict;
use warnings;

use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

sub new
{
    my $class = shift;

    my $this =
    {
        'HEAD_OPTIONS' => {},
        'PLUS_OPTIONS' => {},
        'MINUS_OPTIONS' => [],
        'TREE_OPTIONS' => {},
    };

    bless $this, $class;

    return $this;
}

sub options
{
    my $this = shift;

    my $first_is_negative = 1;
    my $current_default_onto = undef;
    my $head_options = $this->{'HEAD_OPTIONS'};
    my $plus_options = $this->{'PLUS_OPTIONS'};
    my $minus_options = $this->{'MINUS_OPTIONS'};
    my $tree_options = $this->{'TREE_OPTIONS'};

    return
    (
        "onto=s" => sub { $current_default_onto = $_[1]; push @$minus_options, [$_[1], $_[1]]; },
        "head=s" => sub { $head_options->{$_[1]} = 1; },

        "plus=s" => sub { $plus_options->{$_[1]} = 1; },
        "minus=s" => sub
        {
            my $v = $_[1];

            if($v =~ /^(.*):(.*)$/)
            {
                push @$minus_options, [$1, $2];
            }
            else
            {
                die "Single argument --minus given before --onto?" unless $current_default_onto;
                push @$minus_options, [$v, $current_default_onto];
            }

            $first_is_negative = 0;
        },
        "fixed-minus=s" => sub
        {
            push @$minus_options, [$_[1], "SELF"];
            $first_is_negative = 0;
        },

        "<>" => sub
        {
            my $arg = "" . $_[0];
            if($first_is_negative)
            {
                if(!defined($current_default_onto))
                {
                    $current_default_onto = $arg;
                }
                push @$minus_options, [$arg, $current_default_onto];
                $first_is_negative = 0;
                return;
            }

            if(!%$head_options)
            {
                $head_options->{$arg} = 1;
                return;
            }

            $plus_options->{$arg} = 1;
        },

        "tree=s" => sub { $tree_options->{$_[1]} = 1; },
    );
}

sub finish_options
{
    my $this = shift;

    my $head_options = $this->{'HEAD_OPTIONS'};
    my $plus_options = $this->{'PLUS_OPTIONS'};
    my $tree_options = $this->{'TREE_OPTIONS'};

    if(!%$head_options && !%$plus_options && !%$tree_options)
    {
        $head_options->{'HEAD'} = 1;
    }
}

sub generate
{
    my $this = shift;

    my $head_options = $this->{'HEAD_OPTIONS'};
    my $plus_options = $this->{'PLUS_OPTIONS'};
    my $minus_options = $this->{'MINUS_OPTIONS'};
    my $tree_options = $this->{'TREE_OPTIONS'};

    # use of $minus_options below is boned

    # and we should probably convert_commitlike minus_options since we don't
    # want the target we're transplanting on to to slide around...

    $head_options = process_HEAD($head_options);
    $plus_options = process_HEAD($plus_options);
    $minus_options = [map { [Amling::Git::Utils::convert_commitlike($_->[0]), ($_->[1] eq "SELF" ? "SELF" : Amling::Git::Utils::convert_commitlike($_->[1]))] } @$minus_options];

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
            Amling::Git::Utils::log_commits([(map { "^" . $_->[0] } @$minus_options), $tree], $cb);

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
                next if($line =~ /^\(.*\)$/);

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

    my @targets = sort(keys(%{{map { Amling::Git::Utils::convert_commitlike($_) => 1 } keys(%$head_options), keys(%$plus_options)}}));

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

    my %parents;
    my %subjects;
    my $log_cb = sub
    {
        my $h = shift;
        my $commit = $h->{'hash'};

        $parents{$commit} = $h->{'parents'};
        $subjects{$commit} = $h->{'msg'};
    };
    Amling::Git::Utils::log_commits([(map { "^" . $_->[0] } @$minus_options), @targets], $log_cb);

    my %nodes;
    my %old_new;

    for my $target (@targets)
    {
        build_nodes($target, \%nodes, \%old_new, $minus_options, \%parents, \%subjects, 1);
    }

    for my $commit (keys(%$commit_commands))
    {
        if(!defined($old_new{$commit}))
        {
            # wasn't part of our remapping, skip it
            next;
        }
        push @{$nodes{$old_new{$commit}}->{'commands'}}, @{$commit_commands->{$commit}};
    }

    for my $node (values(%nodes))
    {
        @{$node->{'commands'}} = map { $_->[1] } sort { ($a->[0] cmp $b->[0]) || ($a->[1] cmp $b->[1]) } @{$node->{'commands'}};
    }

    my @new_targets = sort(keys(%{{map { $old_new{$_} => 1 } @targets}}));

    my @pregenerated_targets = grep { $nodes{$_}->{'generated'} } @new_targets;

    # if it will get loaded further down the line don't generate it directly to
    # avoid interleaving stuff stupidly
    @new_targets = grep { $nodes{$_}->{'loads'} == 0 } @new_targets;

    my @ret;
    for my $new_target (@new_targets)
    {
        my $build_cb = sub
        {
            my $self = shift;
            my $target = shift;
            my $load = shift;

            my $node = $nodes{$target};

            if($node->{'generated'})
            {
                if($load)
                {
                    push @ret, "load " . $node->{'generated'};
                }
                return;
            }

            $node->{'build'}->(sub { return $self->($self, @_) }, \@ret);

            push @ret, @{$node->{'commands'}};

            if($node->{'loads'} > 1 && $target ne "base")
            {
                push @ret, "save new-$target";
            }

            $node->{'generated'} = "tag:new-$target";
        };
        $build_cb->($build_cb, $new_target, 0);
    }

    for my $pregenerated_target (@pregenerated_targets)
    {
        my $node = $nodes{$pregenerated_target};
        if(@{$node->{'commands'}})
        {
            push @ret, "load " . $node->{'generated'};
            push @ret, @{$node->{'commands'}};
        }
    }

    return \@ret;
}

sub build_nodes
{
    my $target = shift;
    my $nodes = shift;
    my $old_new = shift;
    my $minus_options = shift;
    my $parents = shift;
    my $subjects = shift;
    my $force_include = shift;

    my $new = $old_new->{$target};
    if(defined($new))
    {
        return $new;
    }

    if(!$parents->{$target})
    {
        my $slide = undef;
        for my $minus_option (@$minus_options)
        {
            if(covers($minus_option->[0], $target))
            {
                $slide = $minus_option->[1];
                if($slide eq 'SELF')
                {
                    $slide = $target;
                }
                last;
            }
        }
        if(!defined($slide))
        {
            die "Could not find minus $target in any minus options?!";
        }

        if(!$nodes->{$slide})
        {
            $nodes->{$slide} =
            {
                'loads' => 0,
                'commands' => [],
                'build' => sub
                {
                    die "Build called on minus node?!";
                },
                'generated' => $slide,
                'picks_contained' => {},
                'bases_contained' => {$slide => 1},
            };
        }
        return $old_new->{$target} = $slide;
    }

    my $build;
    my %picks_contained;
    my %bases_contained;
    my @mparents = @{$parents->{$target}};
    if(@mparents == 0)
    {
        $build = sub
        {
            my $cb = shift;
            my $script = shift;

            push @$script, "load $target # [INITIAL] " . Amling::Git::GRD::Utils::escape_msg($subjects->{$target});
        };
        $picks_contained{$target} = 1;
    }
    elsif(@mparents == 1)
    {
        my $parent = build_nodes($mparents[0], $nodes, $old_new, $minus_options, $parents, $subjects, 0);

        # no matter what we load result (base or otherwise) and map to ourselves
        ++$nodes->{$parent}->{'loads'};

        $build = sub
        {
            my $cb = shift;
            my $script = shift;

            $cb->($parent, 1);

            push @$script, "pick $target # " . Amling::Git::GRD::Utils::escape_msg($subjects->{$target});
        };
        $picks_contained{$_} = 1 for(keys(%{$nodes->{$parent}->{'picks_contained'}}));
        $picks_contained{$target} = 1;
        $bases_contained{$_} = 1 for(keys(%{$nodes->{$parent}->{'bases_contained'}}));
    }
    else
    {
        my @new_parents;
        my $merge_command = "cached-merge $target";

        for my $parent (@mparents)
        {
            push @new_parents, build_nodes($parent, $nodes, $old_new, $minus_options, $parents, $subjects, 0);
        }

        {
            my @kept_parents;
            my @parent_queue = reverse(@new_parents);
            while(@parent_queue)
            {
                my $test_parent = shift @parent_queue;
                my %needed_picks = %{$nodes->{$test_parent}->{'picks_contained'}};
                my %needed_bases = %{$nodes->{$test_parent}->{'bases_contained'}};

                clear_picks(\%needed_picks, \%picks_contained);
                clear_bases(\%needed_bases, \%bases_contained);
                for my $queued_parent (@parent_queue)
                {
                    clear_picks(\%needed_picks, $nodes->{$queued_parent}->{'picks_contained'});
                    clear_bases(\%needed_bases, $nodes->{$queued_parent}->{'bases_contained'});
                }

                if(%needed_picks || %needed_bases)
                {
                    unshift @kept_parents, $test_parent;
                    $picks_contained{$_} = 1 for(keys(%{$nodes->{$test_parent}->{'picks_contained'}}));
                    $bases_contained{$_} = 1 for(keys(%{$nodes->{$test_parent}->{'bases_contained'}}));
                }
            }

            @new_parents = @kept_parents;
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
        $build = sub
        {
            my $cb = shift;
            my $script = shift;

            for my $new_parent (@new_parents)
            {
                $cb->($new_parent, 0);
            }

            push @$script, "$merge_command " . join(" ", map { $nodes->{$_}->{'generated'} } @new_parents);
        };
    }

    $nodes->{$target} =
    {
        'loads' => 0,
        'commands' => [],
        'build' => $build,
        'picks_contained' => \%picks_contained,
        'bases_contained' => \%bases_contained,
    };
    return $old_new->{$target} = $target;
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

# TODO: covers (with all its callers) is an assload of shelling out, consider slurping history and answering this internally?

sub covers
{
    my $coverer = shift;
    my $covered = shift;

    my $ret = 0;
    open(my $fh, '-|', 'git', 'merge-base', $coverer, $covered) || die "Cannot open git merge-base $coverer $covered: $!";
    my $line = <$fh> || return 0; # !@#$
    chomp $line;
    if($line eq $covered)
    {
        $ret = 1;
    }
    close($fh) || die "Cannot close git merge-base $coverer $covered: $!";

    return $ret;
}

sub clear_picks
{
    my $needed_picks = shift;
    my $covered_picks = shift;

    return unless(%$covered_picks);

    for my $covered_pick (keys(%$covered_picks))
    {
        delete $needed_picks->{$covered_pick};
    }
}

sub clear_bases
{
    my $needed_bases = shift;
    my $covered_bases = shift;

    for my $covered_base (keys(%$covered_bases))
    {
        return unless(%$needed_bases);
        for my $needed_base (keys(%$needed_bases))
        {
            if(covers($covered_base, $needed_base))
            {
                delete $needed_bases->{$needed_base};
                last;
            }
        }
    }
}

1;
