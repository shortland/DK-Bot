#!/usr/bin/perl

package ApiKeys;

use Exporter;

our @ISA = qw(Exporter);

#can be
our @EXPORT_OK = qw($API_TWITCH $API_YANDEX $API_AI $API_DISCORD);
#default
our @EXPORT = qw($API_TWITCH $API_YANDEX $API_AI $API_DISCORD);

$API_YANDEX = "trnsl.1.1.20170208T112734Z.cedda579a992554c.25465f2ed857be5b1d1482f7f9338080e1e7ffb3";
$API_DISCORD = "MzE0NTAzODQ5NDU5MDU2NjUy.De-EXg.OC-jpUiE_fuk6ENkcMDEhPc2kfk";
$API_TWITCH = "e8la2m8xefhf2rib72273d3m5upqcl";
$API_AI = "de1c3eb4d7ac44aa99d75963b2aa18dc";

1;