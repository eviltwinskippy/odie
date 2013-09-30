# @(#) $Id: main.tcl,v 1.3 2000/10/20 16:01:22 drh Exp $
#
# This script runs first.  To build a standalone application out of
# Tobe, modify this script to initialize the application.
#
source /zvfs/packages.tcl
package require taotk

if {[llength $argv]>0} {
  set argv0 [lindex $argv 0]
  set argv [lrange $argv 1 end]
  source $argv0
} else {
  console:start
  update
  puts -nonewline "Tcl/Tk version $tcl_version\n% "
}
