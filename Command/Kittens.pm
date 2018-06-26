package Command::Kittens;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_kittens);

use Mojo::Discord;
use Bot::Goose;

use File::Slurp;

###########################################################################################
# Command Info
my $command = "kittens";
my $access = 0; # Public
my $description = "This is a kittens command for building new actual commands";
my $pattern = '^(~kittens)\s?([a-zA-Z]+)?\s?';
my $function = \&cmd_kittens;
my $usage = <<EOF;
Basic usage: ~kittens
Advanced usage: ~kittens
Other usage: ~kittens
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

sub cmd_kittens
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    # Send a message back to the channel
    my $all_kittens = read_file("files/kittens.txt");
    my $myID = $author->{'id'};
    my $minimum = 1;
    my $maximum = 17 + 1; # + 1 to make it inclusive of 17
    my $r = $minimum + int(rand($maximum - $minimum));
    if ($args =~ /^(| )$/) {
        if ($all_kittens =~ m/^$myID\|(\d+)/) {
            my $sad = ":kissing_cat:"; 
            $sad = ":crying_cat_face:" if ($1 =~ /^0$/);
            $discord->send_message($channel, "You have $1 kittens " . $sad);
            # author exists so we just need to get thier kittens
        }
        else {
            append_file("files/kittens.txt", $myID."|"."0\n");
            $discord->send_message($channel, "You have 0 kittens :crying_cat_face:");
        }
    }
    elsif ($args =~ /^pic$/) {
        $discord->send_message($channel, "http://138.197.50.244/GOOSE/files/kittens/" . $r . ".jpg");
    }
    # elsif ($args =~ /^all$/) {
    #     use MessageRequest;
    #     my $datum = $all_kittens;

    #     foreach (split(/\n/, $datum)) {
    #         my $line = $_;
    #         #say $line. "I thinks\n";

    #         $line =~ m/^(\d+)\|(\d+)/;
    #         $discord->send_message($channel, "Viewing everyones kittens takes a few seconds...");
    #         my $name = MakeDiscordGet("/users/$1", "", "1", "1")->{'username'};
    #         say $name . " got this from $1";
    #         $datum =~ s/$1/$name/g;
    #     }

    #     $discord->send_message($channel, "$datum");
    # }

}

1;