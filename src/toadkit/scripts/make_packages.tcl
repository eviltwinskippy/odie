set here [file dirname [file normalize [info script]]]
source $here/classes.tcl

set modlist {}
set toadkit_script [file normalize [info script]]
set toadkit_top    [file dirname $here]
foreach file [glob modules/*.tcl] {
  source $file
  lappend modlist [file rootname [file tail $file]]
}

###
# Define the build package for toadkit
###

set order {}
set sorted {}
set allmod [lsort -dictionary [array names modules]]
while 1 {
  set done 1
  foreach {mod object} [lsort -stride 2 [array get modules]] {
    if { $mod in $order } continue
    set after [$object property compile_after]
    if {$after eq {}} {
      lappend order $mod
    } else {
      set idx [lsearch $allmod $after]
      if { $idx < 0} {
        error "$mod requested to be after $after, which wasn't registered in $allmod"
      }
      set idx [lsearch $order $after]
      if { $idx < 0 } {
        set done 0
      } else {
        set order [linsert $order [expr {$idx+1}] $mod]
      }
    }
  }
  if {$done} break
}

puts "BUILDING DYNAMIC MODULES"
foreach mod $order {
  if {[string is true [$modules($mod) property active]]} {
    continue
  }
  $modules($mod) build
}

puts "POPULATING ZIPDIR"
set zipdir ${odie(zipdir)}
#file delete -force $zipdir
if {![file exists $zipdir]} {
  file mkdir $zipdir
}
foreach mod $order {
  $modules($mod) zipdir_populate $zipdir
}