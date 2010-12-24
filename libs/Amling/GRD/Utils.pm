package Amling::GRD::Utils;

use strict;
use warnings;

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

sub run_shell
{
    my $first_shell = shift;
    my $allow_index = shift;
    my $allow_wtree = shift;

    my $shell = $ENV{'SHELL'} || '/bin/sh';
    my $grd_level = ($ENV{'GRD_LEVEL'} || 0);

    EDITLOOP:
    while(1)
    {
        if($first_shell)
        {
            {
                local $ENV{'GRD_LEVEL'} = ($grd_level + 1);
                print "GRD level: " . ($grd_level + 1) . "\n";
                system($shell);
            }
        }
        else
        {
            $first_shell = 1;
        }

        my $fail;
        # TODO: doesn't catch untracked files...
        if(!$fail && !$allow_index && system("git", "diff", "--cached", "--quiet"))
        {
            $fail = "There are differences between HEAD and the index.";
        }

        if(!$fail && !$allow_wtree)
        {
            open(my $fh, "-|", "git", "ls-files", "-u");
            while(<$fh>)
            {
                $fail = "There are unmerged files in the index.";
            }
            close($fh);
        }

        if(!$fail && !$allow_wtree && system("git", "diff", "--quiet"))
        {
            $fail = "There are differences between the index and the working tree.";
        }

        if(!$fail)
        {
            return;
        }

        # TODO: extract menu util
        while(1)
        {
            print "$fail\n";
            print "What should I do?\n";
            print "s - run a shell\n";
            print "q - abort entire rebase\n";
            print "> ";
            my $ans = <>;
            chomp $ans;

            if($ans eq "q")
            {
                print "Giving up.\n";
                exit 1;
            }
            if($ans eq "s")
            {
                next EDITLOOP;
            }

            print "Not an option: $ans\n";
        }
    }
}

sub run
{
    my @cmd = @_;

    print "Running: " . join(", ", @cmd) . "...\n";

    return (system(@cmd) == 0);
}

1;
