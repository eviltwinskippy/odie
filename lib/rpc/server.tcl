###
#  Warning: This code is merely an example of encodeing TCL to 
#  execute code delivered by a network socket
#  
#  Sean does not recommend delivering a raw interpretor onto
#  the internet. Even a safe one.
#
#  Use this idea at your own risk.
###

package provide odie-rpc 0.2
package require tls

::namespace eval ::rpc {}

::namespace eval ::tls {}

###
# topic: 3a16fba6-b42c-de30-7d2d-d1b32aafedd2
###
proc ::rpc::block sock {
fileevent $sock readable {}
fconfigure $sock -blocking 1 -buffering line 
}

###
# topic: bfc3874c-dad0-f0cc-fb25-dcf1eb1fa27e
###
proc ::rpc::buffer_get sock {
gets $sock line
if { $line != "DATA" } { 
    return $line
}
puts $sock OK
set buffer {}
gets $sock buffer
if { $buffer == "." } { 
    puts $sock OK
    return {}
}
while 1 {
    gets $sock line
    if { $line == "." } {
    break
    }
    append buffer [string range $line 1 end]
}
puts $sock "OK"
return $buffer
}

###
# topic: c697b0b5-0cd8-bbee-da37-f241cf6d81b6
###
proc ::rpc::buffer_put {sock buffer} { 
if [regexp \n $buffer] {
    puts $sock DATA
    gets $sock reply
    if { $reply != "OK" } { 
    error "Socket not ready."
    }
    set tbuff ">[string map [list \n \n>] $buffer]"
    puts $sock $tbuff
    puts $sock .
    gets $sock reply
    if { $reply != "OK" } { 
    error "Message not recieved"
    }
} else {
    puts $sock $buffer 
}
}

###
# topic: af022814-0516-dd81-a0a4-36ecf8561d5b
###
proc ::rpc::closechan sock {
	variable multiline
	variable buffers

	array unset multiline $sock
	array unset buffers $sock
	
	catch { close $sock }
	###
	#  Wake up any pending command
	###
	set [namespace current]::${sock}_block -1
	update
	catch {unset [namespace current]::${sock}_block}
	array unset [namespace current]::${sock}
    }

###
# topic: 040e1e3b-eb38-d65b-5bd6-318075547582
###
proc ::rpc::connect {host port openstate} {
variable ssl
if $ssl { 
    puts SSL
    set sock [::tls::socket $host $port]
    ::tls::handshake $sock
} else {
    set sock [socket $host $port]
}
variable socklock
set socklock($sock) 0
fconfigure $sock -buffering line -translation crlf -blocking 0

upvar #0 [namespace current]::${sock} state
array set state [list ipaddr $host ipport $port state $openstate]
unblock $sock
return $sock
}

###
# topic: d21edd17-3409-73b0-6e0a-e0f67799fcb0
###
proc ::rpc::idle sock { 
	#if { [gets $sock line] < 0 } { 
	#    closechan $sock
	#    return
	#}
	block $sock
	set buffer [buffer_get $sock]

	upvar #0 [namespace current]::${sock} state
	set mode $state(state)
	set modevar mode_${mode}
	variable $modevar
	set action [lindex $buffer 0]
	set script [lindex [array get $modevar $action] 1]
	if { $script == {} } { 
	    buffer_put $sock [list ERROR [list unknown command $action in state $mode] {}]
	}

	set closechan 0
	set sendreply 1
	set reply {}
	if [catch {eval $script} result] {
	    buffer_put $sock [list ERROR $result $::errorInfo]
	    return
	}
	if $sendreply {
	    buffer_put $sock $reply
	}
	if $closechan {
	    idlepost {} $state(ipaddr) $buffer
	    closechan $sock
	} else {
	    idlepost $sock $state(ipaddr) $buffer
	    unblock $sock
	}

    }

###
# topic: 18e88f4c-856c-1f6e-249d-f928ed892219
# description: Perform post message housekeeping
###
proc ::rpc::idlepost {sock ipaddr buffer} { 

    }

