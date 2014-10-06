package Klomp::History;
use strict;
use warnings;
use Klomp::Lib;

sub getFiles();
sub getCommits();
sub getCommitInfo($);
sub getHistoryDir();
sub checkHistoryDir();
sub gitLibsRun(@);

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
  return ${Klomp::Lib::getProperties()}{'history'};
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
