package Bot::Goose;

use v5.10;
use strict;
use warnings;

use Data::Dumper;
use Mojo::Discord;
use Component::Database;
use Component::YouTube;
use Component::DarkSky;
use Component::Maps;
use Component::CAH;
use Component::UrbanDictionary;
use Component::Twitch;
use Mojo::IOLoop;

use Exporter qw(import);
our @EXPORT_OK = qw(add_command command get_patterns);

sub new
{
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;

    $self->{'commands'} = {};
    $self->{'patterns'} = {};

    $self->{'discord'} = Mojo::Discord->new(
        'token'     => $params{'discord'}->{'token'},
        'name'      => $params{'discord'}->{'name'},
        'url'       => $params{'discord'}->{'redirect_url'},
        'version'   => '1.0',
        'bot'       => $self,
        'callbacks' => {    # Discord Gateway Dispatch Event Types
            'READY'                 => sub { $self->discord_on_ready(shift) },
            'GUILD_CREATE'          => sub { $self->discord_on_guild_create(shift) },
            'GUILD_UPDATE'          => sub { $self->discord_on_guild_update(shift) },
            'GUILD_DELETE'          => sub { $self->discord_on_guild_delete(shift) },
            'CHANNEL_CREATE'        => sub { $self->discord_on_channel_create(shift) },
            'CHANNEL_UPDATE'        => sub { $self->discord_on_channel_update(shift) },
            'CHANNEL_DELETE'        => sub { $self->discord_on_channel_delete(shift) },
            'TYPING_START'          => sub { $self->discord_on_typing_start(shift) }, 
            'MESSAGE_CREATE'        => sub { $self->discord_on_message_create(shift) },
            'MESSAGE_UPDATE'        => sub { $self->discord_on_message_update(shift) },
            'PRESENCE_UPDATE'       => sub { $self->discord_on_presence_update(shift) },
            'WEBHOOKS_UPDATE'       => sub { $self->discord_on_webhooks_update(shift) },
            'GUILD_MEMBER_REMOVE'   => sub { $self->discord_on_user_changes(shift) },
            'GUILD_MEMBER_ADD'      => sub { $self->discord_on_user_changes(shift) },
        },
        'reconnect' => $params{'discord'}->{'auto_reconnect'},
        'verbose'   => $params{'discord'}->{'verbose'},
    );
    
    $self->{'owner_id'} = $params{'discord'}->{'owner_id'};
    $self->{'trigger'} = $params{'discord'}->{'trigger'};
    $self->{'playing'} = $params{'discord'}->{'playing'};
    $self->{'client_id'} = $params{'discord'}->{'client_id'};
    $self->{'webhook_name'} = $params{'discord'}->{'webhook_name'};
    $self->{'webhook_avatar'} = $params{'discord'}->{'webhook_avatar'};

    # Database
    $self->{'db'} = Component::Database->new(%{$params{'db'}});

    # YouTube API 
    $self->{'youtube'} = Component::YouTube->new(%{$params{'youtube'}}) if ( $params{'youtube'}->{'use_youtube'} );

    # DarkSky Weather API
    $self->{'darksky'} = Component::DarkSky->new(%{$params{'weather'}})  if ( $params{'weather'}->{'use_weather'} );

    # Google Maps API
    $self->{'maps'} = Component::Maps->new(%{$params{'maps'}}) if ( $params{'maps'}->{'use_maps'} );

    # LastFM
    $self->{'lastfm'} = Mojo::WebService::LastFM->new('api_key' => $params{'lastfm'}{'api_key'}) if ( $params{'lastfm'}{'use_lastfm'} );

    # CAH Cards
    $self->{'cah'} = Component::CAH->new('api_url' => $params{'cah'}{'api_url'}) if ( $params{'cah'}{'use_cah'} );

    # Urban Dictionary
    $self->{'urbandictionary'} = Component::UrbanDictionary->new(); # Needs nothing, so no need to check if it's configured.

    # Twitch
    # Needs an API Key (Client ID)
    $self->{'twitch'} = Component::Twitch->new('api_key' => $params{'twitch'}{'api_key'}) if ( $params{'twitch'}{'use_twitch'} );

    return $self;
}

