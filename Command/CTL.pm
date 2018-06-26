package Command::CTL;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_CTL);

use Mojo::Discord;
use Bot::Goose;
use Mojo::JSON qw(decode_json);
use Data::Dumper;
use JSON;
use File::Slurp;
###########################################################################################
# Command Info
my $command = "CTL";
my $access = 0; # Restricted to Owner
my $description = "Make the bot CTL something";
my $pattern = '^(~CTL|~ctl|~Ctl)(\s)?';
my $function = \&cmd_CTL;
my $usage = <<EOF;
Usage: !CTL something
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

sub cmd_CTL
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    say "sending";
    $args = '{"content": "", "embed": { "title": "Chobo Team League (CTL)", "type": "rich", "description": "Chobo Team League (CTL) is a Proleague format Clanwar league for players Gold-Masters. Players will play a single match (except the Masters player plays a best-of 3)", "url": "http://choboteamleague.com", "color": 16776960, "thumbnail": { "url": "https://static-cdn.jtvnw.net/jtv_user_pictures/choboteamleague-profile_image-e2c34336395c1627-300x300.png", "height": 150, "width": 150 },"fields": [ { "name": "CTL Website", "value" :"[ChoboTeamLeague.com](http://choboteamleague.com)", "inline":1 }, { "name": "Video Guide", "value": "[https://www.twitch.tv/videos/143977542](https://www.twitch.tv/videos/143977542)", "inline":1 }, {"name" : "About", "value":"Players themselves schedule their matches in the week, so there is no need to worry about coming to a set time and date. When scheduling players must state their availability and timezone surely (no ifs or maybes) The due date for contacting is Wednesday at 8 pm PST and the deadline for playing your assigned match is Sunday at 8 pm PST.", "inline": 0}, {"name" : "Replay Submission", "value" : "When you have played your match/es. The winner must submit the replay over to the correct CTL Google-Drive folder. Replays must be renamed according as follows:\n Week# Set# Map Name(player1 vs player2)", "inline" : 0}, {"name" : "How do I know I play?", "value" : "Each week our captain HoneyBadger will select who\'ll play for the week. He\'ll message you on Discord. Also, let him know if you\'d like to participate.", "inline" : 0} ] } }';
    my $json = decode_json($args);
    $discord->send_message($channel, $json);
    say "sent";
    # eval 
    # {
    #     my $json = decode_json($args);
    #     $discord->send_message($channel, $json);
    # };
    # if ($@)
    # { 
    #     # Send as plaintext instead.
    #     $discord->send_message($channel, $args);
    # }
}

1;