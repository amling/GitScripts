package Amling::Git::Utils;

use strict;
use warnings;

use Amling::Git::Utils::Commit;

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
    chomp $line if defined($line);
    return $line;
}

sub log_commits
{
    my $args = shift;
    my $cb = shift;

    open(my $fh, '-|', 'git', 'log', '--format=raw', '--name-only', @$args) || die "Cannot open git log: $!";
    my @buffer;
    while(my $line = <$fh>)
    {
        chomp $line;
        if($line =~ /^commit / && @buffer)
        {
            _log_commits_aux($cb, \@buffer);
            @buffer = ();
        }
        push @buffer, $line;
    }
    if(@buffer)
    {
        _log_commits_aux($cb, \@buffer);
    }
    close($fh) || die "Cannot close git log: $!";
}

sub _log_commits_aux
{
    my $cb = shift;
    my $buffer = shift;

    my $commit = Amling::Git::Utils::Commit->new();
    for my $line (@$buffer)
    {
        if(0)
        {
        }
        elsif($line =~ /^commit ([a-f0-9]{40})$/)
        {
            $commit->set_hash($1);
        }
        elsif($line =~ /^tree ([a-f0-9]{40})$/)
        {
            $commit->set_tree($1);
        }
        elsif($line =~ /^parent ([a-f0-9]{40})$/)
        {
            $commit->add_parent($1);
        }
        elsif($line =~ /^author ([^<]*) <([^>]*)>/)
        {
            $commit->set_author($1, $2);
        }
        elsif($line =~ /^committer ([^<]*) <([^>]*)>/)
        {
            $commit->set_committer($1, $2);
        }
        elsif($line =~ /^$/)
        {
        }
        elsif($line =~ /^    (.*)$/)
        {
            $commit->add_body_line($1);
        }
        else
        {
            # ugh, I sure hope I got everything...
            $commit->add_file($line);
        }
    }

    $cb->($commit);
}

sub convert_commitlike
{
    my $commitlike = shift;

    open(my $fh, '-|', 'git', 'rev-parse', $commitlike) || die "Cannot open rev-parse $commitlike: $!";
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
