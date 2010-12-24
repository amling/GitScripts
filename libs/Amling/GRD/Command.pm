package Amling::GRD::Command;

use strict;
use warnings;

my @handlers;

sub add_command
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
            return @ret;
        }
    }

    return undef;
}

# TODO: actual commands
#require Amling::GRD::Command::Push;

1;
