package Amling::Git::GBD::Action::ClearAll;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::State;
use Amling::Git::GBD::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseZeroArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "clear-all";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    $state->clear_all();
    for my $commit (Amling::Git::GBD::State::get_commits($state))
    {
        Amling::Git::GBD::State::clear_commit($state, $commit);
    }
}

1;
