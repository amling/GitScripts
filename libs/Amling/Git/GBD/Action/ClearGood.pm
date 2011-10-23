package Amling::Git::GBD::Action::ClearGood;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseZeroArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "clear-good";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    for my $commit ($state->get_commits())
    {
        my $known = $state->get_known($commit);
        if(defined($known) && $known eq 'GOOD')
        {
            $state->clear_commit($commit);
        }
    }
}

1;
