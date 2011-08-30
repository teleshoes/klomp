#! /usr/bin/perl
use strict;
use warnings;

use Term::ReadKey;
use Time::HiRes qw(time);
use List::Util 'shuffle'; 

sub fetch($);
sub loadPrefs();
sub key();
sub interpretKey($);
sub putCursor($$);
sub parseCsv($);
sub formatClear($$);
sub formatLines(\@$$);
sub showQuery();
sub gui();
sub getSomeKeys();

#prefs
our $keyDelay = 0.4;
our $QPREFS = `echo -n \$HOME/.qprefs`;
our $qdb = `echo -n \$HOME/.qdb`;
our $qdbExec = 'qdb';
our $flacmirrorExec = 'flacmirror';
our $lib = `echo -n \$HOME/Desktop/Music/Library`;
our $flacmirrorLib = `echo -n \$HOME/Desktop/Music/flacmirror`;
our $QLIST = `echo -n \$HOME/.qlist`;

#global state
our $pos = 0;
our $query = '';
our $offset = 0;

sub main(){
  loadPrefs;
 
  my $cmd = $ARGV[0];
  $cmd = '' if not defined $cmd;
  if($cmd !~ /^-(a|p|o|w|r)$/i){
    my $query = join ' ', @ARGV;
    system "clear";
    showQuery;
    while(1){
      gui();
    }
    exit 0;
  }

  shift @ARGV;

  my $query = join ' ', @ARGV;
  print "fetching query: $query\n";
  my @files = fetch $query;
  print scalar(@files) . " files\n";
  
  if($cmd eq lc $cmd){
    @files = List::Util::shuffle @files;
  }
  $cmd = lc $cmd;

  if($cmd eq '-a'){
    print "appending\n";
    appendQlist(\@files);
  }elsif($cmd eq '-p'){
    print "prepending\n";
    prependQlist(\@files, 'off');
  }elsif($cmd eq '-o'){
    print "overwriting\n";
    overwriteQlist(\@files);
  }elsif($cmd eq '-w'){
    print 
    print "making playlist with " . scalar(@files) . " files\n";
    print "write to file: ";
    my $file = <STDIN>;
    $file = `echo -n $file`; #is there a better way to do a shell interpret?
    open FH, "> $file" or die "could not open file $file\n";
    print FH join "\n", @files;
    print FH "\n" if @files > 0;
    close FH;
  }elsif($cmd eq '-r'){
    print "appending " . scalar(@files) . " files and reshuffling\n";
    prependQlist(\@files, 'on');
  }
}