###
# topic: 173c9bae-ade2-c39f-9354-e089c242b1fa
###
proc ::rpc::listen {port openstate} {
variable mysock 
variable sport 
variable error_log_file
variable ssl
set sport $port
if $ssl { 
set mysock [tls::socket -server [list ::rpc::listen_connect $openstate] \
    -certfile /usr/odie/certs/cacert.pem \
    -keyfile /usr/odie/certs/cakey.pem \
    $port]
} else {
    set mysock [socket -server [list ::rpc::listen_connect $openstate] $port]
}
return $mysock
}

###
# topic: c5641c22-3f5d-3f5b-dcc5-f92b0b299c1f
###
proc ::rpc::listen_addr {port addr openstate} {
variable mysock 
variable sport 
variable error_log_file
variable ssl
set sport $port
if $ssl { 
set mysock [tls::socket -server [list ::rpc::listen_connect $openstate] \
    -certfile /usr/odie/certs/cacert.pem \
    -keyfile /usr/odie/certs/cakey.pem \
    $port]
} else {
    set mysock [socket -server [list ::rpc::listen_connect $openstate] $port]
}
return $mysock
}

###
# topic: 69f5cc23-3bcc-fb2d-d126-186912b15925
###
proc ::rpc::listen_connect {openstate sock addr port} {
	variable multiline
	variable buffers
	variable socklock
	set socklock($sock) 0

	fconfigure $sock -buffering line -translation crlf -blocking 0

	upvar #0 [namespace current]::${sock} state
	array set state [list ipaddr $addr ipport $port state $openstate]
	unblock $sock
    }

###
# topic: be5d761a-e36d-9bc6-f54e-d25631f367c0
###
proc ::rpc::mode {state description} {
variable modes
set modevar mode_${state}
variable $modevar
if { $state != "all" } { 
    array set $modevar [array get [namespace current]::mode_all]
}
array set $modevar $description
}

###
# topic: 646e2981-133c-ca8d-7a1e-9262470eaae0
###
proc ::rpc::send {sock buffer} { 
block $sock
buffer_put $sock $buffer
set reply [buffer_get $sock]
unblock $sock
return $reply
}

###
# topic: 134b165d-4d5e-8b13-fadb-94a42f6c63ff
###
proc ::rpc::trace string {
puts $string
}

###
# topic: a743f333-b422-6693-9fb7-ea4209a087cf
###
proc ::rpc::unblock sock {
 fileevent $sock readable [list ::rpc::idle $sock]
fconfigure $sock -blocking 0 -buffering line
}

###
# topic: e8d5d6dc-5724-a074-09f7-67ab6bfaadc9
###
proc ::tls::password {} { 
    return fubar
}

###
# topic: e7ad9bbe-1143-8587-6c71-0d3d83227014
###
namespace eval ::rpc {
    variable mysock
    variable sport 
    variable connections
    variable ssl 1
    

    ###
    #  Connect with the RPC hub
    #  return a socket in a blocked state
    ###




    ###
    #  Using the classic semaphore
    #  to control access to the socket
    #
    #  unblock: down
    #  block: up
    ###










    mode all {
	NOOP {
	    set reply NOOP
	}
	ECHO {
	    set reply $buffer
	}
	QUIT {
	    set sendreply 0
	    set closechan 1
	}
    }
}

#      switch [lindex $argv 0] {
#  	server {
#  	    interp create -safe example
#  	    ::rpc::listen example 6666
#  	    ###
#  	    #  Important, or the server will never
#  	    #  start listening
#  	    ###
#  	    vwait forever
#  	}
#  	client {
#  	    ::rpc::reval_init localhost localhost 6666
#  	    set stmt {expr 1 + 1}
#  	    set dat [time {set reply [reval localhost $stmt]}]
#  	    puts [list $stmt = $reply]
# 	    puts $dat
#  	}
#      }

