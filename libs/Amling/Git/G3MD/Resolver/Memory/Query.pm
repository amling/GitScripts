package Amling::Git::G3MD::Resolver::Memory::Query;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Memory::Database;
use Amling::Git::G3MD::Resolver::Simple;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['mq', 'memoryquery'];
}

sub description
{
    return 'Query memory.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;

    my $result = Amling::Git::G3MD::Resolver::Memory::Database::query($conflict);

    if(!defined($result))
    {
        return undef;
    }

    return [map { ['LINE', $_] } @$result];
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
