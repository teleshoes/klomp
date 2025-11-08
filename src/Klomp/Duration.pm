package Klomp::Duration;
use Exporter 'import';
@EXPORT_OK = qw(getDuration cmdExists formatTimeS formatTimeHMS);
use strict;
use warnings;

my $FFPROBE_EXEC = "ffprobe";

sub selectExec(@);
sub getDuration($);
sub cmdExists();
sub formatTimeS($);
sub formatTimeHMS($);

sub selectExec(@){
  for my $cmd(@_){
    my $path = `sh -c 'command -v $cmd'`;
    chomp $path;
    return $path if $? == 0;
  }
}

sub getDuration($){
  my $file = shift;
  my $ffprobeExec = selectExec "ffprobe";
  die "ERROR: could not find `$FFPROBE_EXEC`\n" if not defined $ffprobeExec;

  return undef if not -f $file;

  my @cmd = ($ffprobeExec,
    "-v", "error",
    "-show_entries", "format=duration",
    "-of", "default=noprint_wrappers=1:nokey=1",
    $file,
  );

  open my $cmdH, "-|", @cmd or die "ERROR: could not run @cmd\n$!\n";
  my $out = join '', <$cmdH>;
  close $cmdH;

  if($out =~ /^(\d+|\d*\.\d+)$/){
    return $1;
  }

  return undef;
}

sub cmdExists(){
  my $exec = selectExec $FFPROBE_EXEC;
  return defined $exec;
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
