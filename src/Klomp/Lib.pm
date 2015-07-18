package Klomp::Lib;
use strict;
use warnings;
use Klomp::Files;

my $defaultKlompLib = Klomp::Files::klompFile("lib");

sub getSongAbsPath($$);
sub getProperties(;$);
sub getAllLibNames(;$);
sub getDefaultLibNames(;$);
sub getLibraryPath($;$);
sub getFlacmirrorPath($;$);
sub isPreferMirror($;$);

sub parseLibs(;$);
sub parseProps(;$);
sub readLibFile(;$);
sub getLibArray($;$);
sub checkPropName($);

my $props = {
};
my $okProps = join "|", sort keys %$props;

sub getSongAbsPath($$){
  my ($lib, $relpath) = @_;
  my $libPath = getLibraryPath $lib;
  my $absPath = "$libPath/$relpath";
  my $prefMirror = isPreferMirror $lib;
  if(-e $absPath and not $prefMirror){
    return $absPath;
  }

  my $flacLibPath = getFlacmirrorPath $lib;
  my $flacrelpath = $relpath;
  $flacrelpath =~ s/\.flac$/\.ogg/i;
  my $flacAbsPath = "$flacLibPath/$flacrelpath";

  if(-e $flacAbsPath){
    return $flacAbsPath;
  }elsif(-e $absPath){
    return $absPath;
  }
  return undef;
}

sub getProperties(;$){
  my ($klompLib) = @_;
  return parseProps $klompLib;
}

sub getProperty($;$){
  my ($prop, $klompLib) = @_;
  checkPropName $prop;
  my $props = parseProps $klompLib;
  return $$props{$prop};
}

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
  return ${readLibFile $klompLib}[0];
}

sub parseProps(;$){
  my ($klompLib) = @_;
  return ${readLibFile $klompLib}[1];
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
  my %props;
  my (@libLines, @properties);
  for my $line(@lines){
    if($line =~ /^\s*#/ or $line =~ /^\s*$/){
      next;
    }elsif($line =~ /^(.*):(.*):(.*):(.*):(.*)/){
      $libs{$1} = [$2, $3, $4, $5];
    }elsif($line =~ /^\s*([^ \t]*)\s*=\s*(.*?)\s*$/){
      my ($propName, $propValue) = ($1, $2);
      checkPropName $propName;
      $props{$propName} = $propValue;
    }else{
      die "Malformed lib line: $line\n";
    }
  }
  return [\%libs, \%props];
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

sub checkPropName($){
  my $propName = shift;
  if($propName !~ /^($okProps)$/){
    my $maxPropNameLen = 0;
    for my $propName(sort keys %$props){
      $maxPropNameLen = length $propName if length $propName > $maxPropNameLen;
    }
    my $propMsg = "";
    for my $propName(sort keys %$props){
      $propMsg .= "  $propName";
      $propMsg .= ' ' x ($maxPropNameLen-length $propName);
      $propMsg .= " => $$props{$propName}\n";
    }
    die "Unknown property '$propName'\nknown properties:\n$propMsg";
  }
}

1;
