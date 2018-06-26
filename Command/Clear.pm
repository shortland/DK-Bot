package Command::Clear;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_clear);

use Mojo::Discord;
use Bot::Goose;

###########################################################################################
# Command Info
my $command = "clear";
my $access = 0; # Public
my $description = "This is a clear command for building new actual commands";
my $pattern = '^(~clear)\s?(.+)';
my $function = \&cmd_clear;
my $usage = <<EOF;
Basic usage: !clear
Advanced usage: !clear
Other usage: !clear
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

sub cmd_clear
{
    my ($self, $channel, $author, $msg) = @_;
    say "test";
    my $args = $msg;
    my $pattern = $self->{'pattern'};
    my $THING = $2;
   # $args =~ s/$pattern/$2/i;

    my $discord = $self->{'discord'};
    my $replyto = '<@' . $author->{'id'} . '>';

    use MessageRequest;
    use File::Slurp;

    if (($author->{'id'}) =~ /^(108805934297387008|131231443694125056|139420334896971776)$/) {
		say "wtf";	
		$discord->send_message($channel, "This command is a little buggy and will not always delete every message. Run it several times (AFTER IT FINISHES) to clear everything.");
	    my $oky = $THING;
	    if ($oky =~ /^ctl$/) {
	    	$oky = "313532518022381569";
	    }
	    my $res = `cd /var/www/html/GOOSE/ && perl clearNotPin.pl $oky`;
	    append_file("static/clears.txt", $res);
	    #$discord->send_message($channel, "Cleared channel ID $oky (data dumped to static/clears.txt)");
    }
    else {
    	say "no u have nopermissions";	

    	$discord->send_message($channel, "Only admins can perform that action");
    }

    # Send a message back to the channel
    
}

1;
