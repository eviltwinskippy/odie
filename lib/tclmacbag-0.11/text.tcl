##############
# Text widget wrapping
# Part of TclMacBag by Peter Caffin, 2007.
##############

package require tile
package require snit

snit::widgetadaptor ::tclmacbag::text {
 component tktext
 component ttkentry

 delegate method * to tklistbox except state
 delegate method state to ttkentry

 constructor {args} { 
  variable ttkentry
  variable tktext
  # We're packing a text widget into a an entry widget to scavenge the entry widget's focus stuff.
  ttk::frame $win
  ttk::entry ${win}_Entry
  ::text ${win}_Text -borderwidth 0 -highlightthickness 0
  installhull $win -padx 0 -pady 0 -sticky nsew
  set ttkentry ${win}_Entry
  set tktext ${win}_Text
  bind $tktext <FocusIn> "$win state focus"
  bind $tktext <FocusOut> "$win state !focus"
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  if {$ThemeNow == "aqua"} { set pad 4 } else { set pad 2 }
  pack $ttkentry -in $win -padx 0 -pady 0 -expand true -fill both
  pack $tktext -in $ttkentry -padx $pad -pady $pad -expand true -fill both
  # Apply args
  foreach {opt value} $args {
   if {$opt != "-borderwidth" && $opt != "-highlightthickness" && $opt != "-background" && $opt != "-bg"} { catch { ${win} configure $opt $value } }
   }
  bind $tktext <Configure> [list $self updateState]
  }

 method updateState {} {
  variable ttkentry
  variable tktext
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  switch $ThemeNow {
   "aqua"      { set bgcolor white ; set dacolor white } 
   "winnative" { set bgcolor white ; set dacolor "SystemButtonFace" }
   "xpnative"  { set bgcolor white ; set dacolor "SystemButtonFace" }
   "clam"      { set bgcolor white ; set dacolor "#dcdad5" }
   "step"      { set bgcolor white ; set dacolor "#a0a0a0" }
   default     { set bgcolor white ; set dacolor "#d9d9d9" }
   }
  set state [lindex [$tktext configure -state] 4]
  if {$state=="disabled" } { 
   $win configure -background "$dacolor"
   } else { 
   $win configure -background "$bgcolor"
   }
  # tk_messageBox -message "So, the state is $state. Is the background $dacolor?"
  }

 # Ends
 }
