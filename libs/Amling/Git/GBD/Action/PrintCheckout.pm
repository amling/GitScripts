package Amling::Git::GBD::Action::PrintCheckout;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseStateExecutor;
use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseStateExecutor',
    'Amling::Git::GBD::Action::BaseZeroArg',
);

sub get_action_name
{
    return "print-checkout";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    print "git checkout " . Amling::Git::GBD::Utils::choose_cutpoint($state) . "\n";
}

1;
