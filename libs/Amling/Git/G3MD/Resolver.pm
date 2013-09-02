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
        elsif($type eq 'LINE')
        {
            push @lines, $block->[1];
        }
        elsif($type eq 'CONFLICT')
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
    for my $line (@{Amling::Git::G3MD::Utils::format_conflict($conflict)})
    {
        print "   $line\n";
    }

    print "Options:\n";
    my %resolvers;
    for my $resolver (@$resolvers)
    {
        my $label = $resolver->[0];
        if($label !~ s/^#//)
        {
            print "($label) " . $resolver->[1] . "\n";
        }
        $resolvers{$label} = $resolver->[2];
    }
    print "> ";
    my $ans = <>;
    chomp $ans;
    my $resolver = $resolvers{$ans};
    die unless($resolver);

    return resolve_blocks($resolver->());
}

use Amling::Git::G3MD::Resolver::Auto;
use Amling::Git::G3MD::Resolver::CharacterMerge;
use Amling::Git::G3MD::Resolver::Edit;
use Amling::Git::G3MD::Resolver::TwoEdit;
use Amling::Git::G3MD::Resolver::Punt;

use Amling::Git::G3MD::Resolver::LeftFront;
use Amling::Git::G3MD::Resolver::RightFront;
use Amling::Git::G3MD::Resolver::LeftBack;
use Amling::Git::G3MD::Resolver::RightBack;

use Amling::Git::G3MD::Resolver::Sort;

1;
