#!/usr/bin/perl
use strict;
use warnings;

if(`whoami` ne "root\n"){
  exec 'sudo', $0, @ARGV;
}

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
  klomp-sync
  klomp-term
  klomp-update
  klomp-size
);


my $dest = '/usr/local/bin';
print "copying the scripts to $dest\n";

for my $exec(@execs){
  run "cp", $exec, $dest;
}
