package Amling::GRD::Command::Splatter;

use strict;
use warnings;

use Amling::GRD::Command;
use Amling::GRD::Command::Simple;
use Amling::GRD::Utils;
use File::Temp ('tempfile');

use base 'Amling::GRD::Command::Simple';

# TODO: splatter like pick that takes a message to amend [or commit] with!

sub name
{
    return "splatter";
}

sub args
{
    return 0;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;

    my $commit = pop @{$ctx->get('commit-stack', [])};
    if(!defined($commit))
    {
        die "Empty commit stack splattered";
    }

    my ($commit_msg_fh, $commit_msg_fn) = tempfile('SUFFIX' => '.commit');
    {
        open(my $fh, '-|', 'git', 'log', "$commit..", "--reverse", "--pretty=raw") || die "Cannot open git log: $!";
        while(my $l = <$fh>)
        {
            if($l =~ /^commit ([0-9a-f]*)$/)
            {
                print $commit_msg_fh "# $l\n";
            }
            elsif($l eq '' || $l =~ s/^    //)
            {
                print $commit_msg_fh "$l\n";
            }
            else
            {
                # ignore
            }
        }
        close($fh) || die "Cannot close git log: $!";
    }
    close($commit_msg_fh) || die "Cannot close temp commit file $commit_msg_fn: $!";

    Amling::GRD::Utils::run("git", "reset", "--soft", $commit) || die "Cannot soft reset to $commit";
    Amling::GRD::Utils::run("git", "commit", "-F", $commit_msg_fn, "-e") || die "Cannot commit?";
    unlink($commit_msg_fn) || die "Cannot unlink temp file $commit_msg_fn";
}

Amling::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
