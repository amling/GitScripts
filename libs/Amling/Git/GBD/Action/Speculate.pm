package Amling::Git::GBD::Action::Speculate;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseOneArg;
use Amling::Git::GBD::Action::BaseStateExecutor;
use Amling::Git::Utils;

use Storable;

use base
(
    'Amling::Git::GBD::Action::BaseOneArg',
    'Amling::Git::GBD::Action::BaseStateExecutor',
);

sub get_action_name
{
    return "speculate";
}

sub execute_state
{
    my $this = shift;
    my $ctx = shift;
    my $state = shift;
    my $depth = $this->get_arg();

    speculate($state, $depth, '');
}

sub speculate
{
    my $state = shift;
    my $depth = shift;
    my $prefix = shift;

    my $cutpoint = $state->choose_cutpoint();
    print "[$prefix] $cutpoint\n";

    if(!($depth > 0))
    {
        return;
    }

    {
        my $state2 = Storable::dclone($state);
        $state2->set_bad($cutpoint);
        speculate($state2, $depth - 1, $prefix . "B");
    }

    {
        my $state2 = Storable::dclone($state);
        $state2->set_good($cutpoint);
        speculate($state2, $depth - 1, $prefix . "G");
    }
}

1;
