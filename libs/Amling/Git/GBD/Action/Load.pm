package Amling::Git::GBD::Action::Load;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::State; # as we're demarshalling I feel we're responsible
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

    $ctx->set_state(Amling::Git::GBD::Utils::load_object($this->get_arg()));
}

1;
