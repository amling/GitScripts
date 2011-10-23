package Amling::Git::GBD::Action::XGood;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Action::Checkout;
use Amling::Git::GBD::Action::Good;
use Amling::Git::GBD::Action::Status;
use Amling::Git::GBD::Utils;

use base ('Amling::Git::GBD::Action::BaseZeroArg');

sub get_action_name
{
    return "xgood";
}

sub execute
{
    my $this = shift;
    my $ctx = shift;

    Amling::Git::GBD::Action::Good->new('HEAD')->execute($ctx);
    Amling::Git::GBD::Action::Checkout->new()->execute($ctx);
    Amling::Git::GBD::Action::Status->new()->execute($ctx);
}

1;
