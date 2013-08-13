package Klomp::Lib;
use strict;
use warnings;
use Klomp::Files;

my $defaultKlompLib = Klomp::Files::klompFile("lib");

sub getAllLibNames(;$);
sub getDefaultLibNames(;$);
sub getLibraryPath($;$);
sub getFlacmirrorPath($;$);

sub readLibFile(;$);
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
sub isPreferMirror($;$){
  my ($lib, $klompLib) = @_;
  my $libArr = getLibArray $lib, $klompLib;
  my $pref = $$libArr[3] if @$libArr >= 4;
  if(defined $pref and $pref =~ /mirror/){
    return 1;
  }else{
    return 0;
  }
}

sub parseLibs(;$){
  my ($klompLib) = @_;
  return readLibFile $klompLib;
}

sub readLibFile(;$){
  my ($klompLib) = @_;
  $klompLib = $defaultKlompLib if not defined $klompLib;
  die "$klompLib file not found\n" if not -e $klompLib;

  open FH, "< $klompLib" or die "Could not read $klompLib";
  my @lines = <FH>;
  close FH;
  chomp foreach @lines;

  my %libs;
  my (@libLines, @properties);
  for my $line(@lines){
    if($line =~ /^\s*#/){
      next;
    }elsif($line =~ /^(.*):(.*):(.*):(.*):(.*)/){
      $libs{$1} = [$2, $3, $4, $5];
    }
  }
  return \%libs;
}

sub getLibArray($;$){
  my ($lib, $klompLib) = @_;
  my $libs = parseLibs $klompLib;
  if(not defined $$libs{$lib}){
    my $okLibs = join ', ', sort keys %$libs;
    die "Unknown lib '$lib' (known libs: $okLibs)\n";
  }
  return $$libs{$lib};
}

1;
