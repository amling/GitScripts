package Amling::Git::G3MD::Resolver;

use strict;
use warnings;

my @resolver_sources;

sub add_resolver_source
{
    my $resolver_source = shift;

    push @resolver_sources, $resolver_source;
}

sub find_resolvers
{
    my $conflict = shift;

    my @ret;
    for my $resolver_source (@resolver_sources)
    {
        push @ret, @{$resolver_source->($conflict)};
    }

    return \@ret;
}

sub resolve_blocks
{
    my $blocks = shift;

    # TODO
}

use Amling::Git::G3MD::Resolver::CharacterMerge;
use Amling::Git::G3MD::Resolver::Edit;

1;
