##############
# Disclosure Frame - dframe
# Part of TclMacBag by Peter Caffin, 2007.
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::dframe {
 ##########################

 component ttklabel
 component ttkimage

 delegate method * to ttklabel

 constructor {args} {
  if {[catch {array set arg $args}]} { bgerror "Unbalanced args for ::tclmadbag::frame"; return }
  if {[info exists arg(-autoresize)] && $arg(-autoresize)=="on"} { set ::tclmacbag::dframeautoresize($win) 1 }
  variable ttklabel
  ttk::frame $win
  installhull $win -padx 0 -pady 0 -sticky nsew
  ttk::frame ${win}.frame
  ttk::frame ${win}.int
  set f ${win}.int
  ttk::label $f.label -text $arg(-label)
  ttk::label $f.image -image TclMacBag.dframeimage(closed)
  set ttklabel ${win}.label
  set ttkimage ${win}.image
  grid $f.image -row 1 -column 1 -sticky w -padx 0 -pady 0
  grid $f.label -row 1 -column 2 -sticky w -padx 0 -pady 0
  grid $f       -row 1 -column 1 -sticky w -padx 0 -pady 0
  grid columnconfigure $win 1 -weight 1
  grid columnconfigure $win.frame 1 -weight 1
  grid rowconfigure $win 2 -weight 1
  grid rowconfigure $win.frame 1 -weight 1
  bind $f.image <Button-1> "::tclmacbag::dframe::Toggle $win"
  bind $f.label <Button-1> "::tclmacbag::dframe::Toggle $win"
  bind $win <Destroy> "catch { unset ::tclmacbag::dframetoggle($win) }"
  }

 proc Toggle {w} {
  if {[info exists ::tclmacbag::dframetoggle($w)]} {
   # Hide the toolbar
   unset ::tclmacbag::dframetoggle($w)
   ${w}.int.image configure -image TclMacBag.dframeimage(closed)
   grid forget ${w}.frame
   } else {
   # Show the toolbar
   set ::tclmacbag::dframetoggle($w) 1
   eval grid ${w}.frame -row 2 -column 1 -rowspan 2 -sticky nsew -padx 0 -pady 0
   ${w}.int.image configure -image TclMacBag.dframeimage(open)
   }
  if {[info exists ::tclmacbag::dframeautoresize($w)]} { ::tclmacbag::dbutton::Resize $w }
  }

proc ToggleTo {w args} {
 if {[catch {array set arg $args}]} { bgerror "Unbalanced args for ::tclmacbag::dframe::ToggleTo"; return }
 if {![info exists arg(-state)]} { bgerror "::tclmacbag::dframe::ToggleTo requires -state option" ; return }
 if {$arg(-state)=="open"} {
  # Switch on
  catch { unset ::tclmacbag::dframetoggle($w) }
  ::tclmacbag::dframe::Toggle $w
  } else {
  # Switch off
  set ::tclmacbag::dframetoggle($w) 1
  ::tclmacbag::dframe::Toggle $w
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

# Images for dframe
if {[tk windowingsystem] == "windows"} {
 image create photo TclMacBag.dframeimage(open)   -file [file join [file dirname [info script]] Resources dframe-minus.gif]
 image create photo TclMacBag.dframeimage(closed) -file [file join [file dirname [info script]] Resources dframe-plus.gif]
 } else {
 image create photo TclMacBag.dframeimage(open)   -file [file join [file dirname [info script]] Resources dframe-open.png]
 image create photo TclMacBag.dframeimage(closed) -file [file join [file dirname [info script]] Resources dframe-closed.png]
 }
