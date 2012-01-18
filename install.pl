#!/usr/bin/perl
use strict;
use warnings;

my $dest = '/usr/local/bin';

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
  my $cmd = "sudo cp $exec $dest";
  print "$cmd\n";
  system $cmd;
}
