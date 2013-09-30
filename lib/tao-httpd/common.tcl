package provide tao-httpd 10.0
package require odie
package require listutil
package require llama
package require qdmailer
package require odie-md5
package require odie-thumbnail
package require odie-config
package require sqlite3

set ::llama::genera httpd

::namespace eval ::httpd {}

::namespace eval ::taourl {}

###
# topic: d91b65b1-95ba-3a8f-5721-93fce5c3c25b
###
proc ::httpd::virtual_alias args {
  global httpd_domains
  if {![info exists httpd_domains]} {
    set httpd_domains {}
  }
  if {[llength $args]} {
    foreach host [string tolower $args] {
      if {$host ni $httpd_domains} {
        lappend httpd_domains $host
      }
    }
  }
  return $httpd_domains
}

###
# topic: 95954565-b568-d79f-184e-524ada935e7d
# description:
#    Hook to allow old code
#    to perform basic queries
###
proc ::sqldb {method args} {
  switch $method {
    eval {
      return [db eval {*}$args]
    }
    cmnd -
    query -
    query_flat {
      return [db eval {*}$args]
    }
    sqlfix {
      return [sqlfix [lindex $args 0]]
    }
    sqlprep {
      return [sqlprep [lindex $args 0]]
    }
    default {
      db $method {*}$args
    }
  }
}

###
# topic: 08ed13fb-bc09-4e56-f0ec-5504bfc6b048
###
proc ::sqlfix data {
  regsub -all {\\} $data {\\} data
  regsub -all "\n" $data {\n} data
  regsub -all "\t" $data {\t} data
  regsub -all "\r" $data {\r} data
  regsub -all "\'" $data {\'} data
  regsub -all "\0" $data {\0} data
  regsub -all "\"" $data {\"} data
  return $data
}

###
# topic: 2ed2b9da-79cf-ddcd-ecd7-58db2c924da8
###
proc ::sqlprep value {
  if { $value == {} } { 
      return NULL
  } elseif [string is integer $value] {
      return $value
  } elseif [string is double $value] {
      return $value
  } else {
      return "[sqlfix $value]'"
  }
}

###
# topic: 21ba8140-769e-210b-00a1-2d22e0b8e22e
###
proc ::taourl::init_common config {
  package require webshed
  
  set siteRoot [dict get $config httpd siteRoot]
  set docRoot [dict get $config httpd siteRoot]
  set libpath [dict get $config httpd library]
  set vhostRoot [dict get $config httpd vhostRoot]
  set debug [dict get $config httpd debug]


  namespace eval ::security {}
  #puts [list sqlite3 db [file join $siteRoot var site.sqlite]]
  sqlite3 db [file join $siteRoot var site.sqlite]
  set ::security::admin_list {1 hypnotoad 2 chad}
  db eval {create temporary table acl_rights (
    acl_name text,
    userid int,
    rights text
  )}

  lappend ::auto_path  $libpath [file join $vhostRoot common libtml]

  if {![file isdirectory $libpath]} {
      Stderr "Code library \"$libpath\" does not exist"
  } else {
      if {$debug} {
          Stderr "Loading code from $libpath"
      }
      foreach f [lsort -dictionary [glob -nocomplain [file join $libpath *.tcl]]] {
          if {[file tail $f] == "pkgIndex.tcl"} {
              continue
          }
          if [catch {source $f} err] {
              Stderr "$f: $err"
          }
      }
  }

  ::httpd::static_root  /         [file join $siteRoot htdocs]
  ::httpd::static_root  /icons	[file normalize [file join $vhostRoot common icons]]
  
  # Doc_TemplateInterp determines which interpreter to use when
  # interpreting templates.
  ::httpd::dynamic_interp     {}
  ::httpd::library_path       $libpath
  ::httpd::index_filepattern  index.{tml,html,shtml,thtml,htm,subst}
  
  ::httpd::virtual_page error    /error.html
  ::httpd::virtual_page notfound /notfound.html

  ::document::init
  ::private::init
}

###
# topic: 3e93a90f-ff83-7dd9-fc10-5bb39e5509c9
###
proc ::taourl::reload {} {
  global taourl

  set loaded {common.tcl wibble.tcl tclhttpd.tcl}

  ###
  # Files which contain dependencies for other files go here
  ###
  foreach file {
  } {
    lappend loaded $file
    source [file join $taourl(root-httpd) $file]
  }
  ###
  # Other files are loaded automatically
  ###
  
  foreach file [glob [file join $taourl(root-httpd) *.tcl]] {
    if { [file tail $file] ni $loaded } {
      #puts [list tao-httpd source $file]
      source $file
    }
  }
}

###
# topic: 657740b2-fbbe-a17c-4d7a-9d58db266554
###
proc ::taourl::sqlitefix data { 
  regsub -all "\'" $data {''} data
  return $data
}

###
# topic: 643ba53c-1d47-1756-f27d-f96d31f50d06
###
proc ::taourl::Stderr args {
  puts stderr $args
}

###
# topic: 8e03f37f-d259-034b-9c38-1ed6e2833ece
# description: Routines for handling forms
###
proc ::taourl::stripList arglist {
  set lastitem $arglist
  while { [llength $arglist] == 1 } {
     set lastitem $arglist
     set arglist [lindex $arglist 0]
  }
  if { [llength $arglist] == 0 } { 
     set arglist $lastitem
  }
  return $arglist
}

###
# topic: ea49c6ee-9368-3c04-1df9-df28062f68e0
###
proc ::taourl::template {template resultvar} {
  upvar 1 $resultvar result
  set result [db eval "select contents,lastcheck,mtime,filename from templates where handle='$template'"]
  if { $result == {} } { 
      return 0
  }
  return 1
}

###
# topic: 0b2b426b-180b-c626-594f-3efab4b9e510
###
proc ::taourl::template_dump template {
  db eval {delete from templates where handle=$template}
}

###
# topic: 2def8e14-af85-afa8-6b45-bcdfe110ef7d
###
proc ::taourl::template_put {template contents filename mtime} {
  set time [clock seconds]
  db eval {insert or replace into templates (handle,lastcheck,mtime,filename,contents) VALUES ($template,$time,$mtime,$filename,$contents)}
}

###
# topic: c594f42c-fd9b-2e3f-f497-a140bbe912a4
###
proc ::taourl::template_touch template {
  set time [clock seconds]
  db eval {update templates set lastcheck=$time where handle=$template}
}

###
# Load the rest of the package
###

set ::taourl(root-httpd) [file dirname [file normalize [info script]]]
::taourl::reload

