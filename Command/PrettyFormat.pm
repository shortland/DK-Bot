package Command::PrettyFormat;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_prettyformat);

use Mojo::Discord;
use Bot::Goose;

###########################################################################################
# Command Info
my $command = "prettyformat";
my $access = 0; # Public
my $description = "This is a prettyformat command for building new actual commands";
my $pattern = '^(~prettyformat)(\s)?';
my $function = \&cmd_prettyformat;
my $usage = <<EOF;
Basic usage: !prettyformat
Advanced usage: !prettyformat
Other usage: !prettyformat
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

sub cmd_prettyformat
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    # Send a message back to the channel
    $discord->send_message($channel, "Your message was:\n```$args```");
}

1;
