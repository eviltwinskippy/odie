###
# Default shell
###
if {[llength $argv]} { 
  set argv [lrange $argv 1 end]
  source [lindex $argv 0]
} else {
  puts "Interactive"
  set thisline {}
  while {[gets stdin line]>=0} {
    append thisline \n $line
    if {[info complete $thisline]} {
      if [catch {eval $thisline} result] {
        puts stderr $result
      } else {
        puts stdout $result
      }
      set thisline {}
    }
  }
}
