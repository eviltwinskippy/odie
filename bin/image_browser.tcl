###
# Example image browser
###
set path [file dirname [file normalize [info script]]]
lappend auto_path [file join $path .. lib] [file join $path .. app image_browser]

package require Tkhtml
package require img::jpeg
package require http
package require uri
package require img::gif
package require img::png
package require img::jpeg
    
source [file join $path ../lib/odie/index.tcl]
source [file join $path ../lib/tao/index.tcl]
source [file join $path ../lib/taotk/index.tcl]
load_path [file join $path ../app/image_browser]

image_window .main
console:start
pack .main -fill both -expand 1