# Connect to discord and start running.
sub start
{
    my $self = shift;

    $self->{'discord'}->init();
    
    # Start the IOLoop unless it is already running. 
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running; 
}


sub discord_on_ready
{
    my ($self, $hash) = @_;

    $self->add_me($hash->{'user'});
    
    #$self->{'discord'}->status_update({'game' => $self->{'playing'}});

    say localtime(time) . " Connected to Discord.";

    #say Dumper($hash);
}

sub discord_on_guild_create
{
    my ($self, $hash) = @_;

    say "Adding guild: " . $hash->{'id'} . " -> " . $hash->{'name'};

    $self->add_guild($hash);

    #say Dumper($hash);
}

sub discord_on_guild_update
{
    my ($self, $hash) = @_;

    # Probably just use add_guild here too.
}

sub discord_on_guild_delete
{
    my ($self, $hash) = @_;

    # Remove the guild
}

sub discord_on_channel_create
{
    my ($self, $hash) = @_;

    # Create the channel
}

sub discord_on_channel_update
{
    my ($self, $hash) = @_;

    # Probably just call the same as on_channel_create does
}

sub discord_on_channel_delete
{
    my ($self, $hash) = @_;

    # Remove the channel
}

# Whenever we get this we should request the webhooks for the channel.
# The only one we care about is the one we created.
sub discord_on_webhooks_update
{
    my ($self, $hash) = @_;

    my $channel = $hash->{'channel_id'};
    delete $self->{'webhooks'}{$channel};

    $self->cache_channel_webhooks($channel);
}

sub discord_on_typing_start
{
    my ($self, $hash) = @_;

    # Not sure if we'll ever do anything with this event, but it's here in case we do.
}

sub discord_on_message_create
{
    my ($self, $hash) = @_;

    my $author = $hash->{'author'};
    my $msg = $hash->{'content'};
    my $channel = $hash->{'channel_id'};
    my @mentions = @{$hash->{'mentions'}};
    my $trigger = $self->{'trigger'};
    my $discord_name = $self->name();
    my $discord_id = $self->id();

    #say Dumper($hash);

    foreach my $mention (@mentions)
    {
        $self->add_user($mention);
    }

    # Look for messages starting with a mention or a trigger, but not coming from a bot.
    if ( !(exists $author->{'bot'} and $author->{'bot'}) and $msg =~ /^(\<\@\!?$discord_id\>|\Q$trigger\E)/i )
    {
        $msg =~ s/^((\<\@\!?$discord_id\>.? ?)|(\Q$trigger\E))//i;   # Remove the username. Can I do this as part of the if statement?

        if ( defined $msg )
        {
            # KITTENS
            use File::Slurp;
            my $readFile = read_file("word_check.txt");
            if($msg =~ m/^$readFile$/i) {
                write_file("word_check.txt", "BIGBADSTUFFHOPEFULLYVERYUNIQUE<<>><><<>>");
                use MessageRequest;
                use GetIDKey;

                my @WH_Search = split(m/\|/, GetIDKeyFromC($channel));
                my $WH_ID = $WH_Search[0];
                my $WH_Key = $WH_Search[1];

                my $replyto = '<@' . $author->{'id'} . '>';

                MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : ":100: '.$replyto.' typed the fastest!\\n :heavy_plus_sign: :one: Kittens for you!"}', "1", "");
                my $personID = $author->{'id'};
                system("perl kitten_cmd.pl add $personID 1");
            }
            # Get all command patterns and iterate through them.
            # If you find a match, call the command fuction.
            foreach my $pattern ($self->get_patterns())
            {
                if ( $msg =~ /$pattern/i )
                {
                    my $command = $self->get_command_by_pattern($pattern);
                    my $access = $command->{'access'};
                    my $owner = $self->owner;

                    if ( defined $access and $access > 0 and defined $owner and $owner != $author->{'id'} )
                    {
                        # Sorry, no access to this command.
                        say localtime(time) . ": '" . $author->{'username'} . "' (" . $author->{'id'} . ") tried to use a restricted command and is not the bot owner.";
                    }
                    elsif ( ( defined $access and $access == 0 ) or ( defined $owner and $owner == $author->{'id'} ) )
                    {
                        my $object = $command->{'object'};
                        my $function = $command->{'function'};
                        $object->$function($channel, $author, $msg);
                    }
                }
            }
        }
    }
}

