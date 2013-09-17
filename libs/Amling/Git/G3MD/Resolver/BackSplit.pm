package Amling::Git::G3MD::Resolver::BackSplit;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::BaseSplit;
use Amling::Git::G3MD::Resolver::Git;
use Amling::Git::G3MD::Resolver;

use base ('Amling::Git::G3MD::Resolver::BaseSplit');

sub _names
{
    return ['backsplit', 'bsp'];
}

sub decide_prefix
{
    my $class = shift;
    my $depth = shift;
    my $length = shift;

    return $length - $depth;
}

sub side
{
    return "back";
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
