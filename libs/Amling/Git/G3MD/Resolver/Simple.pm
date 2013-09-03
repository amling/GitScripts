package Amling::Git::G3MD::Resolver::Simple;

use strict;
use warnings;

sub handle
{
    my $class = shift;
    my $line = shift;
    my $conflict = shift;

    for my $name (@{$class->names()})
    {
        if($line =~ /^\s*\Q$name\E\s*$/)
        {
            return $class->handle_simple($conflict);
        }
    }

    return undef;
}

1;