sub discord_on_message_update
{
    my ($self, $hash) = @_;

    # Might be worth checking how old the message is, and if it's recent enough re-process it for commands?
    # Would let people fix typos without having to send a new message to trigger the bot.
    # Have to track replied message IDs in that case so we don't reply twice.
}

sub discord_on_presence_update
{
    my ($self, $hash) = @_;

    # Will be useful for a !playing command to show the user's currently playing "game".
}

sub cache_channel_webhooks
{
    my ($self, $channel, $callback) = @_;
   
    $self->{'discord'}->get_channel_webhooks($channel, sub
    {
        my $json = shift;

        my $hookname = $self->webhook_name;

        foreach my $hook (@{$json})
        {
            if ( $hook->{'name'} eq $self->webhook_name )
            {
                $self->{'webhooks'}{$channel} = $hook;
            }
        }
    });
}

sub cache_guild_webhooks
{
    my ($self, $guild, $callback) = @_;

    my $id = $guild->{'id'};

    $self->{'discord'}->get_guild_webhooks($id, sub
    {
        my $json = shift;
        #say  Dumper($json);

        if ( ref $json eq ref {} and $json->{'code'} == 50013 )
        {
            # No Access.
            return;
        }

        my $hookname = $self->webhook_name;

        foreach my $hook (@{$json})
        {
            my $channel = $hook->{'channel_id'};
            if(defined($hook->{'name'}) && defined($self->webhook_name)) {
                if ( $hook->{'name'} eq $self->webhook_name )
                {
                    $self->{'webhooks'}{$channel} = $hook;
                }
            }
        }
    });
}

sub add_me
{
    my ($self, $user) = @_;
    say "Adding my ID as " . $user->{'id'};
    $self->{'id'} = $user->{'id'};
    $self->add_user($user);
}

sub id
{
    my $self = shift;

    return $self->{'id'};
}

sub name
{
    my $self = shift;
    return $self->{'users'}{$self->id}->{'username'}
}

sub discriminator
{
    my $self = shift;
    return $self->{'users'}{$self->id}->{'discriminator'};
}

sub client_id
{
    my $self = shift;
    return $self->{'client_id'};
}

sub my_user
{
    my $self = shift;
    my $id = $self->{'id'};
    return $self->{'users'}{$id};
}

sub add_user
{
    my ($self, $user) = @_;
    my $id = $user->{'id'};
    $self->{'users'}{$id} = $user;
}

sub get_user
{
    my ($self, $id) = @_;
    return $self->{'users'}{$id};
}

sub remove_user
{
    my ($self, $id) = @_;

    delete $self->{'users'}{$id};
}


# Tell the bot it has connected to a new guild.
sub add_guild
{
    my ($self, $guild) = @_;

    # Nice and simple. Just add what we're given.
    $self->{'guilds'}{$guild->{'id'}} = $guild;

    # Also, let's request the webhooks for this guild.
    $self->cache_guild_webhooks($guild);

    # Also add entries for channels in this guild.
    foreach my $channel (@{$guild->{'channels'}})
    {
        $self->{'channels'}{$channel->{'id'}} = $guild->{'id'};
    }
}

sub get_guild_by_channel
{
    my ($self, $channel) = @_;

    return $self->{'channels'}{$channel};
}

sub remove_guild
{
    my ($self, $id) = @_;

    delete $self->{'guilds'}{$id} if exists $self->{'guilds'}{$id};
}

# Return a single guild by ID
sub get_guild
{
    my ($self, $id) = @_;

    exists $self->{'guilds'}{$id} ? return $self->{'guilds'}{$id} : return undef;
}

# Return the list of guilds.
sub get_guilds
{
    my $self = shift;

    return keys %{$self->{'guilds'}};
}

sub get_patterns
{
    my $self = shift;
    return keys %{$self->{'patterns'}};
}

# Return a list of all commands
sub get_commands
{
    my $self = shift;

    my $cmds = {};
    
    foreach my $key (keys %{$self->{'commands'}})
    {
        $cmds->{$key} = $self->{'commands'}->{$key}{'description'};
    }

    return $cmds;
}

