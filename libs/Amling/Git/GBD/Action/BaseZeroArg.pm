package Amling::Git::GBD::Action::BaseZeroArg;

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

sub make_options
{
    my $class = shift;
    my $cb = shift;

    my $ocb = sub
    {
        $cb->($class->new());
    };

    return ($class->get_action_name(), $ocb);
}

sub shell_action
{
    my $class = shift;
    my $string = shift;

    my $name = $class->get_action_name();
    if($string =~ /^\s*\Q$name\E\s*$/)
    {
        return $class->new();
    }

    return undef;
}

sub str
{
    my $this = shift;

    return $this->get_action_name();
}

1;
