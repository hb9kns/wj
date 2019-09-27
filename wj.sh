#!/bin/sh
info='wj (workjournal) // 2019-09-27 HB9KNS // git://dome.circumlunar.space/~hb9kns/wj'
wjf="${WJCOUNTERS:-$HOME/.wjcounters}"
tmpf=${TMPDIR:-/tmp}/.wj-$USER-$$.tmp
bupf="$wjf.bak"
editor=${VISUAL:-$EDITOR}
editor=${editor:-/bin/ed -p:}
# special counter name for grand total
cntot='-total-'

# now as seconds since epoch (1970-1-1) and as rounded minutes
now=`date +%s`
nowm=$(( ($now+30)/60 ))

# host running this script
hostn=${HOST:-`hostname`}

# define usage information
showhelp() { cat <<EOH

## $info ##

usage: $0 [-command/option ] [counter ...]

 -h[elp] : this help
 -e[dit] : open counter file with $editor, then report
 -r[eport] : display current status of counters (running are marked with '*')
 -p[ercentage] : same as r[eport], but with percentages of total
 -[stop] : stop all counters (note: also a single '.' will do)
 -c[ontinue] : start all given counters, while also keeping running counters
 -q[uiet] : don't prompt for any user input
 -a[dd]M : add M minutes to all given counters (last -a option overrides all)
 -zero : reset all counters to zero
 if no command given, start all counters given, stop running ones, and report
 if no argument given, report only

* counter values are displayed as "minutes (HH.D)" (hours.decihours)
* counter names yet unknown are prompted for, unless -q option is given
* option -a can be used for correcting/preloading counters (e.g -a20 or -a-5)
* counters are stored in file '$wjf'
  (or WJCOUNTERS), backup in '$bupf'
  (feel free to remove any unwanted counter with a text editor,
  but better not add/modify any lines to prevent malfunctioning)
EOH
} # showhelp

# append current line to tmpf, using global variables
# cnt (name), csum (sum of minutes), cstart (start time), crem (remarks)
writeln() { echo "$cnt	$csum	$cstart	$crem" >> "$tmpf" ; }

# start counter and add minutes given as argument
cntstart() {
#echo : before cntstart: $cnt $csum $cstart
# add argument, if present
 csum=$(( $csum+${1:-0} ))
# current start time = 0 ?
 if test X$cstart = X0
# then start at current number of minutes since epoch (1970-Jan-1)
 then cstart=$nowm
# else don't change anything, counter already running
 fi
#echo : after cntstart: $cnt $csum $cstart
}

# stop counter and add lapsed minutes
cntstop() {
 local delta
#echo : before cntstop: $cnt $csum $cstart
# current start time != 0 ?
 if test X$cstart != X0
 then
# calculate lapsed minutes
  delta=$(( $nowm-$cstart ))
  csum=$(( $csum+$delta ))
# and stop counter
  cstart=0
  echo : $cnt + $delta = $csum
# else don't change anything, counter already stopped
 fi
#echo : after cntstop: $cnt $csum $cstart
}

# convert minutes for report
calctime() {
 local hrs mins
 hrs=$(( ${1:-0}/60 ))
 mins=$(( ${1:-0}%60 ))
# decihours, rounded
 dhrs=$(( (${1:-0}+3)/6 ))
 dhrs=$(( $dhrs/10 )).$(( $dhrs%10 ))
 if test $mins -le 9
 then mins="0$mins"
 fi
# echo "$1 ($hrs:$mins)"
 echo "$1 ($dhrs)"
}

# convert into percentage for report
calcperc() {
 local p ps
# calculate to 1/10 percent with rounding
 p=$(( (10000*$1/$2+5)/10 ))
# insert dot before last figure
 ps=`echo $p|sed -e 's/\(.\)$/.\1/'`
# prepend 0 or leading spaces
 if test $p -lt 10
 then ps="0$ps"
 fi
 if test $p -lt 100
 then ps=" $ps"
 fi
 if test $p -lt 1000
 then ps=" $ps"
 fi
 echo "$ps"
}

# helper for showreport: only display if not only summing
echono() {
 if test "$1" = "no"
 then shift
  echo "$@"
 fi
}

# process workfile and show report with calculated hours and minutes
#  if argument 'onlysum' is given, calculate total without general counter
#  if arguments 'percent' 'NNNN' are given, show report with percentages
#   based on NNNN instead of absolute time
showreport() {
local os pbase
os=no
pbase=''
case $1 in
 onlysum) os=yes ;;
 percent) pbase=$2
  if test "$pbase" = "" -o "$pbase" = "0"
  then ":: error: cannot count percentage with base value of '$pbase'"
   pbase=''
  fi
  ;;
esac
echono $os
if test $os = no
then
 date '+## wj report at %c'
fi
cat "$wjf" | { totmin=0 ; summin=0
 while read cnt csum cstart crem
 do case $cnt in
  \#zeroed*) echono $os "###  $cnt $csum $cstart $crem" ; echono $os ;;
  ''|\#|\#*) ;; # skip comments and empty lines
# except for general counter...
  *) if test X$cnt != X$cntot
