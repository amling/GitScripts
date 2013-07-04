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

    my $bases = [keys(%$minus_options)];
    my $targets = [sort(keys(%{{map { Amling::Git::Utils::convert_commitlike($_) => 1 } keys(%$head_options), keys(%$plus_options)}}))];

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

    for my $commands (values(%$commit_commands))
    {
        @$commands = map { $_->[1] } sort { ($a->[0] cmp $b->[0]) || ($a->[1] cmp $b->[1]) } @$commands;
    }

    return handle_common($bases, $commit_commands, $targets);
}

sub handle_common
{
    my $bases = shift;
    my $commit_commands = shift;
    my $targets = shift;

    my %commits;
    my %parents;
    my %subjects;
    my $cb = sub
    {
        my $h = shift;
        my $commit = $h->{'hash'};

        $commits{$commit} = 1;
        $parents{$commit} = $h->{'parents'};
        $subjects{$commit} = $h->{'msg'};
    };
    Amling::Git::Utils::log_commits([(map { "^$_" } @$bases), @$targets], $cb);

    my @lines;
    push @lines, "save base";
    my %built;
    for my $target (@$targets)
    {
        my ($contributes, @script) = build($target, \%commits, \%built, \%parents, \%subjects, $commit_commands);
        if($contributes)
        {
            push @lines, @script;
        }
    }

    while(1)
    {
        my $progress = 0;
        for my $opt (\&peephole_useless_save, \&peephole_useless_sl_pair)
        {
            my $progress1;
            ($progress1, @lines) = $opt->(@lines);
            if($progress1)
            {
                $progress = 1;
            }
        }
        last unless($progress);
    }

    return \@lines;
}

sub build
{
    my $target = shift;
    my $commits = shift;
    my $built = shift;
    my $parents = shift;
    my $subjects = shift;
    my $commit_commands = shift;

    # asked to build something in base
    if(!$commits->{$target})
    {
        return 0;
    }

    # already built, and it was relevant (but no additional script)
    if($built->{$target})
    {
        return 1;
    }

    my @mparents = @{$parents->{$target}};

    my @ret;

    if(@mparents == 1)
    {
        my ($contributes, @script) = build($mparents[0], $commits, $built, $parents, $subjects, $commit_commands);

        if($contributes)
        {
            # non-merge built on a real commit
            push @ret, @script;
            push @ret, "load tag:new-" . $mparents[0];
        }
        else
        {
            # non-merge built on a dead commit, just build off base
            push @ret, "load tag:base";
        }

        push @ret, "pick $target # " . Amling::Git::GRD::Utils::escape_msg($subjects->{$target});
    }
    else
    {
        my @targets;

        for my $parent (@mparents)
        {
            my ($contributes, @script) = build($parent, $commits, $built, $parents, $subjects, $commit_commands);

            if($contributes)
            {
                push @ret, @script;
                push @targets, $parent;
            }
        }

        if(@targets == 0)
        {
            return 0;
        }

        if(@targets == 1)
        {
            push @ret, "load tag:new-" . $targets[0];
        }
        else
        {
            push @ret, "merge " . join(" ", map { "tag:new-$_" } @targets);
        }
    }

    push @ret, @{$commit_commands->{$target} || []};

    push @ret, "save new-$target";
    $built->{$target} = 1;

    return (1, @ret);
}

sub peephole_useless_save
{
    my @lines = @_;

    my %loaded;

    for my $line (@lines)
    {
        if($line =~ /^load tag:(.*)$/)
        {
            $loaded{$1} = 1;
        }
        elsif($line =~ /^merge (.*)$/)
        {
            for my $name (split(/ /, $1))
            {
                if($name =~ /^tag:(.*)$/)
                {
                    $loaded{$1} = 1;
                }
            }
        }
    }

    my @lines2;
    my $progress = 0;
    for my $line (@lines)
    {
        if($line =~ /^save (.*)$/)
        {
            my $name = $1;
            if(!$loaded{$name})
            {
                $progress = 1;
                next;
            }
        }
        push @lines2, $line;
    }

    return ($progress, @lines2);
}

sub peephole_useless_sl_pair
{
    my @lines = @_;

    my @lines2;
    my $progress = 0;
    my $at = undef;
    for my $line (@lines)
    {
        if($line =~ /^load tag:(.*)$/)
        {
            if(defined($at) && $at eq $1)
            {
                $progress = 1;
                next;
            }
        }
        if($line =~ /^save (.*)$/)
        {
            $at = $1;
        }
        elsif($line =~ /^(head|branch)( |$)/)
        {
            # doesn't change where we're at
        }
        elsif($line =~ /^#/)
        {
            # doesn't change where we're at
        }
        else
        {
            $at = undef;
        }
        push @lines2, $line;
    }

    return ($progress, @lines2);
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
