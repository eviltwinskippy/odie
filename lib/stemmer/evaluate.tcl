#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec /usr/local/bin/tclsh8.3 $0 ${1+"$@"}

source porter.tcl

###
# topic: 5c5f98ee-7f41-a246-556f-a571882fbb37
###
proc ::stem_test in {
    if [catch {open $in} inh] {
	error "Can't open $in"
    }
    set total 0
    set errors 0
    while {[gets $inh line]>=0} {
	incr total
	set result [stem::stem [lindex $line 0]]
	if {![string equal -nocase $result [lindex $line 1]]} {
	    puts "$line -- $result"
	    incr errors
	} 
    }
    puts "Total errors $errors/$total ([expr 100.0 * $errors/$total])"
}

    
stem_test [lindex $argv 0] 


## Local Variables:
## mode: tcl
## End:

