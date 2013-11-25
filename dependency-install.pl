#!/usr/bin/perl
use strict;
use warnings;

sub getDepDebs();
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

  my $debs = getDepDebs();

  print "improved japanese transliteration for tag parsing\n";
  run "dpkg", "-i", $_ foreach values %$debs;

  print "flacmirror: flac=>ogg parallel-dir-structure syncing\n";
  run "apt-get", "install", "dir2ogg";
}

sub getDepDebs(){
  my $depsDir = `dirname $0`;
  chomp $depsDir;
  $depsDir .= "/deps";

  my $debs = {};
  for my $deb(`ls $depsDir/*`){
    chomp $deb;
    my $pkgName = $1 if $deb =~ /^.*\/([a-z0-9\+\-\.]+)_([^\/]*)\.deb/;
    die "weirdly named deb package: $deb\n" if not defined $pkgName;
    $$debs{$pkgName} = $deb;
  }
  return $debs;
}

sub run(@){
  print "@_\n";
  system @_;
}

&main(@ARGV);
