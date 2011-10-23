package Amling::Git::GBD::Action::BaseStateExecutor;

use strict;
use warnings;

sub execute
{
    my $this = shift;
    my $ctx = shift;
    my $state = $ctx->require_state();

    $this->execute_state($ctx, $state);
}

1;
