package Command::Social;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_Social);

use Mojo::Discord;
use Bot::Goose;
use DBI;

use utf8;
use Encode;
use MIME::Base64;
binmode(STDOUT, ':utf8');

use MessageRequest;
use GetIDKey;

###########################################################################################
# Command Info
my $command = "social";
my $access = 0; # Public
my $description = "Bind someones Battle Tag to a Discord Tag";
my $pattern = '^(~social)\s?([a-zA-Z0-9#]+)?\s?([a-zA-Z0-9#]+)?';
my $function = \&cmd_social;
my $usage = <<EOF;
~social <battle tag> <discord tag>

ie:

~social shortland#1803 shortland#3839
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

sub cmd_social
{
    my ($self, $channel, $author, $msg) = @_;

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    my $msg_parsed = $msg;
    $msg_parsed =~ s/~social //g;
    $msg_parsed =~ m/^(\w+) /;

    # web hook identifying
    my $WH_ID;
    my $WH_Key;
    my @WH_Search = split(m/\|/, GetIDKeyFromC($channel));
    $WH_ID = $WH_Search[0];
    $WH_Key = $WH_Search[1];

    my $battle_tag;
    my $discord_tag;
    my $unknown_tag;
    my $cmd_type;
    if ($1 eq "set") {
        $msg_parsed =~ m/^set (\w+#\d+) (\w+#\d+)/;
        $battle_tag = $1; 
        $discord_tag = $2;
        if (index($battle_tag, "#") eq -1 || index($discord_tag, "#") eq -1) { 
            MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "Please include both the Battle Tag and Discord Tags. Blizzard/Battle Tag and Discord Tag must both be in the format: username#1234\\n i.e: ~social set <battle tag> <discord tag>"}', "1", "");
            return;
        }
        else {
        	print my $linkres = `perl social_linker.pl set $battle_tag $discord_tag`;
        	MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "'.$linkres.'"}', "1", "");
        }
    }
    elsif ($1 eq "get") {
        $msg_parsed =~ m/^get (\w+#\d+)/;
        $unknown_tag = $1;
        if (index($unknown_tag, "#") eq -1) { 
            MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "Please include either the Battle Tag or Discord Tag. Battle Tag and/or Discord Tag must be in the format: username#1234\\n i.e: ~social get shortland#1234"}', "1", "");
            return;
        }
        else {
            print my $linkres = `perl social_linker.pl get $unknown_tag`;
            MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "'.$linkres.'"}', "1", "");
        }
    }
    else {
        MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "Currently only ~social set <battle tag> <discord tag>\\nand\\n~social get <discord/battle tag>are available commands"}', "1", "");
        return;
    }
}




1;
