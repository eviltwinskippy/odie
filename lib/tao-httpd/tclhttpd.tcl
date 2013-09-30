package provide tao-httpd-tclhttpd 10.0

::namespace eval ::httpd {}

::namespace eval ::taourl {}

###
# topic: 8403f42c-21de-7ddd-0666-99b1aaffdabb
###
proc ::httpd::dynamic_interp interp {

}

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
  global Direct
  if {[string length $prefix] == 0} {
      set prefix $virtual
  }
  set Direct($prefix) $virtual	;# So we can reconstruct URLs
  Url_PrefixInstall $virtual [list ::taourl::DirectDomain $prefix $mapper] 0      
}

###
# topic: ae787c15-db1f-21fb-7f71-3b01d17d29a7
###
proc ::httpd::dynamic_url {url handler} {
  ::Direct_Url $url $handler
}

###
# topic: 40b81430-23f6-f759-a201-f10c8c3cd0f3
###
proc ::httpd::host hostname {
  ::httpd::virtual_alias $hostname
  set ::Config(host) $hostname
}

###
# topic: 82c7a16a-1302-2738-c304-81b7b99f7f27
###
proc ::httpd::index_filepattern pattern {
  # Doc_IndexFile defines the name of the default index file
  # in each directory.  Its value is a glob pattern.
  DirList_IndexFile $pattern
}

###
# topic: fa87aa54-73b6-ff88-e95b-5dc7c39cfdf6
###
proc ::httpd::library_path dir {
  if {[file isdirectory $dir]} {
    ::Template_Library $dir
  }
}

###
# topic: 0dedb554-d86a-ead8-740b-0543ccc76908
###
proc ::httpd::static_root {url args} {
  variable static_root
  if {[llength $args]} {
    set path [lindex $args 0]
    if {$url eq "/"} {
      ::Doc_Root $path
      #set ::Doc(root) $path
    }
    dict set static_root $url {*}$args
    ::Doc_AddRoot $url $path
  }
  return [dict get $static_root $url]
}

