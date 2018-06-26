use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_Social);

use DBI;

use utf8;
use Encode;
use MIME::Base64;
binmode(STDOUT, ':utf8');

sub get_btag_or_dtag {
    my ($utag) = @_;
    my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
    $dbh->do('SET NAMES utf8mb4') or die($dbh->errstr);
    $dbh->{mysql_enable_utf8mb4} = 1;
    my $sth = $dbh->prepare("SELECT * FROM `everyone_social` WHERE `battle_tag` = '" . $utag . "' or `discord_tag` = '" . $utag . "'");
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    if (!defined $row) {
        return "Unable to find that Battle Tag or Discord Tag.";
    }
    if ($row->{battle_tag} eq $utag) {
        return "Discord Tag: " . $row->{discord_tag};
    }
    else {
        return "Battle Tag: " . $row->{battle_tag};
    }
}

sub btag_exists {
    my ($btag) = @_;
    my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
    $dbh->do('SET NAMES utf8mb4') or die($dbh->errstr);
    $dbh->{mysql_enable_utf8mb4} = 1;
    my $sth;
    $btag .= '\\\\\\\\_';
    $sth = $dbh->prepare("SELECT COUNT(*) FROM `everyone` WHERE `battle_tag` LIKE '%" . $btag . "%'");
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    return $row->{"COUNT(*)"};
}

sub link_btag_dtag {
    my ($btag, $dtag) = @_;
    if (btag_exists($btag) eq 0) {
        return "Unable to find any ranked users with that Battle Tag";
    }
    # if (dtag_exists($dtag) eq 0) {
    #
    # }

    # link the two
    my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
    $dbh->do('SET NAMES utf8mb4') or die($dbh->errstr);
    $dbh->{mysql_enable_utf8mb4} = 1;
    my $sth;
    $sth = $dbh->prepare("INSERT INTO `everyone_social` (`battle_tag`, `discord_tag`) VALUES('".$btag."', '".$dtag."') ON DUPLICATE KEY UPDATE battle_tag = '".$btag."'");
    $sth->execute();
    return "Linked " . $dtag . " to the Battle Tag " . $btag;
}

BEGIN {
	if ($ARGV[0] eq "set") {
		print link_btag_dtag($ARGV[1], $ARGV[2]);
	}
    elsif ($ARGV[0] eq "get") {
        print get_btag_or_dtag($ARGV[1]);
    }
}