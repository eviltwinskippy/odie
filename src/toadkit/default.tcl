###
# Default shell
###
if {[llength $argv]} { 
  set argv [lrange $argv 1 end]
  source [lindex $argv 0]
} else {
  package require odie
  package require tao
  package require taotk
  console:start
}
