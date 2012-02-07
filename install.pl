#!/usr/bin/perl
use strict;
use warnings;

if(`whoami` ne "root\n"){
  exec 'sudo', $0, @ARGV;
}
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
  klomp-sync
  klomp-term
  klomp-update
  klomp-size
);

print "copying these scripts to $dest\n";
print "@execs\n";

for my $exec(@execs){
  system "cp", $exec, $dest;
}
