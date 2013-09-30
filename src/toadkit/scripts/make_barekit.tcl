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

set static_c_declarations {}
set static_c_initialization {}
set static_c_headers [list  -I $odie(sandbox)/tcl/compat/zlib -I $odie(local_repo)/include -I $odie(sandbox)/tcl/generic -I $odie(sandbox)/tk/generic]
set static_linked_objects {}
set static_linked_libraries {}

set static_extensions {}

puts "BUILDING STATIC MODULES"
foreach mod $order {
  set info [$modules($mod) build_info]
  # Skip modules that do not have static build info
  if {![dict exists $info static_c_headers]} continue
  # Skip modules the user has not asked to build statically
  if { $mod ni $odie(static_linked_extensions) } continue
  lappend static_c_headers  {*}[dict get $info static_c_headers]
  lappend static_linked_objects {*}[dict get $info static_linked_objects]
  lappend static_linked_libraries {*}[dict get $info static_linked_libraries]

  append static_c_declarations [dict get $info static_c_declarations] \n
  append static_c_initialization [dict get $info static_c_initialization] \n
}

set hpath ${odie(sandbox)}/build
file mkdir $hpath
cd $hpath

set fout [open $hpath/packages.c w]
puts $fout "#include <tcl.h>"
puts $fout {/*
** Declarations for the initialization routines of
** embedded extensions
*/}
puts $fout $static_c_declarations
puts -nonewline $fout {
/*
** Call initialization code for all extensions
*/
int
Toadkit_Packages_Init(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */}
puts $fout "\{"
puts $fout $static_c_initialization
puts $fout "\}"
close $fout


if {$::tcl_platform(platform) eq "windows"} {
  file copy -force $toadkit_top/src/main.win.c $hpath/main.c
} else {
  file copy -force $toadkit_top/src/main.unix.c $hpath/main.c
}
file copy -force $toadkit_top/src/zvfs.c $odie(sandbox)/build/zvfs.c

set HOST [lindex $::tcl_platform(os) 0]


###
# Detect our build environment from tclConfig.sh and tkConfig.sh
###
set stripexe strip
if {![info exists ::env(LDFLAGS)]} {
  set ::env(LDFLAGS) {}
}
if {![info exists ::env(CFLAGS)]} {
  set ::env(CFLAGS) {}
}

set dat [read_sh_file ${odie(local_repo)}/lib/tclConfig.sh]
set cc [dict get $dat TCL_CC]
set defs [dict get $dat TCL_DEFS]
if {[dict exists $dat TCL_LD_FLAGS]} {
  set ::env(LDFLAGS) [dict get $dat TCL_LD_FLAGS]
}
if {[dict exists $dat TCL_EXTRA_CFLAGS]} {
  set ::env(CFLAGS) [dict get $dat TCL_EXTRA_CFLAGS]
}
if { "tk" in $odie(static_linked_extensions) } {
  set dat [read_sh_file ${odie(local_repo)}/lib/tkConfig.sh]
  if {[dict exists $dat TK_LD_FLAGS]} {
    set ::env(LDFLAGS) [dict get $dat TK_LD_FLAGS]
  }
  if {[dict exists $dat TK_EXTRA_CFLAGS]} {
    set ::env(CFLAGS) [dict get $dat TK_EXTRA_CFLAGS]
  }
  lappend defs {*}[dict get $dat TK_DEFS]

  switch $tcl_platform(platform) {
    "windows" {
      ###
      # When building a TK executable in windows, we need to provide
      # resource objects
      ###
      lappend objs [file join ${odie(sandbox)} tk win tk.res.o]
      lappend objs [file join ${odie(sandbox)} tk win wish.res.o]
      lappend static_c_headers -I $odie(sandbox)/tk/win
    }
    default {
      lappend static_c_headers -I $odie(sandbox)/tk/unix
    }
  }
}

puts "***
*** STATIC_C_HEADERS $static_c_headers
***"


puts "
***
*** BUILDING IN $hpath
***"
$modules(tcl) make_env
puts "
** CFLAGS $env(CFLAGS)
**"
set env(CFLAGS) "-g -DALLOW_EMPTY_EXPAND -arch x86_64 -arch i386 -pipe -fvisibility=hidden   -isysroot /Developer/SDKs/MacOSX10.6.sdk -mmacosx-version-min=10.5"

# Compile our executable's files
foreach cfile {
  main.c  zvfs.c packages.c toadkitMain.c
} {
  set ofile [file rootname $cfile].o
  catch {doexec $cc -DTCL_USE_STATIC_PACKAGES -DSTATIC_BUILD=1 {*}$static_c_headers {*}$::env(CFLAGS) -o $ofile -c $cfile}
  lappend objs $ofile
}



#if { $HOST eq "Windows" } {
#  foreach cfile {
#    tlink32.c tkwinico.c
#  } {
#    file copy -force $toadkit_top/src/$cfile $hpath/$cfile
#    set ofile [file rootname $cfile].o
#    catch {doexec $cc {*}$static_c_headers {*}$::env(CFLAGS) -o $ofile -c $cfile}
#    lappend objs $ofile
#  }
#}
#
# Create the zzipsetupstup binary
catch {doexec $cc {*}$::env(CFLAGS)  -o zzipsetupstub.o -c $toadkit_top/src/zzipsetupstub.c} err
catch {doexec $cc {*}$::env(CFLAGS) zzipsetupstub.o -o zzipsetupstub$exe} err

# Create the bare binary
puts "LINKING kit..."
puts "STATIC LINKED OBJECTS:\n  *[join $static_linked_objects "  \t*"]"
set buildargs [list $cc {*}$objs {*}$static_linked_objects {*}$static_linked_libraries {*}$::env(LDFLAGS)]
puts "doexec $buildargs -o toadkit_bare$exe"
doexec {*}$buildargs -o toadkit_bare$exe
#doexec $stripexe toadkit_bare$exe

file copy -force toadkit_bare$exe ${odie(local_repo)}/bin  
file copy -force zzipsetupstub$exe ${odie(local_repo)}/bin
