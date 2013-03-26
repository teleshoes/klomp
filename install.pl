#!/usr/bin/perl
use strict;
use warnings;

my $libDir = '/opt/klomp/lib';

my $prefix = shift;
$prefix = '/usr/local' if not defined $prefix;

die "Usage: $0 <prefix>\n" if @ARGV > 0;

my $dest = "$prefix/bin";
die "Invalid install location: $dest\n" if not -d $dest;

if(`whoami` ne "root\n"){
  exec 'sudo', $0, @ARGV;
}

my @execs = qw(
  flacmirror
  presync
  klomplayer
  klomp
  klomp-call-handler
  klomp-cmd
  klomp-db
  klomp-fifo-writer
  klomp-files
  klomp-lib
  klomp-size
  klomp-sync
  klomp-tag
  klomp-term
  klomp-update
);

chdir 'src';
print "copying these scripts to $dest\n";
print "@execs\n";

print "copying lib\n";
system "rm", "-r", $libDir;
system "mkdir", "-p", $libDir;
system "cp -r Klomp $libDir";

for my $exec(@execs){
  system "cp", $exec, $dest;
}
