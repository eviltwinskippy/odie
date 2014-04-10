set here [file dirname [file normalize [info script]]]
set toadkit_script [file normalize [info script]]
set toadkit_top    [file dirname $here]
source $toadkit_top/recipes/index.tcl

###
# Define the build package for toadkit
###



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