sub get_command_by_name
{
    my ($self, $name) = @_;

    return $self->{'commands'}{$name};
}

sub get_command_by_pattern
{
    my ($self, $pattern) = @_;

    return $self->get_command_by_name($self->{'patterns'}{$pattern});
}

# Return the bot's trigger prefix
sub trigger
{
    my $self = shift;
    return $self->{'trigger'};
}

# Command modules can use this function to register themselves with the bot.
# - Command
# - Access Level Required (Default 0 - public, 1 - Bot Owner)
# - Description
# - Usage
# - Pattern
# - Function
sub add_command
{
    my ($self, %params) = @_;

    my $command = lc $params{'command'};
    my $access = $params{'access'};
    my $description = $params{'description'};
    my $usage = $params{'usage'};
    my $pattern = $params{'pattern'};
    my $function = $params{'function'};
    my $object = $params{'object'};

    $self->{'commands'}->{$command}{'name'} = ucfirst $command;
    $self->{'commands'}->{$command}{'access'} = $access;
    $self->{'commands'}->{$command}{'usage'} = $usage;
    $self->{'commands'}->{$command}{'description'} = $description;
    $self->{'commands'}->{$command}{'pattern'} = $pattern;
    $self->{'commands'}->{$command}{'function'} = $function;
    $self->{'commands'}->{$command}{'object'} = $object;

    $self->{'patterns'}->{$pattern} = $command;

    say localtime(time) . " Registered new command: '$command' identified by '$pattern'";
}

# This sub calls any of the registered commands and passes along the args
# Returns 1 on success or 0 on failure (if command does not exist)
sub command
{
    my ($self, $command, $args) = @_;

    $command = lc $command;

    if ( exists $self->{'commands'}{$command} )
    {
        $self->{'commands'}{$command}{'function'}->($args);
        return 1;
    }
    return 0;
}

# Returns the owner ID for the bot
sub owner
{
    my $self = shift;
    return $self->{'owner_id'};
}

# Return the webhook name the bot will use
sub webhook_name
{
    my $self = shift;
    return $self->{'webhook_name'};
}

sub webhook_avatar
{
    my $self = shift;
    return $self->{'webhook_avatar'};
}

# Check if a webhook already exists - return it if so.
# If not, create one and add it to the webhooks hashref.
# Is non-blocking if callback is defined.
sub create_webhook
{
    my ($self, $channel, $callback) = @_;

    return $_ if ( $self->has_webhook($channel) );

    # Create a new webhook
    my $discord = $self->discord;

    my $params = {
        'name' => $self->webhook_name, 
        'avatar' => $self->webhook_avatar 
    };

    if ( defined $callback )
    {
        $discord->create_webhook($channel, $params, sub
        {
            my $json = shift;

            if ( defined $json->{'name'} ) # Success
            {
                $callback->($json);
            }
            elsif ( $json->{'code'} == 50013 ) # No permission
            {
                say localtime(time) . ": Unable to create webhook in $channel - Need Manage Webhooks permission";
                $callback->(undef);
            }
            else
            {
                say localtime(time) . ": Unable to create webhook in $channel - Unknown reason";
                $callback-(undef);
            }
        });
    }
    else
    {
        my $json = $discord->create_webhook($channel); # Blocking

        return defined $json->{'name'} ? $json : undef;
    }
}

sub add_webhook
{
    my ($self, $channel, $json) = @_;

    $self->{'webhooks'}{$channel} = $json;
    return $self->{'webhooks'}{$channel};
}

# This retrieves a cached webhook object for the specified channel.
# If there isn't one, return undef and let the caller go make one or request an existing one from Discord.
sub has_webhook
{
    my ($self, $channel) = @_;

    if ( exists $self->{'webhooks'}{$channel} )
    {
        return $self->{'webhooks'}{$channel};
    }
    else
    {
        return undef;
    }
}

# Returns the discord object associated to this bot.
sub discord
{
    my $self = shift;
    return $self->{'discord'};
}

# returns the DB object associated to this bot
sub db
{
    my $self = shift;
    return $self->{'db'};
}

sub youtube
{
    my $self = shift;
    return $self->{'youtube'};
}

sub darksky
{
    my $self = shift;
    return $self->{'darksky'};
}

sub maps
{
    my $self = shift;
    return $self->{'maps'};
}

sub lastfm
{
    my $self = shift;
    return $self->{'lastfm'};
}

sub cah
{
    my $self = shift;
    return $self->{'cah'};
}

sub urbandictionary
{
    my $self = shift;
    return $self->{'urbandictionary'};
}

sub twitch
{
    my $self = shift;
    return $self->{'twitch'};
}

sub discord_on_user_changes {
    my $self = shift;

    # use MessageRequest;
    # use GetIDKey;

    # my @WH_Search = split(m/\|/, GetIDKeyFromC("451188550889766912"));
    # my $WH_ID = $WH_Search[0];
    # my $WH_Key = $WH_Search[1];

    # use Data::Dumper;
    # use File::Slurp;

    # my $response_hash = MakeDiscordGet("/guilds/199730784393756672/members?limit=1000", '', "1", "");

    # my @people;
    # for(my $i = 0; $i < scalar(@{$response_hash}); $i++) {
    # 	my $userID = $response_hash->[$i]{user}{id};
    # 	push(@people, $userID);
    # }

    # my @oldPeople = split(m/\n/, read_file("server_list.txt"));
    # my $outlier = "1234";
    # if (scalar(@oldPeople) > scalar(@people)) {
    # 	foreach my $oldPerson (@oldPeople) {
    # 		if ($oldPerson ~~ @people) {

    # 		}
    # 		else {
    # 			$outlier = $oldPerson;
    # 			last;
    # 		}
    # 	}
    # 	MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", '{"content" : "<@'.$outlier.'> Has left the server"}', "1", "", "");
    # }
    # else {
    # 	my $count;
    #     foreach my $newPerson (@people) {
    # 		if ($newPerson ~~ @oldPeople) {

    # 		}
    # 		else {
    # 			$outlier = $newPerson;
    # 			last;
    # 		}
    # 	}

	   #  my @WH_Search = split(m/\|/, GetIDKeyFromC("451188550889766912"));
	   #  my $WH_ID = $WH_Search[0];
	   #  my $WH_Key = $WH_Search[1];
    #     use MIME::Base64;

    #     my $mess = '{"content": "<@'.$outlier.'>", "embeds": [{"author": {"icon_url": "https://static-cdn.jtvnw.net/emoticons/v1/30259/3.0", "name": "Welcome to ConFed Gaming!"}, "type": "rich", "color": 16726015, "description": "**If you would like to join the clan shoot one of the Admins/Officers a message! Otherwise enjoy your stay. *Salutes!***", "image": {"url": "https://cdn.discordapp.com/attachments/174592353619804161/257696748900843521/Untitled-1.png", "height": 100, "width": 600}}]}';
    #     $mess = encode_base64($mess, "");
    #     #say $mess;
    # 	MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", "$mess", "1", "", "", "base64");

    #      @WH_Search = split(m/\|/, GetIDKeyFromC("451188550889766912"));
    #      $WH_ID = $WH_Search[0];
    #      $WH_Key = $WH_Search[1];

    #      $mess = '{"content": "<@'.$outlier.'>", "embeds": [{"author": {"icon_url": "https://static-cdn.jtvnw.net/emoticons/v1/30259/3.0", "name": "Welcome to ConFed Gaming!"}, "type": "rich", "color": 16726015, "description": "**If you would like to join the clan shoot one of the Admins/Officers a message! Otherwise enjoy your stay. *Salutes!***", "image": {"url": "https://cdn.discordapp.com/attachments/174592353619804161/257696748900843521/Untitled-1.png", "height": 100, "width": 600}}]}';
    #     $mess = encode_base64($mess, "");
    #     #say $mess;
    #     MakeDiscordPostJson("/webhooks/$WH_ID/$WH_Key", "$mess", "1", "", "", "base64");
    # }

    # write_file("server_list.txt", "");
    # foreach my $person (@people) {
    # 	append_file("server_list.txt", $person."\n");
    # }
}

1;
