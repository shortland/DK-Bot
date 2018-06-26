#!/usr/bin/perl

package GetIDKey;

use v5.10;

use File::Slurp;

our @ISA = qw(Exporter);
our @EXPORT = qw(GetIDKeyFromC);

sub GetIDKeyFromC {
	my ($THECHANNEL) = @_;
	my @lines = split(m/\n/, read_file("buffers/webhook_buffer.txt"));

	foreach my $line (@lines) {
		if(((split(m/\|/, $line))[0]) =~ /^($THECHANNEL)$/) {
			return ((split(m/\|/, $line))[1])."|".((split(m/\|/, $line))[2]);
		}
	}
}

1;