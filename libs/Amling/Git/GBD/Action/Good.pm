package Amling::Git::GBD::Action::Good;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::Utils;
use Amling::Git::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseOneArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "good";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    my $commit = $this->get_arg();
    $commit = Amling::Git::Utils::convert_commitlike($commit);
    if(!$state->has_commit($commit))
    {
        die "State doesn't contain $commit";
    }
    $state->set_good($commit);
}

1;
