package Amling::Git::GBD::State;

use strict;
use warnings;

sub new_state
{
    my $commits = shift;

    return
    {
        'commits' => $commits,
    };
}

sub get_commits
{
    my $state = shift;

    return keys(%{$state->{'commits'}});
}

sub clear_commit
{
    my $state = shift;
    my $commit = shift;

    my $commit_state = $state->{'commits'}->{$commit};
    if(defined($commit_state))
    {
        delete $commit_state->{'known'};
    }
}

1;
