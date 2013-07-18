package Amling::Git::GRD::Exec::Context;

use strict;
use warnings;

use Amling::Git::Utils;

sub new
{
    my $class = shift;
    my $head = shift || die;

    my $self =
    {
        'HEAD' => $head,
    };

    bless $self, $class;

    return $self;
}

sub get
{
    my $self = shift;
    my $item = shift;
    my $def = shift;

    if(defined($def) && !defined($self->{$item}))
    {
        $self->{$item} = $def;
    }

    return $self->{$item};
}

sub set
{
    my $self = shift;
    my $item = shift;
    my $def = shift;

    $self->{$item} = $def;
}

sub get_head
{
    my $self = shift;

    return $self->{'HEAD'};
}

sub materialize_head
{
    my $self = shift;
    my $commit = shift;

    if(defined($commit))
    {
        $self->{'HEAD'} = $commit;
    }
    else
    {
        $commit = $self->{'HEAD'};
    }

    Amling::Git::Utils::run_system("git", "checkout", $commit) || die "Cannot checkout $commit";
}

sub set_head
{
    my $self = shift;
    my $commit = shift;

    $self->{'HEAD'} = $commit;
}

sub uptake_head
{
    my $self = shift;

    $self->{'HEAD'} = Amling::Git::Utils::convert_commitlike('HEAD');
}

1;
