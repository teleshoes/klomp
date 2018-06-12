package Klomp::Config;
use strict;
use warnings;
use Klomp::Files;

my $defaultKlompConfigFile = Klomp::Files::klompFile("config");

sub getProperties(;$);
sub getProperty($;$);
sub readConfigFile(;$);
sub checkPropName($);

my $props = {
  symlink       => 'dir where all lib subdirs are symlinked by klomp-update',
  history       => 'git repo where klomp-update tracks database and filenames',
  startCmd      => 'run when klomp-cmd starts klomplayer',
  stopCmd       => 'run when klomp-cmd tries to kill klomplayer',
  hardStartCmd  => 'run after startCmd, but only when previously stopped',
  hardStopCmd   => 'run after stopCmd, but only when previously running',
  playlistCmd   => 'run when klomp-cmd changes playlists',
  updateCurCmd  => 'run by klomplayer every 20s while klompcur is updated',
  renice        => 'renice klomplayer to this value',
  targetUser    => 're-run klomp-cmd as this user using sudo su -c',
  disallowPause => 'klomp-cmd stops instead of pauses, killing klomplayer',
};
my $okProps = join "|", sort keys %$props;

sub getProperties(;$){
  my ($klompConfigFile) = @_;
  return readConfigFile $klompConfigFile;
}

sub getProperty($;$){
  my ($prop, $klompConfigFile) = @_;
  checkPropName $prop;
  my $props = readConfigFile $klompConfigFile;
  return $$props{$prop};
}

sub readConfigFile(;$){
  my ($klompConfigFile) = @_;
  $klompConfigFile = $defaultKlompConfigFile if not defined $klompConfigFile;
  return {} if not -e $klompConfigFile;

  open FH, "< $klompConfigFile" or die "Could not read $klompConfigFile";
  my @lines = <FH>;
  close FH;
  chomp foreach @lines;

  my $props = {};
  for my $line(@lines){
    if($line =~ /^\s*#/ or $line =~ /^\s*$/){
      next;
    }elsif($line =~ /^\s*([^ \t]*)\s*=\s*(.*?)\s*$/){
      my ($propName, $propValue) = ($1, $2);
      checkPropName $propName;
      $$props{$propName} = $propValue;
    }else{
      die "Malformed config line: $line\n";
    }
  }
  return $props;
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
