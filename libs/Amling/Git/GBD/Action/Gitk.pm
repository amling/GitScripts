package Amling::Git::GBD::Action::Gitk;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseStateExecutor;
use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseStateExecutor',
    'Amling::Git::GBD::Action::BaseZeroArg',
);

sub get_action_name
{
    return "gitk";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    my @minima = $state->find_bad_minima();
    if(!@minima)
    {
        die "No BAD minima?\n";
    }
    else
    {
        my $bad = $minima[0]->[0];
        my $bad_ct = $minima[0]->[1];
        my @good_upstreams;
        my $cb =
        sub
        {
            my $commit = shift;
            if($state->is_good($commit))
            {
                push @good_upstreams, $commit;
                return 0;
            }
            return 1;
        };
        $state->traverse_up($bad, $cb);
        Amling::Git::Utils::run_system("gitk", (map { "^$_" } @good_upstreams), $bad);
    }
}

1;
