package Amling::Git::GBD::State;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $commits = shift;

    my $self =
    {
        'commits' => $commits,
    };

    bless $self, $class;

    return $self;
}

sub get_commits
{
    my $this = shift;

    return keys(%{$this->{'commits'}});
}

sub clear_commit
{
    my $this = shift;
    my $commit = shift;

    my $commit_state = $this->{'commits'}->{$commit};
    if(defined($commit_state))
    {
        delete $commit_state->{'known'};
    }
}

1;
