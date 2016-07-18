#!/usr/bin/env perl
# work journal
$Id='$Id: wj,v 1.3 2007/09/07 18:08:44 yargo Exp $';

$BackupExt='~';
$Taskpattern='[0-9a-zA-Z][-_.+0-9a-zA-Z]*';# pattern for task names
$Tasksplit='[.]';# split character for task names
                 # must be contained in $Taskpattern
$launchmin=int(time/60);# absolute minutes at program start
$totalmin=0;
$report=0;
$reset=0;
$verbose=0;
$HOME=($ENV{'HOME'} ne '')?$ENV{'HOME'}:'.';

$task='';# no args given -> stop all tasks

$Jfile=($ENV{'WORKJOURNAL'} ne '')?$ENV{'WORKJOURNAL'}:$HOME.'/.wjournal.dat';
$splitreport=($ENV{'WORKJOURNAL_SPLIT'} ne '')?1:0;

while( $#ARGV>=0 ){
 $arg=shift @ARGV;
 if( $arg=~/^\-+h/ ){# help
  die <<"+EOH+"
usage: $0 [-h] [-r|-R] [-v] [-j file] [task]
work journalling program to count minutes for tasks/projects worked on
    (${Id})
-h: this help
-r: report hours
-R: report hours and reset counters to zero (be careful..)
-s: split reports into those parts of tasknames which are separated by $Tasksplit
    (will be set by default if WORKJOURNAL_SPLIT is set in the environment)
-v: verbose output to stderr (tell what doing)
-j file: change journal file (instead of $Jfile)
         (if WORKJOURNAL is set in the environment, its contents will be used)
task: name of task to start (all others will be stopped)
      task names may consist of the pattern $Taskpattern
	NOTE: If no task is given, all will be stopped!
+EOH+
;
  }
 elsif( $arg=~/^\-+j/ ){# journal file
  $arg=shift @ARGV;
  if( $arg ne '' ){ $Jfile=$arg; }
  }
 elsif( $arg=~/^\-+r/ ){# report only
  $report=1; $reset=0;
  }
 elsif( $arg=~/^\-+s/ ){# split report
  $report=1; $splitreport=1;
  }
 elsif( $arg=~/^\-+R/ ){# report and reset
  $report=1; $reset=1;
  }
 elsif( $arg=~/^\-+v/ ){# verbose
  $verbose=1;
  }
 elsif( $arg=~/^\-/ ){# unknown option
  warn( "[unknown option: $arg]\n" );
  }
 elsif( $arg!~/^${Taskpattern}$/g ){# task name check
  warn( "[illegal character(s) in task name: $arg]\n" );
  }
 else{ $task=$arg; }
 }

print STDERR "[actual time: $launchmin min]\n" if( $verbose );

if( -e $Jfile.$BackupExt ){
 if( -o $Jfile.$BackupExt && -f $Jfile.$BackupExt ){
  unlink $Jfile.$BackupExt if( -e $Jfile);
  }
 else{ die $Jfile.$BackupExt." is not owned or not plain file!\n"; }
 }

if( -e $Jfile ){
 if( -o $Jfile && -f $Jfile ){
  rename $Jfile,$Jfile.$BackupExt;
  }
 else{ die $Jfile." is not owned or not plain file!\n"; }
 }
else{
 if( $task ne '' ){
  open(OLD,'>'.$Jfile.$BackupExt) ||
   die "cannot create new file $Jfile.$BackupExt !\n";
  print OLD "# created by $0 (2001..2007 YCB)\n";
  print OLD "# task minutes start-time[minutes]\n";
  print OLD $task." 0\n";# initialize file with task line
  close OLD;
  }
 else{
  die "no file yet and no task given, so there..\n";
  }
 }

open(OLD,'<'.$Jfile.$BackupExt) || die "cannot open ${Jfile}${BackupExt}!\n";
open(NEW,'>'.$Jfile) || die "cannot open ${Jfile} for writing!\n";

$taskfound=0;
@st=();
%subtask=();

while( <OLD> ){
 if( /^\s*\#/ ){# comment line
  print NEW $_;
  if( $report ){ print STDOUT $_; }
  }
 elsif( /^\s*(${Taskpattern})\s+(\d+)/o ){# task line
  $t=$1; $min=0+$2;# task and total of minutes
  $start=$';# start time (if present)
  if( $start=~/(\d+)/ ){# absolute minutes
   $start=0+$start;
   }
  else{ $start=''; }
  print STDERR "[$t : $min , $start]\n" if( $verbose);
  if( $report ){# stop tasks which are running and report total time
   $dmin=($start ne '')?abs($launchmin-$start):0;
   $min+=$dmin;
   $totalmin+=$min;
   $h=int($min/60); $m=$min-60*$h;
   if( $splitreport ){
    @st=split(/${Tasksplit}/o,$t,-1);# subparts of taskname
     # -1 -> split in unlimited number of fields
     # and preserve trailing empty fields
    $markpos='';
    foreach $s ( @st ){
     if( $s eq '' ){ $s='{unspecified}'; }# empty subtaskname
     $s=$markpos.$s; $markpos.=$Tasksplit;# mark position of subtask in task
     $subtask{$s}+=$min;# add minutes to each subtask
     }
    }
   elsif( $min>0 ){# only report tasks with more than 0min
    print STDOUT $t.'='.sprintf('%d:%02d',$h,$m)."\n";
    }
   if( $reset ){# reset is only allowed if report is given, anyway!
    print NEW '# reported '.$t.'='.sprintf('%d:%02d',$h,$m)." ($min min)\n";
    $min=0;
    }
   print STDERR "[stopping $t : $min (\+$dmin)]\n" if($verbose || ($dmin>0));
   $start='';
   }
  if( $task ne $t ){# not specified tasks
   if( $start ne ''){# stop them
    $dmin=abs($launchmin-$start);
    $min+=$dmin;
    print NEW $t.' '.$min."\n";
    print STDERR "[stopping $t : $min (\+$dmin)]\n";
    }
   else{# or keep them stopped
    print NEW $t.' '.$min."\n";
    print STDERR "[keeping stopped $t : $min]\n" if( $verbose);
    }
   }
  else{# task specified as argument
   if( $taskfound ){
    warn "found $task more than once! Only first instance processed.\n";
    }
   else{
    $taskfound=1;
    if( $start ne '' ){# keep it running
     print NEW $t.' '.$min.' '.$start."\n";
     print STDERR "[kept running $t : $min, $start]\n" if( $verbose);
     }
    else{# or start it
     print NEW $t.' '.$min.' '.$launchmin."\n";
     print STDERR "[started $t : $min, $launchmin]\n";
     }
    }
   }# task specified as argument
  }# task line
 }# while <OLD>

if( $taskfound==0 && $task!~/^\s*$/ ){# append new task line and start, if
# it is a real task name (not just empty)
 print NEW $task.' 0 '.$launchmin."\n";
 print STDERR "[installed (new) $task : 0, $launchmin]\n";
 }

if( $report ){
 if( $splitreport ){
  print STDOUT "# subtasks:\n";
  foreach $s ( sort keys %subtask ){
   if( $subtask{$s}>0 ){# only report subtasks with more than 0min
    $h=int($subtask{$s}/60); $m=$subtask{$s}-60*$h;
    print STDOUT ' ',$s,'='.sprintf('%d:%02d',$h,$m)."\n";
    }
   }
  }
 $h=int($totalmin/60); $m=$totalmin-60*$h;
 print STDOUT "------\ntotal=".sprintf('%d:%02d',$h,$m)."\n";
 }

close NEW;
close OLD;

