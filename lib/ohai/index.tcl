###
# Modifications to wibble for the odie web server
###
package provide ohai 0.1

###
# Load the remainder of the package
###
set loaded [file normalize [info script]]
set taourl(root-ohai) [file dirname $loaded]

###
# Drop in files that need to be loaded into
# a specific sequence here
###
foreach file {
  wibble.tcl
  tclhttpd.tcl
} {
  set script [file join $taourl(root-ohai) $file]
  lappend loaded $script
  source $script
}

###
# Catch any files that haven't been loaded
# yet
###
foreach file [glob [file join $taourl(root-ohai) *.tcl]] {
  if {$file in $loaded} continue
  source $file
}