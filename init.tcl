###
# Global Settings For Network
###

###
# DEPRECATED!!!
###


# Default to be overwritten later
set ::taourl(smtp_host) localhost
namespace eval ::acl {

} 
namespace eval :: {
    proc load_rc filename {
	
    }

    set ::taourl(debug) 1
    set ::taourl(strict) 1


set ::odie(root)      [file dirname [file normalize [info script]]]
set ::odie(httpdroot) /home/httpd

switch $::tcl_platform(os) {
	Darwin {
		set ::odie(sandbox)   /tmp/sandbox
		set ::odie(httpdroot) /opt/local/httpd
	}
	Linux {
		set ::odie(sandbox)   /usr/local/sandbox
	}
	{Windows NT} {
		set ::odie(sandbox)   c:/temp
		set ::odie(httpdroot) c:/tclhttpd
	}
	default {
		set ::odie(sandbox)   /tmp
	}
}

set ::node [string tolower [lindex [split [info hostname] .] 0]]
if { $::node == "localhost" } { 
   set ::node [string tolower [lindex [split [exec hostname] .] 0]]
   if { $::node == {} } { 
	set ::node localhost
   }
}

switch $::node { 
	pop -
	mail {
		set ::node gemini
	}
}

if {[info commands Direct_Url] == {} } { 
   proc Direct_Url args {}
}

switch $::tcl_platform(os) {
	Darwin {
		# Darwin, OSX
		namespace eval ::security {
    variable rootPath        /var/root
		}

        }
	default {
		# Linux, et.all
		namespace eval ::security {
    variable rootPath        /root
		}
        }
}

lappend auto_path [file join $::odie(root) lib]
package require odie-ports

set datafiles {}

foreach path [list \
	[file join $::odie(root) etc] \
	/opt/local/odie/etc \
	/etc/preen \
	/etc/odie  \
	~/.odie/ \
    ] {
	if ![file isdirectory $path] { 
		continue
	}
     foreach fname {preen.rc mysql.rc ldap.rc} {
	set script [file join $path $fname]
        if [file exists $script] {
	   source $script
	}	
    }
}

proc rsync args {
	eval exec rsync $::rsync(flags) $args >&@ stdout
}

set ::tfi(node) $node
set ::odie(node) $node
package provide odie-objects
#source [file join $::odie(root) lib tao init.tcl]

#if [file exists [file join $::odie(root) starkits sqlite.kit]] {
#   catch {source [file join $::odie(root) starkits sqlite.kit]}
#}

package require tao-httpd-tclhttpd
}
