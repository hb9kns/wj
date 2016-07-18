#!/bin/sh
info='wj (workjournal) // 2016-07-17 Y.Bonetti // see gitlab.com/yargo/wj'
wjf="${WJCOUNTERS:-$HOME/.wjcounters}"
tmpf="$wjf.tmp"
bupf="$wjf.bak"

# now as seconds since epoch (1970-1-1)
now=`date +%s`

# define usage information
showhelp() { cat <<EOH

## $info ##

usage: $0 [-command/option [-option ...]] [counter [counter ...]]

 -h[elp] : this help
 -r[eport] : display current status of counters, also if no argument given
 -[stop] : stop all counters (note: also a single '.' will do)
 -c[ontinue] : start all given counters, while also keeping running counters
 -q[uiet] : don't prompt for any user input
 -a[dd]M : add M minutes to all given counters (last -a option overrides all)
 -zero : reset all counters to zero
 if no command given, start all counters given and stop running ones

- counter values are displayed as hours:minutes=totalminutes
- all counter names yet unknown are prompted for, unless -q option is given
- option -a can be used for correcting/preloading counters (e.g -a20 or -a-5)
- more than one command given may result in unexpected behaviour, except for -q

counters are stored in '$wjf'
with backup in '$bupf'

EOH
} # showhelp

# append current line to tmpf, using global variables
# cnt (name), csum (sum of minutes), cstart (start time), crem (remarks)
writeln() { echo "$cnt	$csum	$cstart	$crem" >> "$tmpf" ; }

# start counter and add minutes given as argument
cntstart() {
#echo : before cntstart: $cnt $csum $cstart
# add argument, if present
 csum=`expr $csum + ${1:-0}`
# current start time = 0 ?
 if test X$cstart = X0
# then start at current number of seconds since epoch (1970-Jan-1)
 then cstart=$now
# else don't change anything, counter already running
 fi
#echo : after cntstart: $cnt $csum $cstart
}

# stop counter and add lapsed minutes
cntstop() {
#echo : before cntstop: $cnt $csum $cstart
# current start time != 0 ?
 if test X$cstart != X0
 then
# calculate lapsed minutes
  csum=`expr '(' $now - $cstart + 30 ')' / 60 + $csum`
# and stop counter
  cstart=0
# else don't change anything, counter already stopped
 fi
#echo : after cntstop: $cnt $csum $cstart
}

# convert minutes for report
calctime() {
 local hrs mins
 hrs=`expr ${1:-0} / 60`
 mins=`expr ${1:-0} % 60`
 if test $mins -le 9
 then mins="0$mins"
 fi
 echo "$1 ($hrs:$mins)"
}


showreport() {
cat "$wjf" | { totmin=0 ; summin=0
 while read cnt csum cstart crem
 do case $cnt in
  ''|'#') ;; # skip comments and empty lines
  *) totmin=`expr $totmin + $csum`
# add all mentioned counters
   if `echo "$cntrs" | grep " $cnt " >/dev/null 2>&1`
   then summin=`expr $summin + $csum`
   fi
   echo "$cnt	`calctime $csum`	$crem"
   ;;
  esac
 done
 echo
 echo "	total: `calctime $totmin`"
# remove leading and trailing SPCs
 cntrs=${cntrs## }
 cntrs=${cntrs%% }
 if test "$cntrs" != ""
 then echo "	$cntrs=" | tr ' ' +
 calctime $summin | sed -e 's/^/		/'
 fi
 }
} # showreport

# if no argument at all, display report and hint for help
if test "$1" = ""
then showreport
 echo '# option -h for help'
 exit 1
fi

# read all arguments
while test "$1" != ""
do case $1 in
 -h*) showhelp ; exit 1 ;;
 -q*) quiet=yes ;;
 -r*) report=yes ;;
 -c*) continue=yes ;;
 -zero) allzero=yes ;;
 -a*) addmins=${1#-a} ;;
 -) allstop=yes ;;
 -*) echo ":: ignoring unknown command/option $1" ;;
 *) cntrs="$cntrs $1" ;;
 esac
shift
done

# surround counters string with SPC for pattern matching
cntrs="$cntrs "

addmins=`echo "$addmins"|tr -cd '0-9-'`
addmins=$((addmins+0))
if test $addmins != 0
then echo addmins=$addmins
fi

# initialize workjournal if not readable
if test ! -r "$wjf"
then cat <<EOH > "$wjf"
# initialized on `date` by
# $info
EOH
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
  then crem='# [unknown]'
  else
   echo "counter $cnt yet unknown, please enter description:"
   read crem
   crem="# $crem"
  fi # quiet
# add counter entry
  writeln
 fi # grep
done

# append new counters to journal (might be empty)
cat "$tmpf" >> "$wjf"
# clear tmpfile for next pass
: > "$tmpf"

# report should not change anything, therefore finish after display
if test X$report = Xyes
then showreport
 rm -f "$tmpf"
 exit
fi

if test "$cntrs" != ""
then echo counters: $cntrs
fi

# process workjournal lines
cat "$wjf" | { while read cnt csum cstart crem
do case $cnt in
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
   fi
   writeln
   ;;
 esac
done
}

# save updated journal file
cat "$tmpf" > "$wjf"

rm -f "$tmpf"