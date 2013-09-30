#
##############################################################################
# balloon.tcl - procedures used by balloon help
#
# Copyright (C) 1996-1997 Stewart Allen
# 
# This is part of vtcl source code
# Adapted for general purpose by 
# Daniel Roche <dan@lectra.com>
# version 1.1 ( Dec 02 1998 ) 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

##############################################################################
#
package provide irm::balloon 0.2

###
# topic: d59aa411-3b31-31e0-86b3-e324338fa678
###
proc ::balEnter {w x y text} {
   global Bulle
   set Bulle(set) 0
   set Bulle(first) 1
   set cmd [list balloon $w $text $x $y]
   set Bulle(id) [after 250 $cmd ]
}

###
# topic: 435e6046-9a36-e303-1a0c-40bf6d9d3eb2
###
proc ::balloon {target message {cx 0} {cy 0} } {
  if {![info exists ::simconfig(font-popups)]} {
    set ::simconfig(font-popups) {fixed 8}
  }
    global Bulle
    if {$message==""} return
    if {$Bulle(first) == 1 } {
        set Bulle(first) 2
	if { $cx == 0 && $cy == 0 } {
	    set x [expr [winfo rootx $target] + ([winfo width $target]/2)]
	    set y [expr [winfo rooty $target] + [winfo height $target] + 4]
	} else {
	    set x [expr $cx + 4]
	    set y [expr $cy + 4]
	}
        catch {destroy .balloon}
        toplevel .balloon -bg black
        
        set winsys [tk windowingsystem] 
        if {$winsys eq "aqua"} {
            ::tk::unsupported::MacWindowStyle style .balloon help none
        }
        if {$winsys eq "win32" } {
          wm overrideredirect .balloon 1
          wm attributes .balloon -topmost 1
        }
 
        set sw [winfo screenwidth .balloon]
        set sh [winfo screenheight .balloon]
        label .balloon.l -justify left \
            -text $message -relief flat \
            -bg #ffffaa -fg black -padx 2 -pady 0 -anchor w \
            -font $::simconfig(font-popups)
        pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${sw}+${sh}
        update idletasks
        if {![winfo exists .balloon]} return
        set width [winfo reqwidth .balloon]
        set height [winfo reqheight .balloon]
        if {$x+$width>$sw} {set x [expr {$cx - ($width+4)}]}
        if {$y>$sh*0.75} {set y [expr {$cy - ($height+4)}]}
        wm geometry .balloon +${x}+${y}
        set Bulle(set) 1
        set Bulle(target) $target
    }
}

###
# topic: c14acc32-d305-4cb2-95c1-249d1948b459
###
proc ::balMotion {w x y text} {
   global Bulle
   if {$Bulle(set) == 0} { 
       after cancel $Bulle(id)
       set cmd [list balloon $w $text $x $y]
       set Bulle(id) [after 250 $cmd ]
   }
}

###
# topic: 433253e2-3e2e-c46d-6c67-20a797e64ae8
###
proc ::kill_balloon {} {
    global Bulle
    after cancel $Bulle(id)
    if {[winfo exists .balloon] == 1} {
        destroy .balloon
    }
    set Bulle(set) 0
}

###
# topic: 4a03af7a-3e35-a897-4037-18445bd4e779
###
proc ::set_balloon {target message} {
    global Bulle
    set Bulle($target) $message
    set x [bindtags $target]
    if {[lsearch $x Bulle]<0} {
        lappend x Bulle
        bindtags $target $x
    }
    if { [winfo class $target] == "TButton" } {
	$target configure -width 0
    }
}

###
# topic: e542a87a-7929-1981-e52a-7bf270fa4df0
###
proc ::setBalloonCanvasItem {w id text} {
   global Bulle
   $w bind $id <Enter> [list +[namespace current]::balEnter %W %X %Y $text]

   $w bind $id <Leave> {+
      set Bulle(first) 0
      kill_balloon
   }

   $w bind $id <Button> {+
      set Bulle(first) 0
      kill_balloon
   }

   $w bind $id <Motion> [list +[namespace current]::balMotion %W %X %Y $text]
}

bind Bulle <Enter> {+
    set Bulle(set) 0
    set Bulle(first) 1
    set Bulle(id) [after 250 {balloon %W $Bulle(%W) %X %Y}]
}

bind Bulle <Button> {+
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Leave> {+
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Destroy> {
    if {[info exists Bulle(target)] && "%W"==$Bulle(target)} {
        kill_balloon
    }
}

bind Bulle <Motion> {
    if {$Bulle(set) == 0} {
        after cancel $Bulle(id)
        set Bulle(id) [after 250 {balloon %W $Bulle(%W) %X %Y}]
    }
}




if {[info exists argv] && ([lsearch $argv -testBALLOON] >= 0)} {
  set w [button .b -text Exit -command exit]
  pack $w
  set_balloon $w "Click me to exit"
  
  canvas .c
  pack .c
#  set_balloon .c "Your cursor is on the canvas"
  
  set id [.c create text 20 20 -anchor nw -text "Mouse Over Me"]
  setBalloonCanvasItem .c $id "Hey, I see the cursor!"
}

