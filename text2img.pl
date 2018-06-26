#!/usr/bin/perl

use warnings;
use strict;
use Imager;

use MIME::Base64;

my $img = Imager->new(xsize=>400,ysize=>100);
$img->box(filled=>1, color=>"ffffff"); #fill the background color 

my $blue = Imager::Color->new("#0000FF");

my $font = Imager::Font->new(
   file  => 'gen.ttf',
   index => 0,
   color => $blue,
   size  => 30,
   aa    => 1);
my $fileName = $ARGV[0];
$img->string(
   font=>$font,
   text=>$fileName,
   x=>40,
   y=>60);

$fileName = encode_base64($fileName);
$fileName =~ s/[=| |\n]//g;
$img->write(file=>"files/pics/$fileName.png", type=>"png") or die "Cannot write file: +", Imager->errstr;