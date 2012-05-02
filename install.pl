#!/usr/bin/perl
use strict;
use warnings;

my $prefix = shift() || '/usr/local';
die "Usage: $0 <prefix>\n" if @ARGV > 0;
my $dest = "$prefix/bin";
die "Invalid install location: $dest\n" if not -d $dest;

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

print "copying these scripts to $dest\n";
print "@execs\n";

for my $exec(@execs){
  system "cp", $exec, $dest;
}
