package Amling::Git::GBD::Action::XBad;

use strict;
use warnings;

use Amling::Git::GBD::Action::Bad;
use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Action::Checkout;
use Amling::Git::GBD::Action::Status;

use base ('Amling::Git::GBD::Action::BaseZeroArg');

sub get_action_name
{
    return "xbad";
}

sub execute
{
    my $this = shift;
    my $ctx = shift;

    Amling::Git::GBD::Action::Bad->new('HEAD')->execute($ctx);
    Amling::Git::GBD::Action::Checkout->new()->execute($ctx);
    Amling::Git::GBD::Action::Status->new()->execute($ctx);
}

1;
