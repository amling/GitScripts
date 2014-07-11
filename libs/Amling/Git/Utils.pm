package Amling::Git::Utils;

use strict;
use warnings;

use Amling::Git::Utils::Commit;
use File::Basename;

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

    open(my $fh, '-|', 'git', 'log', '--format=raw', @$args) || die "Cannot open git log: $!";
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
        elsif($line =~ /^commit ((?:[-<>] )?)([a-f0-9]{40})$/)
        {
            $commit->set_decoration(substr($1, 0, 1));
            $commit->set_hash($2);
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
    close($fh) || die "Cannot open log $commitlike: $!";
    chomp $commit;
    if($commit !~ /^([0-9a-f]{40})$/)
    {
        die "Bad rev-parse for $commitlike: $commit";
    }

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

sub slurp
{
    my $f = shift;

    my @lines;
    open(my $fh, '<', $f) || die "Cannot open $f for reading: $!";
    while(my $line = <$fh>)
    {
        chomp $line;
        push @lines, $line;
    }
    close($fh) || die "Cannot close $f for reading: $!";

    return \@lines;
}

sub unslurp
{
    my $f = shift;
    my $lines = shift;

    (system('mkdir', '-p', dirname($f)) == 0) || die "Cannot mkdir -p " . dirname($f) . ": $!";

    open(my $fh, '>', $f) || die "Cannot open $f for writing: $!";
    for my $line (@$lines)
    {
        print $fh "$line\n";
    }
    close($fh) || die "Cannot close $f for writing: $!";
}

1;
