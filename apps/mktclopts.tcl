#! /bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh $0 ${1+"$@"}

#
# This script scans TCL source code looking for switch statements that
# are used to implement widget methods.  It then generates an include
# file that contains the variable definitions and code needed to implement
# that switch statement.
#
#

while {![eof stdin]} {
  set line [gets stdin]
  if {[regexp {^ *case *([A-Z]+)_([A-Z0-9_]+):} $line all prefix label]} {
    lappend cases($prefix) $label
  }
}

set col 0
proc put_item {f x} {
  global col
  if {$col==0} {puts -nonewline $f "   "}
  if {$col<2} {
    puts -nonewline $f [format " %-21s" $x]
    incr col
  } else {
    puts $f $x
    set col 0
  }
}

proc finalize {f} {
  global col
  if {$col>0} {puts $f {}}
  set col 0
}


foreach prefix [array names cases] {
  set f [open [string tolower $prefix]_cases.h w]
  puts $f "/*** Automatically Generated Header File - Do Not Edit ***/"
  puts $f "  const static char *${prefix}_strs\[\] = \173"
  set lx [lsort -dictionary $cases($prefix)]
  foreach item $lx {
    put_item $f \"[string tolower $item]\",
  }
  put_item $f 0
  finalize $f
  puts $f "  \175;"
  puts $f "  enum ${prefix}_enum \173"
  foreach name $lx {
    regsub -all {@} $name {} name
    put_item $f ${prefix}_[string toupper $name],
  }
  finalize $f
  puts $f "  \175;"
  puts $f "\
  int index;
  if( objc<2 ){
    Tcl_WrongNumArgs(interp, 1, objv, \"METHOD ?ARG ...?\");
    return TCL_ERROR;
  }
  if( Tcl_GetIndexFromObj(interp, objv\[1\], ${prefix}_strs,\
            \"option\", 0, &index)){
    return TCL_ERROR;
  }
  switch( (enum ${prefix}_enum)index )"
  close $f
}
