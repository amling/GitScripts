package Amling::Git::GBD::Action::Load;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;

use base ('Amling::Git::GBD::Action::BaseOneArg');

sub get_action_name
{
    return "load";
}

sub execute
{
    print "...\n";
}

1;
