::namespace eval ::wibble {}

::namespace eval ::wibble::zone {}

###
# topic: 1dd9b7f0-f034-eff3-7353-03a8c24bac09
###
proc ::Config args {
  switch [llength $args] {
    1 {
      return [get ::Config([lindex $args 0])]
    }
    2 {
      dict set ::httpd_config [string tolower [lindex $args 0]] [lindex $args 1]
      set ::Config([lindex $args 0]) [lindex $args 1]
    }
  }
}

###
# topic: 72859fe0-15b0-3bc6-3e62-32c7cc97434b
###
proc ::Cookie_Get field {
  global current_state
  return [lindex [dictGet $current_state cookie $field] 1]
}

###
# topic: a14b0f72-bee1-8bf3-7c11-2fff784f45e4
###
proc ::Direct_Url {virtual {prefix {}} {inThread 0}} {
  global Direct
  if {[string length $prefix] == 0} {
      set prefix $virtual
  }
  set Direct($prefix) $virtual	;# So we can reconstruct URLs
  ::wibble::handle $virtual direct_domain virtual $virtual cmdprefix $prefix
}

###
# topic: 39c78e65-d85c-f6f9-e2ab-b3b7f07286b9
###
proc ::Direct_UrlRemove prefix {
  global Direct
  catch { ::wibble::handle_remove $Direct($prefix) }
  catch { unset Direct($prefix) }
}

###
# topic: c8f7f332-f903-1436-b320-33e6c590a3bf
###
proc ::Doc_AddRoot {url fspath} {
  set root [file normalize $fspath]
  ::wibble::handle $url dirslash root $root
  ::wibble::handle $url indexfile root $root indexfile index.html
  ::wibble::handle $url tclhttpd root $root
  ::wibble::handle $url static root $root
  ::wibble::handle $url template root $root
  ::wibble::handle $url script root $root
  ::wibble::handle $url dirlist root $root
  ::wibble::handle $url notfound
}

###
# topic: 1626a2dc-ff5c-5cf7-9162-fb9e1a135b8d
###
proc ::Doc_Dynamic args {
  global do_cache
  set do_cache 0
}

###
# topic: 034d30fd-cfed-5458-a67e-81796cebac31
# description: Register a zone handler.
###
proc ::wibble::handle_remove prefix {
  variable zonehandlers
  set handler_list $zonehandlers
  set zonehandlers {}
  foreach {zprefix command arglist} $handler_list {
    if { $zprefix eq $prefix } continue
    lappend zonehandlers $zprefix $command $arglist
  }
}

###
# topic: 315b0e6a-4f05-7a29-8284-18beaa7550d8
# description: Touches to make wibble compadible with legacy tclhttpd installations
###
proc ::wibble::zone::direct_domain state {
  dict with state request {}
  dict with state options {}

  set prefix [dict get $state options cmdprefix]
  set suffix [dict get $state options suffix]
  set marshall [dictGet $state options marshall]
  if { $marshall eq {} } {
    set marshall ::wibble::zone::Direct_MarshallArguments
  }
  set uri  [dict get $state request uri]
  ###
  # Legacy domain handlers assume a 1->1 relationship
  # between a field and value
  ###
  set query {}
  if {[dict exists $state request query]} {
    foreach {field fdict} [dict get $state request query]
    if {[dict exists $fdict {}]} {
      dict set query [dict get $fdict {}]
    }
  }
  set cmd [{*}$marshall $prefix $suffix $query]
  if { $cmd eq {} } {
    ::wibble::zone::notfound $state
    return
  }
  global current_state
  set current_state $state
  
  dict set response status 200
  dict set response header content-type {} text/plain
  dict set response content ""
  set ::env(content/type) text/html

  if [catch $cmd content erropts] {
    ::wibble::zone::server_error $state $content $erropts
    return
  }
  dict set response header content-type {} $::env(content/type)
  dict set response content $content
  sendresponse $response
}

