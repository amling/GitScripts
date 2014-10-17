package Amling::Git::GBD::Action::ClearBad;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseStateExecutor;
use Amling::Git::GBD::Action::BaseZeroArg;

use base
(
    'Amling::Git::GBD::Action::BaseStateExecutor',
    'Amling::Git::GBD::Action::BaseZeroArg',
);

sub get_action_name
{
    return "clear-bad";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    for my $commit ($state->get_commits())
    {
        if($state->is_bad($commit))
        {
            $state->clear_commit($commit);
        }
    }
}

1;
