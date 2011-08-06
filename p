#!/usr/bin/perl
use strict;
use warnings;

my $dir = $0;
$dir =~ s/([^\/]*)$//;
$dir = `$dir/abspath.py $dir`;
chomp $dir;
chdir $dir;

my $cmd = 'shuffle';
if(@ARGV > 0){
  $cmd = shift;
}

my $db = '/home/wolke/.pdb';
my $lib = '/home/wolke/Desktop/Music/Library';

my $pl = "/tmp/p-shuffle-" . time;

if(!-e $db){
  system "$dir/p-db create $db";
}

my $musicPattern = ".*\\.mp3\\|.*\\.flac\\|.*\\.ogg\\|.*\\.m4a";

my @paths;
if($cmd eq 'shuffle'){
  chdir $lib;
  @paths = `find . -iregex '$musicPattern'`;
  for(my $i=0; $i<@paths; $i++){
    $paths[$i] =~ s/^\.\///;
  }
  chdir $dir;
}elsif($cmd eq 'query'){
  my $query = shift;
  @paths =`./p-db search $db $query`;
}elsif($cmd eq 'scan'){
  chdir $lib;
  @paths = `find . -iregex '$musicPattern'`;
  for(my $i=0; $i<@paths; $i++){
    $paths[$i] =~ s/^\.\///;
  }
  for my $path(@paths){
    $path =~ s/'/'\\''/g;
    print "Adding $path";
    chomp $path;
    system "$dir/p-db add $db '$lib' '$path'";
    system "$dir/p-db info $db '$path'";
  }
  chdir $dir;
}

#shuffle paths
for (my $i = @paths; --$i; ) {
  my $j = int rand ($i+1);
  next if $i == $j;
  @paths[$i,$j] = @paths[$j,$i];
}

open FH, "> $pl";
for my $path(@paths){
  print FH "$lib/$path";
}
close FH;

my @indices =qw(
  0 1 2 3 4 5 6 7 8 9
  q w e r t y u i o p
  a s d f g h j k l
  z x c v b n m);

for(my $i=0; $i<@indices; $i++){
  my $path = $paths[$i];
  my $info = `$dir/p-db info $db '$path'`;
  print $info;
  my %fields;
  while($info =~ m/^([A-Za-z]+)=(.*)$/m){
    $fields{lc $1} = $2;
  }
#  print $indices[$i] . "\t\t" . $fields{'title'} . " " . $path;
}
#exec "mplayer -playlist $pl";
