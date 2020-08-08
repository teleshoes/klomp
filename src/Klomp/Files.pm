package Klomp::Files;
use strict;
use warnings;

sub klompFile($);
sub allKlompFiles();

my $BASE_DIR = "$ENV{HOME}/.klomp";
my $TMP_DIR = "/tmp";

my $BASE_DIR_FILES = {
  db           => "db",
  cur          => "cur",
  list         => "list",
  hist         => "history",
  history      => "history",
  datecache    => "datecache",
  lib          => "lib",
  config       => "config",
  playlistname => "playlist",
  plname       => "playlist",
  pldir        => "list-",
  playlistdir  => "list-",
};
my $TMP_DIR_FILES = {
  bufferlog    => "qtcmdplayer-buffer.log",
  fifo         => "klomplayer_fifo",
  fifopidfile  => "klomplayer_fifo_pid",
  termpidfile  => "klomp_term_pid",
  pidfile      => "klomplayer_pid",
};

my $FILES = {
  baseDir => $BASE_DIR,
  tmpDir  => $TMP_DIR,
  (map {$_ => "$BASE_DIR/$$BASE_DIR_FILES{$_}"} sort keys %$BASE_DIR_FILES),
  (map {$_ => "$TMP_DIR/$$TMP_DIR_FILES{$_}"} sort keys %$TMP_DIR_FILES),
};

sub klompFile($){
  my $path = $$FILES{$_[0]};
  die "Error getting klomp file $_[0]!\n" if not defined $path;
  return $path;
}
sub allKlompFiles(){
  return $FILES;
}

1;
