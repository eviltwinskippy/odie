package provide webshed 0.1

::namespace eval ::webshed {}

###
# topic: 96a1ec46-3342-4d47-4fd1-6d9499c36692
###
proc ::webshed::reload {} {
  variable root
  set loaded index.tcl  
  foreach file {
    community.tcl
  } {
    source [file join $root $file]
    #package provide webshed-[file rootname $file] 0.1
    lappend loaded $file
  }
  
  foreach fpath [glob [file join $root *.tcl]] {
    set file [file tail $fpath]
    if { $file in $loaded } continue
    source $fpath
    #package provide webshed-[file rootname $file] 0.1
    lappend loaded $file
  }
}

set ::webshed::root [file dirname [info script]]
::webshed::reload

