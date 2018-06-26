package Command::Bounds;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_Bounds);

our @PUBLIC_league = ("BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND", "MASTER", "GRANDMASTER");
our @PUBLIC_emojies = ("<:BRONZE3:278725418641522688>", "<:SILVER2:278725418813751297>", "<:GOLD1:278725419073536012>", "<:PLATINUM1:278725419056758784>", "<:DIAMOND1:278725418960551937>", "<:MASTER1:278725418679271425>", "<:GRANDMASTER:278725419186782208>");

use Mojo::Discord;
use Bot::Goose;

use File::Slurp;

use MessageRequest;
use GetIDKey;

###########################################################################################
# Command Info
my $command = "bounds";
my $access = 0; # Public
my $description = "This is a bounds command for building new actual commands";
my $pattern = '^(~bounds)\s?([a-zA-Z]+)?\s?';
my $function = \&cmd_bounds;
my $usage = <<EOF;
Basic usage: ~bounds
Advanced usage: ~bounds
Other usage: ~bounds
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

sub cmd_bounds
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    my $server = "us";
    if ($args =~ /^(eu|kr)$/i) {
        $server = $args;
    }

    my $WH_ID;
    my $WH_Key;

    my @WH_Search = split(m/\|/, GetIDKeyFromC($channel));
    $WH_ID = $WH_Search[0];
    $WH_Key = $WH_Search[1];

    my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
    my $sth = $dbh->prepare("SELECT * FROM `bounds` WHERE server = '".$server."' order by `league` desc, `tier` asc");
    $sth->execute();
    my $text;
    while (my $row = $sth->fetchrow_hashref()) {
        my $league = $PUBLIC_emojies[$row->{league}];    
        $text .= $league . " [" . $row->{tier} . "]   " . $row->{ranges} . "\\n"
    }

    MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "'.$text.'"}', "1", "", 0.2);

    # # Send a message back to the channel
    # $discord->send_message($channel, "server: $server");

    # my $bounds = read_file("bounds_" . $server . ".txt");

    # $discord->send_message($channel, "Server MMR bounds:\n$bounds");
}


1;
