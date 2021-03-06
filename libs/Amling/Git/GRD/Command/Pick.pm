package Amling::Git::GRD::Command::Pick;

use strict;
use warnings;

use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Exec::Context;
use Amling::Git::GRD::Utils;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

# ugh, should probably get tetchy somewhere if we're asked to handle a multi-parent commit

sub extended_handler
{
    my $s0 = shift;
    my $s1 = shift;

    if($s0 !~ /^pick ([^ ]+) ([^#].*)$/)
    {
        return undef;
    }
    my $commit = $1;
    my $msg = Amling::Git::GRD::Utils::unescape_msg($2);

    return [__PACKAGE__->new($commit, $msg), $s1];
}

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
    my $msg = shift;

    my $env =
    {
        'COMMIT' => $commit,
    };

    # if $commit's parent is us we're "picking" a change one down the line, and
    # if we have no message to amend with we can just fast-forward to it
    if(Amling::Git::Utils::convert_commitlike("$commit^") eq $ctx->get_head() && !defined($msg))
    {
        print "Fast-forward cherry-picking $commit...\n";
        $ctx->set_head($commit);
        return;
    }

    $ctx->materialize_head();
    if(!Amling::Git::Utils::run_system("git", "cherry-pick", $commit))
    {
        if(Amling::Git::Utils::is_clean())
        {
            print "git cherry-pick of $commit blew chunks, but we're clean, assuming skip...\n";
            return;
        }

        print "git cherry-pick of $commit blew chunks, please clean it up (get correct version into index)...\n";
        Amling::Git::GRD::Utils::run_shell(1, 1, 0, $env);
        print "Continuing...\n";

        if(Amling::Git::Utils::is_clean())
        {
            print "Shell left clean, assuming skip...\n";
            $ctx->uptake_head();
            return;
        }

        if(defined($msg))
        {
            # allow edit since we would normally
            Amling::Git::Utils::run_system("git", "commit", "-m", $msg, "-e") || die "Cannot commit?";

            # no further amendment required
            $msg = undef;
        }
        else
        {
            Amling::Git::Utils::run_system("git", "commit", "-c", $commit) || die "Cannot commit?";
        }
    }
    $ctx->uptake_head();

    if(defined($msg))
    {
        $ctx->materialize_head();
        Amling::Git::Utils::run_system("git", "commit", "--amend", "-m", $msg) || die "Cannot amend?";
        $ctx->uptake_head();
    }

    # note we intentionally do not run this for changes that didn't actually
    # get picked (i.e.  that bounced out anywhere above)
    $ctx->run_hooks('post-pick', $env);
}

sub str_simple
{
    my $self = shift;
    my $commit = shift;
    my $msg = shift;

    return "pick $commit" . (defined($msg) ? " (amended message)" : "");
}

Amling::Git::GRD::Command::add_command(\&extended_handler);
Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });
Amling::Git::GRD::Exec::Context::add_event('post-pick');

1;
