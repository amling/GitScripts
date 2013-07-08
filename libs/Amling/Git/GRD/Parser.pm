package Amling::Git::GRD::Parser;

use strict;
use warnings;

use Amling::Git::GRD::Command;
use File::Temp ('tempfile');

sub edit_loop
{
    my $lines = shift;
    $lines = [@$lines];
    my $skip_edit = shift;

    while(1)
    {
        my ($commands, $problems) = parse($lines);
        if($skip_edit && $commands)
        {
            return $commands;
        }
        $skip_edit = 1;

        my ($fh, $fn) = tempfile('SUFFIX' => '.grd');

        if(@$problems)
        {
            print $fh "# NOTE: This script does not parse, please correct the errors:\n";
            for my $problem (@$problems)
            {
                print $fh "# NOTE: $problem\n";
            }
            print $fh "\n";
        }

        while(@$lines && @$lines[0] =~ /^# NOTE: /)
        {
            shift @$lines;
        }
        while(@$lines && @$lines[0] eq '')
        {
            shift @$lines;
        }

        for my $line (@$lines)
        {
            print $fh "$line\n";
        }

        close($fh) || die "Cannot close temp file $fn: $!";

        my $editor = $ENV{'EDITOR'} || "vi";
        system($editor, $fn) && die "Edit of file bailed?";

        open($fh, "<", $fn) || die "Cannot reopen temp file $fn: $!";
        $lines = [];
        while(my $line = <$fh>)
        {
            chomp $line;
            push @$lines, $line;
        }
        close($fh) || die "Cannot close temp file $fn: $!";
        unlink($fn) || die "Cannot unlink temp file $fn: $!";
    }
}

sub parse
{
    my $lines = shift;

    my $commands = [];
    my $problems = [];

    for my $line (@$lines)
    {
        $line =~ s/#.*$//;
        $line =~ s/^ *//;
        $line =~ s/ *$//;

        next if($line eq '');

        my $command = Amling::Git::GRD::Command::parse($line);

        if(defined($command))
        {
            push @$commands, $command;
        }
        else
        {
            push @$problems, "Unintelligible line: $line";
        }
    }

    if(@$problems)
    {
        $commands = undef;
    }

    return ($commands, $problems);
}

1;
