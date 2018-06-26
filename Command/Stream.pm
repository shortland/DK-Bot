package Command::Stream;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_stream);

use Mojo::Discord;
use Bot::Goose;

use ApiKeys;
use File::Slurp;
use JSON;

###########################################################################################
# Command Info
my $command = "Stream";
my $access = 0; # Public
my $description = "This is a stream command for building new actual commands";
my $pattern = '^(~stream)\s?([a-zA-Z0-9#]+)?\s?([a-zA-Z0-9]+)?';
my $function = \&cmd_stream;
my $usage = <<EOF;
Basic usage: !stream
Advanced usage: !stream
Other usage: !stream
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

sub cmd_stream
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    # Send a message back to the channel
    my $newMess = $msg;
    $newMess =~ s/~stream //g;
    my $type = lc($newMess);
    
    my $streamers;
    if($type =~ /^all$/) {
        
        $streamers = read_file("streamers.txt");
        my $cleanList;
        foreach (split(m/\n/, $streamers)) {
        	$_ =~ m/(\|\d+)/g;
        	$_ =~ s/$1//g;
        	$_ =~ s/\|//g;
        	$cleanList .= $_ . "\n";
        }

        $discord->send_message($channel, "Streams I check:\n" . $cleanList);
    }
    elsif($type =~ /^live$/) {
        $streamers = read_file("currentLive.txt");

        # my @streams = split(/\n/, $streamers);
        # @streams = reverse(@streams);
        # $streamers = join("\n", @streams);

        my $cleanList;
        foreach (split(m/\n/, $streamers)) {
        	$_ =~ m/(\|\d+)/g;
        	$_ =~ s/$1//g;
        	$_ =~ s/\|//g;
        	$cleanList .= $_ . "\n";
        }

        $discord->send_message($channel, "Currently online streams:\n" . $cleanList);
    }
    elsif($type =~ /^alloff$/) {
        write_file("currentLive.txt", "");

        $discord->send_message($channel, "Cleared online list");
    }
    else {
        my @new = split(" ", $type);
        if ($new[0] =~ /^add$/) {
            $streamers = read_file("streamers.txt");
            my @streamList = split(/\|?\d*\n/, $streamers);
            my $tempVar = $new[1];

            my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/users?login=$tempVar`;
            my $decoded = decode_json($res);
            my $userID = $decoded->{'users'}[0]{'_id'};

            if (!defined $userID || $userID eq "") {
                $discord->send_message($channel, "That user doesn't exist. Are you sure you typed it in right?");
                return;
            }

            if($tempVar ~~ @streamList) {
                $discord->send_message($channel, "That person is already on the list I check.\nUse: **~stream all**\nTo view the list I check.");
                return;
            }
            elsif ($tempVar =~ m/twitch\.tv/i) {
                $discord->send_message($channel, "Just use the persons twitch username, not the whole twitch link.");
                return;
            }
            else {
                append_file("streamers.txt", "$new[1]|$userID\n");
                $discord->send_message($channel, "Added " . $new[1] . " (". $userID .") to the stream list.");
                return;
            }
        }
        elsif ($new[0] =~ /^remove$/) {
            $streamers = read_file("streamers.txt");
            my @fullStreams = split(/\n/, $streamers); # someone|12312
            #my @streams = split(/\|?\d*\n/, $streamers);

            my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/users?login=$new[1]`;
            my $decoded = decode_json($res);
            my $userID = $decoded->{'users'}[0]{'_id'};


            my $full_user_data = $new[1] . "|" . $userID;
            if ($full_user_data ~~ @fullStreams) {

                my $index = 0;
                $index++ until $fullStreams[$index] eq $full_user_data;
                splice(@fullStreams, $index, 1);

                my $flattened = join("\n", @fullStreams);
                write_file("streamers.txt", $flattened."\n");

                $discord->send_message($channel, "Removed " . $full_user_data . " from the stream list.");
                return;
            }
            else {
                $discord->send_message($channel, "Unable to find " . $new[1] . " in the stream list.");
                return;
            }
        }
        elsif ($new[0] =~ /^format$/) {
            my $flattenedFormat = read_file("streamers.txt");
            $flattenedFormat = join(",", split(/\n/, $flattenedFormat));
            $discord->send_message($channel, $flattenedFormat);
        }
        else {
            $discord->send_message($channel, "Sorry I was unable to understand that command.\nTry:\n~stream all\n~stream live\n~stream add TwitchName");
        }
    }
}

1;
