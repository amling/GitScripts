package Amling::Git::GRD::Command::Merge;

use strict;
use warnings;

use Amling::Git::GRD::Command::Load;
use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub name
{
    return "merge";
}

sub min_args
{
    return 2;
}

sub max_args
{
    return undef;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $parent0 = Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, shift);
    my @parents1 = map { Amling::Git::GRD::Command::Load::convert_arg("Merge", $ctx, $_) } @_;

    $ctx->materialize_head($parent0);

    if(!Amling::Git::Utils::run_system("git", "merge", "--commit", "--no-ff", @parents1))
    {
        print "git merge of " . join(", ", @parents1) . " into $parent0 blew chunks, please clean it up (get correct version into index)...\n";
        Amling::Git::GRD::Utils::run_shell(1, 1, 0);
        print "Continuing...\n";

        Amling::Git::Utils::run_system("git", "commit") || die "Could not commit merge";
    }

    $ctx->uptake_head();
}

Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
