### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB



#
# Network Utilites
#

package require listutil
package provide odie-osinfo 1.0

::namespace eval ::osinfo {}

###
# topic: 3334e511-a238-3c5f-58c0-a366957e770c
###
proc ::osinfo {cmnd args} {
    if {[lsearch [get osinfo::methods] $cmnd] >= 0} {
	return [eval osinfo::${cmnd} $args]
    } else {
	return [osinfo::os_version $cmnd]
    }
}

###
# topic: 4427023d-a2e0-d4d1-b305-d47ab28aab4f
# description: Identify the network data for this computer
###
proc ::osinfo::get_iplist {} {
	variable iplist
	if {[get iplist] != {} } {
	    return $iplist
	}

	identify_os
	set ostype [osinfo ostype]
	set method iplist.$ostype
	if {[info procs $method] == {} } {
	    set method iplist.generic
	}
	$method
	return $iplist
    }

###
# topic: 03156b56-92e5-1805-9793-a345fd42d8fe
# description:
#    Parse network configuration information
#    Unknown Platforms
#    
#    Override this method to handle new platforms
###
proc ::osinfo::get_iplist.generic {} { 
variable iplist {}
}

###
# topic: baa4fc73-5bbd-b5b7-3da9-73ece4a76c57
# description: Intelligent cross/platform check for who's account we are using.
###
proc ::osinfo::identify_user {} {
return [local_user]
}

###
# topic: f3a1e2b1-8ff2-53ed-7a85-b1dc78132f51
# description: Return list of IP addresses attached to this machine.
###
proc ::osinfo::iplist {{fields {}}} {
    set ipfields {device network ip mac dhcp}
set iplist   [osinfo::get_iplist]

if { $fields == {} } {
    set fields $ipfields
}
set result {}
foreach row $iplist {
    set rrow {}
    foreach item $fields {
    lappend rrow [lindex $row [lsearch $ipfields $item]]
    }
    lappend result $rrow
}
return $result
}

###
# topic: b8c4e681-f6b8-46c6-4c95-292f9903d2a1
# description: Return extended information about the operating system version
###
proc ::osinfo::os_version field {
identify_os
variable os_version
switch $field {
    os -
    ostype { return $::tcl_platform(os) }
    kernel { return $::tcl_platform(osVersion) }
    machine { 
    set value $::tcl_platform(machine)
    if { $value == "intel" } {
        set value i386
    }
    return $value
    }
    platform {
    return $::tcl_platform(platform)
    }
    user {
    return [string tolower $::tcl_platform(user)]
    }
    host {
    return [string tolower [lindex [split [info hostname] .] 0]] 
    }
    default {
    return [get os_version($field)]
    }
}
}

###
# topic: f6f468ad-4ec8-f167-f970-d1aa800e0602
# description: Detect if an address is localhost, an RFC 1918 network, or public internet
###
proc ::osinfo::subnet ip {
if { $ip == "localhost" } {
    return local
}
if { $ip == "127.0.0.1" } { 
    return local
}
if { $ip == "0.0.0.0" } {
    return {}
}
if { $ip == "" } {
    return {}
}
set subs [split $ip .]
switch [lindex $subs 0] {
    169 {
    # Default address
    return {} 
    } 
    192 {
    if { [lindex $subs 1] == "168" } { 
        return internal
    }
    }
    172 {
    set s [lindex $subs 1]
    if { $s >= 16 && $s <= 31 } {
        return internal
    }
    }
    10 {
    return internal
    }
}
return public
}

if [catch {
    package require odie-osinfo-$::tcl_platform(platform)
} err] {
    puts $err
    package require odie-osinfo-generic
}

set osinfo::methods [namespace eval osinfo {info procs}]

