package provide odie-prompt 1.0

###
# topic: 761680e5-267a-1995-7ad3-1a086befffbf
###
proc ::prompt {line {default {}}} {
	if { $default != {} } { 
	     puts -nonewline "$line \[$default\]: "
	} else {
	     puts -nonewline "$line: "
	}
	flush stdout
	gets stdin var
	if { $default != {} && $var == {} } { 
		return $default
	}
	return $var
}

