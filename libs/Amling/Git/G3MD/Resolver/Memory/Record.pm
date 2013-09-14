package Amling::Git::G3MD::Resolver::Memory::Record;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Memory::Database;
use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['mr', 'memoryrecord'];
}

sub description
{
    return 'Start recording a conflict reoslution.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;

    print "Starting recording memory...\n";
    my $result = Amling::Git::G3MD::Resolver::resolve_conflict($conflict);

    my $ok = 1;
    for my $line (@$result)
    {
        if($line =~ /^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)( |$)/)
        {
            print "Recording refused (still contains conflict headers).\n";
            $ok = 0;
            last;
        }
    }

    if($ok)
    {
        Amling::Git::G3MD::Resolver::Memory::Database::record($conflict, $result);
        print "Recording completed.\n";
    }

    return [map { ['LINE', $_] } @$result];
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
