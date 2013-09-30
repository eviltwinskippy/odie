
set Config(home) [file normalize \
	[file join [file dirname [info script]] ..] ]
set Config(lib)       [file join $Config(home) lib]

if { $argv eq {} } {
  set siteRoot $Config(home)
  set root [file join $Config(home) htdocs default]

  Direct_Url /home ::home
  proc ::home {} {
    return "<h1>Welcome home!</h1>"
  }
} else {
  
}

set httpd_config {
  vhostRoot /opt/local/httpd/sites
  siteRoot  /opt/local/httpd/sites/default
  docRoot   /opt/local/httpd/sites/default/htdocs
  library   /opt/local/httpd/sites/default/libtml

  site      default
  smtp_host localhost:25
}

dict set httpd_config home $Config(home)
dict set httpd_config lib $Config(lib)

set ::tao(smtp_host) mail.etoyoc.com:2500
namespace eval ::security {}


foreach {arg val} $argv {
  switch $arg {
    vhostRoot {
      dict set httpd_config vhostRoot [file normalize $val]
    }
    site {
      dict with httpd_config {
        set site $val
        set siteRoot [file join $vhostRoot $val]
        set docRoot  [file join $siteRoot htdocs]
        set library  [file join $siteRoot libtml]
      }
    }
    default {
      dict set httpd_config $var $val
    }
    #siteRoot {
    #  set ::siteRoot [file normalize $val]
    #}
  }
}
proc ::thread_init {config} {
  
}
if { $Config(lib) ni $auto_path } {
  lappend auto_path $Config(lib)
}
package require listutil
#lappend auto_path /opt/local/odie/lib
# Guess the root directory.

package require tao-httpd-wibble
set siteRoot [dict get $httpd_config siteRoot]
if {[file exists $siteRoot/httpd.rc]} {
  source $siteRoot/httpd.rc
}
set libpath [dict get $httpd_config library]
if {[file exists $libpath]} {
  foreach file {
    init.tcl
  } {
    set fname [file join $libpath $file]
    if {[file exists $fname]} {
      source $fname
    }
  }
  foreach file [glob [file join $libpath *.tcl]] {
    if {[file tail $file] in {pkgIndex.tcl init.tcl}} continue
    source $file
  }
}

::thread_init $httpd_config

# Define zone handlers.
::wibble::handle /vars vars

if {[file exists [dict get $httpd_config docRoot]]} {
  ::httpd::static_root / [dict get $httpd_config docRoot]
}

# Start a server and enter the event loop.
catch {
    ::wibble::listen 8015
}
vwait forever
