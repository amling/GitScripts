package Amling::Git::G3MD::Resolver::Memory::Main;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver::Memory::Query;
use Amling::Git::G3MD::Resolver::Memory::Record;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['m', 'memory'];
}

sub description
{
    return 'Query memory and start recording on a miss.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;

    my $result = Amling::Git::G3MD::Resolver::Memory::Query->handle_simple($conflict);

    if(defined($result))
    {
        return $result;
    }

    return Amling::Git::G3MD::Resolver::Memory::Record->handle_simple($conflict);
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
