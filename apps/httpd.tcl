#!/bin/sh
#
# Tcl HTTPD
#
# This is the main script for an HTTP server. 
# To test out of the box, do
# tclsh httpd.tcl -debug 1
# or
# wish httpd.tcl -debug 1
#
# For a quick spin, just pass the appropriate settings via the command line.
# For fully custom operation, see the notes in README_custom.
#
# A note about the code structure:
# httpd.tcl	This file, which is the main startup script.  It does
#		command line processing, sets up the auto_path, and
#		loads tclhttpd.rc and httpdthread.tcl.  This file also opens
#		the server listening sockets and does setuid, if possible.
# tclhttpd.rc	This has configuration settings like port and host.
#		It is sourced one time by the server during start up
#		before command line arguments are processed.
# httpdthread.tcl	This has the bulk of the initialization code.  It is
#		split out into its own file because it is loaded by
#		by each thread: the main thread and any worker threads
#		created by the "-threads N" command line argument.
# ../lib	The script library that contains most of the TclHttpd
#		implementation
# ../tcllib	The Standard Tcl Library.  TclHttpd ships with a copy
#		of this library because it depends on it.  If you already
#		have copy installed TclHttpd will attempt to find it.
#
# TclHttpd now requires Tcl 8.0 or higher because it depends on some
#	modules in the Standard Tcl Library (tcllib) that use namespaces.
#	In practice, some of the modules in tcllib may depend on
#	new string commands introduced in Tcl 8.2 and 8.3.  However,
#	the server core only depends on the base64 and ncgi packages
#	that may/should be/are compatible with Tcl 8.0
#
# Copyright (c) 1997 Sun Microsystems, Inc.
# Copyright (c) 1998-2000 Scriptics Corporation
# Copyright (c) 2001-2002 Panasas
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# RCS: @(#) $Id: httpd.tcl,v 1.40.2.5 2002/09/04 02:52:50 welch Exp $
#
# \
exec tclsh "$0" ${1+"$@"}

############
# auto_path
############

# Configure the auto_path so we can find the script library.
# home is the directory containing this script

##############
# Config file
##############

# I dunno... vhosts wants to see it
set v 3.5.1

# Load the configuration file into the Config array
# First, we preload a couple of defaults

set Config(compat)    3.3
set Config(debug)     0
set Config(mail)      [info host]
set Config(webmaster) root@$Config(mail)
set Config(site)      default

set Config(home) [file normalize \
	[file join [file dirname [info script]] ..] ]

set Config(vhostRoot) [file join /opt/local/httpd sites]
set Config(siteRoot)  [file join $Config(vhostRoot) default]
set Config(docRoot)   [file join $Config(siteRoot) htdocs]
set Config(library)   [file join $Config(siteRoot) libtml]
set Config(main)      [file join $Config(home) bin vhost-thread.tcl]
set Config(lib)       [file join $Config(home) lib]
set Config(auth)      {}

# The configuration bootstrap goes like this:
# 1) Look on the command line for a -config rcfile name argument
# 2) Load this configuration file via the config module
# 3) Process the rest of the command line arguments so the user
#       can override the settings in the rc file with them.

set ix [lsearch $argv -config]
if {$ix >= 0} {
    incr ix
    set Config(config) [lindex $argv $ix]
} else {
    set Config(config) [file join $Config(vhostRoot) default tclhttpd.rc]
}

###
# TRACER
###
if { $Config(lib) ni $auto_path } {
  lappend auto_path $Config(lib)
}

package require httpd 1.6
package require httpd::version		;# For Version proc
package require httpd::utils		;# For Stderr
package require httpd::counter		;# For Count

package require httpd::config		;# for config::init
config::init $Config(config) Config
namespace import config::cget

#
#foreach {var val} $argv {
#  set Httpd([string trimleft $var -]) $val
#  set Config([string trimleft $var -]) $val
#}

# The Config array now reflects the info in the configuration file

