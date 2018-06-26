#!/usr/bin/perl

use File::Slurp;

# command 
my $cmd = $ARGV[0];
# user
my $myID = $ARGV[1];
# amount
my $amt = $ARGV[2];

my $all_kittens = read_file("files/kittens.txt");

if ($cmd =~ /^(add)$/) {
    if ($all_kittens =~ m/^$myID\|(\d+)/) {
        # my $sad = ":kissing_cat:"; 
        # $sad = ":crying_cat_face:" if ($1 =~ /^0$/);
        # $discord->send_message($channel, "You have $1 kittens " . $sad);
        # author exists so we just need to get thier kittens
        my $newAMT = $1 + $amt;
        $all_kittens =~ s/^$myID\|(\d+)/$myID\|$newAMT/g;
        write_file("files/kittens.txt", $all_kittens);
        print "added a kitten";
    }
    else {
        append_file("files/kittens.txt", $myID."|".$amt."\n");
        print "added and created";
    }
}
else {
	print "idk that cmd";
}