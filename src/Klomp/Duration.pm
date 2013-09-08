package Klomp::Duration;
use Exporter 'import';
@EXPORT_OK = qw(getLen formatLenS formatLenHMS);
use strict;
use warnings;

sub selectExec(@);
sub getLen($);
sub formatLenS($);
sub formatLenHMS($);

sub selectExec(@){
  for my $cmd(@_){
    my $path = `which $cmd`;
    chomp $path;
    return $path if $? == 0;
  }
}

sub getLen($){
  my $file = shift;
  die "file not found: $file\n" unless -e $file;

  my @cmds = ("ffmpeg", "avconv");
  my $exec = selectExec @cmds;
  die "Could not find these on path: @cmds\n" if not defined $exec;

  $file =~ s/"/\\"/g;
  my $info = `$exec -i "$file" 2>&1`;
  if($info =~ /Duration: (\d+):(\d+):(\d+(?:\.\d+))/){
    return $3 + ($2*60) + ($1*60*60);
  }else{
    die "Unknown length for input: $file\n";
  }
}

sub formatLenS($){
  return sprintf "%.2f", $_[0];
}
sub formatLenHMS($){
  my $len = shift;
  $len = int(0.5 + $len);
  my $h = int($len / (60*60));
  my $m = int($len % (60*60) / (60));
  my $s = $len - ($m*60) - ($h*60*60);
  $s = "0$s" if $s < 10;

  if($h == 0){
    return "$m:$s";
  }else{
    $m = "0$m" if $m < 10;
    return "$h:$m:$s";
  }
}

1;
