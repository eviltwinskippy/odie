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
# Operating System Info
# Unix Platform
#

package require listutil
package provide odie-osinfo-unix 1.0

::namespace eval ::osinfo {}

###
# topic: 3fab72c9-0fd7-4e87-e6c9-443e5fcf1a2c
###
proc ::osinfo::identify_os {} {

	variable os_version
	if [info exists os_version(ostype)] {
	    return
	}

	array set os_version {
	    kernel      {}
	    serial      {}
	    installtime {}
	    version     {}
	    release       {}
	    release.major {}
            release.minor {}
	    vendor      {}
	}
	
	set os_version(ostype)  [string tolower [exec uname -s]]
	set os_version(kernel)  [string tolower [exec uname -r]]
	
	###
	# Identify Version of Linux Distro
	# (We only know redhat 6.x/7.x at this point)
	###
	if {$os_version(ostype) == "linux" } {
	    ###
	    # What species of linux are we?
	    ###

	    if [file exists /etc/redhat-release] {
		###
		# Aha! RedHat
		###
		set os_version(vendor) {Red Hat}
		set buf [exec cat /etc/redhat-release]
		set os_version(version) [string trim $buf]

		set version [split [lindex $buf 4] .]
		set maj [lindex $version 0]
		set min [lindex $version 1]
		set os_version(release) redhat
		set os_version(release.major) $maj
		set os_version(release.minor) $min

		set os_version(installtime) [string range [exec uname -v] 1 end]
	    }
	}
    }

###
# topic: c16362a4-e9ac-ef56-6d18-ab00951781ce
# description:
#    Parse network configuration information
#    for unix-like systems
###
proc ::osinfo::iplist.unix {} { 
	variable iplist {}

	set buffer [exec /sbin/ifconfig]
	set scan "inet addr:"
	
	set addrlist {}
	foreach line [split $buffer \n] {
	    if [regexp HWaddr $line] {
		lappend addrlist [lindex $line 0] [lindex $line end]
	    }
	    if ![regexp $scan $line] continue
	    set s [expr [string first $scan $line 0] + \
		       [string length $scan]]
	    set f [expr [string first " " $line $s] - 1]
	    
	    set addr [string range $line $s $f]	
	    
	    if { $addr != "127.0.0.1" } {
		lappend addrlist $addr
	    }
	}

	foreach {device mac addr} $addrlist {
	    set device [string tolower $device]

	    if [catch {exec ps ax | grep dhcpcd | grep $device}] {
		set dhcp no
	    } else {
		set dhcp yes
            }
	    set dhcp [linux_dhcp_device $device]
	    lappend iplist [list $device $addr $mac $dhcp]
	}
	return $iplist
    }

###
# topic: 11041623-4189-9ca9-4209-8d12651c159b
###
proc ::osinfo::local_domain {} { 
return TFI
}

###
# topic: 586b771d-294e-b4d0-08d9-5968e3bf406f
###
proc ::osinfo::local_user {} { 
if ![info exists ::env(USER)] {
    if [info exists ::env(USERNAME)] {
    set ::env(USER) $::env(USERNAME)
    } else {
    set ::env(USER) root
    }
}
set user $::env(USER)
return $user
}

###
# topic: 9f5d6f3f-1203-0021-33b2-06824ccb58f9
###
proc ::osinfo::rc_base {} { 
variable os_unix
if ![info exists os_unix(rc_base)] {
    ###
    # So we can run on both redhat and debian, figure out where runlevel
    # scripts live
    ###
    
    if [file exists /etc/rc.d/init.d] {
    set os_unix(rc_base) /etc/rc.d/init.d
    }
    if [file exists /etc/init.d] {
    if {[file type /etc/init.d] == "directory" } {
        set os_unix(rc_base) /etc/init.d
    }
    }
}
return $os_unix(rc_base)
}

###
# topic: 9ffa4766-81f0-c685-0018-0b35d19adadb
###
proc ::osinfo::reboot {} {
go_offline
exec /sbin/shutdown -r now &
}

###
# topic: 27c661dc-3062-e2fc-5904-39f63b4b4d2f
###
proc ::osinfo::service {cmnd service} {
set rcscript [file join [osinfo rc_base] $service]
if ![file exists $rcscript] {
    #
    # Ignore commands to shutdown non-existant
    # processes
    tfirpc::log [get ::tfi(computer_id)] service "$service $cmnd (ignored)"
    
    return
}
tfirpc::log [get ::tfi(computer_id)] service "$service $cmnd"
switch $cmnd {
    start {
    exec $rcscript start 
    }
    stop {
    exec $rcscript stop 
    }
    status {
    return 1
    }
    restart {
    exec $rcscript stop
    exec $rcscript start 
    }
}
}

###
# topic: b4005889-d033-fc0f-7ddc-8cf8485b49fd
###
proc ::osinfo::shutdown {} {
go_offline
exec /sbin/shutdown -h now &
}

###
# topic: 263d1a4a-4d73-2f5f-91a7-ea7c56689b52
###
namespace eval ::osinfo {
    #####################
}

