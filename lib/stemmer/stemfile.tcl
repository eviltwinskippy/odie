#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec /usr/local/bin/tclsh8.3 $0 ${1+"$@"}

source porter.tcl

stem::stem_file [lindex $argv 0] [lindex $argv 1]


## Local Variables:
## mode: tcl
## End:
