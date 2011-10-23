package Amling::Git::GBD::Action::Shell;

use strict;
use warnings;

use Amling::Git::GBD::Action::BaseZeroArg;
use Amling::Git::GBD::Action;

use base ('Amling::Git::GBD::Action::BaseZeroArg');

sub get_action_name
{
    return "shell";
}

sub execute
{
    my $this = shift;
    my $ctx = shift;

    while(1)
    {
        print "> ";
        my $line = <>;
        if(!$line)
        {
            last;
        }
        chomp $line;
        if($line =~ /^\s*(exit|quit)\s*$/)
        {
            last;
        }
        my $action = Amling::Git::GBD::Action::shell_action($line);
        if(!defined($action))
        {
            print "Could not parse: " . $line . "\n";
        }
        else
        {
            eval
            {
                $action->execute($ctx);
            };
            if($@)
            {
                print "Action caught fire:\n";
                warn $@;
            }
        }
    }
}

1;
