package Amling::Git::GBD::Action::Debug;

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
    return "debug";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    use Data::Dumper; print Dumper($state->find_bad_minima());
}

1;
