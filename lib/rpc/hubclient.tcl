#! /usr/bin/tclsh

source /usr/odie/init.tcl
package require odie-rpc-client


switch [lindex $argv 0] {
    server {
	::rpchub::init
	###
	#  Important, or the server will never
	#  start listening
	###
	vwait forever
    }
    service {
	::rpcclient::init 
	
    }
    client {

	set sock [::rpc::connect localhost 6666 example]
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
