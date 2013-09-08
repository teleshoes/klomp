package Klomp::Duration;
use Exporter 'import';
@EXPORT_OK = qw(getDuration cmdExists formatTimeS formatTimeHMS);
use strict;
use warnings;

my @cmds = ("ffmpeg", "avconv");

sub selectExec(@);
sub getDuration($);
sub cmdExists();
sub formatTimeS($);
sub formatTimeHMS($);

sub selectExec(@){
  for my $cmd(@_){
    my $path = `which $cmd`;
    chomp $path;
    return $path if $? == 0;
  }
}

sub getDuration($){
  my $file = shift;
  my $exec = selectExec @cmds;
  return undef if not -f $file or not defined $exec;

  $file =~ s/"/\\"/g;
  $file =~ s/`/\\`/g;
  my $info = `$exec -i "$file" 2>&1`;
  if($info =~ /Duration: (\d+):(\d+):(\d+(?:\.\d+))/){
    return $3 + ($2*60) + ($1*60*60);
  }
  return undef;
}

sub cmdExists(){
  my $exec = selectExec @cmds;
  return defined $exec;
}

sub formatTimeS($){
  return sprintf "%.2f", $_[0];
}
sub formatTimeHMS($){
  my $time = shift;
  $time = int(0.5 + $time);
  my $h = int($time / (60*60));
  my $m = int($time % (60*60) / (60));
  my $s = $time - ($m*60) - ($h*60*60);
  $s = "0$s" if $s < 10;

  if($h == 0){
    return "$m:$s";
  }else{
    $m = "0$m" if $m < 10;
    return "$h:$m:$s";
  }
}

1;
