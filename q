#! /usr/bin/perl
use strict;
use warnings;
use POSIX 'setsid';
use Term::ReadKey;

my $QEXEC = '~/q/q';
my $QDB = '~/.qdb';

sub key(){
  my $BSD = -f '/vmunix';
  if ($BSD) {
    system "stty cbreak /dev/tty 2>&1";
  }else {
    system "stty", '-icanon', 'eol', "\001";
  }
  my $key = getc(STDIN);
  if ($BSD) {
    system "stty -cbreak /dev/tty 2>&1";
  }
  else {
    system "stty", 'icanon';
    system "stty", 'eol', '^@'; # ascii null
  }
  return $key;
}

sub cmd($){
  my $key = shift;
  $key = ord $key;
  if($key == 127){
    return 'BACKSPACE';
  }elsif($key == 10){
    return 'ENTER';
  }elsif($key == 27){
    my $key2 = ord key;
    if($key2 == 91){
      my $key3 = ord key;
      if($key3 == 65){
        return 'UP';
      }elsif($key3 == 66){
        return 'DOWN';
      }elsif($key3 == 67){
        return 'RIGHT';
      }elsif($key3 == 68){
        return 'LEFT';
      }elsif($key3 == 51){
        my $key4 = ord key;
        if($key4 == 126){
          return 'DELETE';
        }
      }
    }elsif($key2 == 79){
      my $key3 = ord key;
      if($key3 == 72){
        return 'HOME';
      }elsif($key3 == 70){
        return 'END';
      }
    }else{
      return $key2;
    }
  }
  return undef;
}

sub putCursor($$){
  my $line = shift;
  my $column = shift;
  system "echo '\\033[$line;${column}H'"
}

my $pos = 0;
my $query = join ' ', @ARGV;
my @all_songs;
my %selections;
my @sels = qw(
  1 2 3 4 5 6 7 8 9 0
  q w e r t y u i o p
  a s d f g h j k l
  z x c v b n m
  );

sub showQuery(){
  system "clear";
  my @size = Term::ReadKey::GetTerminalSize;
  my $width = $size[0];
  my $lines = $size[1];
  

  my $limit = $lines-2;
  my $q = $query;
  $q =~ s/'/'\\''/g;
  my @songs = `$QEXEC $QDB -s '$q' -l $limit`;
  my $overlength = 0;
  for my $song(@songs){
    chomp $song;
    $overlength++ if (length $song) + 3 > $width;
  }
  %selections = ();
  @all_songs = ();
  for(my $i=0; $i<@songs-$overlength; $i++){
    if($i < @sels){
      print " $sels[$i]:";
      $selections{$sels[$i]} = $songs[$i];
    }
    print $songs[$i] . "\n";
    push @all_songs, $songs[$i];
  }



  putCursor $lines-2, $pos+1;
  print substr($query, 0, $pos);
  print "|";
  print substr($query, $pos);
  putCursor $lines-1, $pos+1;
}

showQuery;

while(1){
  my $choice = key; #blocks
  my $cmd = cmd $choice;
  if(defined $cmd){
    if($cmd eq 'BACKSPACE'){
      if($pos > 0){
        my $prefix = substr $query, 0, $pos-1;
        my $suffix = substr $query, $pos;
        $query = "$prefix$suffix";
        $pos--;
      } 
    }elsif($cmd eq 'DELETE'){
      if($pos < length $query){
        my $prefix = substr $query, 0, $pos;
        my $suffix = substr $query, $pos+1;
        $query = "$prefix$suffix";
      }
    }elsif($cmd eq 'LEFT'){
      if($pos > 0){
        $pos--;
      }
    }elsif($cmd eq 'RIGHT'){
      if($pos < length $query){
        $pos++;
      }
    }elsif($cmd eq 'HOME'){
      $pos = 0;
    }elsif($cmd eq 'END'){
      $pos = length $query;
    }elsif($cmd eq 'ENTER' or defined $selections{lc chr $cmd}){
      if($cmd eq 'ENTER'){
        print "  selection: (enter again for all)";
        $cmd = ord key;
      }
      if($cmd == 10){
        chdir '/home/wolke/Desktop/Music/Library';
        system 'mplayer', @all_songs;
      }
      my $path = $selections{lc chr $cmd};
      chdir '/home/wolke/Desktop/Music/Library';
      system 'mplayer', $path;
    }
  }else{
    my $prefix = substr $query, 0, $pos;
    my $suffix = substr $query, $pos;
    $query = "$prefix$choice$suffix";
    $pos += length $choice;
  }
  showQuery;
}


