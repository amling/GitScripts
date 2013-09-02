package Amling::Git::G3MD::Resolver::ThreeEdit;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Git;
use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;
use File::Temp ('tempfile');

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['3e', 'threeedit'];
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my ($fh1, $fn1) = tempfile('SUFFIX' => '.lhs.conflict');
    my ($fh2, $fn2) = tempfile('SUFFIX' => '.mhs.conflict');
    my ($fh3, $fn3) = tempfile('SUFFIX' => '.rhs.conflict');

    for my $line (@$lhs_lines)
    {
        print $fh1 "$line\n";
    }
    close($fh1) || die "Cannot close temp file $fn1: $!";

    for my $line (@$mhs_lines)
    {
        print $fh2 "$line\n";
    }
    close($fh2) || die "Cannot close temp file $fn2: $!";

    for my $line (@$rhs_lines)
    {
        print $fh3 "$line\n";
    }
    close($fh3) || die "Cannot close temp file $fn3: $!";

    system('vim', '-O', $fn1, $fn2, $fn3) && die "Edit of files bailed?";

    my $lhs_lines2 = Amling::Git::G3MD::Utils::slurp($fn1);
    my $mhs_lines2 = Amling::Git::G3MD::Utils::slurp($fn2);
    my $rhs_lines2 = Amling::Git::G3MD::Utils::slurp($fn3);

    unlink($fn1) || die "Cannot unlink temp file $fn1: $!";
    unlink($fn2) || die "Cannot unlink temp file $fn2: $!";
    unlink($fn3) || die "Cannot unlink temp file $fn3: $!";

    return Amling::Git::G3MD::Resolver::Git->handle_simple([$lhs_title, $lhs_lines2, $mhs_title, $mhs_lines2, $rhs_title, $rhs_lines2]);
}

Amling::Git::G3MD::Resolver::add_resolver(sub { return __PACKAGE__->handle(@_); });

1;
