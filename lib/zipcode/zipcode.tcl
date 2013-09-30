### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

###
# Sean's Zipcode Package
###

package require odie-objects
package require listutil
package provide odie-zipcode 1.0

###
# Load the zipcode database
###

::namespace eval ::zipcode {}

###
# topic: a1ec3464-e0df-8376-6e38-dffda4a6880b
# description: Return list of zipcodes
###
proc ::zipcode::getcodes {} {
variable state_abbr
return [lsort [array names state_abbr]]
}

###
# topic: e63374af-080c-0d1b-1e11-671ba660fd96
###
proc ::zipcode::statecode name {
variable state_name
set name [string toupper $name]
foreach {state sname} [array get state_name] {
    if { $sname == $name } {
    return $state
    }
}
}

###
# topic: 2146170f-fb80-86bb-68b5-82a3212e36ff
###
proc ::zipcode::statename state {
variable state_name
return [get state_name([string toupper $state])]
}

###
# topic: 436e2015-110c-aad1-43c9-9a9f985ea684
###
proc ::zipcode::validate {city state zip} {
	variable states
	variable cities
	variable state_abbr

	if { [string length $zip] == "10" } {
	    set zip [string range $zip 0 4]
	}
	if {[string length $zip] != 5 } { 
	    error "Invalid string for zipcode"
	}
	if ![string is integer $zip] { 
	    error "Invalid string for zipcode"
	}

	set city [string toupper $city]
	set state [string toupper $state]
	if { [lsearch [array names state_abbr] $state] < 0 } {
	    error "Invalid state $state"
	}
	
	if [info exists cities($state,$city)] {
	    set pat [string range $zip 0 2]
	    if { [lsearch $cities($state,$city) $pat] < 0 } {
		error "Invalid Zipcode for $city,$state"
	    }
	}

	###
	# Ok, not a major city
	# Let's just see if the zipcode is in the
	# ballpark for the state
	###
	if [info exists states($state)] {
	    set pat [string range $zip 0 1]
	    if { [lsearch $states($state) $pat] < 0 } {
		error "Invalid Zipcode for $state"
	    }
	}
    }

###
# topic: 95d841f1-d5a1-ad53-0b3d-2adb14e7ee74
###
proc ::zipcode::whereis zip {
	# Reverse-lookup at zipcode
	variable states
	variable cities
	variable state_abbr

	set pat [string range $zip 0 2]
	foreach {city codes} [array get cities] {
	    if {[lsearch $codes $pat] >= 0 } {
		return $city
	    }
	}

	set pat [string range $zip 0 1]
	foreach {state codes} [array get states] {
	    if {[lsearch $codes $pat] >= 0 } {
		return $state
	    }
	}
    }

###
# topic: 3590cf6f-5e43-2f76-a5e9-f33dc02b24f4
# description: US Postal Code validation routines
###
namespace eval ::zipcode {
    puts "Loading Data...[info script]"
    source [file dirname [file normalize [info script]]]/zipcode.rc
}

