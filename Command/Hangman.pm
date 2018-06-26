package Command::Hangman;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_hangman);

use Mojo::Discord;
use Bot::Goose;

use File::Slurp;

###########################################################################################
# Command Info
my $command = "hangman";
my $access = 0; # Public
my $description = "This is a hangman command for building new actual commands";
my $pattern = '^(~hangman|~hm|~h )\s?([a-zA-Z]+)?\s?';
my $function = \&cmd_hangman;
my $usage = <<EOF;
Basic usage: ~hangman
Advanced usage: ~hangman
Other usage: ~hangman
EOF
###########################################################################################

sub new
{
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;
     
    # Setting up this command module requires the Discord connection 
    $self->{'bot'} = $params{'bot'};
    $self->{'discord'} = $self->{'bot'}->discord;
    $self->{'pattern'} = $pattern;

    # Register our command with the bot
    $self->{'bot'}->add_command(
        'command'       => $command,
        'access'        => $access,
        'description'   => $description,
        'usage'         => $usage,
        'pattern'       => $pattern,
        'function'      => $function,
        'object'        => $self,
    );
    
    return $self;
}
#
sub cmd_hangman
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    #$args =~ s/$pattern/$2/i;
    $args =~ s/(~hm|~hangman|~h)\s?//g;
   # print "THIS" . $args;
    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    if ($args =~ /^(| |\.)$/) {
        my $response = `perl Command/hangman.pl`;
        sleep(0.1);

        $discord->send_message($channel, $response);
    }
    elsif ($args =~ /^new$/) {
        write_file("word.txt", "");
        write_file("guessed.txt", "");
        my $response = `perl Command/hangman.pl`;

        sleep(0.1);

        $discord->send_message($channel, $response);
    }
    else {
        if(length($args) > 1) {
            $discord->send_message($channel, "Unknown command, only 1 letter at a time");
        }
        elsif(length($args) eq 1) {
            my $response = `perl Command/hangman.pl $args`;
            sleep(0.1);
            $discord->send_message($channel, $response);
        }
        else {
            my $response = `perl Command/hangman.pl`;
            sleep(0.1);
            $discord->send_message($channel, $response);
        }
    }
}

1;