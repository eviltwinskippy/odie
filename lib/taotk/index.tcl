###
# The embyronic base classes and high level abstractions
# used by the IRMSDE suite of mega-widgets
#
# We provide a single package as most of these are interdependent
###

package provide taotk 0.1
package require tao 2.0
package require Tk

::namespace eval ::objects {}

::namespace eval ::tao {}

::namespace eval ::taotk {}

::namespace eval ::taotk::icon {}

###
# topic: ad669362-d10b-794d-183a-7c4957cadb79
###
proc ::tao::db_console {} {
  if {[winfo exists .odiedb]} {
    wm deiconfiy .odiedb
    raise .odiedb
    return
  }
  taotk::sqlconsole .odiedb -db ::tao::db
}

if {$::tcl_platform(platform) eq "windows"} {
  set ::tao::platform windows
  catch {::ttk::style theme use xpnative}
} else {
  if {$tcl_platform(os) == "Darwin"} {
    set ::tao::platform macosx
  } else {
    set ::tao::platform unix
  }
  catch {::ttk::style theme use clam}
}

set cpath  [file dirname [info script]]
load_path [file dirname [info script]] {
  widget.tcl
  page.tcl
  megawidget.tcl
  toolwin.tcl
  tree.tcl
  scrollframe.tcl
  application.tcl
  notebook.tcl
  preferences.tcl
  notetab.tcl
  console.tcl
}
load_path [file join [file dirname [info script]] dynamic] {basic.tcl select.tcl}

if {[info command ::taotk::stylesheet] eq {}} {
  ###
  # Create a default style sheet
  ###
  ::taotk::meta::widget.stylesheet create ::taotk::stylesheet
}

set rpath  [file join [file dirname [info script]] resources]
foreach file [glob [file join $rpath *]] {
  if [catch {
  image create photo ::taotk::icon::[file rootname [file tail $file]] -file $file
  } err] {
    puts "Bad image: [file tail $rpath]"
  }
}
switch $::tao::platform {
  macosx {
    image create photo ::taotk::icon::help -file [file join $rpath help-mac.gif]
  }
  windows {
    image create photo ::taotk::icon::help -file [file join $rpath help-windows.gif]
  }
  default {
    image create photo ::taotk::icon::help -file [file join $rpath help-x11.gif]
  }
}

