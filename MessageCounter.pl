#!/usr/bin/perl -w

use JSON;
use File::Slurp;
use Data::Dumper;

my $DATABASE = "message_counter.json";

my $personID = "131231443694125056";
my $msgAmount = 21;

# 1.)
	# method that remakes database.json
	# gets all channels and counts all user messages from every channel.
	# this would obviously take awhile so don't use unless needed for whatever reason

# 2.) sub userExists()
	# return boolen 0,1
	# method that checks if a userid exists in db.json

# 3.) sub makeUser()
	# create user id in db. set message count to 0

# 4.) 
	# ++count to user

print "initializing\n";

if(userExists($personID)) {
	print "he exists!\n";
}
else {
	makeUser($personID, $msgAmount);
}

sub userExists {
	my ($userID) = @_;
	my $exists = 0;
	for my $person (peopleList()) {
		if ($userID =~ /^$person->{idn}$/) {
			$exists = 1;
			last;
		}
	}
	return $exists;
}

sub pushToArray {
	my (@array, $value) = @_;
	my @newArray;
	my $c;
	for my $value (@array) {
		print $value;
		$newArray[$c++] = $value;
	}
	$newArray[$c] = $value;
	print $newArray[0] . "here is supposed to be 000";
	return @newArray;
}

sub makeUser {
	my ($userID, $amount) = @_;
	my $data = decode_json(''.read_file($DATABASE));

	my @newArray = @{pushToArray(@{peopleList()}, ("{'idn' : '$userID', 'count' : 0}"))};
	#
	print "test";
	print $newArray[0]->{idn};
	#$data->{users} = 
	
	setUserAmount($userID, $amount);
}

sub setUserAmount {
	my ($userID, $amount) = @_;

}

sub setLastUpdate {
	#
}

sub peopleList {
	my $data = read_file($DATABASE);
	my $decoded = decode_json($data);
	my @people = @{$decoded->{users}};
	return @people;
}