#! /usr/bin/tclsh

source /usr/odie/init.tcl
package require odie-rpc


::rpc::mode example {
    EXPR {
	set reply [eval expr [lindex $buffer 1]]
    }
    EVAL {
	set reply [eval [lindex $buffer 1]]
    }
    TIME {
	set reply [clock seconds]
    }
}
switch [lindex $argv 0] {
    server {
	::rpc::listen 13013 example
	###
	#  Important, or the server will never
	#  start listening
	###
	vwait forever
    }
    client {
	set sock [::rpc::connect 192.168.2.41 13013 example]
	set time [::rpc::send $sock TIME]
	puts [list > TIME < $time]
	set stmt {expr 1 + 1}
	set dat [time {set reply [::rpc::send $sock [list EVAL $stmt]]} 100]
	puts [list $stmt = $reply]
	puts $dat
	set time [::rpc::buffer_put $sock QUIT]
	::rpc::closechan $sock
    }
}
