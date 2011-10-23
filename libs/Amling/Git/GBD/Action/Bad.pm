package Amling::Git::GBD::Action::Bad;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::Action::BaseStateExecutor;
use Amling::Git::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseOneArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "bad";
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
    $state->set_bad($commit);
}

1;
