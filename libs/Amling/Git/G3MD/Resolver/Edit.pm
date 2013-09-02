package Amling::Git::G3MD::Resolver::Edit;

use strict;
use warnings;

sub get_resolvers
{
    my $conflict = shift;

    return [['e', 'Edit', sub { return _handle($conflict); }]];
}

sub _handle
{
    my $conflict = shift;

    # TODO
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
