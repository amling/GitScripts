package Amling::Git::GBD::Action::Status;

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
            my @good_upstreams;
            my $cb =
            sub
            {
                my $commit = shift;
                my $known = $state->get_known($commit);
                if(defined($known) && $known eq 'GOOD')
                {
                    push @good_upstreams, $commit;
                    return 0;
                }
                return 1;
            };
            $state->traverse_up($bad, $cb);
            print "Incomplete:\n";
            print "Best BAD minimum is $bad with $bad_ct unknown commits above it.\n";
            print "Good minima above that are: " . join(" ", @good_upstreams) . "\n";
        }
    }
}

1;