#########################
# command line arguments
#########################

# Override config file settings with command line arguments.

package require cmdline
array set Config [cmdline::getoptions argv [list \
        [list virtual.arg      [cget virtual]      {Virtual host config list}] \
        [list config.arg       [cget config]       {Configuration File}] \
        [list main.arg         [cget main]         {Per-Thread Tcl script}] \
        [list vhostRoot.arg    [cget vhostRoot]      {Root directory for virtual hosts}] \
        [list vhost.arg    [cget vhost]      {Virtual host to run}] \
        [list docRoot.arg      [cget docRoot]      {Root directory for documents}] \
        [list port.arg         [cget port]         {Port number server is to listen on}] \
        [list host.arg         [cget host]         {Server name, should be fully qualified}] \
        [list ipaddr.arg       [cget ipaddr]       {Interface server should bind to}] \
        [list https_port.arg   [cget https_port]   {SSL Port number}] \
        [list https_host.arg   [cget https_host]   {SSL Server name, should be fully qualified}] \
        [list https_ipaddr.arg [cget https_ipaddr] {Interface SSL server should bind to}] \
        [list webmaster.arg    [cget webmaster]    {E-mail address for errors}] \
        [list uid.arg          [cget uid]          {User Id that server runs under}] \
        [list gid.arg          [cget gid]          {Group Id for caching templates}] \
        [list secs.arg          [cget secsPerMinute] {Seconds per "minute" for time-based histograms}] \
        [list threads.arg      [cget threads]      {Number of worker threads (zero for non-threaded)}] \
        [list library.arg      [cget library]      {Directory list where custom packages and auto loads are}] \
	[list debug.arg	       0	        {If true, start interactive command loop}] \
        [list gui.arg           [cget gui]      {flag for launching the user interface}] \
        [list mail.arg           [cget MailServer]      {Mail Servers for sending email from tclhttpd}] \
        [list compat.arg       3.3	        {version compatibility to maintain}] \
	[list objecthost.arg	localhost	{ODIE Object server}] \
	[list objectport.arg	13000		{ODIE Object server port}] \
	[list ssl_password     [cget SSL_PASSWORD] {Password used to sign key} ] \
    ] \
    "usage: httpd.tcl options:"]

if {[string length $Config(library)]} {
    lappend auto_path $Config(library)
}

if {$Config(debug)} {
    puts stderr "auto_path:\n[join $auto_path \n]"
    if {[catch {package require httpd::stdin}]} {
	puts "No command loop available"
	set Config(debug) 0
    }
}


###
# https is pushed off to the individual hosts
###
###
# See if we have any domain specific SSL
###
if {![catch {package require tls}]} {

# Secure server startup, which depends on the TLS extension.
# Tls doesn't provide good error messages in these cases,
# so we check ourselves that we have the right certificates in place.
proc ::tls::password {} {
    return [cget SSL_PASSWORD]
}


if {[catch {
    if {![file exists [cget SSL_CADIR]] && ![file exists [cget SSL_CAFILE]]} {
        return -code error "No CA directory \"[cget SSL_CADIR]\" nor a CA file \"[cget SSL_CAFILE]\""
    }
    if {![file exists [cget SSL_CERTFILE]]} {
        return -code error "Certificate  \"[cget SSL_CERTFILE]\" not found"
    }
    tls::init -request [cget SSL_REQUEST] \
             -require [cget SSL_REQUIRE] \
             -ssl2 [cget USE_SSL2] \
             -ssl3 [cget USE_SSL3] \
             -tls1 [cget USE_TLS1] \
             -cipher [cget SSL_CIPHERS] \
             -cadir [cget SSL_CADIR] \
             -cafile [cget SSL_CAFILE] \
             -certfile [cget SSL_CERTFILE] \
             -keyfile [cget SSL_KEYFILE]
    Httpd_SecureServer $Config(https_port) $Config(https_host) $Config(https_ipaddr)
    append startup "secure httpd started on SSL port for $Config(https_host) $Config(https_port)\n"
    } err]} {
        append startup "SSL startup failed: $err"
    }
}

