package Amling::Git::G3MD::Resolver::Punt;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver;
use Amling::Git::G3MD::Utils;
use File::Temp ('tempfile');

sub get_resolvers
{
    my $conflict = shift;

    return [['p', 'punt', sub { return _handle($conflict); }]];
}

sub _handle
{
    my $conflict = shift;

    return Amling::Git::G3MD::Utils::format_conflict($conflict);
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
