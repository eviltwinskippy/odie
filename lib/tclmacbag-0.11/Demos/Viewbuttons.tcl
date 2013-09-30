package require tile
package require tclmacbag

if {[tk windowingsystem] == "x11"} {style theme use alt }

# Setup a dialog box
wm withdraw .
set w .main
::tclmacbag::toplevel $w
wm protocol $w WM_DELETE_WINDOW {exit }
wm title $w "Viewbutton styles"
wm resizable $w off off

# Init
set pictureA [image create photo -file [file join [file dirname [info script]] Images imageA.gif]]
set pictureB [image create photo -file [file join [file dirname [info script]] Images searchentry-replace.gif]]

# Group buttons
switch $::tile::currentTheme {
 "aqua"      {set color #A1A1A1 ;# Current colour } 
 "winnative" {set color "SystemButtonFace" }
 "xpnative"  {set color "SystemButtonFace" }
 "clam"      {set color "#dcdad5" }
 "step"      {set color "#a0a0a0" }
 default     {set color "#d9d9d9" }
 } ;# A darker grey for Mac users, theme defaults for everyone else.

set color #A1A1A1

grid [::tclmacbag::colorframe .main.multi -background $color -force yes] -row 2 -column 1 -sticky nsew

grid [::tclmacbag::colorframe .main.multi.pill -background $color -force yes] -row 1 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.multi.pill.b1 -background $color -image $pictureA -style pill-left   -command {puts Test} -force yes -variable ::a -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.multi.pill.b2 -background $color -image $pictureA -style pill-middle -command {puts Test} -force yes -variable ::a -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.multi.pill.b3 -background $color -image $pictureA -style pill-right  -command {puts Test} -force yes -variable ::a -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.multi.l1 -text "pill-left, pill-middle, pill-right" -background $color] -row 1 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.multi.chrome -background $color -force yes] -row 2 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.multi.chrome.b1 -background $color -image $pictureA -style chrome-left   -command {puts Test} -force yes -variable ::b -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.multi.chrome.b2 -background $color -image $pictureA -style chrome-middle -command {puts Test} -force yes -variable ::b -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.multi.chrome.b3 -background $color -image $pictureA -style chrome-right  -command {puts Test} -force yes -variable ::b -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.multi.l2 -text "chrome-left, chrome-middle, chrome-right" -background $color] -row 2 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.multi.steel -background $color -force yes] -row 3 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.multi.steel.b1 -background $color -image $pictureA -style steel-left   -command {puts Test} -force yes -variable ::c -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.multi.steel.b2 -background $color -image $pictureA -style steel-middle -command {puts Test} -force yes -variable ::c -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.multi.steel.b3 -background $color -image $pictureA -style steel-right  -command {puts Test} -force yes -variable ::c -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.multi.l3 -text "steel-left, steel-middle, steel-right" -background $color] -row 3 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.multi.simple -background $color -force yes] -row 4 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.multi.simple.b1 -background $color -image $pictureA -style simple-left   -command {puts Test} -force yes -variable ::d -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.multi.simple.b2 -background $color -image $pictureA -style simple-middle -command {puts Test} -force yes -variable ::d -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.multi.simple.b3 -background $color -image $pictureA -style simple-right  -command {puts Test} -force yes -variable ::d -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.multi.l4 -text "simple-left, simple-middle, simple-right" -background $color] -row 4 -column 2 -sticky w -padx 5 -pady 5

set color #b1b1b1
grid [::tclmacbag::colorframe .main.tb -background $color -force yes] -row 3 -column 1 -sticky nsew

grid [::tclmacbag::colorframe .main.tb.pill -background $color -force yes] -row 1 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.tb.pill.b1 -background $color -text "Cats and Dogs" -style pill-left   -command {puts Test} -force yes -variable ::a2 -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.tb.pill.b2 -background $color -text "Men and Women" -style pill-middle -command {puts Test} -force yes -variable ::a2 -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.tb.pill.b3 -background $color -text "Giraffes" -style pill-right  -command {puts Test} -force yes -variable ::a2 -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.tb.l1 -text "Text using Pill style" -background $color] -row 1 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.tb.chrome -background $color -force yes] -row 2 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.tb.chrome.b1 -background $color -text "Cats and Dogs" -style chrome-left   -command {puts Test} -force yes -variable ::b2 -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.tb.chrome.b2 -background $color -text "Men and Women" -style chrome-middle -command {puts Test} -force yes -variable ::b2 -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.tb.chrome.b3 -background $color -text "Giraffes" -style chrome-right  -command {puts Test} -force yes -variable ::b2 -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.tb.l2 -text "Text using Chrome style" -background $color] -row 2 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.tb.steel -background $color -force yes] -row 3 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.tb.steel.b1 -background $color -text "Cats and Dogs" -style steel-left   -command {puts Test} -force yes -variable ::c2 -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.tb.steel.b2 -background $color -text "Men and Women" -style steel-middle -command {puts Test} -force yes -variable ::c2 -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.tb.steel.b3 -background $color -text "Giraffes" -style steel-right  -command {puts Test} -force yes -variable ::c2 -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.tb.l3 -text "Text using Steel style" -background $color] -row 3 -column 2 -sticky w -padx 5 -pady 5

grid [::tclmacbag::colorframe .main.tb.simple -background $color -force yes] -row 4 -column 1 -sticky nsew -padx 5
grid [::tclmacbag::viewbutton .main.tb.simple.b1 -background $color -text "Cats and Dogs" -style simple-left   -command {puts Test} -force yes -variable ::d2 -onwhen 1 ] -row 1 -column 1 -pady 5
grid [::tclmacbag::viewbutton .main.tb.simple.b2 -background $color -text "Men and Women" -style simple-middle -command {puts Test} -force yes -variable ::d2 -onwhen 2 ] -row 1 -column 2 -pady 5
grid [::tclmacbag::viewbutton .main.tb.simple.b3 -background $color -text "Giraffes" -style simple-right  -command {puts Test} -force yes -variable ::d2 -onwhen 3 ] -row 1 -column 3 -pady 5
grid [label .main.tb.l4 -text "Text using Simple style" -background $color] -row 4 -column 2 -sticky w -padx 5 -pady 5

# Finish up
grid rowconfigure      .main 10 -weight 1
grid columnconfigure   .main 1 -weight 1
grid columnconfigure   .main.multi 10 -weight 1
grid columnconfigure   .main.tb 10 -weight 1

# Defaults
set ::a 1
set ::b 2
set ::c 3
set ::d 1
set ::a2 1
set ::b2 2
set ::c2 3
set ::d2 1


vwait end
after 20 exit