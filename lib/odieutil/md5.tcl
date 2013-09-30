### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2007 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

package provide odie-md5 0.1

catch {package require md5}
if { [info command md5] == "md5" } {
    proc md5hash file {
        set fin [open $file r]
	binary scan [md5 -in $fin] H* hash
	close $fin
	return $hash
    }
} else {
    if [file exists /usr/bin/md5] {
        proc md5hash file {
            return [lindex [exec md5 $file] 0]
        }
    } elseif [file exists /usr/bin/md5sum] {
        proc md5hash file {
            return [lindex [exec md5sum $file] 0]
        }        
    } else {
        error "Cannot Locate either the md5 package or a local md5 checkum"
    }
}