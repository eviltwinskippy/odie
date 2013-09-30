###
#  Listens for traffic
###

package provide odie-rpc-service 0.1
package require odie-osinfo
package require odie-rpc

::rcp::mode rpcservice {
    OS {
	set reply [eval ::osinfo [lrange $buffer 1 end]] 
    }
    TIME {
	return [clock seconds]
    }
    HELO {
	set reply OK
    }
}

###
# topic: 7970a0a5-aa96-54ef-8ef1-696edd86ebf4
###
namespace eval ::rpcservice {
    ###
    #  Look for services
    ###
    foreach path [list \
		      [file join $::odie(root) etc] \
		      /usr/odie/etc \
		      /etc/preen \
		      /etc/odie  \
		      ~/.odie/\
		     ] {
	if ![file isdirectory $path] { 
	    continue
	}
	foreach fname {services.rc} {
	    set script [file join $path $fname]
	    if [file exists $script] {
		source $script
	    }
	}
    }
}
::rpc::listen $::odie(rpc_service_port) rpcservice
set sock [::rpc::connect $::odie(rpc_hub) $::odie(rpc_hub_port)]
set reply [::rpc::send $sock [list REGISTER $::odie(rpc_agent) $::odie(rpc_service_port)]]
if { $reply != "OK" } { 
    error "Could not register with RPC hub: $reply"
}
vwait forever

