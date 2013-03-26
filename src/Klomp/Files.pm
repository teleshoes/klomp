package Klomp::Files;
use strict;
use warnings;

sub klompFile($);
sub allKlompFiles();

my $files = {
  db           => "$ENV{HOME}/.klompdb",
  cur          => "$ENV{HOME}/.klompcur",
  list         => "$ENV{HOME}/.klomplist",
  history      => "$ENV{HOME}/.klomphistory",
  lib          => "$ENV{HOME}/.klomplib",
  playlistname => "$ENV{HOME}/.klomplist",
  playlistdir  => "$ENV{HOME}/.klomplist-",
  fifo         => "/tmp/klomplayer_fifo",
  fifopidfile  => "/tmp/klomplayer_fifo_pid",
  termpidfile  => "/tmp/klomp_term_pid",
  pidfile      => "/tmp/klomplayer_pid",
};
my $synonyms = {
  plname => 'playlistname',
  pldir => 'playlistdir',
  hist => 'history',
};
for my $key(keys %$synonyms){
  $$files{$key} = $$files{$$synonyms{$key}};
}

sub klompFile($){
  my $path = $$files{$_[0]};
  die "Error getting klomp file $_[0]!\n" if not defined $path;
  return $path;
}
sub allKlompFiles(){
  return $files;
}

1;
