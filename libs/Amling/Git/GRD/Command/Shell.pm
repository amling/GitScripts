package Amling::Git::GRD::Command::Shell;

use strict;
use warnings;

use Amling::Git::GRD::Command::Simple;
use Amling::Git::GRD::Command;
use Amling::Git::GRD::Utils;

use base 'Amling::Git::GRD::Command::Simple';

sub extended_handler
{
    my $s = shift;

    my $cmd;
    if($s =~ /^shell (.+)$/)
    {
        $cmd = $1;
    }
    else
    {
        return undef;
    }

    return __PACKAGE__->new($cmd);
}

sub name
{
    return "shell";
}

sub args
{
    return 0;
}

sub execute_simple
{
    my $self = shift;
    my $ctx = shift;
    my $cmd = shift;

    $ctx->materialize_head();

    if(defined($cmd))
    {
        print "Invoking: $cmd\n";
        system('/bin/sh', '-c', $cmd);
        Amling::Git::GRD::Utils::run_shell(0, 0, 0);
        print "Invoking complete, continuing...\n";
    }
    else
    {
        print "Shell requested, dropping into shell...\n";
        Amling::Git::GRD::Utils::run_shell(1, 0, 0);
        print "Shell complete, continuing...\n";
    }

    $ctx->uptake_head();
}

Amling::Git::GRD::Command::add_command(sub { return __PACKAGE__->handler(@_) });
Amling::Git::GRD::Command::add_command(\&extended_handler);

1;