sub loadPrefs(){
  for my $line(-e $QPREFS ? `cat ~/.qprefs` : ()){
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
}


sub putCursor($$){
  my $line = shift;
  my $column = shift;
  system "echo", "-e", "\\033[$line;${column}H"
}

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
    utf8::decode($songRow);
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

sub prependQlist($$){
  my @files = @{shift()};
  my $shuffle = shift;

  for my $file(@files){
    $file =~ s/\n*$/\n/;
  }
  
  my @existingFiles = -e $QLIST ? `cat $QLIST` : ();
  @files = (@files, @existingFiles);

  @files = List::Util::shuffle(@files) if $shuffle eq 'on';

  open FH, "> $QLIST" or die "Could not write to $QLIST";
  print FH @files;
  close FH;
}

sub overwriteQlist($){
  my @files = @{shift()};

  open FH, "> $QLIST" or die "Could not write to $QLIST";
  print FH join "\n", @files;
  print FH "\n" if @files > 0;
  close FH;
}

sub appendQlist($){
  my @files = @{shift()};

  open FH, ">> $QLIST" or die "Could not append to $QLIST";
  print FH join "\n", @files;
  print FH "\n" if @files > 0;
  close FH;
}

sub flacmirror($$){
  my $libpath = shift;
  my $relpath = shift;
  #replace last path entry with 'flacmirror'
  $libpath =~ s/\/[^\/]+$/\/flacmirror/;
  #replace .flac with .ogg, case insensitive on the 'flac'
  $relpath =~ s/\.flac$/\.ogg/i;
  return "$libpath/$relpath";
}

sub fetch($){
  my $query = shift;

  my $columns = "artist album number title relpath libpath";
  my @songRows = `$qdbExec $qdb -s '$query' --columns $columns`;
  
  my @files;
  for my $songRow(@songRows){
    chomp $songRow;

    my @cols = parseCsv($songRow);
    my ($artist, $album, $number, $title, $relpath, $libpath) = @cols;
    
    my $fullPath = "$libpath/$relpath";
    my $flacmirrorPath = flacmirror $libpath, $relpath;
    if(not -e $fullPath and -e $flacmirrorPath){
      push @files, $flacmirrorPath;
    }else{
      push @files, $fullPath;
    }
  }

  return @files;
}

sub prompt(\@){
  my @files = @{shift()};
  my $shuffle = 'on';

  print scalar(@files) . " files\n"
    . "space - toggle shuffle (currently $shuffle)\n"
    . "enter - append files to $QLIST and ensure playing\n"
    . "a     - append files to $QLIST\n"
    . "p     - prepend files to $QLIST 'Add to play queue'\n"
    . "o     - overwrite $QLIST with files\n"
    . "w     - write to a file you specify\n"
    . "r     - append files to $QLIST and (re)shuffle the whole thing\n"
    ;

  my $key = ReadKey 0;
  while($key eq ' '){
    $shuffle = $shuffle eq 'on' ? 'off' : 'on';
    print "shuffle is now $shuffle\n";
    $key = ReadKey 0;
  }

  if($shuffle eq 'on'){
    @files = List::Util::shuffle(@files);
  }

  if($key eq "\n"){
    appendQlist(\@files);
    system "qcmd start > /dev/null 2>/dev/null &";
  }elsif($key eq "a"){
    appendQlist(\@files);
  }elsif($key eq "p"){
    prependQlist(\@files, 'off');
  }elsif($key eq "o"){
    overwriteQlist(\@files);
  }elsif($key eq "w"){
    print "write to file: ";
    my $file = <STDIN>;
    $file = `echo -n $file`; #is there a better way to do a shell interpret?
    open FH, "> $file" or die "could not open file $file\n";
    print FH join "\n", @files;
    print FH "\n" if @files > 0;
    close FH;
  }elsif($key eq "r"){
    prependQlist(\@files, 'on');
  }
}

sub modifyQuery($){
  my $key = shift;
  if($key eq 'BACKSPACE'){
    if($pos > 0){
      my $prefix = substr $query, 0, $pos-1;
      my $suffix = substr $query, $pos;
      $query = "$prefix$suffix";
      $pos--;
    } 
  }elsif($key eq 'DELETE'){
    if($pos < length $query){
      my $prefix = substr $query, 0, $pos;
      my $suffix = substr $query, $pos+1;
      $query = "$prefix$suffix";
    }
  }elsif($key eq 'UP'){
    $offset--;
    $offset = 0 if $offset < 0;
  }elsif($key eq 'DOWN'){
    $offset++;
  }elsif($key eq 'LEFT'){
    if($pos > 0){
      $pos--;
    }
  }elsif($key eq 'RIGHT'){
    if($pos < length $query){
      $pos++;
    }
  }elsif($key eq 'PGUP'){
    my ($width, $height) = Term::ReadKey::GetTerminalSize;
    $offset -= $height;
  }elsif($key eq 'PGDN'){
    my ($width, $height) = Term::ReadKey::GetTerminalSize;
    $offset += $height;
  }elsif($key eq 'HOME'){
    $pos = 0;
  }elsif($key eq 'END'){
    $pos = length $query;
  }elsif($key eq 'ENTER'){
    my @files = fetch $query;
    system "clear";
    prompt @files;
    system "clear";
  }else{
    my $prefix = substr $query, 0, $pos;
    my $suffix = substr $query, $pos;
    $query = "$prefix$key$suffix";
    $pos += length $key;
  }
}

sub gui(){
  for my $key(@{getSomeKeys()}){
    modifyQuery $key;
  }
  showQuery;
}

sub getSomeInput(){
  ReadMode 3;
  my @bytes;
  my $start = time;
  while(1){
    my $byte = ReadKey(-1);
    last if not defined $byte and time - $start > $keyDelay;
    push @bytes, $byte if defined $byte;
  }
  return \@bytes;
}

#assumes utf8
sub getSomeKeys(){
  my $enter = 'ENTER';
  my $bkspc = 'BACKSPACE';
  my @cmds = (
    ['[', 'A'], 'UP',
    ['[', 'B'], 'DOWN',
    ['[', 'C'], 'RIGHT',
    ['[', 'D'], 'LEFT',
    ['O', 'H'], 'HOME',
    ['O', 'F'], 'END',
    ['[', '2', '~'], 'INSERT',
    ['[', '3', '~'], 'DELETE',
    ['[', '5', '~'], 'PGUP',
    ['[', '6', '~'], 'PGDN',
  );

  my @keys;
  my @bytes = @{getSomeInput()};
  for(my $i=0; $i<@bytes; $i++){
    if(ord $bytes[$i] == 0x1b){
      my $k1 = $i+1<=$#bytes ? $bytes[$i+1] : '';
      my $k2 = $i+2<=$#bytes ? $bytes[$i+2] : '';
      my $k3 = $i+3<=$#bytes ? $bytes[$i+3] : '';
      for(my $c=0; $c<@cmds; $c+=2){
        my @cmdArr= @{$cmds[$c]};
        my $cmd= $cmds[$c+1];
        if(@cmdArr == 2 and $cmdArr[0] eq $k1 and $cmdArr[1] eq $k2){
          push @keys, $cmd;
          $i+=2;
          last;
        }elsif(@cmdArr == 3 and
               $cmdArr[0] eq $k1 and
               $cmdArr[1] eq $k2 and
               $cmdArr[2] eq $k3){
          push @keys, $cmd;
          $i+=3;
          last;
        }
      }
    }elsif($bytes[$i] eq "\n"){
      push @keys, $enter;
    }elsif(ord $bytes[$i] == 0x7f){
      push @keys, $bkspc;
    }elsif(ord $bytes[$i] >= 0xc2 and ord $bytes[$i] <= 0xdf){
      my $b1 = $bytes[$i];
      my $b2 = $i+1<=$#bytes ? $bytes[$i+1] : '';
      my $key = "$b1$b2";
      $i+=1;
      utf8::decode($key);
      push @keys, $key; 
    }elsif(ord $bytes[$i] >= 0xe0 and ord $bytes[$i] <= 0xef){
      my $b1 = $bytes[$i];
      my $b2 = $i+1<=$#bytes ? $bytes[$i+1] : '';
      my $b3 = $i+2<=$#bytes ? $bytes[$i+2] : '';
      my $key = "$b1$b2$b3";
      $i+=2;
      utf8::decode($key);
      push @keys, $key;
    }else{
      push @keys, $bytes[$i];
    }
  }
  return \@keys;
}

&main;
