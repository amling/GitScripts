package Amling::Git::G3MD::Resolver::CharacterMerge;

use strict;
use warnings;

sub get_resolvers
{
    my $conflict = shift;

    return [['ch', 'Character merge', sub { return _handle($conflict); }]];
}

sub _handle
{
    my $conflict = shift;

    # TODO
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
