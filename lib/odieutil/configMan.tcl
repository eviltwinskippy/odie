package provide odie-config 0.1

::namespace eval ::config {}

###
# topic: baf6e98d-2160-1445-2cab-1832c1877293
###
proc ::config::default {element dictConfig} {
variable configDict
if ![dict exists $configDict $element] {
    dict set configDict $element $dictConfig
    return
}
set v [dict get $configDict $element]
set newVal [dict merge $dictConfig $v]
dict set configDict $element $newVal
}

###
# topic: 46d7aa3c-353f-0b12-4fd3-7a1f83e0dc9b
###
proc ::config::peek element {
variable configDict
    if {[dict exists $configDict $element]} {
      return [dict get $configDict $element]
    }
}

###
# topic: 8e978efd-bc0b-9da4-57f4-85297a8fb119
###
proc ::config::peekField {element field} {
variable configDict
    if {[dict exists $configDict $element $field]} {
      return [dict get $configDict $element $field]
    }
}

###
# topic: 24b88c1d-7b3e-e107-9af1-53d733592fde
###
proc ::config::poke {element dictConfig} {
variable configDict
if ![dict exists $configDict $element] {
    dict set configDict $element $dictConfig
    return
}
    set v [dict get $configDict $element]
set newVal [dict merge $v $dictConfig]
dict set configDict $element $newVal
}

###
# topic: 40dabac7-9468-72c2-3b00-817bb210c67f
###
namespace eval ::config {
    variable configDict
    if ![info exists configDict] { 
	set configDict {}
    }
}

if [package vsatisfies $tcl_version 8.5] {
    namespace eval ::config { namespace export * ; namespace ensemble create }
} else {
    proc ::config args {
	return [namespace eval ::config $args]
    }
}

