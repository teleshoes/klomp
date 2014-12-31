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

  my %tagReaders = (
    'python-mutagen'     => "mp3 {mid3v2}",
    'lltag'              => "ogg, flac",
    'libaudio-wma-perl'  => "wma",
    'atomicparsley'      => "mp4, m4a, m4p, m4v, m4b",
  );

  my @essential = qw(perl python mplayer sqlite3);
  my @tagging = sort keys %tagReaders;
  my @translit = qw(libtext-unidecode-perl);
  my @flacmirror = qw(dir2ogg);
  my @japanese = qw(liblingua-ja-romanize-japanese-perl);
  my @duration = qw(libav-tools);

  my $msg = ''
    . "searching for and playing music:\n"
    . "  @essential\n"
    . "Tag reading\n"
    .   (join '', (map {"  $_ => $tagReaders{$_}\n"} @tagging))
    . "non-roman => ascii transliteration for tag parsing:\n"
    . "  @translit\n"
    . "flacmirror {flac=>ogg parallel-dir-structure}:\n"
    . "  @flacmirror\n"
    . "improved japanese transliteration for tag parsing:\n"
    . "  @japanese\n"
    ;

  my $debs = getDepDebs();

  my @packages = (@essential, @tagging, @translit, @flacmirror, @japanese, @duration);
  my @aptPackages = grep {not defined $$debs{$_}} @packages;
  my @debPackages = grep {defined $$debs{$_}} @packages;

  print "$msg\n\n\n";

  run "apt-get", "install", @aptPackages;
  run "dpkg", "-i", $$debs{$_} foreach @debPackages;
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
