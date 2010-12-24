package Amling::GRD::Command;

use strict;
use warnings;

my @handlers;

sub add_command
{
    my $pfn = shift;

    push @handlers, $pfn;
}

sub parse
{
    my $s = shift;

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

require Amling::GRD::Command::Branch;
require Amling::GRD::Command::Edit;
require Amling::GRD::Command::Head0;
require Amling::GRD::Command::Head1;
require Amling::GRD::Command::Pick;
require Amling::GRD::Command::Pop;
require Amling::GRD::Command::Push;
# TODO: squash
# TODO: fracture
# TODO: reword
# TODO: fixup

1;
