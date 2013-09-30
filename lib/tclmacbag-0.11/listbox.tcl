##############
# Listbox widget wrapping
# Part of TclMacBag by Peter Caffin, 2007.
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::listbox {
 component tklistbox
 component ttkentry

 delegate method * to tklistbox except state
 delegate method state to ttkentry

 constructor {args} { 
  variable ttkentry
  variable tklistbox
  # We're packing a listbox widget into a an entry widget to scavenge the entry widget's focus stuff.
  ttk::frame $win
  ttk::entry ${win}_Entry
  ::listbox ${win}_Listbox -borderwidth 0 -highlightthickness 0
  installhull $win -padx 0 -pady 0 -sticky nsew
  set ttkentry ${win}_Entry
  set tklistbox ${win}_Listbox
  bind $tklistbox <FocusIn> "$win state focus"
  bind $tklistbox <FocusOut> "$win state !focus"
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  if {$ThemeNow == "aqua"} { set pad 4 } else { set pad 2 }
  pack $ttkentry -in $win -padx 0 -pady 0 -expand true -fill both
  pack $tklistbox -in $ttkentry -padx $pad -pady $pad -expand true -fill both
  # Apply args
  foreach {opt value} $args {
   if {$opt != "-borderwidth" && $opt != "-highlightthickness" && $opt != "-background" && $opt != "-bg"} { catch { ${win} configure $opt $value } }
   }
  bind $tklistbox <Configure> [list $self updateState]
  }

 method updateState {} {
  variable ttkentry
  variable tklistbox
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  switch $ThemeNow {
   "aqua"      { set bgcolor white ; set dacolor white } 
   "winnative" { set bgcolor white ; set dacolor "SystemButtonFace" }
   "xpnative"  { set bgcolor white ; set dacolor "SystemButtonFace" }
   "clam"      { set bgcolor white ; set dacolor "#dcdad5" }
   "step"      { set bgcolor white ; set dacolor "#a0a0a0" }
   default     { set bgcolor white ; set dacolor "#d9d9d9" }
   }
  set state [lindex [$tklistbox configure -state] 4]
  if {$state=="disabled" } { 
   $win configure -background "$dacolor"
   } else { 
   $win configure -background "$bgcolor"
   }
  # tk_messageBox -message "So, the state is $state. Is the background $dacolor?"
  }

 # Ends
 }
