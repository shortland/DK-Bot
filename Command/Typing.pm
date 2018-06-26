package Command::Typing;

use v5.10;
use strict;
use warnings;

use MIME::Base64;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_typing);

use Mojo::Discord;
use Bot::Goose;

use File::Slurp;

###########################################################################################
# Command Info
my $command = "typing";
my $access = 0; # Public
my $description = "This is a typing command for building new actual commands";
my $pattern = '^(~typing)';
my $function = \&cmd_typing;
my $usage = <<EOF;
Basic usage: ~typing
Advanced usage: ~typing
Other usage: ~typing
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

sub cmd_typing
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    #$args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    # Send a message back to the channel
    my $myID = $author->{'id'};

    my $word = `curl -s "http://www.setgetgo.com/randomword/get.php"`;
    system(`perl text2img.pl $word`);

    #http://138.197.50.244/GOOSE/files/pics/
    my $newName = encode_base64($word);
    $newName =~ s/[=| |\n]//g;
    write_file("word_check.txt", $word);
    $discord->send_message($channel, "http://138.197.50.244/GOOSE/files/pics/" . ($newName) . ".png");
}

1;