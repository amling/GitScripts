package Amling::Git::G3MD::Resolver::Git;

use strict;
use warnings;

use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;
use File::Temp ('tempfile');

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['g', 'git'];
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
    for my $line (@$mhs_lines)
    {
        print $fh2 "$line\n";
    }
    for my $line (@$rhs_lines)
    {
        print $fh3 "$line\n";
    }

    close($fh1) || die "Cannot close temp file $fn1: $!";
    close($fh2) || die "Cannot close temp file $fn2: $!";
    close($fh3) || die "Cannot close temp file $fn3: $!";

    open(my $fh, '-|', 'git', 'merge-file', '-L', $lhs_title, '-L', $mhs_title, '-L', $rhs_title, '-p', '-q', $fn1, $fn2, $fn3) || die "Cannot open git merge-file ...: $!";
    my @lines;
    while(my $line = <$fh>)
    {
        chomp $line;
        push @lines, $line;
    }
    close($fh); # nope || die ...

    unlink($fn1) || die "Cannot unlink temp file $fn1: $!";
    unlink($fn2) || die "Cannot unlink temp file $fn2: $!";
    unlink($fn3) || die "Cannot unlink temp file $fn3: $!";

    return Amling::Git::G3MD::Parser::parse_lines(\@lines);
}

Amling::Git::G3MD::Resolver::add_resolver(sub { return __PACKAGE__->handle(@_); });

1;
