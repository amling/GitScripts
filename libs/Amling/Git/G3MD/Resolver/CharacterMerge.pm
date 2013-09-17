package Amling::Git::G3MD::Resolver::CharacterMerge;

use strict;
use warnings;

use Amling::Git::G3MD::Parser;
use Amling::Git::G3MD::Resolver::Simple;
use Amling::Git::G3MD::Resolver;
use File::Temp ('tempfile');

use base ('Amling::Git::G3MD::Resolver::Simple');

sub names
{
    return ['character', 'char', 'cm', 'c'];
}

sub description
{
    return '3-way merge by character.';
}

sub handle_simple
{
    my $class = shift;
    my $conflict = shift;
    my ($lhs_title, $lhs_lines, $mhs_title, $mhs_lines, $rhs_title, $rhs_lines) = @$conflict;

    my $stage2 = _stage12($lhs_lines, $mhs_lines, $rhs_lines);
    #use Data::Dumper; print Dumper($stage2);
    my $stage3 = _stage3($stage2);
    #use Data::Dumper; print Dumper($stage3);
    my $stage4 = _stage4($stage3, $lhs_title, $mhs_title, $rhs_title);
    #use Data::Dumper; print Dumper($stage4);

    return $stage4;
}

sub _steps
{
    my $e = shift;
    my $lhs_tokens = shift;
    my $mhs_tokens = shift;
    my $rhs_tokens = shift;

    my ($lhs_depth, $mhs_depth, $rhs_depth) = split(/,/, $e);
    my $lhs_depth2 = $lhs_depth + 1;
    my $mhs_depth2 = $mhs_depth + 1;
    my $rhs_depth2 = $rhs_depth + 1;

    my $lhs_token = ($lhs_depth < @$lhs_tokens ? $lhs_tokens->[$lhs_depth] : "");
    my $mhs_token = ($mhs_depth < @$mhs_tokens ? $mhs_tokens->[$mhs_depth] : "");
    my $rhs_token = ($rhs_depth < @$rhs_tokens ? $rhs_tokens->[$rhs_depth] : "");

    my @steps;

    if($lhs_token ne '' && $mhs_token ne '' && $rhs_token ne '' && $lhs_token eq $mhs_token && $mhs_token eq $rhs_token)
    {
        push @steps, ["$lhs_depth2,$mhs_depth2,$rhs_depth2", 0];
        # mmm, I think like 2 side case it's never worth refusing a match
        return \@steps;
    }
    if($lhs_token ne '' && $mhs_token ne '' && $lhs_token eq $mhs_token)
    {
        push @steps, ["$lhs_depth2,$mhs_depth2,$rhs_depth", 1];
    }
    if($mhs_token ne '' && $rhs_token ne '' && $mhs_token eq $rhs_token)
    {
        push @steps, ["$lhs_depth,$mhs_depth2,$rhs_depth2", 1];
    }
    if($lhs_token ne '' && $rhs_token ne '' && $lhs_token eq $rhs_token)
    {
        push @steps, ["$lhs_depth2,$mhs_depth,$rhs_depth2", 1];
    }
    if($lhs_token ne '')
    {
        push @steps, ["$lhs_depth2,$mhs_depth,$rhs_depth", 1];
    }
    if($mhs_token ne '')
    {
        push @steps, ["$lhs_depth,$mhs_depth2,$rhs_depth", 1];
    }
    if($rhs_token ne '')
    {
        push @steps, ["$lhs_depth,$mhs_depth,$rhs_depth2", 1];
    }

    return \@steps;
}

