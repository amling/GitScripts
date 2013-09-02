package Amling::Git::G3MD::Resolver::TwoEdit;

use strict;
use warnings;

use Amling::Git::G3MD::Algo;
use File::Temp ('tempfile');

sub get_resolvers
{
    my $conflict = shift;

    return [['t', 'Two diff edit', sub { return _handle($conflict); }]];
}

sub _handle
{
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $lhs_diff = _two_diff($mhs_lines, $lhs_lines);
    my $rhs_diff = _two_diff($mhs_lines, $rhs_lines);
    my $dbl_diff = _two_diff($lhs_lines, $rhs_lines);

    my $main_title;
    my $main_lines;
    my $ref_title;
    my $ref_lines;
    if($dbl_diff->[0] <= $lhs_diff->[0] && $dbl_diff->[0] <= $rhs_diff->[0])
    {
        $main_title = "$lhs_title/$rhs_title";
        $main_lines = _format_diff($dbl_diff->[1], $lhs_title, $rhs_title);
        $ref_title = $mhs_title;
        $ref_lines = $mhs_lines;
    }
    elsif($rhs_diff->[0] <= $lhs_diff->[0])
    {
        $main_title = $lhs_title;
        $main_lines = $lhs_lines;
        $ref_title = "$mhs_title/$rhs_title";
        $ref_lines = _format_diff($rhs_diff->[1], $mhs_title, $rhs_title);
    }
    else
    {
        $main_title = $rhs_title;
        $main_lines = $rhs_lines;
        $ref_title = "$mhs_title/$lhs_title";
        $ref_lines = _format_diff($lhs_diff->[1], $mhs_title, $lhs_title);
    }

    $ref_lines = ["# Main: $main_title", "# Reference: $ref_title", @$ref_lines];

    my ($fh1, $fn1) = tempfile('SUFFIX' => '.main.conflict');
    my ($fh2, $fn2) = tempfile('SUFFIX' => '.ref.conflict');

    for my $line (@$main_lines)
    {
        print $fh1 "$line\n";
    }
    close($fh1) || die "Cannot close temp file $fn1: $!";

    for my $line (@$ref_lines)
    {
        print $fh2 "$line\n";
    }
    close($fh2) || die "Cannot close temp file $fn2: $!";

    system('vim', '-O', $fn1, $fn2) && die "Edit of files bailed?";

    my $lines2 = Amling::Git::G3MD::Utils::slurp($fn1);

    unlink($fn1) || die "Cannot unlink temp file $fn1: $!";
    unlink($fn2) || die "Cannot unlink temp file $fn2: $!";

    # TODO: determine if something went wrong, etc.

    return [map { ['LINE', $_] } @$lines2];
}

sub _two_diff
{
    my $lhs_lines = shift;
    my $rhs_lines = shift;

    my $cb =
    {
        'first' => '0,0',
        'last' => scalar(@$lhs_lines) . "," . scalar(@$rhs_lines),
        'step' => sub
        {
            my $e = shift;

            my ($lhs_depth, $rhs_depth) = split(/,/, $e);
            my $lhs_depth2 = $lhs_depth + 1;
            my $rhs_depth2 = $rhs_depth + 1;

            my $lhs_e = ($lhs_depth < @$lhs_lines) ? $lhs_lines->[$lhs_depth] : undef;
            my $rhs_e = ($rhs_depth < @$rhs_lines) ? $rhs_lines->[$rhs_depth] : undef;

            my @steps;

            if(defined($lhs_e) && defined($rhs_e) && $lhs_e eq $rhs_e)
            {
                push @steps, ["$lhs_depth2,$rhs_depth2", 0];
            }
            if(defined($lhs_e))
            {
                push @steps, ["$lhs_depth2,$rhs_depth", 1];
            }
            if(defined($rhs_e))
            {
                push @steps, ["$lhs_depth,$rhs_depth2", 1];
            }

            return \@steps;
        },
        'result' => sub
        {
            my $prev = shift;
            my $pos = shift;

            my ($prev_lhs_depth, $prev_rhs_depth) = split(/,/, $prev);
            my ($pos_lhs_depth, $pos_rhs_depth) = split(/,/, $pos);

            my $lhs_element;
            if($prev_lhs_depth == $pos_lhs_depth)
            {
                $lhs_element = undef;
            }
            elsif($prev_lhs_depth + 1 == $pos_lhs_depth)
            {
                $lhs_element = $lhs_lines->[$prev_lhs_depth];
            }
            else
            {
                die;
            }

            my $rhs_element;
            if($prev_rhs_depth == $pos_rhs_depth)
            {
                $rhs_element = undef;
            }
            elsif($prev_rhs_depth + 1 == $pos_rhs_depth)
            {
                $rhs_element = $rhs_lines->[$prev_rhs_depth];
            }
            else
            {
                die;
            }

            return [$lhs_element, $rhs_element];
        },
    };

    my $r = Amling::Git::G3MD::Algo::dfs($cb);

    my $ct = 0;
    for my $e (@$r)
    {
        if(!defined($e->[0]) || !defined($e->[1]))
        {
            ++$ct;
        }
    }

    return [$ct, $r];
}

sub _format_diff
{
    my $diff = shift;
    my $lhs_title = shift;
    my $rhs_title = shift;

    my @ret;

    my @lhs;
    my @rhs;

    my $flush_block = sub
    {
        if(@lhs || @rhs)
        {
            push @ret, "<<<<<<< $lhs_title";
            push @ret, @lhs;
            push @ret, "=======";
            push @ret, @rhs;
            push @ret, ">>>>>>> $rhs_title";

            @lhs = ();
            @rhs = ();
        }
    };

    for my $e (@$diff)
    {
        if(defined($e->[0]) && defined($e->[1]))
        {
            $flush_block->();
            push @ret, $e->[0];
        }
        elsif(defined($e->[0]))
        {
            push @lhs, $e->[0];
        }
        elsif(defined($e->[1]))
        {
            push @rhs, $e->[1];
        }
        else
        {
            die;
        }
    }
    $flush_block->();

    return \@ret;
}

Amling::Git::G3MD::Resolver::add_resolver_source(\&get_resolvers);

1;
