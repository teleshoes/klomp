#! /usr/bin/perl
use strict;
use warnings;
use POSIX 'setsid';
use Term::ReadKey;

my $QDBEXEC = '~/q/qdb';
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
      }elsif($key3 == 68){
        return 'LEFT';
      }elsif($key3 == 67){
        return 'RIGHT';
      }elsif($key3 == 53){
        return 'PGUP';
      }elsif($key3 == 54){
        return 'PGDN';
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
my $offset = 0;
my @all_songs;
my %selections;
my @sels = qw(
  1 2 3 4 5 6 7 8 9 0
  q w e r t y u i o p
  a s d f g h j k l
  z x c v b n m
  );

sub parseCsv($){
  my $csv = shift;
  my @cols;
  while($csv ne ''){
    if($csv =~ /^".*"/){
      my $len = length $csv;
      for(my $i=1; $i<$len; $i++){
        my $c = substr $csv, $i, 1;
        if($c eq '"'){
          $i++;
          my $cNext = '';
          $cNext = substr $csv, $i, 1 if $i < $len;
          if($cNext ne '"'){
            my $col = substr $csv, 1, $i-2;
            $col =~ s/""/"/g;
            push @cols, $col;

            if($i < $len){
              $csv = substr $csv, $i+1, $len-$i-1;
            }else{
              $csv = '';
            }
            last;
          }
        }
      }
    }elsif($csv =~ s/^([^,]*),//){
      push @cols, $1;
    }else{
      push @cols, $csv;
      $csv = '';
    }
  }
  return @cols;
}
sub formatSong(\@){
  my @cols = @{shift()};
  return "$cols[0] - $cols[2]";
}

sub showQuery(){
  system "clear";
  my @size = Term::ReadKey::GetTerminalSize;
  my $width = $size[0];
  my $lines = $size[1];
 
  my $columns = 1;#1 + int($width / 100);

  my $limit = ($lines-5)*$columns + $offset;
  my $q = $query;
  $q =~ s/'/'\\''/g;
  
  my $colWidth = $width / $columns - 1;
  
  my @songs = `$QDBEXEC $QDB -s '$q' -l $limit -m awesomebar`;
  @songs = @songs[$offset .. $#songs];
  my $len = @songs + 0;
  for(my $i=0; $i<$len; $i++){
    my $song = $songs[$i];
    chomp $song;
    my @cols = parseCsv($song);
    $song = formatSong @cols;
    $songs[$i] = $song;
    $len -= int((length $song) / $colWidth)*$columns;
  }
  %selections = ();
  @all_songs = ();

  my $maxColLen = $len/$columns;
  $maxColLen += 1 if $len % $columns > 0;

  my @cols;
  for(my $col=0; $col<$columns; $col++){
    push @cols, ();
    my $start = $col*$maxColLen;
    my $end = ($col+1)*$maxColLen;
    $end = $len if $end +1 > $len;
    for(my $s=$start; $s<$end; $s++){
      my $song = $songs[$s];
      if($s < @sels){
        $selections{$sels[$s]} = $songs[$s];
      }
      push @all_songs, $song;
      push @{$cols[$col]}, $song;
    }
  }

  for(my $i=0; $i<$maxColLen; $i++){
    for(my $col=0; $col<$columns; $col++){
      my @curCol = @{$cols[$col]};
      my $disp = '';
      if($i <= $#curCol){
        $disp = $curCol[$i];
      }

      my @lines;
      for(my $i=0; $i<length $disp; $i+=$colWidth ){
        push @lines, substr $disp, $i, $colWidth;
      }
      
      $disp = '';
      for(my $i=0; $i<@lines; $i++){
        $disp .= $lines[$i];
        if($i == $#lines){
          $disp .= ' ' x ($colWidth - length $lines[$i]);
        }else{
          $disp .= "\n" . ' 'x(($colWidth+1)*$col);
        }
      }
      
      $disp .= '|' if $columns > 1;
      print $disp;
    }
    print "\n";
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
    }elsif($cmd eq 'UP'){
      $offset--;
      $offset = 0 if $offset < 0;
    }elsif($cmd eq 'DOWN'){
      $offset++;
    }elsif($cmd eq 'LEFT'){
      if($pos > 0){
        $pos--;
      }
    }elsif($cmd eq 'RIGHT'){
      if($pos < length $query){
        $pos++;
      }
    }elsif($cmd eq 'PGUP'){
      $offset = 0;
    }elsif($cmd eq 'HOME'){
      $pos = 0;
    }elsif($cmd eq 'END'){
      $pos = length $query;
    }elsif($cmd eq 'ENTER'){
      print "  selection: (enter again for all, space to toggle shuffle)\n";
      my $key = ord key;
      my $shuffle = 'off';
      while($key == 32){
        $shuffle = $shuffle eq 'on' ? 'off' : 'on';
        print "shuffle is $shuffle\n";
        $key = ord key;
      }
      if($key == 10){
        chdir '/home/wolke/Desktop/Music/Library';
        if($shuffle eq 'on'){
          BEGIN {
            eval {
              use List::Util 'shuffle'; 
            };
          };
          @all_songs = List::Util::shuffle(@all_songs);
        }
        system 'mplayer', @all_songs;
      }else{
        my $path = $selections{lc chr $key};
        chdir '/home/wolke/Desktop/Music/Library';
        system 'mplayer', $path;
      }
    }
  }else{
    my $prefix = substr $query, 0, $pos;
    my $suffix = substr $query, $pos;
    $query = "$prefix$choice$suffix";
    $pos += length $choice;
  }
  showQuery;
}


