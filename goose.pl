#!/usr/bin/env perl

use v5.10;
use utf8;
use strict;
use warnings;

use File::Slurp;
use MessageRequest;

binmode STDOUT, ":utf8";

use Config::Tiny;
use Bot::Goose;

# Load in the bot command modules
use Command::Shrug;
use Command::Roster;
use Command::Ping;
use Command::Help;
use Command::Player;
use Command::Clan;
use Command::Bnet;
use Command::Bounds;
use Command::CTL;
use Command::Social;

# Fallback to "config.ini" if the user does not pass in a config file.
my $config_file 	= $ARGV[0] // 'config.ini';
my $config 			= Config::Tiny->read($config_file, 'utf8');
say localtime(time) . " Loaded Config: $config_file";

# For miscellaneous information about this bot such as discord id
my $self = {};

# Initialize the bot
my $bot = Bot::Goose->new(%{$config});

# Register the commands
Command::Shrug->new			('bot' => $bot);
Command::Roster->new		('bot' => $bot);
Command::Ping->new			('bot' => $bot);
Command::Help->new			('bot' => $bot);
Command::Player->new		('bot' => $bot);
Command::Clan->new			('bot' => $bot);
Command::Bnet->new			('bot' => $bot);
Command::Bounds->new		('bot' => $bot);
Command::CTL->new			('bot' => $bot);
Command::Social->new		('bot' => $bot);

# Initialize webhooks
GetAndMakeHooks(MyBotName(), MyServers());

sub MyBotName {
	return MakeDiscordGet('/users/@me', "", "1")->{'username'};
}

sub MyServers {
	return MakeDiscordGet('/users/@me/guilds', "", "1");
}

sub LogMsg {
	my ($q) = @_;
	say localtime(time) . " " . $q;
}

sub GetAndMakeHooks {
	my @parms = @_;
	# $parms[0] = bot name
	# $parms[1] = array of servers bot is in

	LogMsg("Processing webhooks");
	LogMsg("This takes awhile... (not optimized to use previously created webhooks... deletes & remakes them which makes this process slow)");
	
	# Contains list of channels the bot handles
	write_file("buffers/channel_buffer.txt", "");

	# Contains list of webhooks the bot handles (renewed on reboot)
	write_file("buffers/webhook_buffer.txt", "");

	# Loop through servers that the bot is in
	for (my $i = 0; $i < scalar(@{$parms[1]}); $i++) {

		# List of webhooks for the server
		my $webhookList = MakeDiscordGet("/guilds/" . $parms[1]->[$i]{'id'} . "/webhooks", "", "1");
		
		LogMsg("Found " . scalar(@{$webhookList}) . " old webhooks to delete. (bot removes previously created webhooks because its not smart enough to use them...)");
		
		# Delete any pre-existing webhooks,... It's quicker than having to check if exists for x channel then remake
		# This definitely needs to be changed to use previously created webhooks. I was in a rush when originally creating this section
		# Loops through and deletes every individual webhook with this bots "name" (created by this bot)
		for (my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if ($webhookList->[$j]{'name'} eq $parms[0]) {
				LogMsg("Deleted Web Hook ID: " . $webhookList->[$j]{'id'});
				MakeDiscordPostJson("/webhooks/" . $webhookList->[$j]{'id'}, "", "1", "DELETE");
			}
		}

		# JSON Array of all the Channels the bot can access (including voice)
		my $channelList = MakeDiscordGet("/guilds/$parms[1]->[$i]{'id'}/channels", "", "1");
		
		# Profile Picture of bot to create the webhook with.
		my $picture = read_file("static/picture");

		# Loop through channel list and create webhooks for text channels
		for (my $j = 0; $j < scalar(@{$channelList}); $j++) {
			if ($channelList->[$j]{'type'} eq 0) {
				LogMsg("Creating webhook for " . $channelList->[$j]->{name});
				append_file("buffers/channel_buffer.txt", $channelList->[$j]{'id'} . "|");
				MakeDiscordPostJson("/channels/" . $channelList->[$j]{'id'} . "/webhooks", '{"name":"' . $parms[0] . '", "avatar" : "' . $picture . '"}', "1");
			}
		}

		# List of webhooks for the server (new list)
		$webhookList = MakeDiscordGet("/guilds/" . $parms[1]->[$i]{'id'} . "/webhooks", "", "1");
		
		# Loop through the new list and append it to the buffer
		for (my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if ($webhookList->[$j]{'name'} eq $parms[0]) {
				LogMsg("Wrote webhook for channel " . $webhookList->[$j]{'channel_id'} . " to buffer file");
				append_file("buffers/webhook_buffer.txt", ($webhookList->[$j]{'channel_id'} . "|" . $webhookList->[$j]{'id'} . "|" . $webhookList->[$j]{'token'} . "\n"));
			}
		}
	}

	LogMsg("Finished processing webhooks");
}

# Start the bot
$bot->start();
