package Amling::Git::GRD::Command::Splatter;

use strict;
use warnings;

use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;
use File::Temp ('tempfile');

use base 'Amling::Git::GRD::Command::Simple';

sub extended_handler
{
    my $s0 = shift;
    my $s1 = shift;

    if($s0 !~ /^splatter (.*)$/)
    {
        return undef;
    }
    my $msg = $1;

    return [__PACKAGE__->new(Amling::Git::GRD::Utils::unescape_msg($msg)), $s1];
}

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
    my $msg = shift;

    $ctx->materialize_head();

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
            chomp $l;
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

    Amling::Git::Utils::run_system("git", "reset", "--soft", $commit) || die "Cannot soft reset to $commit";
    if(defined($msg))
    {
        Amling::Git::Utils::run_system("git", "commit", "-m", $msg) || die "Cannot commit?";
    }
    else
    {
        Amling::Git::Utils::run_system("git", "commit", "-F", $commit_msg_fn, "-e") || die "Cannot commit?";
    }
    unlink($commit_msg_fn) || die "Cannot unlink temp file $commit_msg_fn";

    $ctx->uptake_head();
}

sub str_simple
{
    my $self = shift;
    my $msg = shift;

    return "splatter" . (defined($msg) ? " (amended message)" : "");
}

Amling::Git::GRD::Command::add_command(\&extended_handler);
Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
