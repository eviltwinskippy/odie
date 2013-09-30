##############
# Disclosure Button - dbutton
# Part of TclMacBag by Peter Caffin, 2008.
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::dbutton {
 ##########################

 component ttklabel
 component ttkimage

 delegate method * to ttklabel

 constructor {args} {
  if {[catch {array set arg $args}]} { bgerror "Unbalanced args for ::tclmadbag::frame" ; return }
  if {![info exists arg(-widget)] || ![info exists arg(-gridopts)]} { bgerror "-gridopts or -widget options not present." ; return }
  if {[info exists arg(-autoresize)] && $arg(-autoresize)=="on"} { set ::tclmacbag::dbuttonautoresize($win) 1 }
  set ::tclmacbag::dbuttonwidget($win)   $arg(-widget)
  set ::tclmacbag::dbuttongridopts($win) $arg(-gridopts)
  variable ttklabel
  ttk::frame $win
  installhull $win -padx 0 -pady 0 -sticky nsew
  ttk::frame ${win}.frame
  ttk::frame ${win}.int ; set f ${win}.int
  ::tclmacbag::stylebutton $f.button -style gel-small -image TclMacBag.dbuttonimage(closed) -command "::tclmacbag::dbutton::Toggle $win"
  set ttklabel ${win}.label

  # tk_messageBox -message $args
  grid $f.button -row 1 -column 2 -sticky w -padx 0 -pady 0
  grid $f       -row 1 -column 1 -sticky w -padx 0 -pady 0
  grid columnconfigure $win 1 -weight 1
  grid columnconfigure $win.frame 1 -weight 1
  grid rowconfigure $win 2 -weight 1
  grid rowconfigure $win.frame 1 -weight 1
  bind $win <Destroy> "catch { unset ::tclmacbag::dbuttontoggle($win) }"
  }

 proc Toggle {w} {
  if {[info exists ::tclmacbag::dbuttontoggle($w)]} {
   # Hide the toolbar
   unset ::tclmacbag::dbuttontoggle($w)
   ${w}.int.button configure -image TclMacBag.dbuttonimage(closed)
   grid forget $::tclmacbag::dbuttonwidget($w)
   } else {
   # Show the toolbar
   set ::tclmacbag::dbuttontoggle($w) 1
   eval grid $::tclmacbag::dbuttonwidget($w) $::tclmacbag::dbuttongridopts($w)
   ${w}.int.button configure -image TclMacBag.dbuttonimage(open)
   }
  if {[info exists ::tclmacbag::dbuttonautoresize($w)]} { ::tclmacbag::dbutton::Resize $w }
  }

proc ToggleTo {w args} {
 if {[catch {array set arg $args}]} { bgerror "Unbalanced args for ::tclmacbag::dbutton::ToggleTo"; return }
 if {![info exists arg(-state)]} { bgerror "::tclmacbag::dbutton::ToggleTo requires -state option" ; return }
 if {$arg(-state)=="open"} {
  # Switch on
  catch { unset ::tclmacbag::dbuttontoggle($w) }
  ::tclmacbag::dbutton::Toggle $w
  } else {
  # Switch off
  set ::tclmacbag::dbuttontoggle($w) 1
  ::tclmacbag::dbutton::Toggle $w
  }
 }

proc Resize {w} {
 update idletasks
 # Has the height changed? If not, lets bail out.
 if {[winfo reqheight [winfo toplevel $w]] == [winfo height [winfo toplevel $w]]} { return }
 # If we're managing the size using this mechanism, lets ensure the window's not resizable.
 wm resizable [winfo toplevel $w] 0 0
 # Resize
 wm withdraw [winfo toplevel $w]
 wm geometry [winfo toplevel $w] [winfo reqwidth [winfo toplevel $w]]x[winfo reqheight [winfo toplevel $w]]
 wm deiconify [winfo toplevel $w]
 }

 ##########################
 } ;# End of snit widget

######
# Init
######

# Images for dbutton
image create photo TclMacBag.dbuttonimage(open)   -file [file join [file dirname [info script]] Resources dbutton-open.png]
image create photo TclMacBag.dbuttonimage(closed) -file [file join [file dirname [info script]] Resources dbutton-closed.png]