# ...add all to totmin
   then totmin=$(( $totmin+$csum ))
# ...add all mentioned to summin
    if `echo "$cntrs" | grep " $cnt " >/dev/null 2>&1`
    then summin=$(( $summin+$csum ))
    fi
   fi
   if test ${cstart:-0} -gt 0
# flag running counters
   then runflg='*'
   else runflg=''
   fi
   if test "$pbase" != ""
# report percent values relative to base
   then echono $os "$runflg$cnt	`calcperc $csum $pbase`	$runflg	$crem"
# report absolute values in mins and hours:mins
   else echono $os "$runflg$cnt	`calctime $csum`$runflg	$crem"
   fi
   ;;
  esac
 done
 echono $os
# remove general counter for summation
 cntrs=`echo "$cntrs" | sed -e "s/$cntot//g"`
# remove leading and trailing SPCs
 cntrs=${cntrs## }
 cntrs=${cntrs%% }
 if test "$cntrs" != "" -a $os = no
 then echo "	$cntrs=" | tr ' ' +
 calctime $summin | sed -e 's/^/		/'
 fi
# if onlysum, just report total time for further processing
 if test $os = yes
 then echo $totmin
 fi
 }
} # showreport


# initialize workjournal unless non-zero file
if test ! -s "$wjf"
then cat <<EOH > "$wjf"
# initialized on `date` by
# $info
#zeroed
#modified at initialization on $hostn
EOH
echo :: $wjf was empty and is now initialized
fi

# if no argument at all, display report and hint for help
if test "$1" = ""
then showreport
 echo '# option -h for help'
 exit 1
fi

# add general counter
cntrs=" $cntot"

# report current date for info
date '+# wj // %c' >&2

# read all arguments
while test "$1" != ""
do case $1 in
 -h*) showhelp ; exit 1 ;;
 -e*) $editor "$wjf" ; report=yes ;;
 -q*) quiet=yes ;;
 -r*) report=yes ;;
 -p*) percent=yes ; report=yes ;;
 -c*) continue=yes ;;
 -zero) allzero=yes ;;
 -a*) addmins=${1#-a} ;;
 -|'.') allstop=yes ;;
 -*) echo ":: ignoring unknown command/option $1" ;;
 *) cntrs="$cntrs $1" ;;
 esac
shift
done

# surround counters string with SPC for pattern matching
cntrs="$cntrs "

addmins=`echo "$addmins"|tr -cd '0-9-'`
addmins=$(( $addmins+0 ))
if test $addmins != 0
then echo ": add $addmins mins"
fi

# clear tempfile
: > "$tmpf"
# backup current journal
cat "$wjf" > "$bupf"

# preset values for new counters
csum=0
cstart=0

# look for yet unknown counter names
for cnt in $cntrs
# names must be at beginning of lines and followed by SPC or TAB
do if ! grep -e "^$cnt[	 ]" "$wjf" >/dev/null 2>&1
 then if test X$quiet = Xyes
  then if test X$cnt = X$cntot
   then crem='# general/total counter'
   else crem='# [unknown]'
   fi
  else
   echo ": counter '$cnt' unknown, description? (. will remove counter)"
   read crem
   crem="# $crem"
  fi # quiet
# add counter entry
  if test "$crem" = "# ."
  then echo ": counter $cnt not added!"
  else writeln
  fi
 fi # grep
done

# append new counters to journal (might be empty)
cat "$tmpf" >> "$wjf"
# clear tmpfile for next pass
: > "$tmpf"

if test X$percent = Xyes
# for percentage, first sum all counters
then pbase="percent `showreport onlysum`"
# else set empty base which will result in absolute values reported
else pbase=''
fi

# report should not change anything, therefore finish after display
if test X$report = Xyes
then showreport $pbase
 rm -f "$tmpf"
 exit
fi

# process workjournal lines
cat "$wjf" | { foundzeroed=no
while read cnt csum cstart crem
do case $cnt in
  '#zeroed') foundzeroed=yes
   if test X$allzero = Xyes
   then echo '#zeroed at' `date +%c` >> "$tmpf" # add start time
   else echo $cnt $csum $cstart $crem >> "$tmpf" # copy old start time
   fi ;;
  '#modified')
   echo '#modified' `date +%c` on $hostn >> "$tmpf" # add modification time
   ;;
  '#') echo $cnt $csum $cstart $crem >> "$tmpf" ;; # copy comment lines
  '') ;; # skip empty lines
  *) # process counter entry
# current counter given as argument ?
   if { echo "$cntrs" | grep -e " $cnt " >/dev/null 2>&1 ; }
   then cntstart $addmins
# stop unmentioned counters unless -continue
   else if test X$continue != Xyes
    then cntstop
    fi
   fi # current counter
# stop in any case if -[stop]
   if test X$allstop = Xyes
   then cntstop
   fi
# clear if -zero
   if test X$allzero = Xyes
   then csum=0 ; cstart=0
    if test X$foundzeroed = Xno
    then echo '#zeroed' >> "$tmpf"
    fi
   fi
   writeln
   ;;
 esac
done
}

# save updated journal file
cat "$tmpf" > "$wjf"

rm -f "$tmpf"
