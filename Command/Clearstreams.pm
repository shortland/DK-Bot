package Command::Clearstreams;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_clearstreams);

use Mojo::Discord;
use Bot::Goose;

###########################################################################################
# Command Info
my $command = "clearstreams";
my $access = 0; # Public
my $description = "This is a clearstreams command for building new actual commands";
my $pattern = '^(~clearstreams)(\s)?';
my $function = \&cmd_clearstreams;
my $usage = <<EOF;
Basic usage: !clearstreams
Advanced usage: !clearstreams
Other usage: !clearstreams
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

sub cmd_clearstreams
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    $discord->send_message($channel, "Streams channel cleared. \nPlease note: this action is already automatically done once a day.");

    `cd /var/www/html/GOOSE/ && perl clear_channel.pl`;

    # Send a message back to the channel
    
}

1;
