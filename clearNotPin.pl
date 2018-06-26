#!/usr/bin/perl -

use v5.10;
use utf8;
use open ':std', ':encoding(UTF-8)';
binmode(FILE, ':utf8');

use JSON;
use File::Slurp;
use ApiKeys;
use MessageRequest;

my $channel = $ARGV[0];
if (!defined $channel || $channel eq "") {
    die "no defined channel ID\n";
}
my $args = GetLastMessage(MakeDiscordGet("/channels/$channel/messages", "", "1"));
my $pins = GetPinsIDs(MakeDiscordGet("/channels/$channel/pins", "", "1"));
say $args;
say "pins are " . $pins;

my $pinned = read_file("$pins");
my @pinnedMessages = split(/\,/, $pinned);
say $pinnedMessages[0];

my $read_messages = read_file("$args");
my @messages = split(/\,/, $read_messages);

for my $messageID (@messages) {
    recursiveDelete($messageID);
}

sub recursiveDelete {
    my ($thing) = @_;
    $thing =~ s/ //g;
    if ($thing ~~ @pinnedMessages) {
        say "Not deleting $thing cause it's a pinned message";
    }
    elsif ((" ".$thing) ~~ @pinnedMessages) {
        say "jesus not real";
    }
    elsif (($thing . " ") ~~ @pinnedMessages) {
        say "sometimes he aint real";
    }
    else {
        MakeDiscordPostJson("/channels/$channel/messages/$thing", '', '0', "DELETE", "0.1");
        say $thing . " deleted.";
    }
}

sub GetPinsIDs {
    my ($encodedPins) = @_;
    my @chars = ("A".."Z", "a".."z", "0".."9");
    my $fileName;
    $fileName .= $chars[rand @chars] for 1..16;
    write_file("static/${fileName}.log.txt", "");
    foreach my $jsonMessage (@{$encodedPins}) {
        if (@{$arrayJsonData}[-1] == $jsonMessage) {
            $lastMessage = $jsonMessage->{id};
        }
        (my $context = $jsonMessage->{content}) =~ s/\n/\\n/g;;

        append_file_utf8("static/${fileName}.log.txt", $jsonMessage->{id}.", ");
    }
    return "static/".$fileName.".log.txt";
}

sub GetLastMessage {
    my ($arrayJsonData, $messageCalled, $fileName) = @_;
    my @chars = ("A".."Z", "a".."z", "0".."9");
    my $string = $fileName;
    if (!defined $messageCalled) {
        $string = "";
        $string .= $chars[rand @chars] for 1..16;

        write_file("static/${string}.log.txt", "");
    }
    if (!defined $arrayJsonData) {
        say "That call didn't have data... meaning there are no messages prior to that one.\n";
        exit;
    }
    my $lastMessage;
    foreach my $jsonMessage (@{$arrayJsonData}) {
        if (!defined $messageCalled) {
            $messageCalled = "not undef";
            say "Set Channel ID";
        }
        if (@{$arrayJsonData}[-1] == $jsonMessage) {
            $lastMessage = $jsonMessage->{id};
        }
        (my $context = $jsonMessage->{content}) =~ s/\n/\\n/g;;

        append_file_utf8("static/${string}.log.txt", $jsonMessage->{id}.", ");
    }
    if (!defined $lastMessage) {
        say "No more messages: " . $messageCalled;
        my $wholeData = read_file("static/".$string.".log.txt");
        $wholeData = substr($wholeData, 0, -2);
        write_file("static/".$string.".log.txt", $wholeData);
        return "static/" . $string . ".log.txt";
    }
    else {
        say "Doing recusive ($lastMessage)";
        GetLastMessage(MakeDiscordGet("/channels/$channel/messages?before=$lastMessage", "", "1"), $lastMessage, $string);
    }
}

sub append_file_utf8 {
    my ($name, $data) = @_;
    open my $fh, '>>:encoding(UTF-8)', $name
        or die "Couldn't create '$name': $!";
    local $/;
    print $fh $data;
    close $fh;
};