###
# topic: 0c595a04-d145-fcd8-8a05-1793f3d8cb7a
###
proc ::httpd::virtual_host rcfile {
  global virtual
  if {![file exists $rcfile]} {
    return
  }
  
  set site [file tail [file rootname [file dirname $rcfile]]]

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
  $slave eval {package require tao-httpd-tclhttpd}
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
# topic: e4cabbb1-f165-145e-0fae-15e1a1da8c64
###
proc ::httpd::virtual_page {which virtual} {
  global Doc
  set Doc(page,${which}) [Doc_Virtual {} {} $virtual]
}

###
# topic: 6157e2fb-4028-bfe0-7ff8-d3a279148499
###
proc ::httpd::webmaster email {
  cput webmaster $email
  set ::Httpd(webmaster) $email
}

###
# topic: a2c27d94-5afa-e7c5-706b-e2b30e2e8317
# description: Main handler for Direct domains (i.e. tcl commands)
###
proc ::taourl::DirectDomain {prefix mapper sock suffix} {
  global Direct
  global env
  upvar #0 Httpd$sock data

  # Set up the environment a-la CGI.

  Cgi_SetEnv $sock $prefix$suffix

  # Prepare an argument data from the query data.

  Url_QuerySetup $sock
  set query {}
  foreach {item value} [::ncgi::nvlist] {
    dict set query $item {} $value
  }
  set cmd [{*}$mapper $prefix $suffix $query]
  if {$cmd == ""} {
      Doc_NotFound $sock
      return
  }

  # Eval the command.  Errors can be used to trigger redirects.

  set code [catch $cmd result]

  set type text/html
  upvar #0 $prefix$suffix aType
  if {[info exist aType]} {
      set type $aType
  }

  Direct_Respond $sock $code $result $type
}

###
# topic: 3ba68d6d-23b5-219d-47e8-6459e0754e5d
###
proc ::taourl::init rcfile {
  global Config httpd_config
  
  namespace import ::config::cget
  namespace eval :: {namespace import -force ::config::cget}
  # This replaces the command line processing
  array set ::Config [array get ::config::Config]

  foreach {field value} [array get ::Httpd] {
    dict set httpd_config httpd $field $value  
  }
  foreach {field value} [array get ::Config] {
    dict set httpd_config httpd $field $value  
  }
  if {[file exists $rcfile]} {
    source $rcfile
  }

  set ::DebugPassword fubar	
  set ::odie(httpd_admin_password) fubar

  # Standard Library dependencies
  package require ncgi
  catch {
      # Prodebug pukes on this because it defines html::foreach
      package require html
  }
  
  # Core modules
  package require httpd          	;# Protocol stack
  package require httpd::version	;# Version number
  package require httpd::url	;# URL dispatching
  package require httpd::mtype	;# Mime types
  
  package require httpd::counter	;# Statistics
  package require httpd::utils	;# handy stuff like "lassign"
  
  package require httpd::redirect	;# URL redirection
  package require httpd::auth	;# Basic authentication
  package require httpd::log	;# Standard logging
  package require httpd::digest	;# Digest authentication
  
  package require httpd::direct		;# Application Direct URLs
  package require httpd::status		;# Built in status counters
  package require httpd::dirlist		;# Directory listings
  package require httpd::include		;# Server side includes
  package require httpd::admin		;# Url-based administration
  package require httpd::session		;# Session state module (better Safe-Tcl)
  package require httpd::redirect	;# Url redirection tables
  
  #package require httpd::mail		;# Crude email form handlers
  #package require httpd::debug		;# Debug utilites
  
  if {$Config(threads) > 0} {
      package require Thread		;# C extension
      package require httpd::threadmgr	;# Tcl layer on top
  }
  
  # Image maps are done either using a Tk canvas (!) or pure Tcl.
  
  if {[info exists tk_version]} {
      package require httpd::ismaptk
  } else {
      package require httpd::ismaptcl
  }

  # These packages are required for "normal" web servers
  
  # doc
  # provides access to files on the local file systems.
  
  package require httpd::doc

  Httpd_Init
  
  # Doc_Root defines the top-level directory, or folder, for
  # your web-visible file structure.
  
  # uncomment this and comment the package requires
  # if you want to leave out cgi support
  #proc ::Cgi_Domain {virtual directory sock suffix} {
  #        Doc_NotFound $sock
  #        return
  #}
  #package require httpd::cgi		;# Standard CGI
  #Cgi_Directory			/cgi-bin
  
  # Search for mime.types either right in Config(lib), or down
  # one level in the installed tclhttpd subdirectory
  
  foreach path [list \
      [file join $Config(lib) mime.types] \
      [glob -nocomplain [file join $Config(lib) tclhttpd* mime.types]] \
      ] {
    if {[llength $path] > 0} {
      set path [lindex $path 0]
    }
    if {[file exists $path]} {
      Mtype_ReadTypes $path
      break
    }
  }

  set ::Config(siteRoot) [file join $::Config(vhostRoot) $::Config(site)]
  
  # Doc_PublicHtml turns on the mapping from ~user to the
  # specified directory under their home directory.
  
  Doc_PublicHtml			public_html
  
  # Doc_CheckTemplates causes the processing of text/html files to
  # first look aside at the corresponding .tml file and check if it is
  # up-to-date.  If the .tml (or its dependent files) are newer than
  # the HTML file, the HTML file is regenerated from the template.
  
  Template_Check		1

  #Doc_Root  /         [file join ::Config(siteRoot) htdocs]

  Counter_Init $Config(secs)
  Status_Url			/status /images
  Admin_Url			/admin
  #Mail_Url			/mail
  #Debug_Url			/debug
  #Redirect_Init			/redirect
    
  if {[catch {
      Auth_InitCrypt			;# Probe for crypt module
  } err]} {
      catch {puts "No .htaccess support: $err"}
  }

  ::Httpd_Webmaster $::Config(webmaster)

  ###
  # Gather list of domains from the config file used
  # by the vhost mapper
  ###
  set ::Config(domainlist) [::httpd::virtual_alias]

  
  if {$Config(threads) > 0} {
      package require Thread		;# C extension
      package require httpd::threadmgr	;# Tcl layer on top
      Thread_Init $Config(threads)
  } else {
      # Stub out Thread_Respond so threadmgr isn't required
      proc Thread_Respond {args} {return 0}
      proc Thread_Enabled {} {return 0}
  }
  set logroot /var/log/tclhttpd/[file tail $Config(siteRoot)]
  if [catch {file mkdir $logroot}] {
    set logroot /tmp/tclhttpd/[file tail $Config(siteRoot)]
    file mkdir $logroot
  }
  set ::Config(Log_File) [file join $logroot log]
  ::Log_CompressProg	[cget CompressProg]
  ::Log_SetFile         $Config(Log_File)$Config(port)_
  ::Log_FlushMinutes	0
  ::Log_Flush

  ::taourl::init_common $::httpd_config
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
  ::Doc_Redirect $url
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
  dict set result host    $::env(HTTP_HOST)
  dict set result referer $::env(HTTP_REFERER)
  dict set result cookie  $::env(HTTP_COOKIE)
  return $result
}

###
# topic: 997a5a0b-f5e5-84d5-789a-cfc2f67e3a03
###
proc ::taourl::uploadUrl {url path handler} {
  ::Upload_Url $url $path $handler 
}

# Main handler for Direct domains (i.e. tcl commands)
# prefix: the Tcl command prefix of the domain registered with Direct_Url 
# sock: the socket back to the client
# suffix: the part of the url after the domain prefix.
#
# This calls out to the Tcl procedure named "$prefix$suffix",
# with arguments taken from the form parameters.
# Example:
# Direct_Url /device Device
# if the URL is /device/a/b/c, then the Tcl command to handle it
# should be
# proc Device/a/b/c
# You can define the content type for the results of your procedure by
# defining a global variable with the same name as the procedure:
# set Device/a/b/c text/plain
#  The default type is text/html

source [file join [file dirname [file normalize [info script]]] common.tcl]

