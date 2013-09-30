###
#  Warning: This code is merely an example of encodeing TCL to 
#  execute code delivered by a network socket
#  
#  Sean does not recommend delivering a raw interpretor onto
#  the internet. Even a safe one.
#
#  Use this idea at your own risk.
###

package provide odie-rpc-client 0.1

::namespace eval ::rpcclient {}

###
# topic: 2dbb7689-d204-374c-d1ce-ad193e83a3f3
###
proc ::rpcclient::helo {} { 
variable hubsock
variable agentid
::rpc::send $hubsock [list HELO $agentid]
}

###
# topic: b9a2d9b5-8a19-389a-7e28-1279a5c17369
###
proc ::rpcclient::init {} { 
#::rpc::listen 13013 rpcclient 

}

###
# topic: 178aa46d-2286-1c1a-6bf5-a7445efaedfe
###
proc ::rpcclient::poll {} { 
::rpc::cend
}

###
# topic: b12ac60c-cab7-f2f8-33e3-499c25a7d664
###
namespace eval ::rpcclient {
    variable hubsock
}

::rpc::mode rpcclient {
    WAKE {
	::rpcclient::poll
	set reply OK
    }
}

