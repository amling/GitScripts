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
        my $bad = $minima[0]->[0];
        my $bad_ct = $minima[0]->[1];
        if($bad_ct == 0)
        {
            print "Complete: BAD $bad has no unknown commits above it.\n";
        }
        else
        {
            print "Incomplete: best BAD minimum is $bad with $bad_ct unknown commits above it.\n";
        }
    }
}

1;
