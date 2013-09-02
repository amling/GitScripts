package Amling::Git::G3MD::Resolver;

use strict;
use warnings;

my @resolver_sources;

sub add_resolver_source
{
    my $resolver_source = shift;

    push @resolver_sources, $resolver_source;
}

sub _find_resolvers
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

    my @lines;
    for my $block (@$blocks)
    {
        my $type = $block->[0];

        if(0)
        {
        }
        elsif($type->[0] eq 'LINE')
        {
            push @lines, $type->[1];
        }
        elsif($type->[0] eq 'CONFLICT')
        {
            my $conflict = [@$block];
            shift @$conflict;

            push @lines, @{_resolve_conflict($conflict)};
        }
        else
        {
            die;
        }
    }

    return \@lines;
}

sub _resolve_conflict
{
    my $conflict = shift;

    my $resolvers = _find_resolvers($conflict);

    # TODO: consider pager?
    print "Conflict:\n";
    for my $line format_conflict($conflict)
    {
        print "   $line\n";
    }

    print "Options:\n";
    my %resolvers;
    for my $resolver (@$resolvers)
    {
        print "(" . $resolver->[0] . ") " . $resolver->[1] . "\n";
        $resolvers{$resolver->[0]} = $resolver->[2];
    }
    print "> \n";
    my $ans = <>;
    chomp $ans;
    my $resolver = $resolvers{$ans};
    die unless($resolver);
    return $resolver->();
}

use Amling::Git::G3MD::Resolver::CharacterMerge;
use Amling::Git::G3MD::Resolver::Edit;

1;
