package require tile
package require tclmacbag

if {[tk windowingsystem] == "x11"} { style theme use alt }

# Setup a dialog box
wm withdraw .
set w .main
::tclmacbag::toplevel $w
wm protocol $w WM_DELETE_WINDOW { exit }
wm title $w "TclMacBag widgets"
wm resizable $w off off

set picture1   [image create photo -file [file join [file dirname [info script]] Images image1.gif]]
set pictureA   [image create photo -file [file join [file dirname [info script]] Images imageA.gif]]
set SE_Replace [image create photo -file [file join [file dirname [info script]] Images searchentry-replace.gif]]

::tclmacbag::toolbar [ttk::frame .main.title] -row 0 -column 1 -sticky nsew
grid [ttk::label .main.title.l1  -text "Toolbar: (On Mac, click above-right)"] -row 1 -column 1
grid [ttk::separator .main.title.sep -orient horizontal] -row 2 -column 1 -sticky nsew

grid [ttk::frame .main.combos] -row 1 -column 1 -sticky w -padx 10
grid [ttk::label .main.combos.t1 -text "Combo: "] -row 1 -column 1 -sticky w
grid [::tclmacbag::combo .main.combos.m1 -textvariable animals -values [list  {Giant Panda} Cat Dog {Drop Bear}] ] -row 1 -column 2 -sticky nsew

grid [ttk::frame .main.a] -row 10 -column 1 -sticky nsew -padx 10
grid [ttk::label .main.a.b0  -text "Flatbutton: "] -row 1 -column 0 -sticky w
grid [::tclmacbag::flatbutton .main.a.b1 -image $picture1 -command { tk_messageBox -message "Box 1\nAnimals: $animals" }] -row 1 -column 1 
grid [::tclmacbag::flatbutton .main.a.b2 -image $picture1 -command { tk_messageBox -message "Box 2\nAnimals: $animals" } -state disabled ] -row 1 -column 2

grid [ttk::frame .main.b] -row 11 -column 1 -sticky nsew -padx 10
grid [ttk::label .main.b.b0  -text "Flatbutton (-force yes): "] -row 1 -column 0 -sticky w
grid [::tclmacbag::flatbutton .main.b.b1 -image $picture1 -command { tk_messageBox -message "Box 3\nAnimals: $animals" } -force yes] -row 1 -column 1 
grid [::tclmacbag::flatbutton .main.b.b2 -image $picture1 -command { tk_messageBox -message "Box 4\nAnimals: $animals" } -force yes -state disabled] -row 1 -column 2

grid [ttk::frame .main.search] -row 20 -column 1 -sticky nsew -padx 10

grid [ttk::label .main.search.l1  -text "Searchentry: "] -row 1 -column 1 -sticky w
grid [::tclmacbag::searchentry .main.search.se -textvariable ::bob] -row 2 -column 1 -sticky nsew
grid [ttk::label .main.search.l2  -text "Searchentry (with -image): "] -row 3 -column 1 -sticky w
grid [::tclmacbag::searchentry .main.search.re -textvariable ::ben -image $SE_Replace] -row 4 -column 1 -sticky nsew

grid [ttk::frame .main.tlb] -row 30 -column 1 -sticky nsew -padx 10
grid [ttk::label .main.tlb.l1  -text "Text: "] -row 1 -column 1 -sticky w
grid [::tclmacbag::text .main.tlb.text -width 30 -height 3] -row 2 -column 1 -sticky nsew

# .main.tlb.text_Text insert end "Hello. this is some test text."
.main.tlb.text insert end "Hello. this is some test text."
after 10000 { .main.tlb.text configure -state disabled }


grid [ttk::label .main.tlb.l2  -text "Listbox: "] -row 3 -column 1 -sticky w
grid [::tclmacbag::listbox .main.tlb.lb -width 30 -height 3] -row 4 -column 1 -sticky nsew
.main.tlb.lb insert end {Giant Panda} Cat Dog {Drop Bear}

grid [ttk::frame .main.help] -row 49 -column 1 -sticky nsew -padx 10
grid [ttk::label .main.help.lb -text "Helpbutton:"] -row 1 -column 1 -sticky w
grid [::tclmacbag::helpbutton .main.help.b -command { tk_messageBox -message "Help Box" }] -row 1 -column 2 -sticky e

grid [ttk::frame .main.q] -row 50 -column 1 -sticky nsew -pady 10 -padx 10
grid [ttk::button .main.q.quit -text "Quit" -command { set end 1 }] -row 10 -column 1

grid rowconfigure      .main {1 2} -weight 1
grid columnconfigure   .main 1 -weight 1


grid rowconfigure      .main.combos 1 -weight 1
grid columnconfigure   .main.title 1 -weight 1
grid rowconfigure      .main.combos 4 -weight 1
grid columnconfigure   .main.combos 2 -weight 1
grid columnconfigure   .main.search 1 -weight 1
grid columnconfigure   .main.tlb 1 -weight 1
grid columnconfigure   .main.help 1 -weight 1

grid columnconfigure   .main.a 0 -weight 1
grid columnconfigure   .main.b 0 -weight 1

# Set values and defaults
set animals Dog

vwait end
after 20 { exit }
