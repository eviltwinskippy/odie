package provide tao 2.0

###
# topic: 8b8d3c47-197b-0abe-5005-b2a644ebcb7d
###
proc ::load_path {path {ordered_files {}}} {
  lappend loaded index.tcl pkgIndex.tcl
  if {[file exists [file join $path baseclass.tcl]]} {
    lappend loaded baseclass.tcl
    uplevel #0 [list source [file join $path baseclass.tcl]]
  }
  foreach file $ordered_files {
    lappend loaded $file
    uplevel #0 [list source [file join $path $file]]
  }
  foreach file [glob -nocomplain [file join $path *.tcl]] {
    if {[file tail $file] in $loaded} continue
    lappend loaded [file tail $file]
    uplevel #0 [list source $file]
  }
}

set loaded {pkgIndex.tcl index.tcl}
package require odie
set tao_path [file dirname [info script]]

load_path $tao_path {
  lutils.tcl
  ootools.tcl
  moac.tcl
  oosqlite.tcl
}

