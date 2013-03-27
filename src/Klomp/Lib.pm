package Klomp::Lib;
use strict;
use warnings;
use Klomp::Files;

my $defaultKlompLib = Klomp::Files::klompFile("lib");

sub getAllLibNames(;$);
sub getDefaultLibNames(;$);
sub getLibraryPath($;$);
sub getFlacmirrorPath($;$);

sub parseLibs(;$);
sub getLibArray($;$);

sub getAllLibNames(;$){
  my ($klompLib) = @_;
  my $libs = parseLibs $klompLib;
  return sort keys %$libs;
}

sub getDefaultLibNames(;$){
  my ($klompLib) = @_;
  my $libs = parseLibs $klompLib;
  return grep {${$$libs{$_}}[0] eq 'default'} sort keys %$libs;
}

sub getLibraryPath($;$){
  my ($lib, $klompLib) = @_;
  my $libArr = getLibArray $lib, $klompLib;
  return $$libArr[1] if @$libArr >= 2;
}
sub getFlacmirrorPath($;$){
  my ($lib, $klompLib) = @_;
  my $libArr = getLibArray $lib, $klompLib;
  return $$libArr[2] if @$libArr >= 3;
}


sub parseLibs(;$){
  my ($klompLib) = @_;
  $klompLib = $defaultKlompLib if not defined $klompLib;
  die "$klompLib file not found\n" if not -e $klompLib;

  open FH, "< $klompLib" or die "Could not read $klompLib";
  my @lines = grep {/^[^#]/} <FH>;
  close FH;
  chomp foreach @lines;
  my %libs = map {my @arr = split ':'; {shift @arr, \@arr}} @lines;
  return \%libs;
}

sub getLibArray($;$){
  my ($lib, $klompLib) = @_;
  my $libs = parseLibs $klompLib;
  if(not defined $$libs{$lib}){
    die "Unknown lib '$lib' (known libs: " . (join ', ', keys %$libs) . ")\n";
  }
  return $$libs{$lib};
}

1;
