package Klomp::Tag;
use strict;
use warnings;

my $MPEG_LIB = eval{system "command -v AtomicParsley >/dev/null"; $? == 0};
my $MP3_LIB = eval{system "command -v eyeD3 >/dev/null"; $? == 0};
my $OGG_FLAC_LIB = eval{system "command -v lltag >/dev/null"; $? == 0};
my $WMA_LIB = eval{require Audio::WMA};
BEGIN{
  if(eval {require Audio::WMA}){
    require Audio::WMA; 
    Audio::WMA->import;
  }
}
my $UNIDECODE_LIB = eval {require Text::Unidecode};
BEGIN{
  if(eval {require Text::Unidecode}){
    require Text::Unidecode;
    Text::Unidecode->import;
  }
}
my $JAPANESE_LIB = eval {require Lingua::JA::Romanize::Japanese};
BEGIN{
  if(eval {require Lingua::JA::Romanize::Japanese}){
    require Lingua::JA::Romanize::Japanese;
    Lingua::JA::Romanize::Japanese->import;
  }
}

sub guess($$$);
sub transliterateJapanese($);
sub transliterateAscii($);
sub readTags($);

sub guess($$$){
  my $col = shift;
  my $pathHint = shift;
  my $valueHint = shift;

  my ($filename, $innerDir, $outerDir);
  if($pathHint =~ /([^\/]*) \/ ([^\/]*) \/ ([^\/]*)$/x){
    ($filename, $innerDir, $outerDir) = ($3, $2, $1);
  }elsif($pathHint =~ /([^\/]*) \/ ([^\/]*)$/x){
    ($filename, $innerDir, $outerDir) = ($2, '', $1);
  }elsif($pathHint =~ /([^\/]*)$/x){
    ($filename, $innerDir, $outerDir) = ($1, '', '');
  }

  my $guess = '';

  if(length $valueHint > 0){
    $guess = transliterateJapanese $valueHint if $guess eq '';
    $guess = transliterateAscii $valueHint if $guess eq '';
  }else{
    if($col eq 'title'){
      $guess = $filename;
      $guess =~ s/\.[a-z0-9]{1,5}$//i;
      $guess =~ s/^[0-9 \-_]+//;
    }elsif($col eq 'artist'){
      $guess = $outerDir;
    }elsif($col eq 'album'){
      $guess = $innerDir;
    }elsif($col eq 'number'){
      if($filename =~ /^\s*(\d+)\s*/){
        $guess = $1;
      }
    }elsif($col eq 'date'){
      if($pathHint =~ /(19\d\d|20\d\d)/){
        $guess = $1;
      }
    }
  }

  return $guess;
}

sub transliterateJapanese($){
  return '' if not $JAPANESE_LIB;
  my $arg = shift;
  if(length $arg == 0){
    return $arg;
  }
  utf8::decode($arg);
  my @parts;
  my $theRest;
  while($arg =~/
      (.*?)
      ((?:\p{Hiragana}|\p{Katakana}|\p{Han})+)
      (?=(.*$))
    /gsxi){
    my $nonjap = $1;
    my $jap = $2;
    $theRest = $3;
    my $conv = Lingua::JA::Romanize::Japanese->new();
    my $romaji = $conv->chars($jap);

    push @parts, $nonjap;
    if(not $? and defined $romaji){
      $romaji =~ s/\s+//g;
      push @parts, $romaji;
    }else{
      push @parts, $jap;
    }
  }
  utf8::encode($arg);
  if(@parts > 0){
    push @parts, $theRest;
    my $res = join '', @parts;
    utf8::encode($res);
    return $res;
  }
  return '';
}

sub transliterateAscii($){
  return '' if not $UNIDECODE_LIB;
  my $arg = shift;
  return '' if $arg eq '';
  
  my $oldArg = $arg;

  utf8::decode($arg);
  $arg = unidecode $arg;
  utf8::encode($arg);
  
  if($oldArg eq $arg){
    return '';
  }else{
    return $arg;
  }
}

