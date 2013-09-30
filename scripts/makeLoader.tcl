###
# ROUTINE TO BUILD A PACKAGE LOADER FOR EVERY EXTENSION
# STITCHED INTO AN ODIE BUILD
###

set base [file dirname [file dirname [file normalize [info script]]]]
source [file join $base lib odieutil codebale.tcl]

set tclCompiler [lindex $argv 1]
set package_files {}
set stack {}
set fout [open [file join $base lib packages.tcl] w]
puts $fout {
namespace eval ::starkit {
  variable topdir
  set topdir $::SRCDIR
}
}
set result [::codebale::sniffPath [file join $base lib] stack]
# [lindex $argv 0]

while {[llength $stack]} {
  set stackpath [lindex $stack 0]
  set stack [lrange $stack 1 end]
  # Was throwing random errors under linux
  #lappend result {*}[::codebale::sniffPath $stackpath stack]
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
            puts $fout "package ifneeded $package $version \[list source \[file join \$::SRCDIR $dir [file tail $file]\]\]"
            ::codebale::read_tclsourcefile $file
        }
        source {
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
                  puts $fout "package ifneeded $package $version \[list source \[file join \$::SRCDIR $dir [file tail $file]\]\]"
               }
            }
            ::codebale::read_tclsourcefile $file
            if { $tclCompiler != {} } {
               exec $tclCompiler $file
               file rename -force [file rootname $file].tbc $file
            }
        }
        index {
            set dir [string trimleft [string range [file dirname $file] $i end] /]
            puts $fout "set dir \[file join \$::SRCDIR $dir\] \; source \[file join \$::SRCDIR $dir pkgIndex.tcl\]"             
            flush $fout
        }
    }
}
close $fout
#meta_output $base/build/help.rc
exit 0
