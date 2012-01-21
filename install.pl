#!/usr/bin/perl
use strict;
use warnings;

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
run qw(apt-get install perl python mplayer);

print "\n\n";

print "optional interactive CLI\n";
runPrompt qw(cpan Term::ReadKey);

print "\n\n";

print "optional tag-reading-libs for:\n";
print "\n\n-mp3 {eyed3}\n";
runPrompt qw(apt-get install eyed3);

print "\n\n-ogg and flac {lltag}:\n";
runPrompt qw(apt-get install lltag);

print "\n\n-wma {Audio::WMA}\n";
runPrompt qw(cpan Audio::WMA);

print "\n\n-mp4, m4a, m4p, m4v, m4b {AtomicParsley }\n";
runPrompt qw(apt-get install atomicparsley);

print "\n\n";

print "japanese transliteration tagging {Lingua::JA::Romanize::Japanese}\n";
runPrompt qw(cpan Lingua::JA::Romanize::Japanese);

print "\n\n";

print "flacmirror: flac=>ogg parallel-dir-structure syncing\n";
runPrompt qw(apt-get install dir2ogg);

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
  run ("cp", $exec, $dest);
}
