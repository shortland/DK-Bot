#!/usr/bin/perl

use File::Slurp;
use BIGWORDLIST;

my $wrong = 0; # if wrong == 6, die
my @correct;
my $sent = 0;

# we dont have a answer sheet yet
if (read_file("word.txt") eq "") {
	my $newword = $WORDLIST[int(rand(scalar(@WORDLIST))) + 1] . "        " . $WORDLIST[int(rand(scalar(@WORDLIST))) + 1];
	write_file("word.txt", lc($newword));
}

if(!defined($ARGV[0]) || $ARGV[0] eq "") {
	#print "yes print should be";
	PrintUnknowns(lc(read_file("word.txt")), lc(read_file("guessed.txt")));# $sent = 1;
	PrintWrong();
	exit;
}
else {
	#print "this was response :" . $ARGV[0];
}
$ARGV[0] = lc($ARGV[0]);

# file not empty
if (read_file("guessed.txt") ne "") {
	#already guessed true and false
	my @alreadyGuessed = split(//, read_file("guessed.txt"));
	if ( ($ARGV[0]) ~~ @alreadyGuessed ) {
		print "Already guessed that letter!";
		exit;
	}
	else {
		#print "didnt guess ARGV=" . $ARGV[0];
		
		append_file("guessed.txt", $ARGV[0]);
		#print read_file("guessed.txt");
		# count number of wrong
		# and push to correct array
		foreach (split(//, read_file("guessed.txt"))) {
			my @letteredWords = split(//, read_file("word.txt"));
			if (($_) ~~ @letteredWords) {
				# that's right :D
				push(@correct, $_);
			}
			else {
				#print $_ . " is incorrect";
				$wrong++;
			}
		}

		if ($wrong eq 6) {
			# send full ded stickman
			print "Game over! The answer was: **\"".read_file("word.txt")."\"**";
			PrintWrong();
			write_file("guessed.txt", "");
			exit;
		}
	}
}
else {
	# it's empty so put it in
	append_file("guessed.txt", $ARGV[0]);

	my @letteredWords = split(//, read_file("word.txt"));
	if ($ARGV[0] ~~ @letteredWords) {
		# that's right :D
		push(@correct, $ARGV[0]);
	}
	else {
		$wrong++;
	}
}

if (Guess_Letter(lc(read_file("word.txt")), lc($ARGV[0]))) {
	#print "That's in it!\n";	
}
else {
	#print "NOPE\n";
}

# BOOLEAN
sub Guess_Letter {
	my ($characters, $guess) = @_;
	my @splitChars = split(//, $characters);

	if ($guess ~~ @splitChars) {
		return 1;
	}
	else {
		return 0;
	}
}

# check if it's solved
my $readNoSpaces = read_file("word.txt");
$readNoSpaces =~ s/ //g;
my @whatItIs = split(//, $readNoSpaces);

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

@whatItIs = uniq(@whatItIs);

my @whatIHave = @correct;

# this technically should work, length of correct compared to length of given
if (scalar(@whatItIs) eq scalar(@whatIHave)) {
	print "You solved it!\n";
	PrintUnknowns(lc(read_file("word.txt")), lc(read_file("guessed.txt")));
	PrintWrong();
	write_file("guessed.txt", "");
	write_file("word.txt", "");
	exit;
}
else {
	#print scalar(@whatItIs);
	#print scalar(@whatIHave);
}

#print "WRONG AMT: " . $wrong;

PrintUnknowns(lc(read_file("word.txt")), lc(read_file("guessed.txt")));
sub PrintUnknowns {
	my ($string, $knowChars) = @_;
	my @charArray = split(//, $knowChars);
	my @matchAgainst = ("a".."z");

	#my $count = 0;
	foreach (@charArray) {
		my $index = 0;
		$index++ until $matchAgainst[$index] eq $_;
		splice(@matchAgainst, $index, 1);
		#$count++;
	}

	my $know = join("", @matchAgainst);

	$string =~ s/[$know]/\?/g;
	$string =~ s/(\w)/:regional_indicator_$1:/g;
	$string =~ s/\?/:question:/g;
	print $string.".";
}
PrintWrong();
sub PrintWrong {
	print "\n";
	for (my $i = 0; $i < $wrong; $i++) {
		print ":x:";
	}
	for (my $i = 0; $i < (6-$wrong); $i++) {
		print ":heavy_multiplication_x:";
	}
	print ".";
}