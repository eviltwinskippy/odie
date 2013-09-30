###
# SBIR DATA RIGHTS
# Contract No.: N00024-11-C-4120
# Contractor Name: Test & Evaluation Solutions, LLC
# Contractor Address: 400 Holiday CT, STE 204, Warrenton, VA 20186
#
# Expiration of SBIR Data Rights Period: 22 May 2017
#   The Government's rights to use, modify, reproduce, release, perform,
#   display, or disclose technical data or computer software marked with
#   this legend are restricted during the period shown as provided in
#   paragraph (b)(4) of the Rights in Noncommercial Technical Data and
#   Computer Software--Small Business Innovative Research (SBIR) Program
#   clause contained in the above identified contract. No restrictions
#   apply after the expiration date shown above. Any reproduction of
#   technical data, computer software, or portions thereof marked with
#   this legend must also reproduce the markings.
#
# Distribution Statement B: Distribution authorized to U.S. Government
# agencies only; (DFARS - SBIR Data Rights); 22 November 2010. Other
# requests for this document shall be referred to Naval Sea Systems
# Command ATTN: Small Business Innovation Research Program Office
# SEA05T1R, 1333 Isaac Hull Ave SE, Washington Navy Yard, DC 20376.
###

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

