###
#  Odie iCal Export
###

package provide calendar-ical 0.1

namespace eval ::calendar {
    proc icaltext string {
	regsub -all \n $string {\n} parse
	set buffer [string range $parse 0 60]
	set parse [string range $parse 61 end]
	if { $string != {} } {
	    while { [string length $parse] > 0 } {
		append buffer "\n [string range $parse 0 60]"
		set parse [string range $parse 61 end]
	    }
	}
	return $buffer
    }
    
}