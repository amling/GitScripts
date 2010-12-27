package Amling::GRD::Operation::Linear;

use strict;
use warnings;

use Amling::GRD::Utils;

# TODO: kill this in favor of MLinear?

sub handler
{
    my $s = shift;

    my ($base, $branch);
    if($s =~ /^(?:linear|L):([^,]*)(?:,([^,]*))?$/)
    {
        $base = $1;
        $branch = $2;
    }
    else
    {
        return;
    }

    my $head_branch = undef;
    {
        open(my $fh, '-|', 'git', 'symbolic-ref', '-q', 'HEAD') || die "Cannot open git symbolic-ref: $!";
        while(my $line = <$fh>)
        {
            chomp $line;
            if($line =~ /^refs\/heads\/(.*)$/)
            {
                $head_branch = $1;
            }
        }
        close($fh); # do not die, if HEAD is detached this fails, stupid fucking no good way to figure that out
    }

    my $place_branch = undef;
    if(defined($branch))
    {
        $place_branch = $branch;
    }
    else
    {
        $place_branch = $head_branch; # undef or otherwise
        $branch = "HEAD";
    }

    my %rshowref;
    {
        open(my $fh, '-|', 'git', 'show-ref') || die "Cannot open git show-ref: $!";
        while(my $line = <$fh>)
        {
            if($line =~ /^([0-9a-f]{40}) (.*)$/)
            {
                my ($commit, $ref) = ($1, $2);
                if($ref =~ /^refs\/heads\/(.*)$/)
                {
                    $rshowref{$commit}->{$1} = 1;
                }
            }
            else
            {
                die "Bad line: $line";
            }
        }
        close($fh) || die "Cannot close git show-ref: $!";
    }

    my @lines;
    {
        open(my $fh, '-|', 'git', 'log', "$base..$branch", '--pretty=format:%H:%s') || die "Cannot open top git log: $!";
        while(my $line = <$fh>)
        {
            chomp $line;
            if($line =~ /^([0-9a-f]{40}):(.*)$/)
            {
                my ($commit, $msg) = ($1, $2);
                unshift @lines, "pick $commit # $msg";
                for my $cbranch (sort(keys(%{$rshowref{$commit} || {}})))
                {
                    if(defined($place_branch) && $place_branch eq $cbranch)
                    {
                        next;
                    }
                    unshift @lines, "# branch $cbranch";
                }
            }
            else
            {
                die "Bad line: $line";
            }
        }
        close($fh) || die "Cannot close top git log: $!";
    }

    if(defined($place_branch))
    {
        push @lines, "head $place_branch";
    }
    else
    {
        push @lines, "head";
    }

    my $latest_base = Amling::GRD::Utils::convert_commitlike($base);

    return ($latest_base, \@lines);
}

Amling::GRD::Operation::add_operation(\&handler);

1;
