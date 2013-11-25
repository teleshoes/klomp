#!/usr/bin/perl
use strict;
use warnings;

my $depsDir = `dirname $0`;
chomp $depsDir;
$depsDir .= "/deps";

sub run(@);

sub main(@){
  die "Usage: $0\n" if @_ > 0;
  if(`whoami` ne "root\n"){
    print "rerunning as root\n";
    exec 'sudo', $0, @ARGV;
  }

  print "searching for and playing music:\n";
  run qw(apt-get install perl python mplayer sqlite3);

  print "Tag reading\n\n\n";
  my %tagReaders = (
    'python-mutagen'     => "mp3 {mid3v2}",
    'lltag'              => "ogg, flac",
    'libaudio-wma-perl'  => "wma",
    'atomicparsley'      => "mp4, m4a, m4p, m4v, m4b",
  );
  print "\n\n\n";
  print "$_ => $tagReaders{$_}\n" foreach keys %tagReaders;
  run "apt-get", "install", keys %tagReaders;

  print "\n\n\n";
  print "non-roman => ascii transliteration for tag parsing\n";
  run "apt-get", "install", "libtext-unidecode-perl";

  print "improved japanese transliteration for tag parsing\n";
  run "dpkg -i $depsDir/liblingua-ja-romanize-japanese-perl*.deb";

  print "flacmirror: flac=>ogg parallel-dir-structure syncing\n";
  run "apt-get", "install", "dir2ogg";
}

sub run(@){
  print "@_\n";
  system @_;
}

&main(@ARGV);
