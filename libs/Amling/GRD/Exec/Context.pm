package Amling::GRD::Exec::Context;

use strict;
use warnings;

sub new
{
    my ($class) = @_;

    my $self =
    {
        'stack'        => [],
        'set_branches' => {},
    };

    bless $self, $class;

    return $self;
}

sub set_branch
{
    my ($self, $branch, $commit) = @_;

    $self->{'set_branches'}->{$branch} = $commit;
}

sub get_branches
{
    my ($self) = @_;

    return $self->{'set_branches'};
}

sub pushc
{
    my ($self, $commit) = @_;

    push @{$self->{'stack'}}, $commit;
}

sub popc
{
    my ($self, $commit) = @_;

    return ((pop @{$self->{'stack'}}) || die "Empty stack popped?!");
}

1;
