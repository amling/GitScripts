package Amling::Git::GBD::Action::Save;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::Utils;

use base ('Amling::Git::GBD::Action::BaseOneArg');

sub get_action_name
{
    return "save";
}

sub execute
{
    my $this = shift;
    my $ctx = shift;

    # TODO: skip if unchanged(?!)
    Amling::Git::GBD::Utils::save_object($this->get_arg(), $ctx->require_state());
}

1;
