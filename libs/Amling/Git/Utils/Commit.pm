package Amling::Git::Utils::Commit;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self =
    {
        'hash' => undef,
        'tree' => undef,
        'parents' => [],
        'msg' => undef,
        'author_name' => undef,
        'author_email' => undef,
        'committer_name' => undef,
        'committer_email' => undef,
        'files' => [],
    };

    bless $self, $class;

    return $self;
}

sub _set
{
    my $this = shift;
    my $key = shift;
    my $value = shift;

    if(defined($this->{$key}))
    {
        die "Commit got two of $key?";
    }

    $this->{$key} = $value;
}

sub set_hash
{
    my $this = shift;
    my $hash = shift;

    $this->_set('hash', $hash);
}

sub set_tree
{
    my $this = shift;
    my $tree = shift;

    $this->_set('tree', $tree);
}

sub add_parent
{
    my $this = shift;
    my $parent = shift;

    push @{$this->{'parents'}}, $parent;
}

sub set_author
{
    my $this = shift;
    my $author_name = shift;
    my $author_email = shift;

    $this->_set('author_name', $author_name);
    $this->_set('author_email', $author_email);
}

sub set_committer
{
    my $this = shift;
    my $committer_name = shift;
    my $committer_email = shift;

    $this->_set('committer_name', $committer_name);
    $this->_set('committer_email', $committer_email);
}

sub add_body_line
{
    my $this = shift;
    my $line = shift;

    if(!defined($this->{'subj'}))
    {
        $this->{'subj'} = $line;
    }
    if(defined($this->{'msg'}))
    {
        $this->{'msg'} .= "\n$line";
    }
    else
    {
        $this->{'msg'} = $line;
    }
}

sub add_file
{
    my $this = shift;
    my $file = shift;

    push @{$this->{'files'}}, $file;
}

sub count_files
{
    my $this = shift;
    my $re = shift;

    return scalar(grep { $_ =~ $re } @{$this->{'files'}});
}

1;
