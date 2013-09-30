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

package require odie-objects
package require listutil
package provide odie-osinfo-generic 1.0

::namespace eval ::osinfo {}

###
# topic: 3fab72c9-0fd7-4e87-e6c9-443e5fcf1a2c
###
proc ::osinfo::identify_os {} {

	variable os_version
	if [info exists os_version(ostype)] {
	    return
	}

	array set osinfo {
	    kernel      {}
	    serial      {}
	    installtime {}
	    version     {}
	    release       {}
	    release.major {}
            release.minor {}
	    vendor      {}
	    ostype      {}
	}
    }

###
# topic: 586b771d-294e-b4d0-08d9-5968e3bf406f
###
proc ::osinfo::local_user {} { 
return {}
}

