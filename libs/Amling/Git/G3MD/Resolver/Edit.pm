package Amling::Git::G3MD::Resolver::Edit;

use strict;
use warnings;

use Amling::Git::G3MD::Parser;
use Amling::Git::G3MD::Resolver::Git;
use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;
use Amling::Git::G3MD::Utils;
use File::Temp ('tempfile');

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['e', 'edit'];
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;

    my ($fh, $fn) = tempfile('SUFFIX' => '.conflict');

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

    return Amling::Git::G3MD::Resolver::Git->resolve_blocks($blocks);
}

Amling::Git::G3MD::Resolver::add_resolver(sub { return __PACKAGE__->handle(@_); });

1;
