package Command::Ping;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_ping);

use Mojo::Discord;
use Bot::Goose;
use Mojo::JSON qw(decode_json);
use Data::Dumper;
use File::Slurp;

###########################################################################################
# Command Info
my $command = "Ping";
my $access = 0; # For everyone
my $description = "List available commands";
my $pattern = '^(~ping)(\s)?';
my $function = \&cmd_ping;
my $usage = <<EOF;
Usage: ~ping
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

sub cmd_ping
{
    my ($self, $channel, $author, $msg) = @_;

    #my $args = read_file("files/help.txt");
    my $pattern = $self->{'pattern'};

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    eval 
    { 
        my $json = decode_json("pong");
        $discord->send_message($channel, $json);
    };
    if ($@)
    {
        #Send as plaintext instead.
       $discord->send_message($channel, "pong");
    }
}

1;
