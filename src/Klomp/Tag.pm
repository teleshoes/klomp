package Klomp::Tag;
use strict;
use warnings;

my $MPEG_LIB = eval{system "command -v AtomicParsley >/dev/null"; $? == 0};
my $MP3_LIB = eval{system "command -v mid3v2 >/dev/null"; $? == 0};
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
    if($col =~ /^title$/){
      $guess = $filename;
      $guess =~ s/\.[a-z0-9]{1,5}$//i;
      $guess =~ s/^[0-9 \-_]+//;
    }elsif($col =~ /^(artist|albumartist)$/){
      $guess = $outerDir;
    }elsif($col =~ /^album$/){
      $guess = $innerDir;
    }elsif($col =~ /^number$/){
      if($filename =~ /^\s*(\d+)\s*/){
        $guess = $1;
      }
    }elsif($col =~ /^date$/){
      if($pathHint =~ /(19\d\d|20\d\d)/){
        $guess = $1;
      }
    }
  }

  if($col eq 'number'){
    #guess should be integral and contain exactly five digits if possible
    my $num;
    if($guess =~ /^(\d+)/){
      $num = $1;
    }elsif($valueHint =~ /^(\d+)/){
      $num = $1;
    }
    $guess = ('0' x (5 - length $num)) . $num if defined $num;
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

sub readMid3v2($){
  my $mid3v2Output = shift;
  my $frames = {
    title => [
      [TIT2 => "Title"],
      [TIT3 => "Subtitle/Description refinement"],
      [TIT1 => "Content group description"],
      [TSOT => "Title Sort Order key"],
    ],
    artist => [
      [TPE1 => "Lead Artist/Performer/Soloist/Group"],
      [TPE2 => "Band/Orchestra/Accompaniment"],
      [TPE3 => "Conductor"],
      [TPE4 => "Interpreter/Remixer/Modifier"],
      [TCOM => "Composer"],
      [TOPE => "Original Artist/Performer"],
      [TMCL => "Musicians Credits List"],
      [TIPL => "Involved People List"],
      [TSO2 => "iTunes Album Artist Sort"],
      [TSOP => "Perfomer Sort Order key"],
      [TSOC => "iTunes Composer Sort"],
    ],
    albumartist => [
      [TPE2 => "Band/Orchestra/Accompaniment"],
      [TPE3 => "Conductor"],
      [TCOM => "Composer"],
      [TPE4 => "Interpreter/Remixer/Modifier"],
    ],
    album => [
      [TALB => "Album"],
      [TOAL => "Original Album"],
      [TSOA => "Album Sort Order key"],
    ],
    disc => [
      [TPOS => "Part of a set"],
    ],
    number => [
      [TRCK => "Track Number"],
    ],
    date => [
      [TYER => "Year of recording"],
      [TORY => "Original Release Year"],
      [TRDA => "Recording Dates"],
      [TDRL => "Release Time"],
      [TDRC => "Recording Time"],
      [TIME => "Time of recording (HHMM)"],
      [TDAT => "Date of recording (DDMM)"],
      [TDOR => "Original Release Time"],
      [TDTG => "Tagging Time"],
      [TDEN => "Encoding Time"],
    ],
    genre => [
      [TCON => "Content type (Genre)"],
      [TMOO => "Mood"],
    ],
  };

  #remove the descs
  map {map {pop @$_} @$_} values %$frames;
  #flatten the single-element arrays
  for my $tag(keys %$frames){
    my @fs = map {@$_} @{$$frames{$tag}};
    $$frames{$tag} = \@fs;
  }

  my %parsedFrames;
  for my $tag(keys %$frames){
    for my $frame(@{$$frames{$tag}}){
      if($mid3v2Output =~ /^$frame=(.*)/m){
        $parsedFrames{$frame} = $1;
      }
    }
  }

  my %info;
  for my $tag(keys %$frames){
    $info{$tag} = '';
    for my $frame(@{$$frames{$tag}}){
      if(defined $parsedFrames{$frame}){
        my $t = $parsedFrames{$frame};
        $t =~ s/^[ \t\n\/]*//;
        $t =~ s/[ \t\n\/]*$//;
        $info{$tag} = $t;
        last;
      }
    }
  }
  if(defined $parsedFrames{TYER} and defined $parsedFrames{TDAT}){
    my $y = $parsedFrames{TYER};
    my $dm = $parsedFrames{TDAT};

    my $year;
    if($y =~ /^\s*(\d+)\s*$/){
      $year = $1;
    }else{
      $year = $y;
    }

    if($dm =~ /^\s*(\d\d)[ =_\/\-]*(\d\d)\s*$/){
      my ($month, $day) = ($2, $1);
      $info{date} = "$year-$month-$day";
    }else{
      $info{date} = "$year $dm";
    }
  }
  return \%info;
}

sub readTags($){
  my $file = shift;
  my $path = $file;
  $file =~ s/'/'\\''/g;

  my $title='';
  my $artist='';
  my $albumartist='';
  my $album='';
  my $disc='';
  my $number='';
  my $date='';
  my $genre='';
  if($file =~ /\.mp3$/i){
    if($MP3_LIB){
      my $mid3v2 = `mid3v2 '$file'`;
      my %m = %{readMid3v2 $mid3v2};
      ($title, $artist, $albumartist, $album, $disc, $number, $date, $genre) = (
        $m{title}, $m{artist}, $m{albumartist},
        $m{album}, $m{disc}, $m{number}, $m{date}, $m{genre});
    }else{
      print STDERR "WARNING: no tags for $file, missing mid3v2\n";
    }
  }elsif($file =~ /\.(ogg|flac)$/i){
    if($OGG_FLAC_LIB){
      my $lltag = `lltag -S '$file'`;
      $title       = $1 if $lltag =~ m/^\s*TITLE=(.*)$/mix;
      $artist      = $1 if $lltag =~ m/^\s*ARTIST=(.*)$/mix;
      $albumartist = $1 if $lltag =~ m/^\s*ALBUMARTIST=(.*)$/mix;
      $album       = $1 if $lltag =~ m/^\s*ALBUM=(.*)$/mix;
      $disc        = $1 if $lltag =~ m/^\s*DISCNUMBER=(.*)$/mix;
      $number      = $1 if $lltag =~ m/^\s*NUMBER=(.*)$/mix;
      $number      = $1 if $lltag =~ m/^\s*TRACKNUMBER=(.*)$/mix;
      $date        = $1 if $lltag =~ m/^\s*DATE=(.*)$/mix;
      $genre       = $1 if $lltag =~ m/^\s*GENRE=(.*)$/mix;
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
      $title       = $tags{$tag} if $tag =~ m/^TITLE$/mix;
      $artist      = $tags{$tag} if $tag =~ m/^AUTHOR$/mix;
      $albumartist = $tags{$tag} if $tag =~ m/^ALBUMARTIST$/mix;
      $album       = $tags{$tag} if $tag =~ m/^ALBUMTITLE$/mix;
      $disc        = $tags{$tag} if $tag =~ m/^PARTOFSET$/mix;
      $number      = $tags{$tag} if $tag =~ m/^TRACKNUMBER$/mix;
      $date        = $tags{$tag} if $tag =~ m/^YEAR$/mix;
      $genre       = $tags{$tag} if $tag =~ m/^GENRE$/mix;
    }
  }elsif($file =~ /\.(mp4|m4a|m4p|m4v|m4b)$/i){
    if($MPEG_LIB){
      my $atomic = `AtomicParsley '$file' -t`;
      $title       = $1 if $atomic =~ m/^Atom\ "©NAM"\ contains:\ (.*)$/mix;
      $artist      = $1 if $atomic =~ m/^Atom\ "©ART"\ contains:\ (.*)$/mix;
      $albumartist = $1 if $atomic =~ m/^Atom\ "aART"\ contains:\ (.*)$/mix;
      $album       = $1 if $atomic =~ m/^Atom\ "©ALB"\ contains:\ (.*)$/mix;
      $disc        = $1 if $atomic =~ m/^Atom\ "disk"\ contains:\ (.*)$/mix;
      $number      = $1 if $atomic =~ m/^Atom\ "trkn"\ contains:\ (.*)$/mix;
      $date        = $1 if $atomic =~ m/^Atom\ "©day"\ contains:\ (.*)$/mix;
      $genre       = $1 if $atomic =~ m/^Atom\ "(?:gnre|©gen)"\ contains:\ (.*)$/mix;
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
    albumartist => $albumartist,
    album => $album,
    disc => $disc,
    number => $number,
    date => $date,
    genre => $genre);
}

1;
