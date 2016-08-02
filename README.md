# wj // work journal

This is a small shell script for keeping track of time spent on different
tasks or projects, with time resolution in minutes.

_While this README is under construction, running the script with option `-h` should give enough information for its use._

## file structure

The work journal file normally is named `$HOME/.wjcounters` and is of the
following structure:

	# comments
	-total-	0	0	# TOTAL
	cntr	123	0	# counter description

Lines not starting with `#` are counter lines, with fields separated by
`TAB` (^H).

- The first field is the counter index/name (only reasonable characters are allowed; your best bet is to use the set 0-9a-zA-Z- only); it must be unique.
- The second field is the number of minutes the counter has been running already.
- The third field contains the number of seconds since epoch (normally January 1, 1970) when the counter has been started, or 0 if it is currently stopped.
- The fourth field must be preceded with `#` if present, and contains the description of the counter.

The journal file normally contains a counter named `-total-` which is started
whenever any counter is started, and stopped when all counters are stopped.
It therefore contains the total time journalling has been used.
(This name has been chosen because it is difficult to enter as argument.)

---

_old-wj.pl is here for historical reasons: Initially, I used a Perl version of the script, but I don't maintain it any longer._

---

_(2016 Y.Bonetti)_

