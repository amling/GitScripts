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

sub help
{
    my $class = shift;

    my $names = $class->names();
    my $names_str;
    if(@$names == 1)
    {
        $names_str = $names->[0];
    }
    else
    {
        $names_str = "{" . join("|", @$names) . "}";
    }
    my $desc = $class->description();

    return [$names->[0], "$names_str - $desc"];
}

1;
