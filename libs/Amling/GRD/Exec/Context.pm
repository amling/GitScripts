package Amling::GRD::Exec::Context;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self =
    {
        'stack'        => [],
        'set_branches' => {},
        'head'         => undef,
    };

    bless $self, $class;

    return $self;
}

sub set_branch
{
    my $self = shift;
    my $branch = shift;
    my $commit = shift;

    $self->{'set_branches'}->{$branch} = $commit;
}

sub get_branches
{
    my $self = shift;

    return $self->{'set_branches'};
}

sub pushc
{
    my $self = shift;
    my $commit = shift;

    push @{$self->{'stack'}}, $commit;
}

sub popc
{
    my $self = shift;
    my $commit = shift;

    return ((pop @{$self->{'stack'}}) || die "Empty stack popped?!");
}

sub set_dhead
{
    my $self = shift;
    my $commit = shift;

    $self->{'head'} = [0, $commit];
}

sub set_head
{
    my $self = shift;
    my $branch = shift;

    $self->{'head'} = [1, $branch];
}

1;
