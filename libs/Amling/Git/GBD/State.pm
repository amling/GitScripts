package Amling::Git::GBD::State;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $commits_external = shift;

    my $parents = {};
    my $children = {};
    my $commits = {};

    for my $commit (keys(%$commits_external))
    {
        my $commit_state_external = $commits_external->{$commit};
        $commits->{$commit} =
        {
            'weight' => $commit_state_external->{'weight'},
            'parents' => [],
            'children' => [],
        };
    }

    for my $child (keys(%$commits_external))
    {
        my $commit_state_external = $commits_external->{$child};
        for my $parent (@{$commit_state_external->{'parents'}})
        {
            if($commits->{$parent})
            {
                push @{$commits->{$child}->{'parents'}}, $parent;
                push @{$commits->{$parent}->{'children'}}, $child;
            }
        }
    }

    my $self =
    {
        'commits' => $commits,
        'parents' => $parents,
        'children' => $children,
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
    my $root_commit = shift;

    my $root_known = $this->get_known($root_commit);
    if(defined($root_known))
    {
        my $field;
        if($root_known eq 'GOOD')
        {
            $field = 'children';
        }
        elsif($root_known eq 'BAD')
        {
            $field = 'parents';
        }
        my $cb = sub
        {
            my $commit = shift;
            my $known = $this->get_known($commit);
            if(defined($known) && $known eq $root_known)
            {
                $this->_set_known($commit, undef);
                return 1;
            }
            return 0;
        };
        $this->_traverse($root_commit, $cb, $field);
    }
}

sub has_commit
{
    my $this = shift;
    my $commit = shift;

    return defined($this->{'commits'}->{$commit});
}

sub get_known
{
    my $this = shift;
    my $commit = shift;

    my $commit_state = $this->{'commits'}->{$commit};
    if(!defined($commit_state))
    {
        return undef;
    }

    return $commit_state->{'known'};
}

sub _set_known
{
    my $this = shift;
    my $commit = shift;
    my $known = shift;

    my $commit_state = $this->{'commits'}->{$commit};
    if(!defined($commit_state))
    {
        die "_set_known() on unknown $commit_state!";
    }

    $commit_state->{'known'} = $known
}

sub set_bad
{
    my $this = shift;
    my $root_commit = shift;

    $this->set_common($root_commit, 'BAD', 'children');
}

sub set_good
{
    my $this = shift;
    my $root_commit = shift;

    $this->set_common($root_commit, 'GOOD', 'parents');
}

sub set_common
{
    my $this = shift;
    my $root_commit = shift;
    my $root_known = shift;
    my $field = shift;

    my $cb = sub
    {
        my $commit = shift;
        my $known = $this->get_known($commit);
        if(defined($known))
        {
            if($known eq $root_known)
            {
                return 0;
            }
            else
            {
                die "$commit is already $known!";
            }
        }
        else
        {
            $this->_set_known($commit, $root_known);
            return 1;
        }
    };
    $this->_traverse($root_commit, $cb, $field);
}

sub _traverse
{
    my $this = shift;
    my $root_commit = shift;
    my $cb = shift;
    my $field = shift;

    my @q = ($root_commit);
    my %done = ($root_commit => 1);
    while(@q)
    {
        my $commit = shift @q;
        if($cb->($commit))
        {
            if($this->{'commits'}->{$commit})
            {
                for my $next (@{$this->{'commits'}->{$commit}->{$field}})
                {
                    if(!$done{$next})
                    {
                        push @q, $next;
                        $done{$next} = 1;
                    }
                }
            }
        }
    }
}

1;
