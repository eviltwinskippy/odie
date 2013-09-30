###
#  Warning: This code is merely an example of encodeing TCL to 
#  execute code delivered by a network socket
#  
#  Sean does not recommend delivering a raw interpretor onto
#  the internet. Even a safe one.
#
#  Use this idea at your own risk.
###

package provide odie-rpc-hub 0.1

::namespace eval ::rpc {}

::namespace eval ::rpchub {}

###
# topic: 18e88f4c-856c-1f6e-249d-f928ed892219
###
proc ::rpc::idlepost {sock ipaddr buffer} {
###
#  Take attendance
###
::rpchub::agent [lindex $buffer 0] $ipaddr $sock
###
#  Deliver any new messages
###
::rpchub::deliver
}

###
# topic: ea0d647f-0895-8acb-d8d4-7781cc21e175
###
proc ::rpchub::agent {agent addr sock} { 
sqlhub eval "insert or replace into agents (agent,listen_addr,listen_sock,lastpoll,lastseen) VALUES ('$agent','$addr','$sock',[clock seconds],[clock seconds])"
}

###
# topic: d769a65d-4949-6e15-e5aa-aeecd06f1286
###
proc ::rpchub::delete_messages {agent mlist} { 
sqlhub eval "begin transaction"
foreach m $mlist {
    sqlhub eval "delete from messages where mid='$mlist'"
}
sqlhub eval "commit transaction"
}

###
# topic: 8a539600-ec38-4d75-75a0-d1868b67d774
###
proc ::rpchub::find agent { 
return [sqlhub eval "select listen_addr,listen_port where agent='$agent'"]
}

###
# topic: bbd17110-b416-f4f5-686b-1bc9b7317256
###
proc ::rpchub::fix string {
    return [string map {' ''} $string]
}

###
# topic: 2921fa3a-53fa-4246-0587-bdf631b34452
###
proc ::rpchub::init {} {
	package require odie-rpc
	package require sqlite3

	variable hubdatafile 
	sqlite sqlhub $hubdatafile
	set tablelist [tables sqlhub]
	foreach {table def} {
	    messages {
		CREATE TABLE messages (
		  mid INTEGER PRIMARY KEY,
		  from  text,
		  to    text,
		  subject text,
		  message text,
		  replycode int,
		  reply  text
		  );
		CREATE INDEX fromdx ON messages (from,subject,replycode);
		CREATE INDEX todx ON messages (to,subject,replycode);
	    }
	    agents {
		CREATE TABLE agents (
		   agent       text,
		   listen_addr text,
		   listen_port int,
		   listen_sock text,
		   lastpoll    int,
		   lastseen    int,
		   UNIQUE     (agent) ON CONFLICT REPLACE;
		   );
		
	    }
	} {
	    if {[lsearch $tablelist $table] < 0 } {
		sqlhub eval $def
	    }
	}
    }

###
# topic: 1ce59556-320e-b5d1-174a-973b8992208d
###
proc ::rpchub::list_messages agent {
return [sqlhub eval "select mid,from,subject,message from messages where to='$agent' and code is not null"]
}

###
# topic: da64effe-75e6-e7c7-a77b-e5f0342bcef8
###
proc ::rpchub::list_reply agent {
return [sqlhub eval "select mid,code,reply from messages where from='$agent' and code is not null"]
}

###
# topic: 680eec12-4de6-db04-2854-354ef3d0df7a
###
proc ::rpchub::newclientid {} { 
variable nextclient
while 1 {
    set agent agent[incr nextclient]
    if { [sqlhub eval "select agent from agents where agent='$agent'"] == {} } { 
    break
    }
}
return $agent
}

###
# topic: b218758f-ff17-9648-c3cd-5136611c48fe
###
proc ::rpchub::recv_message {agent mid} {
set dat [sqlhub eval "select from,subject,message from messages where to='${agent}' and mid='${mid}'"]
return $dat
}

###
# topic: 1f5ae187-3a39-8913-f75f-7ca9f4c0dfe7
###
proc ::rpchub::recv_reply {agent mid} { 
set dat [sqlhub eval "select replycode,reply from messages where to='${agent}' and mid='${mid}'"]
return $dat
}

###
# topic: 1b931698-78a1-6cac-c95d-77ebd6b95ab4
###
proc ::rpchub::send_message {to from mtype data} {
set mid [sqlhub eval "select max(mid) + 1 from messages"]
sqlhub eval "insert into messages set to='$to',from='$from',subject='$mtype',message='[fix $data]'"
return $mid
}

###
# topic: 7b2fd937-e1b9-1d2c-4dc9-0b951c0725e9
###
proc ::rpchub::send_reply {mid code reply} { 
sqlhub eval "update messages set code='[fix $code]',reply='[fix $reply] where mid='$mid'"
return $mid
}

###
# topic: 2ca3934f-4b89-d5d6-72ab-c11e7302df57
###
proc ::rpchub::service {agent addr port} { 
sqlhub eval "insert or replace into agents (agent,listen_addr,listen_port,lastpoll,lastseen) VALUES ('$agent','$addr','$port',[clock seconds],[clock seconds])"
}

###
# topic: 270dc279-f268-9009-8579-d8a7cc5d92af
###
proc ::rpchub::tables handle {
    return [$handle eval "select name from sqlite_master where type='table'"]
}

###
# topic: 99421dd2-7af1-f05c-82f5-ce034bcbbf38
###
namespace eval ::rpchub {
    variable nextmessage 100000
    variable nextclient  100000
    variable hubdatafile /var/lib/odie/rpcdata.sqlite
    
}

###
# topic: e7ad9bbe-1143-8587-6c71-0d3d83227014
###
namespace eval ::rpc {
    mode rpcservice {
	WHOAMI {
	    set reply [::rpchub::newclientid]
	}
	REGISTER {
	    set agent [lindex $buffer 1]
	    set ipaddr $state(ipaddr)
	    set port [lindex $buffer 2]
	    ::rpchub::service $agent $ipaddr $port
	    set reply OK
	}
	FIND {
	    set agent [lindex $buffer 1]
	    set dest  [lindex $buffer 2]
	    set reply [::rpchub::find $dest]
	}
	MLIST {
	    set reply [::rpchub::list_messages [lindex $buffer 1]]
	}
	RLIST {
	    set reply [::rpchub::list_reply [lindex $buffer 1]]
	}
	REPLY {
	    set agent [lindex $buffer 1]
	    set mid  [lindex $buffer 2]
	    set code [lindex $buffer 3]
	    set reply [lindex $buffer 4]
	    set reply [::rpchub::send_reply $mid $code $reply]
	}
	SEND {
	    set from  [lindex $buffer 1]
	    set to    [lindex $buffer 2]
	    set mtype [lindex $buffer 3]
	    set data  [lindex $buffer 4]
	    set reply [::rpchub::send_message $to $from $mtype $data]
	}
	GET {
	    set agent [lindex $buffer 1]
	    set mid  [lindex $buffer 2]
	    return [::rpchub::recv_message $agent $mid]
	}
	GETREPLY {
	    set agent [lindex $buffer 1]
	    set mid  [lindex $buffer 2]
	    set reply [::rpchub::recv_reply $agent $mid]
	}
	DELE {
	    set agent [lindex $buffer 1]
	    set midlist [lindex $buffer 2]
	    ::rpchub::delete_messages $midlist
	    set reply OK
	}
    }
}