sub _make_tokens
{
    my $lines = shift;

    my @ret;
    for my $line (@$lines)
    {
        my $line2 = $line;
        if($line2 =~ s/^(\s+)//)
        {
            push @ret, $1;
        }
        push @ret, split(//, $line2);
        push @ret, "\n";
    }

    return \@ret;
}

sub _stage12
{
    my $lhs_lines = shift;
    my $mhs_lines = shift;
    my $rhs_lines = shift;

    my $lhs_tokens = _make_tokens($lhs_lines);
    my $mhs_tokens = _make_tokens($mhs_lines);
    my $rhs_tokens = _make_tokens($rhs_lines);

    my ($fh1, $fn1) = tempfile('SUFFIX' => '.lhs');
    my ($fh2, $fn2) = tempfile('SUFFIX' => '.mhs');
    my ($fh3, $fn3) = tempfile('SUFFIX' => '.rhs');

    for my $token (@$lhs_tokens)
    {
        print $fh1 unpack("H*", $token) . "\n";
    }
    close($fh1) || die "Cannot close temp file $fn1: $!";

    for my $token (@$mhs_tokens)
    {
        print $fh2 unpack("H*", $token) . "\n";
    }
    close($fh2) || die "Cannot close temp file $fn2: $!";

    for my $token (@$rhs_tokens)
    {
        print $fh3 unpack("H*", $token) . "\n";
    }
    close($fh3) || die "Cannot close temp file $fn3: $!";

    open(my $fh, '-|', 'git', 'merge-file', '--diff3', '-p', '-q', $fn1, $fn2, $fn3) || die "Cannot open git merge-file ...: $!";
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

    my $blocks = Amling::Git::G3MD::Parser::parse_3way(\@lines);

    my @ret;
    for my $block (@$blocks)
    {
        my $type = $block->[0];

        if(0)
        {
        }
        elsif($type eq 'LINE')
        {
            my $text = pack("H*", $block->[1]);
            push @ret, ['RESOLVED', $text];
        }
        elsif($type eq 'CONFLICT')
        {
            my $conflict = [@$block];
            shift @$conflict;

            my ($sub_lhs_title, $sub_lhs_lines, $sub_mhs_title, $sub_mhs_lines, $sub_rhs_title, $sub_rhs_lines) = @$conflict;

            my $sub_lhs_text = pack("H*", join("", @$sub_lhs_lines));
            my $sub_mhs_text = pack("H*", join("", @$sub_mhs_lines));
            my $sub_rhs_text = pack("H*", join("", @$sub_rhs_lines));

            push @ret, ['CONFLICT', $sub_lhs_text, $sub_mhs_text, $sub_rhs_text];
        }
        else
        {
            die;
        }
    }

    return \@ret;
}

sub _stage3
{
    my $stage2 = shift;

    my @ret;

    my $lhs_text = "";
    my $mhs_text = "";
    my $rhs_text = "";
    my $had_conflict = 0;

    my $flush_block = sub
    {
        if($had_conflict)
        {
            push @ret, ['CONFLICT', $lhs_text, $mhs_text, $rhs_text];
        }
        else
        {
            push @ret, ['RESOLVED', $mhs_text];
        }

        $lhs_text = "";
        $mhs_text = "";
        $rhs_text = "";
        $had_conflict = 0;
    };

    for my $stage2_e (@$stage2)
    {
        my $type = $stage2_e->[0];

        if(0)
        {
        }
        elsif($type eq 'CONFLICT')
        {
            $lhs_text .= $stage2_e->[1];
            $mhs_text .= $stage2_e->[2];
            $rhs_text .= $stage2_e->[3];
            $had_conflict = 1;
        }
        elsif($type eq 'RESOLVED')
        {
            for my $c (split(//, $stage2_e->[1]))
            {
                $lhs_text .= $c;
                $mhs_text .= $c;
                $rhs_text .= $c;
                if($c eq "\n")
                {
                    $flush_block->();
                }
            }
        }
        else
        {
            die;
        }
    }
    $flush_block->();

    return \@ret;
}

sub _split_lines
{
    my $text = shift;

    my @ret;
    while(1)
    {
        if($text =~ s/^(.*)\n//)
        {
            push @ret, $1;
            next;
        }
        if($text eq '')
        {
            return \@ret;
        }
        die;
    }
}

sub _stage4
{
    my $stage3 = shift;
    my $lhs_title = shift;
    my $mhs_title = shift;
    my $rhs_title = shift;

    my @ret;

    my $lhs_text = "";
    my $mhs_text = "";
    my $rhs_text = "";
    my $non_empty = 0;

    my $flush_block = sub
    {
        if($non_empty)
        {
            push @ret,
            [
                'CONFLICT',
                $lhs_title,
                _split_lines($lhs_text),
                $mhs_title,
                _split_lines($mhs_text),
                $rhs_title,
                _split_lines($rhs_text),
            ];
        }

        $lhs_text = "";
        $mhs_text = "";
        $rhs_text = "";
        $non_empty = 0;
    };

    for my $stage3_e (@$stage3)
    {
        my $type = $stage3_e->[0];

        if(0)
        {
        }
        elsif($type eq 'CONFLICT')
        {
            $lhs_text .= $stage3_e->[1];
            $mhs_text .= $stage3_e->[2];
            $rhs_text .= $stage3_e->[3];
            $non_empty = 1;
        }
        elsif($type eq 'RESOLVED')
        {
            $flush_block->();
            push @ret, map { ['LINE', $_] } @{_split_lines($stage3_e->[1])};
        }
        else
        {
            die;
        }
    }
    $flush_block->();

    return \@ret;
}

Amling::Git::G3MD::Resolver::add_resolver(__PACKAGE__);

1;
