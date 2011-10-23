package Amling::Git::GBD::Action::Clear;

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
    return "clear";
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
    $state->clear_commit($commit);
}

1;
