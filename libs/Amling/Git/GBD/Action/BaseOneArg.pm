package Amling::Git::GBD::Action::BaseOneArg;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $arg = shift;

    my $self =
    {
        'arg' => $arg,
    };

    bless $self, $class;

    return $self;
}

sub make_options
{
    my $class = shift;
    my $cb = shift;

    my $ocb = sub
    {
        $cb->($class->new($_[1]));
    };

    return ($class->get_action_name() . "=s", $ocb);
}

sub shell_action
{
    my $class = shift;
    my $string = shift;

    my $name = $class->get_action_name();
    if($string =~ /^\s*\Q$name\E\s+(.*)$/)
    {
        return $class->new($1);
    }

    return undef;
}

sub str
{
    my $this = shift;

    return $this->get_action_name() . " " . $this->{'arg'};
}

sub get_arg
{
    my $this = shift;

    return $this->{'arg'};
}

1;
