#! /usr/bin/perl
use strict;
use warnings;
use POSIX 'setsid';
use Term::ReadKey;

my $qdb = `echo -n \$HOME/.qdb`;
my $qdbExec = 'qdb';
my $flacmirrorExec = 'flacmirror';
my $lib = `echo -n \$HOME/Desktop/Music/Library`;
my $flacmirrorLib = `echo -n \$HOME/Desktop/Music/flacmirror`;

for my $line(`cat ~/.qprefs`){
  if($line =~ /^QDB=\s*(.*)/i){
    $qdb = `echo -n $1`;
  }elsif($line =~ /^QDB_EXEC=\s*(.*)/i){
    $qdbExec = `echo -n $1`;
  }elsif($line =~ /^FLACMIRROR_EXEC=\s*(.*)/i){
    $flacmirrorExec = `echo -n $1`;
  }elsif($line =~ /^LIB=\s*(.*)/i){
    $lib = `echo -n $1`;
  }elsif($line =~ /^FLACMIRROR_LIB=\s*(.*)/i){
    $flacmirrorLib = `echo -n $1`;
  }
}

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
        key; #generates a ~
        return 'PGUP';
      }elsif($key3 == 54){
        key; #generates a ~
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
  system "echo", "-e", "\\033[$line;${column}H"
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

sub formatClear($$){
  my $width = shift;
  my $height = shift;
  my $out = '';
  for(my $i=1; $i<=$height+1; $i++){
    $out .= "\\033[$i;0H" . ' 'x$width;
  }
  return $out;
}

sub formatLines(\@$$){
  my @lines = @{shift()};
  my $width = shift;
  my $height = shift;
 
  if($offset > $#lines){
    $offset = $#lines;
  }
  if($offset < 0){
    $offset = 0;
  }
  my $topLimit = $offset+$height-2;
  $topLimit = $#lines if $topLimit > $#lines;

  my $out = '';
  my $curLine = 2;
  for my $line(@lines[$offset .. $topLimit]){
    if(length $line > $width){
      $line = substr $line, 0, $width;
    }
    $out .= "\\033[$curLine;0H$line";
    $curLine++;
  }
  return $out;
}

sub showQuery(){
  my @size = Term::ReadKey::GetTerminalSize;
  my $width = $size[0];
  my $height = $size[1];
 
  #limit controls the number of elements returned
  my $limit = 2*$height + $offset;
  my $q = $query;
  $q =~ s/'/'\\''/g;
  
  my $columns = "artist album number title relpath";
  my @songRows = `$qdbExec $qdb -s '$q' -l $limit --columns $columns`;

  my %artists;
  for my $songRow(@songRows){
    chomp $songRow;
    my @cols = parseCsv($songRow);
    my ($artist, $album, $number, $title, $relpath, $libpath) = @cols;
    my $albums;
    if(not defined $artists{$artist}){
      my %hash;
      $albums = \%hash;
      $artists{$artist} = $albums;
    }else{
      $albums = $artists{$artist};
    }

    my $songs;
    if(not defined $$albums{$album}){
      my @arr;
      $songs = \@arr;
      $$albums{$album} = $songs;
    }else{
      $songs = $$albums{$album};
    }
    $number = '0'x(10 - length $number) . $number;
    push @{$songs}, "$number: $title";
  }

  my @lines;
  for my $artist(sort keys %artists){
    push @lines, "#$artist";
    my %albums = %{$artists{$artist}};
    for my $album(sort keys %albums){
      push @lines, " &$album";
      my @songs = @{$albums{$album}};
      @songs = sort @songs;
      for my $song(@songs){
        $song =~ s/^0*/  /;
        push @lines, "  $song";
      }
    }
  }
  
  my $promptLine = 1;
  my $promptCol = $pos+1;
  my $out = ''
    . formatClear($width, $height)
    . "\\033[$promptLine;0H"
    . substr($query, 0, $pos)
    . substr($query, $pos)
    . formatLines(@lines, $width, $height)
    . "\\033[$promptLine;${promptCol}H"
    ;

  system 'echo', '-ne', $out;
}

system "clear";
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
      my ($width, $height) = Term::ReadKey::GetTerminalSize;
      $offset -= $height;
    }elsif($cmd eq 'PGDN'){
      my ($width, $height) = Term::ReadKey::GetTerminalSize;
      $offset += $height;
    }elsif($cmd eq 'HOME'){
      $pos = 0;
    }elsif($cmd eq 'END'){
      $pos = length $query;
    }elsif($cmd eq 'ENTER'){
      system "clear";
      print "fetching\n";
      my $columns = "artist album number title relpath libpath";
      my @songRows = `$qdbExec $qdb -s '$query' --columns $columns`;
      my $len = scalar @songRows;
      my $shuffle = 'on';
      
      print "  play $len songs? space to toggle shuffle (shuffle is $shuffle):\n";
      my $key = key;
      while($key eq ' '){
        $shuffle = $shuffle eq 'on' ? 'off' : 'on';
        print " (shuffle is $shuffle)\n";
        $key = key;
      }

      my @files;
      for my $songRow(@songRows){
        chomp $songRow;

        my @cols = parseCsv($songRow);
        my ($artist, $album, $number, $title, $relpath, $libpath) = @cols;
        #replace last path item in lib with 'flacmirror', if flac file absent
        if(!-e "$libpath/$relpath" and $relpath =~ /\.flac$/i){
          $relpath =~ s/\.flac$/\.ogg/i;
          $libpath =~ s/\/[^\/]+$/\/flacmirror/;
        }
        push @files, "$libpath/$relpath";
      }

      if($shuffle eq 'on'){
        BEGIN {
          eval {
            use List::Util 'shuffle'; 
          };
        };
        @files = List::Util::shuffle(@files);
      }
      
      if($key eq 'p'){
        print "\n\nplaylist file: ";
        my $f = <STDIN>;
        open FH, "> $f";
        print FH join "\n", @files;
        print FH "\n";
        close FH;
      }
      if($key eq "\n"){
        system 'mplayer', @files;
      }
      system "clear";
    }
  }else{
    my $prefix = substr $query, 0, $pos;
    my $suffix = substr $query, $pos;
    $query = "$prefix$choice$suffix";
    $pos += length $choice;
  }
  showQuery;
}


