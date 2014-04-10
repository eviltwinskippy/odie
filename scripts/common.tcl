source [file join [file dirname [info script]] helpdoc.tcl]

::irm::helpDocCreate ::helpdoc [file join [file dirname [info script]] helpdoc.sqlite]

proc sniffPath {spath stackvar} {
    upvar 1 $stackvar stack    
    set result {}
    if { ![file isdirectory $spath] } return
    if { [string toupper [file tail $spath]] == "CVS" } return
    if {[file extension $spath] eq ".vfs"} return
    if {[file exists [file join $spath pkgIndex.tcl]]} {
        lappend result index [file join $spath pkgIndex.tcl]
    } else {
        foreach f [glob -nocomplain $spath/*.tcl] {
            lappend result source $f
        }
    }
    foreach f [glob -nocomplain $spath/*.tm] {
        lappend result module $f
    }
    foreach f [glob -nocomplain $spath/*.c] {
        lappend result csource $f
    }
    foreach f [glob -nocomplain $spath/*] {
        if [file isdirectory $f] {
            push stack $f
        }
    }
    return $result
}

proc pop {stackvar resultvar} {
   upvar 1 $stackvar stack 
   upvar 1 $resultvar result
   if { [set len [llength $stack]] == 0 } { 
	set result {}
	return 0
   }
   set result [lindex $stack end]
   if { $len == 1 } { 
	set stack {}
   } else {
     set stack [lrange $stack 0 end-1]
   }
   return 1 
} 

proc push {stackvar value} {
  upvar 1 $stackvar stack
  lappend stack $value
}



proc meta_output outfile {
set ::irm_version 1.0
puts "SAVING TO $outfile" 
::irm::docDump $outfile
return
set fout [open $outfile a]
puts $fout ""
puts $fout ""
flush $fout
puts -nonewline $fout "array set filemd5 "
flush $fout
puts $fout "\x7b"
foreach {file md5} [lsort -dictionary -stride 2 [array get ::filemd5]] {
  puts $fout "    [list $file $md5]"
}
puts $fout "\x7d"
close $fout
return
foreach {tclmod info} [lsort -dictionary -stride 2 [array get ::docInfo]] {
  puts $fout "[list ::irm::tclcmdDefine $tclmod] \x7b"
  foreach field {subtype title desc type file returns yields} {
    if { ![dict exists $::docInfo($tclmod) $field] } {
      dict set ::docInfo($tclmod) $field {}
    }
    puts $fout "   [list $field [dict get $::docInfo($tclmod) $field]]"
  }
  foreach field {arglist superclasses subclasses defined} {
    if { ![dict exists $::docInfo($tclmod) $field] } {
      continue
    } else {
      set value [string trim [dict get $::docInfo($tclmod) $field]]
    }
    if {$value eq {} } continue
    puts $fout "   [list $field $value]"
  }
  puts $fout "\x7d"
}
close $fout
}

