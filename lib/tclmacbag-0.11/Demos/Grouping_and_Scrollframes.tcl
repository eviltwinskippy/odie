############
# TclMacBag Example
############

package require tclmacbag

wm withdraw .
tclmacbag::toplevel .tl
wm minsize  .tl 350 1
wm resizable .tl 0 0 
wm title .tl "Various widgets"

if {[tk windowingsystem]=="x11"} { style theme use alt } ;# Looks nicest :)

############
# PNB (Panther Notebook)
############

grid [::tclmacbag::pnb .tl.pnb] -row 1 -column 1 -sticky nsew -padx 10 -pady 10
grid rowconfigure .tl 1 -weight 1 ; grid columnconfigure .tl 1 -weight 1

set pnb .tl.pnb
$pnb add [ttk::frame $pnb.a1] -text "Scrollframe"
$pnb add [ttk::frame $pnb.a2] -text "Groupbox"
$pnb add [ttk::frame $pnb.a3] -text "Disclosures"

#############
# Scrolledframe
#############

grid [::tclmacbag::scrolledframe $pnb.a1.sf -yscrollcommand "$pnb.a1.vs set"] -row 1 -column 1 -sticky nsew -padx {10 0} -pady 5 
grid [::tclmacbag::scrollbar $pnb.a1.vs -command "$pnb.a1.sf yview" -orient vertical] -row 1 -column 2 -sticky nse -padx {0 10} -pady 0
grid rowconfigure $pnb.a1 1 -weight 1 ; grid columnconfigure $pnb.a1 1 -weight 1

set a 1 ; while {$a < 51} { 
 grid [::ttk::label $pnb.a1.sf.scrolled.l$a -text "This is label #$a"] -row $a -column 1 -sticky w
 incr a 
 }

#############
# Groupbox
#############

grid [::tclmacbag::groupbox $pnb.a2.gb] -row 1 -column 1 -sticky nsew -padx 10 -pady 10
grid rowconfigure $pnb.a2 1 -weight 1 ; grid columnconfigure $pnb.a2 1 -weight 1

set gb $pnb.a2.gb
$gb add [ttk::label $gb.a1 -text "Burma is closer to Indonesia."] -text "European Burmese"
$gb add [ttk::label $gb.a2 -text "No, not Chairman Mau."] -text "Egyptian Mau"
$gb add [ttk::label $gb.a3 -text "The Rex which goes with tea."] -text "Devon Rex"
$gb add [ttk::label $gb.a4 -text "Pasties are made from these."] -text "Cornish Rex"

#############
# Disclosures
#############

set w $pnb.a3.buttons
grid [ttk::frame $w] -row 1 -column 1 -sticky nsew -padx 0 -pady {0 10}
grid [ttk::button $w.b2 -text "Open" -command { 
 foreach i [list $pnb.a3.df0.button ] { ::tclmacbag::dbutton::ToggleTo $i -state open }
 foreach i [list $pnb.a3.df1 $pnb.a3.df2] { ::tclmacbag::dframe::ToggleTo $i -state open }
 }] -row 1 -column 1 -sticky w
grid [ttk::button $w.b3 -text "Closed" -command { 
 foreach i [list $pnb.a3.df0.button ] { ::tclmacbag::dbutton::ToggleTo $i -state closed }
 foreach i [list $pnb.a3.df1 $pnb.a3.df2] { ::tclmacbag::dframe::ToggleTo $i -state closed }
 }] -row 1 -column 2 -sticky w
grid [ttk::button $w.b1 -text "Toggle" -command { 
 foreach i [list $pnb.a3.df0.button ] { ::tclmacbag::dbutton::Toggle $i }
 foreach i [list $pnb.a3.df1 $pnb.a3.df2] { ::tclmacbag::dframe::Toggle $i }
 }] -row 1 -column 3 -sticky w

# ::tclmacbag::dframe::Toggle $w
# ::tclmacbag::dframe::ToggleTo $w -state open


# Disclosure buttons

set w $pnb.a3.df0 ; set f $w.frame
grid [ttk::frame ${w}] -row 10 -column 1 -sticky w
grid [ttk::label ${w}.label -text "Disclosure Button: "] -row 3 -column 1 -sticky w
grid [::tclmacbag::dbutton ${w}.button -autoresize on -widget $pnb.a3.zzz -gridopts {-row 99 -column 1 -sticky nsew -padx 5 -pady 5}] -row 3 -column 2 -sticky nsew
set w $pnb.a3.zzz ; set f $w.frame
::tclmacbag::boxframe $w
grid columnconfigure $w 1 -weight 1
grid [ttk::label $w.label -text "The Disclosure Button can disclose any widget, anywhere."] -row 2 -column 1 -sticky w

# Disclosure frame, example 1

set w $pnb.a3.df1 ; set f $w.frame
grid [::tclmacbag::dframe $w -label "Disclosure Frame" -autoresize on] -row 11 -column 1 -sticky nsew
grid rowconfigure $pnb.a3 100 -weight 1 ; grid columnconfigure $pnb.a3 1 -weight 1
grid [ttk::label $f.l1 -text "Examination of the Federal Government's Smart Traveller website paints a dim, dangerous picture of the world beyond our shores." -justify left -wraplength 320] -row 1 -column 1 -sticky w

# Disclosure frame, example 2

set w $pnb.a3.df2 ; set f $w.frame
grid [::tclmacbag::dframe $w -label "Disclosure Frame exposing a Boxframe" -autoresize on] -row 12 -column 1 -sticky nsew
grid rowconfigure $pnb.a3 100 -weight 1 ; grid columnconfigure $pnb.a3 1 -weight 1

grid [::tclmacbag::boxframe $f.lf] -row 1 -column 1 -sticky nsew -padx 5 -pady 0
grid [ttk::label $f.lf.l1 -text "This label is in a boxframe." ] -row 1 -column 1 -sticky w
grid [ttk::label $f.lf.l2 -text "But it could have been put in anything."] -row 2 -column 1 -sticky w
grid rowconfigure $f.lf 100 -weight 1 ; grid columnconfigure $f.lf 1 -weight 1

grid [ttk::separator $pnb.a3.sep -orient horizontal] -row 95 -column 1 -sticky ew

#############
# The End.
#############

vwait forever
exit
