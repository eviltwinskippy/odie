##############
# Panther Notebook (PNB)
# Part of TclMacBag by Peter Caffin, 2007.
# My first Snit widget. Guaranteed to prove cringwworthy when I look at it in 6-12 months time :-).
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::pnb {
 component notebook

 delegate method add to notebook
 delegate method forget to notebook
 delegate method index to notebook
 delegate method insert to notebook
 delegate method select to notebook
 delegate method tab to notebook
 delegate method tabs to notebook

 constructor {args} { 
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  switch -- $ThemeNow {
   "aqua"  {
           ttk::labelframe $win -labelanchor n -text {}
           ttk::notebook $win.nb -style Plain.TNotebook -padding {0 15 0 0} ;# left top right bottom
           installhull $win -padx 0 -pady 0 -sticky nsew
           set notebook $win.nb
           grid rowconfigure $win 1 -weight 1 ; grid columnconfigure $win 1 -weight 1
           grid $notebook -sticky nsew -padx 0 -pady 0 -row 1 -column 1
           ::ttk::frame $win.buttons
           update idletasks
           bind $win <Configure> [list $self _updateControls]
           bind $notebook <<NotebookTabChanged>> [list $self _updateControls]
           bind $notebook <Destroy> "catch { unset ::tclmacbag::pnbvalue($win) ; unset ::tclmacbag::pnbwidth($win) }"
           }
   default {
           ttk::frame $win
           ttk::notebook $win.nb -padding {0 5 0 0} ;# left top right bottom
           installhull $win -padx 0 -pady 0 -sticky nsew
           set notebook $win.nb
           grid rowconfigure $win 1 -weight 1 ; grid columnconfigure $win 1 -weight 1
           grid $notebook -sticky nsew -padx 0 -pady 0 -row 1 -column 1
           }
   }
  }

 method _updateControls {} {
  variable notebook
  # Anything changed?
  if {[info exists ::tclmacbag::pnbwidth($win)] && $::tclmacbag::pnbwidth($win) == [winfo width $win]} { return }
  # Set up the buttons
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  if {$ThemeNow == "aqua"} {
   # Mac
   set last [expr [llength [$notebook tabs]]-1]
   # Add any viewbuttons not installed
   set i -1 ; foreach tab [$notebook tabs] {
    incr i ; switch $i {
     0       { set St "tnb-left" } 
     default { set St "tnb-middle" }
     }
    if {![winfo exists $win.buttons.b$i] } { 
     grid [::tclmacbag::pnb_viewbutton $win.buttons.b$i -text [$notebook tab $tab -text] -style $St -command [list $win.nb select $i] -variable ::tclmacbag::pnbvalue($win) -onwhen $i ] -row 1 -column $i
     } else {
     $win.buttons.b$i configure -style pnb_viewbutton.$St
     }
    }
   $win.buttons.b$i configure -style pnb_viewbutton.tnb-right ;# Last one in is a rotten right-button
   if {![info exists ::tclmacbag::pnbvalue($win)]} { set ::tclmacbag::pnbvalue($win) 0 ; $win.nb select 0 } ;# Set a default value.
   update idletasks
   # Mac
   set ypad -12
   set winmiddle [expr [winfo width $win]/2]
   set halfbuttons [expr [winfo reqwidth $win.buttons]/2]
   set w [expr $winmiddle-$halfbuttons] ;# Centered.
   } else { 
   # Everyone else
   set ypad -17 
   set w 5 ;# Left with some padding.
   }
#  grid forget $win.buttons
  place $win.buttons -in $win -y $ypad -x $w -anchor nw
  set ::tclmacbag::pnbwidth($win) [winfo width $win]
  update idletasks
  } 
 # Ends
 }
