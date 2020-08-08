package Klomp::Files;
use strict;
use warnings;

sub klompFile($);
sub allKlompFiles();

my $files = {
  baseDir      => "$ENV{HOME}/.klomp",
  db           => "$ENV{HOME}/.klomp/db",
  cur          => "$ENV{HOME}/.klomp/cur",
  list         => "$ENV{HOME}/.klomp/list",
  history      => "$ENV{HOME}/.klomp/history",
  hist         => "$ENV{HOME}/.klomp/history",
  datecache    => "$ENV{HOME}/.klomp/datecache",
  lib          => "$ENV{HOME}/.klomp/lib",
  config       => "$ENV{HOME}/.klomp/config",
  playlistname => "$ENV{HOME}/.klomp/playlist",
  plname       => "$ENV{HOME}/.klomp/playlist",
  playlistdir  => "$ENV{HOME}/.klomp/list-",
  pldir        => "$ENV{HOME}/.klomp/list-",
  bufferlog    => "/tmp/qtcmdplayer-buffer.log",
  fifo         => "/tmp/klomplayer_fifo",
  fifopidfile  => "/tmp/klomplayer_fifo_pid",
  termpidfile  => "/tmp/klomp_term_pid",
  pidfile      => "/tmp/klomplayer_pid",
};

sub klompFile($){
  my $path = $$files{$_[0]};
  die "Error getting klomp file $_[0]!\n" if not defined $path;
  return $path;
}
sub allKlompFiles(){
  return $files;
}

1;
