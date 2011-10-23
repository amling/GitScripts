package Amling::Git::GBD::Action;

use strict;
use warnings;

use Amling::Git::GBD::Action::Load;

my @handlers =
(
    'Amling::Git::GBD::Action::Load',
);

sub make_options
{
    my $ar = shift;

    my $cb = sub
    {
        my $action = shift;
        push @$ar, $action;
    };

    return map { $_->make_options($cb) } @handlers;
}

sub shell_action
{
    my $string = shift;

    for my $handler (@handlers)
    {
        my $action = $handler->shell_action($string);
        if(defined($action))
        {
            return $action;
        }
    }

    return undef;
}

1;
