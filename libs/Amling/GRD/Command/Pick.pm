package Amling::GRD::Command::Pick;

use strict;
use warnings;

use Amling::GRD::Command;
use Amling::GRD::Command::Simple;
use Amling::GRD::Utils;

use base 'Amling::GRD::Command::Simple';

# ugh, should probably get tetchy somewhere if we're asked to handle a multi-parent commit

sub name
{
    return "pick";
}

sub args
{
    return 1;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $commit = shift;

    # if $commit's parent is us we're "picking" a change one down the line, we
    # can just fast-forward to it
    if(Amling::GRD::Utils::convert_commitlike("$commit^") eq Amling::GRD::Utils::convert_commitlike("HEAD"))
    {
        print "Fast-forward cherry-picking $commit...\n";
        Amling::GRD::Utils::run("git", "reset", "--hard", $commit);
        return;
    }

    if(!Amling::GRD::Utils::run("git", "cherry-pick", $commit))
    {
        print "git cherry-pick of $commit blew chunks, please clean it up (get correct version into index)...\n";
        Amling::GRD::Utils::run_shell(1, 1, 0);
        print "Continuing...\n";

        # TODO: handle empty commits (if we get set up to do an empty commit it probably means the user wants a skip)
        Amling::GRD::Utils::run("git", "commit", "-c", $commit);
    }
}

Amling::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
