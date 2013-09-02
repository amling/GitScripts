package Amling::Git::G3MD::Resolver::Sort;

use strict;
use warnings;

use Amling::Git::G3MD::Parser;
use Amling::Git::G3MD::Resolver;
use Amling::Git::G3MD::Utils;
use File::Temp ('tempfile');

sub get_resolvers
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my %lhs_lines;
    my %mhs_lines;
    my %rhs_lines;
    my %all_lines;

    for my $pair ([\%lhs_lines, $lhs_lines], [\%mhs_lines, $mhs_lines], [\%rhs_lines, $rhs_lines])
    {
        my ($hr, $ar) = @$pair;

        for my $line (@$ar)
        {
            return [] if($hr->{$line});
            $hr->{$line} = 1;
            $all_lines{$line} = 1;
        }
    }

    my @ret;
    for my $line (sort(keys(%all_lines)))
    {
        my $lhs_present = $lhs_lines{$line} || 0;
        my $mhs_present = $mhs_lines{$line} || 0;
        my $rhs_present = $rhs_lines{$line} || 0;

        my $present;
        if($lhs_present == $mhs_present)
        {
            $present = $rhs_present;
        }
        elsif($mhs_present == $rhs_present)
        {
            $present = $lhs_present;
        }
        else
        {
            die;
        }

        push @ret, ['LINE', $line] if($present);
    }

    return [['s', 'Sort', sub { return \@ret; }]];
}

sub _handle
{
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

    return Amling::Git::G3MD::Parser::parse_lines($lines);
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
