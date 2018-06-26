package Command::Sql;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_sql);

use Mojo::Discord;
use Bot::Goose;

use File::Slurp;

###########################################################################################
# Command Info
my $command = "sql";
my $access = 0; # Public
my $description = "This is a sql command for building new actual commands";
my $pattern = '^(~sql)\s?([a-zA-Z\s\*=\'\d]+)?\s?';
my $function = \&cmd_sql;
my $usage = <<EOF;
Basic usage: ~sql
Advanced usage: ~sql
Other usage: ~sql
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

sub cmd_sql
{
    my ($self, $channel, $author, $msg) = @_;
    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    my $args = $msg;
    my $pattern = $self->{'pattern'};
    if(!$2) {
        $discord->send_message($channel, "plz no abuse t.t");
        exit;
    }
    else {
        $args =~ s/$pattern/$2/i;
    }

    $args =~ m/^(select)/i;

    if($author->{'id'} !~ "131231443694125056") {
        if ($1 !~ /^select$/i) {
            $discord->send_message($channel, "Only select for you!");
        }
        $discord->send_message($channel, "user");
        my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
        my $sth;
        #$discord->send_message($channel, "$args");
        $sth = $dbh->prepare($args);
        $sth->execute();
        my $datas;
        use Data::Dumper;
        while (my $row = $sth->fetchrow_hashref()) {
            $datas = Dumper $row;
            $discord->send_message($channel, "```JSON\n$datas```");
        }
    }
    else {
        $discord->send_message($channel, "admin");
        my $dbh = DBI->connect("DBI:mysql:database=teamconfed;host=localhost", "root", "LegoApril181998!", {'RaiseError' => 1});
        my $sth;
        #$discord->send_message($channel, "$args");
        $sth = $dbh->prepare($args);
        $sth->execute();
        my $datas;
        use Data::Dumper;
        while (my $row = $sth->fetchrow_hashref()) {
            $datas = Dumper $row;
            $discord->send_message($channel, "```JSON\n$datas```");
        }
    }

}

1;