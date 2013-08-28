package Amling::Git::GRD::Command::Load;

use strict;
use warnings;

use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub name
{
    return "load";
}

sub args
{
    return 1;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $commit = convert_arg("Load", $ctx, shift);

    $ctx->set_head($commit);
}

sub convert_arg
{
    my $type = shift;
    my $ctx = shift;
    my $arg = shift;

    if($arg =~ /^tag:(.*)$/)
    {
        my $commit = $ctx->get('tags', {})->{$1};
        if(!defined($commit))
        {
            die "$type of unknown $arg";
        }
        return $commit;
    }

    return Amling::Git::Utils::convert_commitlike($arg);
}

Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });

1;
