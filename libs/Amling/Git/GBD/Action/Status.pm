package Amling::Git::GBD::Action::Status;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Utils;
use Amling::Git::Utils;

use base
(
    'Amling::Git::GBD::Action::BaseZeroArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "status";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;

    my @minima = $state->find_bad_minima();
    if(!@minima)
    {
        print "No BAD minima?\n";
    }
    else
    {
        print "Best BAD minimum is " . $minima[0]->[0] . " with " . $minima[0]->[1] . " unknown commits above it.\n";
    }
}

1;
