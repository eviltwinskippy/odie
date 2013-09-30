###
# ROUTINE TO BUILD A PACKAGE LOADER FOR EVERY EXTENSION
# STITCHED INTO AN ODIE BUILD
###

set base [file join [file dirname [file dirname [file normalize [info script]]]] lib]
source [file join $base odieutil codebale.tcl]

set tclCompiler [lindex $argv 1]
set package_files {}
set stack {}
set fout [open [file join $base pkgIndex.tcl] w]
set result [::codebale::sniffPath $base stack]
#foreach directory [glob [file join $base *]] {
#  if {[file isdirectory $directory]} {
#    puts $directory
#    set result [::codebale::sniffPath $directory stack]
#  }
#}
# [lindex $argv 0]

while {[llength $stack]} {
  set stackpath [lindex $stack 0]
  set stack [lrange $stack 1 end]
  foreach {type file} [::codebale::sniffPath $stackpath stack] { 
    lappend result $type $file
  }
}
set i [string length $base]
foreach {type file} $result {
    switch $type {
        module {
            set fname [file rootname [file tail $file]]
            set package [lindex [split $fname -] 0]
            set version [lindex [split $fname -] 1]
            set dir [string trimleft [string range [file dirname $file] $i end] /]
            puts $fout "package ifneeded $package $version \[list source \[file join \$dir $dir [file tail $file]\]\]"
            ::codebale::read_tclsourcefile $file
        }
        source {
            if { $file == "$base/pkgIndex.tcl" } continue
            if { $file == "$base/packages.tcl" } continue
            if { $file == "$base/main.tcl" } continue
            if { [file tail $file] == "version_info.tcl" } continue
            set fin [open $file r]
            set dat [read $fin]
            close $fin
            if {[regexp "package provide" $dat]} {
               set fname [file rootname [file tail $file]]

               set dir [string trimleft [string range [file dirname $file] $i end] /]
            
               foreach line [split $dat \n] {
                  set line [string trim $line]
                  
                  if { [string range $line 0 14] != "package provide" } continue
                  set package [lindex $line 2]
                  set version [lindex $line 3]
                  puts $fout "package ifneeded $package $version \[list source \[file join \$dir $dir [file tail $file]\]\]"
		  break
               }
            }
            ::codebale::read_tclsourcefile $file
            if { $tclCompiler != {} } {
               exec $tclCompiler $file
               file rename -force [file rootname $file].tbc $file
            }
        }
    }
}
close $fout
#meta_output $base/build/help.rc
exit 0
