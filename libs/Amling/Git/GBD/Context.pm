package Amling::Git::GBD::Context;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self =
    {
    };

    bless $self, $class;

    return $self;
}

sub require_state
{
    my $this = shift;

    my $state = $this->{'state'};
    if(!defined($state))
    {
        die "No state!";
    }

    return $state;
}

sub set_state
{
    my $this = shift;
    my $state = shift;

    $this->{'state'} = $state;
}

1;