###
# topic: 7948a04d-12ce-028b-2e68-59e4ddb842bd
###
proc ::wibble::zone::Direct_MarshallArguments {prefix suffix query} {
  set cmd [string trimleft $prefix$suffix /]
  if {![iscommand $cmd]} {
    return
  }

  # Compare built-in command's parameters with the form data.
  # Form fields with names that match arguments have that value
  # passed for the corresponding argument.
  # Form fields with no corresponding parameter are collected into args.

  set cmdOrig $cmd
  set params [info args $cmdOrig]
  if { $params in {"arglist" "query"}} {
    return [list $cmdOrig $query]
  }
  foreach arg $params {
    if {![dict exists $query $arg]} {
      if {[info default $cmdOrig $arg value]} {
        lappend cmd $value
      } elseif {[string compare $arg "args"] == 0} {
        set needargs yes
      } else {
        lappend cmd {}
      }
    } else {
      
      # The original semantics for Direct URLS is that if there
      # is only a single value for a parameter, then no list
      # structure is added.  Otherwise the parameter gets a list
      # of all values.

      lappend vlist [dict get $query $arg]
    }
  }
  if {[info exists needargs]} {
    foreach {name value} $query {
      if {[lsearch $params $name] < 0} {
        lappend cmd $name $value
      }
    }
  }
  return $cmd
}

###
# topic: f1378624-c36d-9831-ce96-27fed9009c5b
# description: Send a 404 Not Found.
###
proc ::wibble::zone::server_error {state err erropts} {
    dict set response status 500
    dict set response header content-type {} text/plain
    dict set response content "Internal Server Error\n$err\n[dict get $erropts -errorinfo]"
    sendresponse $response
}

###
# topic: 7bda5329-84ac-9502-eba1-b61b2bef9144
# description: Interpret tclhttpd style template files.
###
proc ::wibble::zone::tclhttpd state {
  global do_cache
  set do_cache 1
  
  dict with state request {}; dict with state options {}
  set tmlpath [file rootname $fspath]
  if {[file readable $tmlpath.tml] && [file exists $tmlpath.html]} {
    if {[file mtime $tmlpath.tml] > [file mtime $tmlpath.html]} {
      file delete $tmlpath.html
    }
  }
  if {[file exists $tmlpath.html]} {
    set newstate $state
    dict set state request path $path.html
    nexthandler $newstate $state
    return
  }
  
  if {[file readable $tmlpath.tml]} {
    global current_state
    set current_state $state
  
    dict set response status 200
    dict set response header content-type {} text/plain
    dict set response content ""
    set ::env(content/type) text/html
    set fin [open $tmlpath.tml r]
    set data [read $fin]
    close $fin
    dict set response header content-type {} $::env(content/type)
    set content [subst $data]
    dict set response content $content 
    if { $do_cache } {
      set fout [open $tmlpath.html w]
      puts $fout $content
      close $fout
    }
    sendresponse $response
  }
}

# Direct_MarshallArguments --
#
#	Use the url prefix, suffix, and cgi values (set with the
#	ncgi package) to create a Tcl command line to invoke.
#
# Arguments:
# 	prefix		The Tcl command prefix of the domain registered 
#			with Direct_Url.
#	suffix		The part of the url after the domain prefix.
#
# Results:
#	Returns a Tcl command line.
#
# Side effects:
#	If the prefix and suffix do not map to a Tcl procedure,
#	returns empty string.


# Direct_Url
#	Define a subtree of the URL hierarchy that is implemented by
#	direct Tcl calls.
#
# Arguments
#	virtual The name of the subtree of the hierarchy, e.g., /device
#	prefix	The Tcl command prefix to use when constructing calls,
#		e.g. Device
#	inThread	True if this should be dispatched to a thread.
#
# Side Effects
#	Register a prefix


# Direct_UrlRemove
#       Remove a subtree of the URL hierarchy that is implemented by
#       direct Tcl calls.
#
# Arguments
#       prefix  The Tcl command prefix used when constructing calls,
#
# Side Effects
#
       

