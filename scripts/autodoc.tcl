###
# This script parses through TCL files
# and systematically adds template entries
# for the auto-documenter, and captures
# any information filled out for the
# auto-documenter to ../lib/classes.rc
###
package require md5
package require sqlite3
package require tao-sqlite

#set base [file normalize [file join [file dirname [info script]] ..]]
set base [pwd]

###
# Build a database file
###
set docfile [file join $base helpdoc.sqlite]
set exists [file exists $docfile]
tao.yggdrasil create helpdoc $docfile

if {!$exists} {
  set rcfile [file join $base helpdoc.rc]
  if {[file exists $rcfile]} {
    source $rcfile
    helpdoc eval {update file set hash=NULL}
  }
}

set pathlist {}
if {[llength $argv]} {
  helpdoc eval {update file set hash=NULL}
  foreach path ${argv} {
    lappend pathlist [file join $base $argv]
  }
} else {
  foreach path {lib src/toadkit} {
    lappend pathlist [file join $base $path]
  }  
}
puts $pathlist
::codebale::parse_path {rewrite 1 repo plugin} $base {*}$pathlist
::codebale::meta_output $base/helpdoc.rc
