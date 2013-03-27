#!/usr/bin/perl
use strict;
use warnings;

my $depsDir = `dirname $0`;
chomp $depsDir;
$depsDir .= "/deps";

if(`whoami` ne "root\n"){
  exec 'sudo', $0, @ARGV;
}

sub run(@){
  print "@_\n";
  system @_;
}
sub runPrompt(@){
  print "@_\nrun the above cmd? [y/N]";
  if(lc <STDIN> eq "y\n"){
    system @_;
  }
}

print "searching for and playing music:\n";
run qw(apt-get install perl python mplayer sqlite3);

print "\n\n";

print "optional tag-reading-libs for:\n";

print "\n  mp3 {eyed3}\n";
runPrompt qw(apt-get install eyed3);

print "\n  ogg and flac {lltag}:\n";
runPrompt qw(apt-get install lltag);

print "\n  wma {perl module Audio::WMA}\n";
runPrompt qw(apt-get install libaudio-wma-perl);

print "\n  mp4, m4a, m4p, m4v, m4b {AtomicParsley}\n";
runPrompt qw(apt-get install atomicparsley);

print "\n\n";

print "non-roman => ascii transliteration for tag parsing\n";
print "  {perl module Text::Unidecode}\n";
runPrompt qw(apt-get install libtext-unidecode-perl);

print "\n\n";

print "improved japanese transliteration for tag parsing\n";
print "  {perl module Lingua::JA::Romanize::Japanese}\n";
runPrompt "dpkg -i $depsDir/liblingua-ja-romanize-japanese-perl*.deb";

print "\n\n";

print "flacmirror: flac=>ogg parallel-dir-structure syncing\n";
runPrompt qw(apt-get install dir2ogg);
