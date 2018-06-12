package Klomp::History;
use strict;
use warnings;
use Klomp::Config;

sub getDateCache();
sub getFiles();
sub getCommits();
sub getCommitInfo($);
sub getHistoryDir();
sub checkHistoryDir();
sub gitLibsRun(@);

sub getDateCache(){
  return undef if not checkHistoryDir;

  my @files = getFiles();
  my @commits = getCommits();

  my %fileCommit;

  my $commitInfo = {};
  for my $c(@commits){
    $$commitInfo{$c} = getCommitInfo $c;
    for my $file(@{$$commitInfo{$c}{files}}){
      next if $file !~ s/^("?)libs\//$1/;
      if(not defined $fileCommit{$file}){
        $fileCommit{$file} = $c;
      }
    }
  }

  my $cnt = 0;
  for my $file(@files){
    if(not defined $fileCommit{$file}){
      print "$file\n";
    }else{
      $cnt++;
    }
  }

  my $dateCache = {};

  for my $file(@files){
    my $path = $file;
    if($path =~ /^".*"$/){
      $path =~ s/^"//;
      $path =~ s/"$//;
      $path =~ s/\\"/"/g;
      $path =~ s/\\\\/\\/g;
    }
    $$dateCache{$path} = $$commitInfo{$fileCommit{$file}}{date};
  }

  return $dateCache;
}

sub getFiles(){
  return gitLibsRun "ls-files";
}

sub getCommits(){
  return gitLibsRun "log", "--format=format:%H", ".";
}

sub getCommitInfo($){
  my $commit = shift;
  return {
    files => [gitLibsRun(
      "diff-tree", "--root", "--no-commit-id", "--name-only", "-r", $commit
    )],
    date => gitLibsRun(
      "log", "-n", "1", "--format=format:%at", $commit
    ),
  };
}

sub getHistoryDir(){
  return Klomp::Config::getProperty('history');
}

sub checkHistoryDir(){
  my $d = getHistoryDir();
  if(defined $d and -d $d and -d "$d/.git" and -d "$d/libs"){
    return 1;
  }else{
    return 0;
  }
}

sub gitLibsRun(@){
  my $historyDir = getHistoryDir();
  open FH, "-|", "cd \"$historyDir/libs\"; git -c core.quotepath=false @_";
  my @lines = <FH>;
  close FH;
  chomp foreach @lines;
  return @lines;
}

1;
