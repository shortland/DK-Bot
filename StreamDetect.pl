#!/usr/bin/perl

use File::Slurp;
use JSON;

use ApiKeys;
use MessageRequest;
use GetIDKey;

# Getting any missing IDs of players
my $streamListed = read_file("streamers.txt");
SeeAndSetIDs($streamListed);

# set as live/not-live
$streamListed = read_file("streamers.txt");
StreamTesting($streamListed);

sub StreamTesting {
	my ($allStreamers) = @_;

	my $joinedPeople;
	foreach (split("\n", $allStreamers)) {
		$_ =~ m/^[\w]*\|(\w*)/g;
		if($1 ne "") {
			$joinedPeople .= $1 . ",";
		}
	}
	$joinedPeople =~ s/,$//;

	GetGamePlaying($joinedPeople);
}

sub SeeAndSetIDs {
	my ($streamList) = @_;

	my @lines = split(/\n/, $streamList);
	my @newList;
	foreach (@lines) {
		$_ =~ m/([\w\d]+)\|?([\w\d]+)?/g;
		if (!defined($2)) {
			print "Getting stream ID of $_\n";
			$_ =~ s/\|//g;
			push(@newList, ($_ . "|" . GetUserID($_)));
		}
		else {
			push(@newList, $_);
		}
	}
	
	my $newStreamList = join("\n", @newList);
	write_file("streamers.txt", $newStreamList."\n"); #remember has empty line at end
}

sub GetUserID {
	my ($username) = @_;

	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/users?login=$username`;
	my $decoded = decode_json($res);
	my $userID = $decoded->{'users'}[0]{'_id'};
	return $userID;
}

sub GetGamePlaying {
	my ($userID) = @_;

	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/streams/?channel=$userID`; 
	$res =~ s/null/"null"/g;

	my $decoded = decode_json($res);
	$decoded = $decoded->{'streams'};

	my $previouslyOnline = read_file("currentLive.txt");
    write_file("currentLive.txt", "");
    my @previousOnList = split("\n", $previouslyOnline);

	for my $stream (@$decoded) {
		#print encode_json $stream;
    	my $streamerData = $stream->{'channel'}{'name'} . "|" . $stream->{'channel'}{'_id'};
    	
    	if ($streamerData ~~ @previousOnList) {
    		append_file("currentLive.txt", $streamerData . "\n");
    	}
    	else {
    		print my $streamName = $stream->{'channel'}{'display_name'};
    		print my $streamURL = $stream->{'channel'}{'url'};
    		print my $streamGame = $stream->{'game'};
    		print my $streamStatus = $stream->{'channel'}{'status'};
    		print my $streamLogo = $stream->{'channel'}{'logo'}; 
    		if ($streamLogo !~ /(http)/) { 
    			$streamLogo = "https://i.ytimg.com/vi/pv1O41akdeI/maxresdefault.jpg"; 
    		}
    		print my $streamFollowers = $stream->{'channel'}{'followers'};

			$STREAM_POST = '{"embeds":[{"title":"'.$streamName.'","type":"rich","description":"'.$streamStatus.'","url":"'.$streamURL.'","color":10175220,"thumbnail":{"url":"'.$streamLogo.'","height":100,"width":100},"fields":[{"name":"Game","value":"'.$streamGame.'","inline":1},{"name":"Followers","value":"'.$streamFollowers.'","inline":1}]}]}';

    		append_file("currentLive.txt", $streamerData . "\n");

    		my $bufferIDKey = GetIDKeyFromC('279305780338098176');
    		my @words = split(m/\|/, $bufferIDKey);
    		#print "res:". encode_json MakeDiscordPostJson("/webhooks/$words[0]/$words[1]", "".$STREAM_POST."", "1", "", "2");

			my $response = `curl -s --max-time 5 -X POST -d '$STREAM_POST' -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/json" -H "Authorization: Bot $API_DISCORD" "https://discordapp.com/api/webhooks/$words[0]/$words[1]" -L`;

			print $response;
			sleep(2);
    	}
	}
}