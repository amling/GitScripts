package Amling::GRD::Operation::MLinear;

use strict;
use warnings;

use Amling::GRD::Utils;

# TODO: configurable or scoped better (in particular multiple mlinears will probably end up sad)
our $PREFIX = "INTERNAL";

# TODO: think hard about whether or not peephole optimization will clean up this mess
# TODO: peephole optimizers need to understand comment branch comments (I think this only blocks load/save pair which is useless anyway)
# TODO: peephole optimization for load/save pair (alias, ugh, this is only for 1-parent merge, fuck it)

sub handler
{
    my $s = shift;

    my ($base, $branch);
    if($s =~ /^(?:simple|S):([^,]*)(?:,([^,]*))?$/)
    {
        $base = $1;
        $branch = $2;
    }
    else
    {
        return;
    }

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

    my $place_branch = undef;
    if(defined($branch))
    {
        $place_branch = $branch;
    }
    else
    {
        $place_branch = $head_branch; # undef or otherwise
        $branch = "HEAD";
    }

    my %comment_branches;
    {
        open(my $fh, '-|', 'git', 'show-ref') || die "Cannot open git show-ref: $!";
        while(my $line = <$fh>)
        {
            if($line =~ /^([0-9a-f]{40}) (.*)$/)
            {
                my ($commit, $ref) = ($1, $2);
                if($ref =~ /^refs\/heads\/(.*)$/)
                {
                    # don't comment for the branch we're gonna place at the end anyway
                    my $branch = $1;
                    if(defined($place_branch) && $place_branch eq $branch)
                    {
                        next;
                    }
                    $comment_branches{$commit}->{$branch} = 1;
                }
            }
            else
            {
                die "Bad line: $line";
            }
        }
        close($fh) || die "Cannot close git show-ref: $!";
    }

    my %commits;
    my %parents;
    my %subjects;
    my $first;
    {
        open(my $fh, '-|', 'git', 'log', "$base..$branch", '--pretty=format:%H:%P:%s') || die "Cannot open top git log: $!";
        while(my $line = <$fh>)
        {
            chomp $line;
            if($line =~ /^([0-9a-f]{40}):([0-9a-f ]*):(.*)$/)
            {
                my ($commit, $parents, $msg) = ($1, $2, $3);
                if(!defined($first))
                {
                    $first = $commit;
                }
                my @parents = split(/ /, $parents);
                for my $parent (@parents)
                {
                    if(length($parent) != 40)
                    {
                        die "Bad parent: $parent";
                    }
                }
                $commits{$commit} = 1;
                $parents{$commit} = \@parents;
                $subjects{$commit} = $msg;
            }
            else
            {
                die "Bad line: $line";
            }
        }
        close($fh) || die "Cannot close top git log: $!";
    }

    my @lines;
    if(defined($first))
    {
        push @lines, "save $PREFIX-base";
        my ($contributes, @script) = build($first, \%commits, {}, \%parents, \%subjects, \%comment_branches);
        if($contributes)
        {
            push @lines, @script;
            push @lines, "load $PREFIX-$first";
        }
        else
        {
            push @lines, "load $PREFIX-base";
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

    if(defined($place_branch))
    {
        push @lines, "head $place_branch";
    }
    else
    {
        push @lines, "head";
    }

    my $latest_base = Amling::GRD::Utils::convert_commitlike($base);

    return ($latest_base, \@lines);
}

Amling::GRD::Operation::add_operation(\&handler);

sub build
{
    my $target = shift;
    my $commits = shift;
    my $built = shift;
    my $parents = shift;
    my $subjects = shift;
    my $comment_branches = shift;

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
        my ($contributes, @script) = build($mparents[0], $commits, $built, $parents, $subjects, $comment_branches);

        if($contributes)
        {
            # non-merge built on a real commit
            push @ret, @script;
            push @ret, "load $PREFIX-" . $mparents[0];
        }
        else
        {
            # non-merge built on a dead commit, just build off base
            push @ret, "load $PREFIX-base";
        }

        push @ret, "pick $target # " . $subjects->{$target};
    }
    else
    {
        my @targets;

        for my $parent (@mparents)
        {
            my ($contributes, @script) = build($parent, $commits, $built, $parents, $subjects, $comment_branches);

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
            push @ret, "load $PREFIX-" . $targets[0];
        }
        else
        {
            push @ret, "merge " . join(" ", map { "$PREFIX-$_" } @targets);
        }
    }

    for my $comment_branch (sort(keys(%{$comment_branches->{$target} || {}})))
    {
        push @ret, "# branch $comment_branch";
    }

    push @ret, "save $PREFIX-$target";
    $built->{$target} = 1;

    return (1, @ret);
}

sub peephole_useless_save
{
    my @lines = @_;

    my %loaded;

    for my $line (@lines)
    {
        if($line =~ /^load (.*)$/)
        {
            $loaded{$1} = 1;
        }
        elsif($line =~ /^merge (.*)$/)
        {
            for my $name (split(/ /, $1))
            {
                $loaded{$name} = 1;
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
        if($line =~ /^load (.*)$/)
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
        else
        {
            $at = undef;
        }
        push @lines2, $line;
    }

    return ($progress, @lines2);
}

1;