sub readTags($){
  my $file = shift;
  my $path = $file;
  $file =~ s/'/'\\''/g;

  my $title='';
  my $artist='';
  my $album='';
  my $number='';
  my $date='';
  my $genre='';
  if($file =~ /\.mp3$/i){
    if($MP3_LIB){
      my $eyeD3 = `eyeD3 --no-color '$file'`;
      $eyeD3 =~ s/\t\t/\n/g;

      $title  = $1 if $eyeD3 =~ /^title: (.*)/mi;
      $artist = $1 if $eyeD3 =~ /artist: (.*)\n/mi;
      $album  = $1 if $eyeD3 =~ /^album: (.*)$/mi;
      $number = $1 if $eyeD3 =~ /^track: (.*)$/mi;
      $date   = $1 if $eyeD3 =~ /^year: (.*)$/mi;
      $genre  = $1 if $eyeD3 =~ /^genre: (.*)$/mi;

      $genre =~ s/ \(id \d+\)$//; #trim the genre id
    }else{
      print STDERR "WARNING: no tags for $file, missing eyeD3\n";
    }
  }elsif($file =~ /\.(ogg|flac)$/i){
    if($OGG_FLAC_LIB){
      my $lltag = `lltag -S '$file'`;
      $title  = $1 if $lltag =~ m/^\s*TITLE=(.*)$/mix;
      $artist = $1 if $lltag =~ m/^\s*ARTIST=(.*)$/mix;
      $album  = $1 if $lltag =~ m/^\s*ALBUM=(.*)$/mix;
      $number = $1 if $lltag =~ m/^\s*NUMBER=(.*)$/mix;
      $date   = $1 if $lltag =~ m/^\s*DATE=(.*)$/mix;
      $genre  = $1 if $lltag =~ m/^\s*GENRE=(.*)$/mix;
    }else{
      print STDERR "WARNING: no tags for $file, missing lltag\n";
    }
  }elsif($file =~ /\.(wma)$/i){
    my %tags;
    if($WMA_LIB){
      my $wma  = Audio::WMA->new($path);
      %tags = %{$wma->tags()};
    }else{
      print STDERR "WARNING: no tags for $file, missing Audio::WMA\n";
    }

    for my $tag(keys %tags) {
      $title  = $tags{$tag} if $tag =~ m/^TITLE$/mix;
      $artist = $tags{$tag} if $tag =~ m/^ALBUMARTIST$/mix;
      $artist = $tags{$tag} if $tag =~ m/^AUTHOR$/mix;
      $album  = $tags{$tag} if $tag =~ m/^ALBUMTITLE$/mix;
      $number = $tags{$tag} if $tag =~ m/^TRACKNUMBER$/mix;
      $date   = $tags{$tag} if $tag =~ m/^YEAR$/mix;
      $genre  = $tags{$tag} if $tag =~ m/^GENRE$/mix;
    }
  }elsif($file =~ /\.(mp4|m4a|m4p|m4v|m4b)$/i){
    if($MPEG_LIB){
      my $atomic = `AtomicParsley '$file' -t`;
      $title  = $1 if $atomic =~ m/^Atom\ "©NAM"\ contains:\ (.*)$/mix;
      $artist = $1 if $atomic =~ m/^Atom\ "©ART"\ contains:\ (.*)$/mix;
      $album  = $1 if $atomic =~ m/^Atom\ "©ALB"\ contains:\ (.*)$/mix;
      $number = $1 if $atomic =~ m/^Atom\ "trkn"\ contains:\ (.*)$/mix;
      $date   = $1 if $atomic =~ m/^Atom\ "©day"\ contains:\ (.*)$/mix;
      $genre  = $1 if $atomic =~ m/^Atom\ "(?:gnre|©gen)"\ contains:\ (.*)$/mix;
    }else{
      print STDERR "WARNING: no tags for $file, missing AtomicParsley\n";
    }
  }elsif($file =~ /\.wav$/i){
    #so wavs apparently have RIFF tags, but ive never seen em
  }else{
    print STDERR "Not a filetype we know how to read tags from: $path";
  }

  return (
    title => $title,
    artist => $artist,
    album => $album,
    number => $number,
    date => $date,
    genre => $genre);
}

1;