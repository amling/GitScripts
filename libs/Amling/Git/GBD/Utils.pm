package Amling::Git::GBD::Utils;

use strict;
use warnings;

use Data::Dumper;

sub save_object
{
    my $file = shift;
    my $object = shift;

    my $fh;
    if($file eq "-")
    {
        open($fh, ">&STDOUT") || die "Cannot open $file: $!";
    }
    else
    {
        open($fh, ">", $file) || die "Cannot open $file: $!";
    }
    my $d = Data::Dumper->new([$object]);
    $d->Purity(1);
    print $fh $d->Dump($object);

    close($fh) || die "Cannot close $file: $!";
}

sub load_object
{
    my $file = shift;

    my $fh;
    if($file eq "-")
    {
        open($fh, "<&STDIN") || die "Cannot open $file: $!";
    }
    else
    {
        open($fh, "<", $file) || die "Cannot open $file: $!";
    }
    my $s = join("", <$fh>);
    close($fh) || die "Cannot close $file: $!";
    my $r;
    {
        no warnings;
        no strict;
        $r = eval($s);
    }
    if($@)
    {
        die "While parsing state file: $@";
    }
    return $r;
}

1;
