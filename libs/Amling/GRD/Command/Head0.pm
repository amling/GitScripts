package Amling::GRD::Command::Head0;

use strict;
use warnings;

use Amling::GRD::Command;
use Amling::GRD::Command::Simple;
use Amling::GRD::Utils;

use base 'Amling::GRD::Command::Simple';

sub name
{
    return "head";
}

sub args
{
    return 0;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;

    $ctx->set_dhead(Amling::GRD::Utils::convert_commitlike("HEAD"));
}

Amling::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
