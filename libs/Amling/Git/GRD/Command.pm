package Amling::Git::GRD::Command;

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

use Amling::Git::GRD::Command::Branch;
use Amling::Git::GRD::Command::BranchHead;
use Amling::Git::GRD::Command::DetachedHead;
use Amling::Git::GRD::Command::Edit;
use Amling::Git::GRD::Command::FSplatter;
use Amling::Git::GRD::Command::Fixup;
use Amling::Git::GRD::Command::Load;
use Amling::Git::GRD::Command::Merge;
use Amling::Git::GRD::Command::Pick;
use Amling::Git::GRD::Command::Pop;
use Amling::Git::GRD::Command::Push;
use Amling::Git::GRD::Command::Save;
use Amling::Git::GRD::Command::Splatter;
use Amling::Git::GRD::Command::Squash;

1;
