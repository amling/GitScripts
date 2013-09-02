package Amling::Git::G3MD::Resolver;

use strict;
use warnings;

my @resolvers;

sub add_resolver
{
    my $resolver = shift;

    push @resolvers, $resolver;
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

    while(1)
    {
        # TODO: consider pager?
        print "Conflict:\n";
        for my $line (@{Amling::Git::G3MD::Utils::format_conflict($conflict)})
        {
            print "   $line\n";
        }

        print "> ";
        my $ans = <>;
        chomp $ans;

        for my $resolver (@resolvers)
        {
            my $result = $resolver->($ans, $conflict);
            next unless($result);
            return resolve_blocks($result);
        }

        print "?\n";
    }
}

use Amling::Git::G3MD::Resolver::Auto;
use Amling::Git::G3MD::Resolver::CharacterMerge;
use Amling::Git::G3MD::Resolver::Edit;
use Amling::Git::G3MD::Resolver::Git;
use Amling::Git::G3MD::Resolver::LeftBack;
use Amling::Git::G3MD::Resolver::LeftFront;
use Amling::Git::G3MD::Resolver::Punt;
use Amling::Git::G3MD::Resolver::RightBack;
use Amling::Git::G3MD::Resolver::RightFront;
use Amling::Git::G3MD::Resolver::Sort;
use Amling::Git::G3MD::Resolver::TwoEdit;

1;
