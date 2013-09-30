set here [file dirname [file normalize [info script]]]
source $here/classes.tcl

set modlist {}
set toadkit_script [file normalize [info script]]
set toadkit_top    [file dirname $here]
foreach file [glob modules/*.tcl] {
  source $file
  lappend modlist [file rootname [file tail $file]]
}

if {[llength $argv] eq 0} {
  puts "usage: make_project.tcl PATH"
  exit 1
}
set hpath [file normalize [lindex $argv 0]]
file mkdir $hpath/src

file copy -force $toadkit_top/scripts/loader.tcl $hpath/loader.tcl
file copy -force $toadkit_top/src/main.tcl $hpath/src
set fout [open [file join $hpath Makefile] w]
set fin [open $toadkit_top/src/Makefile.in r]
set buffer [read $fin]

dict set map %hpath% $hpath
dict set map %barekit% toadkit_bare$exe
dict set map %exe% $exe
dict set map %kitmakerroot% [file dirname [file normalize [info script]]]
if {[file exists ~/odie/bin/toadkit_bare$exe]} {
  dict set map %barekit% [file normalize ~/odie/bin/toadkit_bare$exe]
} else {
  dict set map %barekit% [file normalize ~/odie/bin/toadkit_bare]
}
if {$tcl_platform(platform)=="windows"} {
    dict set map %path_to_zip% zip.exe 
} else {
  if {[file exists ~/odie/bin/zip$exe]} {
    dict set map %path_to_zip% [file normalize ~/odie/bin/zip$exe]
  } else {
    dict set map %path_to_zip% [file normalize ~/odie/bin/zip]
  }
}
dict set map %path_to_tclsh% $odie(tcl_shell)

if {[file exists ~/odie/bin/zzipsetupstub$exe]} {
  dict set map %path_to_zipsetup% [file normalize  ~/odie/bin/zzipsetupstub$exe]
} else {
  dict set map %path_to_zipsetup% [file normalize  ~/odie/bin/zzipsetupstub]
}
puts $fout [string map $map $buffer]
close $fin

#file copy -force $hpath/toadkit_bare$exe $hpath/toadkit.zip
#cd $hpath
#if {[file exists toadkit.zip]} {
#  file delete toadkit.zip
#}
#doexec zip -0 toadkit.zip toadkit_bare$exe
#cd $zipdir
#puts [pwd]
#doexec zip -rAq ../build/toadkit.zip . -i *
#cd $hpath
#doexec ./zzipsetupstub$exe toadkit.zip toadkit_bare$exe
#file rename -force toadkit.zip toadkit$exe
#doexec chmod +x toadkit$exe