if {$Config(compat)} {
    if {[catch {package require httpd::compat}]} {
	puts stderr "tclhttpd$Config(compat) compatibility mode failed."
    } else {
	# Messages here just confuse people
    }
}

# Try to increase file descriptor limits

if [catch {
    package require limit
    set Config(limit) [cget MaxFileDescriptors]
    limit $Config(limit)
} err] {
    Stderr $err
    set Config(limit) default
}
Stderr "Running with $Config(limit) file descriptor limit"

# Try to change UID to tclhttpd so we can write template caches

# Try to get TclX, if present
catch {load {} Tclx}		;# From statically linked shell
catch {package require Tclx}	;# From dynamically linked DLL
catch {package require setuid}	;# TclHttpd extension

if {"[info command id]" == "id"} {
  # Emulate TclHttpd C extension with TclX commands
  # Setting the group before setting the user is necessary.
  
  proc setuid {uid gid} {
    id groupid $gid
    id userid $uid
  }
}
if ![catch {
    setuid $Config(uid) $Config(gid)
}] {
    Stderr "Running as user $Config(uid) group $Config(gid)"
}

# Initialize worker thread pool, if requested

if {$Config(threads) > 0} {
    package require Thread		;# C extension
    package require httpd::threadmgr		;# Tcl layer on top
    Stderr "Threads enabled"
    Thread_Init $Config(threads)
} else {
    # Stub out Thread_Respond so threadmgr isn't required
    proc Thread_Respond {args} {return 0}
    proc Thread_Enabled {} {return 0}
}

##################################
# Main application initialization
##################################
package require tao-httpd-tclhttpd



###################
# Start the server
###################
#Counter_Init $Config(secs)
# Open the listening sockets
Httpd_Server $Config(port) $Config(host) $Config(ipaddr)
append startup "httpd started on port $Config(port)\n"

set vroot [cget vhostRoot]
if {[file exists [file join $vroot local.rc]]} {
  source [file join $vroot local.rc]
}
if { [cget vhost] != {} } {
  ###
  # In this mode, run the webserver with
  # vhost as the only host running
  ###
  set thishost [cget vhost]
  set dir [file join $vroot $thishost]
  set rcfile [file join $dir httpd.rc]
  if {[file exists $rcfile]} {
    ::taourl::init $rcfile
  }
} elseif {$vroot != {}} {
  if {[file exists $vroot]} {
    foreach dir [glob -nocomplain [file join $vroot *]] {
      set thishost [file tail $dir]
      if { $thishost == "default " } {
        # Default is strictly a catch-all
        continue
      }
      set dir [file join $vroot $thishost]
      set rcfile [file join $dir httpd.rc]
      if {[file exists $rcfile]} {
        puts [list $rcfile $Config(port)]
        ::httpd::virtual_host $rcfile  
      }
    }
  }

  set thishost default
  set dir [file join $::Config(vhostRoot) $thishost]
  set rcfile [file join $dir httpd.rc]
  ::taourl::init $rcfile
} else {
  set thishost default
  set dir [file join $::Config(vhostRoot) $thishost]
  set rcfile [file join $dir httpd.rc]
  ::taourl::init $rcfile
}


# Start up the user interface and event loop.

if {[info exists tk_version] && [string is true $Config(gui)]} {
    package require httpd::srvui
    package require tkcon
    set ::tkcon::OPT(exec)  {}
    ::tkcon::Init
    SrvUI_Init "Tcl HTTPD $Httpd(version)"
}

Stderr $startup
if {$Config(debug)} {

    if {[info commands "console"] == "console"} {
	console show
    } else {
	Stdin_Start "httpd % "
	Httpd_Shutdown
    }
} else {
    vwait forever
}

