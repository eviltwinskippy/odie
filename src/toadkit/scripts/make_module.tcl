###
# For debugging:
# (Re)build a single module
###
if { $argv eq {} } {
  puts "Usage: make_module.tcl MODULENAME ?MODULENAME...?"
  exit 1
}
set here [file dirname [file normalize [info script]]]
source $here/classes.tcl
set modlist {}
set toadkit_script [file normalize [info script]]
set toadkit_top    [file dirname $here]

foreach file [glob $here/../modules/*.tcl] {
  puts [list source $file]
  source $file
  lappend modlist [file rootname [file tail $file]]
}
set zipdir ~/odie/zipdir

foreach mod $argv {
  puts [list $mod -> $modules($mod)]
  if {$mod ni {tcl tk}} {
    set path [$modules($mod) build_path]
    puts [list $mod -> $path]
    $modules($mod) step_download_do
    $modules($mod) make_clean
    $modules($mod) build
  }
  $modules($mod) zipdir_populate $zipdir
}