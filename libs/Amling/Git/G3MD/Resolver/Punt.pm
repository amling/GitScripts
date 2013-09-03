package Amling::Git::G3MD::Resolver::Punt;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;
use Amling::Git::G3MD::Utils;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['p', 'punt'];
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;

    return [map { ['LINE', $_] } @{Amling::Git::G3MD::Utils::format_conflict($conflict)}];
}

Amling::Git::G3MD::Resolver::add_resolver(sub { return __PACKAGE__->handle(@_); });

1;
