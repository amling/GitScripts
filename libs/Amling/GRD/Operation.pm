package Amling::GRD::Operation;

use strict;
use warnings;

my @handlers;

sub add_operation
{
    my ($pfn) = @_;

    push @handlers, $pfn;
}

sub parse
{
    my ($s) = @_;

    for my $handler (@handlers)
    {
        my @ret = $handler->($s);

        if(@ret)
        {
            return (1, @ret);
        }
    }

    return (0);
}

# TODO: require Amling::GRD::Operation::Tree;
require Amling::GRD::Operation::Linear;

1;
