package Amling::Git::G3MD::Resolver::Edit;

use strict;
use warnings;

use Amling::Git::G3MD::Parser;
use Amling::Git::G3MD::Resolver;
use Amling::Git::G3MD::Utils;
use File::Temp ('tempfile');

sub get_resolvers
{
    my $conflict = shift;

    return [['e', 'Edit', sub { return _handle($conflict); }]];
}

sub _handle
{
    my $conflict = shift;

    my ($fh, $fn) = tempfile('SUFFIX' => '.grd');

    for my $line (@{Amling::Git::G3MD::Utils::format_conflict($conflict)})
    {
        print $fh "$line\n";
    }
    close($fh) || die "Cannot close temp file $fn: $!";

    my $editor = $ENV{'EDITOR'} || "vi";
    system($editor, $fn) && die "Edit of file bailed?";

    my $lines = Amling::Git::G3MD::Utils::slurp($fn);

    unlink($fn) || die "Cannot unlink temp file $fn: $!";

    my $blocks = Amling::Git::G3MD::Parser::parse_lines($lines);
    my $lines2 = Amling::Git::G3MD::Resolver::resolve_blocks($blocks);
    return $lines2;
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
