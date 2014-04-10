package provide llama 0.1

###
# Load the remainder of the package
###
set loaded [file normalize [info script]]
set path [file dirname $loaded]
lappend loaded [file join $path pkgIndex.tcl]

###
# Drop in files that need to be loaded into
# a specific sequence here
###
foreach file {
  common.tcl
  layout.tcl
  widgets.tcl
} {
  set script [file join $path $file]
  lappend loaded $script
  source $script
}

###
# Catch any files that haven't been loaded
# yet
###
foreach file [glob [file join $path *.tcl]] {
  if {$file in $loaded} continue
  source $file
}