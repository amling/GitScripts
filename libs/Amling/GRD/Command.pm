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
        my $ret = $handler->($s);

        if(defined($ret))
        {
            return $ret;
        }
    }

    return undef;
}

# TODO: [more] actual commands
require Amling::GRD::Command::Push;
require Amling::GRD::Command::Pop;

1;
