package Amling::Git::GBD::State;

use strict;
use warnings;

sub new_state
{
    my $commits = shift;

    return
    {
        'commits' => $commits,
    };
}

1;
