### BEGIN COPYRIGHT BLURB
#
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2012 Sean Woods
#
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
### END COPYRIGHT BLURB

package provide tao-httpd-wibble 10.0
package require ohai

::namespace eval ::httpd {}

::namespace eval ::taourl {}

###
# topic: 0aa474a4-e36a-39df-c4f8-e025523b6d2a
# description:
#    Domain_Url
#    Define a subtree of the URL hierarchy that is implemented by
#    direct Tcl calls.
#    
#    Arguments
#    virtual The name of the subtree of the hierarchy, e.g., /device
#    prefix	The Tcl command prefix to use when constructing calls,
#    e.g. Device
#    inThread	True if this should be dispatched to a thread.
#    
#    Side Effects
#    Register a prefix
###
proc ::httpd::dynamic_root {virtual prefix mapper} {
  ::wibble::handle $virtual direct_domain virtual $virtual cmdprefix $prefix marshall $mapper
}

###
# topic: ae787c15-db1f-21fb-7f71-3b01d17d29a7
###
proc ::httpd::dynamic_url {virtual handler} {
  ::wibble::handle $virtual direct_domain virtual $virtual cmdprefix $handler
}

###
# topic: 40b81430-23f6-f759-a201-f10c8c3cd0f3
###
proc ::httpd::host hostname {
  ::httpd::virtual_alias $hostname
  set ::Config(host) $hostname
}

###
# topic: 0dedb554-d86a-ead8-740b-0543ccc76908
###
proc ::httpd::static_root {url path} {
  set root [file normalize $path]
  ::wibble::handle $url dirslash root $root
  ::wibble::handle $url indexfile root $root indexfile index.html
  ::wibble::handle $url tclhttpd root $root
  ::wibble::handle $url staticfile root $root
  ::wibble::handle $url staticfile root $root
  ::wibble::handle $url scriptfile root $root
  ::wibble::handle $url templatefile root $root
  ::wibble::handle $url dirlist root $root
  ::wibble::handle $url notfound
}

###
# topic: 0c595a04-d145-fcd8-8a05-1793f3d8cb7a
###
proc ::httpd::virtual_host rcfile {
  global virtual
  if {![file exists $rcfile]} {
    return
  }
  
  set site [file rootname [file dirname $rcfile]]

  set slave [interp create site${site}]
  
  # Transfer the scalar global variables
  foreach var {::v ::auto_path} {
      $slave eval [list set $var [set $var]]
  }
  # Transfer the array global variables
  foreach arr {::Config ::Httpd} {
      $slave eval [list array set $arr [array get $arr]]
  }
  $slave eval [list array set ::Httpd [list site $site name $site]]
  # Load the packages
  $slave eval package require httpd [package provide httpd]
  foreach pkg {version utils counter config} {
      $slave eval \
              package require httpd::$pkg [package provide httpd::$pkg]
  }
  $slave eval {package require tao-httpd-wibble}
  # Added things that taourl is looking for
##################################
# Main application initialization
##################################
  $slave eval [list array set Config [list config $rcfile site $site siteRoot [file dirname $rcfile]]]
  $slave eval [list ::taourl::init $rcfile]
  set hosts [$slave eval {::httpd::virtual_alias}]
  if {![llength $hosts]} {
    error "$rcfile defines no hosts"
  }
  foreach host $hosts {
    set host [string tolower $host]
    if {[info exists virtual($host)]} {
      error "Virtual host $host already exists"
    }
    set virtual($host) $slave
  }
}

###
# topic: 6157e2fb-4028-bfe0-7ff8-d3a279148499
###
proc ::httpd::webmaster email {
  cput webmaster $email
  set ::Httpd(webmaster) $email
}

###
# topic: 926680e2-0935-3d58-2eb9-74007d90626f
###
proc ::taourl::objectUrl {url object} {
  ::Object_Url $url $object
}

###
# topic: 7fde1b8e-eaf3-6dca-7eb3-ae647147963c
###
proc ::taourl::objectUrlRemove {url object} {
  ::Object_UrlRemove $url $object
}

###
# topic: 32d1595b-bdb3-b20c-c322-a619364c1146
###
proc ::taourl::prefixInstall {url path} {
  ::Url_PrefixInstall $url  $path
}

###
# topic: 7dab327c-c813-c815-347c-694c0f3bcc6c
###
proc ::taourl::redirect url {
    Doc_Redirect $url
}

###
# topic: a443ff01-350c-6c6c-ec6a-69193df5698a
###
proc ::taourl::request_get field {
  set info [request_info]
  return [dictGet $info $field]
}

###
# topic: abbf06e9-c089-235d-67ad-7aa5c9efef0b
###
proc ::taourl::request_info {} {
  set result {}
  global current_state
  set result [dict get $current_state request]
  foreach {cookie dat} [dictGet $current_state cookie] {
    foreach var $dat {
      if { $var ne {} } {
        dict lappend result cookie $cookie $var            
      }
    }
  }
  return $result
}

###
# topic: 997a5a0b-f5e5-84d5-789a-cfc2f67e3a03
###
proc ::taourl::uploadUrl {url path handler} {
  ::Upload_Url $url $path $handler 
}

source [file join [file dirname [file normalize [info script]]] common.tcl]

