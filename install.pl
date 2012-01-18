#!/usr/bin/perl
use strict;
use warnings;

sub run(@){
  print "@_\n";
  system @_;
}

print "searching for and playing music:\n";
run qw(sudo apt-get install perl python mplayer);

print "\n\n";

print "optional interactive CLI\n";
run qw(sudo cpan Term::ReadKey);

print "\n\n";

print "optional tag-reading-libs for:\n";
print "\n\n-mp3 {eyed3}\n";
run qw(sudo apt-get install eyed3);

print "\n\n-ogg and flac {lltag}:\n";
run qw(sudo apt-get install lltag);

print "\n\n-wma {Audio::WMA}\n";
run qw(sudo cpan Audio::WMA);

print "\n\n-mp4, m4a, m4p, m4v, m4b {AtomicParsley }\n";
run qw(sudo apt-get install atomicparsley);

print "\n\n";

print "japanese transliteration {Lingua::JA::Romanize::Japanese}\n";
run qw(sudo cpan Lingua::JA::Romanize::Japanese);

print "\n\n";

print "flacmirror: flac=>ogg parallel-dir-structure syncing\n";
run qw(sudo apt-get install dir2ogg);

print "\n\n";

my $dest = '/usr/local/bin';
print "copying the scripts to $dest\n";

my @execs = qw(
  flacmirror
  klomplayer
  klomp
  klomp-call-handler
  klomp-cmd
  klomp-db
  klomp-fifo-writer
  klomp-lib
  klomp-search
  klomp-term
  klomp-update
);

for my $exec(@execs){
  run ("sudo", "cp", $exec, $dest);
}
