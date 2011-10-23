package Amling::Git::Utils;

use strict;
use warnings;

sub find_root
{
    my $optional = shift;
    my $fh;
    # !@#$ no silent mode
    if(!open($fh, 'git rev-parse --show-toplevel 2> /dev/null |'))
    {
        if($optional)
        {
            return undef;
        }
        else
        {
            die "Cannot open git rev-parse --show-toplevel: $!";
        }
    }
    my $line = <$fh>;
    if(!close($fh))
    {
        if($optional)
        {
            return undef;
        }
        else
        {
            die "Cannot close git rev-parse --show-toplevel: $!";
        }
    }
    chomp $line;
    return $line;
}

sub log_commits
{
    my $args = shift;
    my $cb = shift;

    my $SENTINEL = "WHY_GIT_WHY_DID_YOU_FUCK_US_WHY_DOES_DASH_Z_NOT_WORK_WITH_FORMAT";
    open(my $fh, '-|', 'git', 'log', "--format=%H:%P:%B$SENTINEL", @$args) || die "Cannot open git log: $!";
    # first newline is git being dumb(?), $SENTINEL is our fault, second newline is separating records
    local $/ = "\n$SENTINEL\n";
    while(my $line = <$fh>)
    {
        # N.B.:  chomps all of $SENTINEL!
        chomp $line;
        if($line =~ /^([^:]*):([^:]*):(.*)$/s)
        {
            my ($commit, $parents, $body) = ($1, $2, $3);

            if(length($commit) != 40)
            {
                die "Bad commit: $commit";
            }

            my @parents;
            for my $parent (split(/ /, $parents))
            {
                if(length($parent) != 40)
                {
                    die "Bad parent: $parent";
                }
                push @parents, $parent;
            }

            # TODO: more commit data
            $cb->({'hash' => $commit, 'parents' => \@parents, 'msg' => $body});
        }
    }
    close($fh) || die "Cannot close git log: $!";
}

sub convert_commitlike
{
    my $commitlike = shift;

    open(my $fh, '-|', 'git', 'log', '-1', $commitlike, '--pretty=format:%H') || die "Cannot open log $commitlike: $!";
    my $commit = <$fh> || die "Could not read head commit for $commitlike";
    chomp $commit;
    if($commit !~ /^([0-9a-f]{40})$/)
    {
        die "Bad head commit for $commitlike: $commit";
    }
    close($fh) || die "Cannot open log $commitlike: $!";

    return $commit;
}

sub is_clean
{
    my ($dirtyness, $message) = get_dirtyness();
    return ($dirtyness ? 0 : 1);
}

sub get_dirtyness
{

    if(system("git", "diff", "--quiet"))
    {
        return (2, "There are differences between the index and the working tree.");
    }

    {
        my $fail = 0;
        open(my $fh, "-|", "git", "ls-files", "-u");
        while(<$fh>)
        {
            $fail = 1;
        }
        close($fh);
        if($fail)
        {
            return (2, "There are unmerged files in the index.");
        }
    }

    # TODO: doesn't catch untracked files... (?)
    if(system("git", "diff", "--cached", "--quiet"))
    {
        return (1, "There are differences between HEAD and the index.");
    }

    return 0;
}

sub run_system
{
    my @cmd = @_;

    print "Running: " . join(", ", @cmd) . "...\n";

    return (system(@cmd) == 0);
}

1;
