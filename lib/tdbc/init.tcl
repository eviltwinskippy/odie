
package provide odiedbc 0.1

package require TclOO

set tdbcroot [file dirname [file normalize [info script]]]
source [file join $tdbcroot common.tcl]

unset tdbcroot