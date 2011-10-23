package Amling::Git::GBD::Action::Load;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::State;
use Amling::Git::GBD::Utils;

use base ('Amling::Git::GBD::Action::BaseOneArg');

sub get_action_name
{
    return "load";
}

sub execute
{
    my $this = shift;
    my $ctx = shift;

    my $state = Amling::Git::GBD::Utils::load_object($this->get_arg());
    if(!$state->isa('Amling::Git::GBD::State'))
    {
        die "State is not a Amling::Git::GBD::State?";
    }
    $ctx->set_state($state);
}

1;
