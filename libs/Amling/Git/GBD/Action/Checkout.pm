package Amling::Git::GBD::Action::Checkout;

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
    return "checkout";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    Amling::Git::Utils::run_system("git", "checkout", $state->choose_cutpoint());
}

1;
