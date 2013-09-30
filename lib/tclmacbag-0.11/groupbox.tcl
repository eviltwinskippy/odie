##############
# Groupbox by Peter Caffin, 2007.
# Based on one by Joe English, who is not to blame for this one :)
# Part of TclMacBag 
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::groupbox {
##########################################################

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
  ttk::labelframe $win -text {} 
  ttk::notebook $win.nb -style Plain.TNotebook -padding {0 12 0 0} ;# left top right bottom
  set notebook $win.nb
  tclmacbag::combo $win.buttons -textvariable ::tclmacbag::groupboxvalue($win) -postcommand "$self _updateNotebook $win.buttons"
  installhull $win -padx 0 -pady 0 -sticky nsew
  grid rowconfigure $win 1 -weight 1 ; grid columnconfigure $win 1 -weight 1
  grid $notebook -sticky nsew -padx 0 -pady 0 -row 1 -column 1
  update idletasks
  bind $win <Configure> [list $self _updateNotebook $win.buttons]
  bind $notebook <<NotebookTabChanged>> "set ::tclmacbag::groupboxvalue($win) \[$notebook tab current -text\]"
  bind $win.buttons <Map> [list $self _updateNotebook $win.buttons]
  bind $notebook <Destroy> "catch { unset ::tclmacbag::groupboxvalue($win) ; unset ::tclmacbag::groupboxwidth($win) }"
  }

 method _updateNotebook {combo} {
  variable notebook
  set tabs [$notebook tabs]
  if {[info exists ::tclmacbag::groupboxvalue($win)] && [llength $tabs] > 0} {
   foreach i $tabs { lappend vals [$notebook tab $i -text] }
   set pos [lsearch -exact $vals $::tclmacbag::groupboxvalue($win) ]
   if {$pos > -1} { $notebook select $pos }
   }
  # Update Tabs if we need to
  set vals {} ; foreach i [$notebook tabs] { lappend vals [$notebook tab $i -text] }
  ::tclmacbag::combo_Set $combo -values $vals -postcommand "$self _updateNotebook $win.buttons"
  if {[llength [$notebook tabs]] > 0 && ![info exists ::tclmacbag::groupboxvalue($win)] || $::tclmacbag::groupboxvalue($win)==""} {  
   $win.nb select 0 ; set ::tclmacbag::groupboxvalue($win) [$notebook tab 0 -text] ; update idletasks
   } ;# Set a default value.

  # Do we need to resize? If not, bail out.
  if {[info exists ::tclmacbag::groupboxwidth($win)] && $::tclmacbag::groupboxwidth($win) == [winfo width $win]} { return }
  # Set up the buttons
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  switch $ThemeNow {
   "aqua" {
       # Mac
       set ypad -12
       set winmiddle [expr [winfo width $win]/2]
       set halfbuttons [expr [winfo reqwidth $win.buttons]/2]
       set w [expr $winmiddle-$halfbuttons] ;# Centered.
       }
   "xpnative" {
       # XP Native has slightly oversize buttons
       set ypad -15
       set w 5 ;# Left with a little padding.
       }
   default { 
       # Tile fallback
       set ypad -16
       set w 5 ;# Left with a little padding.
       }
   }
  place $win.buttons -in $win -y $ypad -x $w -anchor nw
  set ::tclmacbag::groupboxwidth($win) [winfo width $win]
  update idletasks
  }

##########################################################
 } ;# End of snit::widgetadaptor ::tclmacbag::groupbox 
