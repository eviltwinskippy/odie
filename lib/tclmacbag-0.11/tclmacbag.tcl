####################################################################
# TclMacBag
# Except where otherwise noted, TclMacBag is (C) Peter Caffin, 2007-
# For more info: http://tclmacbag.autons.net/
####################################################################

if {[info patchlevel] < 8.5 } { package require tile }
package require Img
package provide tclmacbag 0.11

namespace eval tclmacbag {
#############################################################################################
set ::tclmacbag::version 0.11

############
# Combo/Drop-Box
############

proc combo {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::combo $wn $args:\nWidget already exists." }
 set req 0 ; foreach {opt value} $args {
  switch -- $opt {
   "-textvariable" { incr req }
   "-values" {}
   "-postcommand" {}
   "-state" {}
   default { bgerror "While executing ::tclmacbag::combo $wn $args:\nUnknown option $opt $value\nMust be -textvariable, -values, -bind or -postcommand.\n" }
   }
  }
 if {![info exists req] || $req < 1} { bgerror "While executing ::tclmacbag::combo $wn $args\nRequires -textvariable declared.\n" }
 # Start
 foreach {opt value} $args { set arg($opt) $value }
 if {[tk windowingsystem]=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  catch { style configure TMenubutton -anchor w } ;# Fixes a positioning bug in Tile 0.7.8 on Mac. Needs catching as style command disappears in 0.8.x
  ttk::menubutton $wn -menu $wn.menu -direction flush ; menu $wn.menu
  if {[info exists arg(-textvariable)]} { ::tclmacbag::combo_Set $wn -textvariable $arg(-textvariable) }
  if {[info exists arg(-values)]} { ::tclmacbag::combo_Set $wn -values $arg(-values) }
  if {[info exists arg(-postcommand)]} { ::tclmacbag::combo_Set $wn -postcommand $arg(-postcommand) }
  if {[info exists arg(-state)]} {  ::tclmacbag::combo_Set $wn -state $arg(-state) }
  # Set the width
  if {[info exists arg(-values)]} {
   set max 0 ; foreach value $arg(-values) { if {[string length [list $value]] > $max} { set max [string length [list $value]] } }
   if {$max < 5} { set max 5 } ; $wn configure -width $max
   }
  } else {
  # Tile/Ttk on Windows/X11. Just a simple read-only combobox using Tile.
  ttk::combobox $wn -state readonly
  foreach {opt value} $args {
   switch -- $opt {
    "-textvariable" { ::tclmacbag::combo_Set $wn -textvariable $value }
    "-values" { ::tclmacbag::combo_Set $wn -values $value }
    "-postcommand" {::tclmacbag::combo_Set $wn -postcommand $value }
    "-state" { ::tclmacbag::combo_Set $wn -state $value }
    }
   }
  }
 # Finish up.
 return $wn
 }

proc combo_Set {wn args} {
 # Check for bad options.
 set req 0 ; foreach {opt value} $args {
  switch -- $opt {
   "-textvariable" {}
   "-values" {}
   "-state" {}
   "-postcommand" {}
  default { bgerror "Unknown option while executing ::tclmacbag::combo_Set $wn:\n$opt $value\nMust be -textvariable, -values or -postcommand.\n" }
  }
 }
 # Start
 foreach {key value} $args { set arg($key) $value }
 set type [winfo class $wn]
 if {$type=="TMenubutton"} {
  # Mac
  if {[info exists arg(-values)]} { set ::tclmacbag::combovalues($wn) $arg(-values) } ;# Temp thing until I sort out querying the menu for its items.
  # Create the menu
  set var [$wn cget -textvariable]
  catch { destroy $wn.menu } ; menu $wn.menu
  if {[info exists arg(-postcommand)]} {
   if {[info exists ::tclmacbag::combovalues($wn)]} {
    foreach {val} $::tclmacbag::combovalues($wn) { $wn.menu add radiobutton -variable $var -label $val -value $val -command "after 50 \" $arg(-postcommand) \" ; update idletasks" }
    }
   } else {
   if {[info exists ::tclmacbag::combovalues($wn)]} {
    foreach {val} $::tclmacbag::combovalues($wn) { $wn.menu add radiobutton -variable $var -label $val -value $val }
    }
   }
  # Set the width
  if {[info exists ::tclmacbag::combovalues($wn)]} {
   set max 0 ; foreach value $::tclmacbag::combovalues($wn) { if {[string length [list $value]] > $max} { set max [string length [list $value]] } }
   if {$max < 5} { set max 5 } ; $wn configure -width $max
   }
  if {[info exists arg(-textvariable)]} { $wn configure -textvariable $arg(-textvariable) }
  if {[info exists arg(-state)]} { $wn configure -state $arg(-state) ; $wn state $arg(-state) }
  } else {
  # X11/Windows
  if {[info exists arg(-values)]} {
   # Add the value
   $wn configure -values $arg(-values)
   # Set the width
   set max 0 ; foreach value $arg(-values) { if {[string length [list $value]] > $max} { set max [string length [list $value]] } }
   if {$max < 5} { set max 5 } ; $wn configure -width $max
   }
  if {[info exists arg(-textvariable)]} { $wn configure -textvariable $arg(-textvariable) }
  if {[info exists arg(-state)]} { $wn configure -state $arg(-state) ; $wn state $arg(-state) }
  if {[info exists arg(-postcommand)] && [tk windowingsystem]!="aqua"} { bind $wn <<ComboboxSelected>> $arg(-postcommand) }
  }
 return $wn
 }

############
# Flat Button
############

proc flatbutton {wn args} {
 # Check for bad options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::flatbutton $wn $args:\nWidget already exists." }
 foreach {opt value} $args {
  switch -- $opt {
   "-image" {}
   "-command" {}
   "-state" {}
   "-force" {}
   default { bgerror "Unknown option while executing ::tclmacbag::flatbutton $wn:\n$opt $value\nMust be -image, -command, -state or -force.\n" }
   }
  }
 # Go ahead.
 foreach {opt value} $args { set arg($opt) $value }
 if {[tk windowingsystem]=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  # Aqua style
  ttk::label $wn
  if {[info exists arg(-image)]} { flatbutton_Set $wn -image $arg(-image) } else { bgerror "While executing ::tclmacbag::flatbutton $wn $args:\nWidget must set an image with -image." }
  if {[info exists arg(-command)]} { ::tclmacbag::flatbutton_Set $wn -command $arg(-command) }
  if {[info exists arg(-state)] } { ::tclmacbag::flatbutton_Set $wn -state $arg(-state) }
  # Mouse bindings
  bind $wn <Enter> { ::tclmacbag::flatbutton_ButtonEnter %W }
  bind $wn <Leave> { ::tclmacbag::flatbutton_ButtonLeave %W }
  bind $wn <ButtonPress-1> { ::tclmacbag::flatbutton_ButtonDown %W }
  } else {
  # Tile style
  ttk::button $wn
  foreach {opt value} $args {
   catch { $wn configure $opt $value }
   if {$opt=="-state"} { ::tclmacbag::flatbutton_Set $wn -state $arg(-state) }
   }
  }
 return $wn
 }

proc flatbutton_Set {wn args} {
 # Check for bad options.
 foreach {opt value} $args {
  switch -- $opt {
   "-image" {}
   "-command" {}
   "-state" {}
   default { bgerror "Unknown option while executing ::tclmacbag::flatbutton_Set $wn:\n$opt $value\nMust be -image, -command or -state.\n" }
   }
  }
 # Start
 foreach {opt value} $args { set arg($opt) $value }
 if {[winfo class $wn]=="TLabel"} {
  # Aqua style
  if {[info exists arg(-image)]} {
	set h [image height $arg(-image)]
	set w [image width $arg(-image)]
	set id [image create photo -width $w -height $h]
	$id copy $arg(-image)
	$wn configure -image $id
  	}
  if {[info exists arg(-command)]} {
	bind $wn <ButtonRelease-1> "
	 if {\[$wn cget -state\] != \"disabled\" && \[info exists ::tclmacbag::flatbuttonpressable($wn)\]} {
	  ::tclmacbag::flatbutton_ButtonUp $wn
	  $arg(-command)
	  }
	 "
	}
  if {[info exists arg(-state)] } {
        set img [$wn cget -image]
        if {$arg(-state) == "enabled" || $arg(-state) == "normal" } { $img configure -palette fullcolor -gamma 1.0 ; $wn state !disabled ; $wn configure -state normal }
        if {$arg(-state) == "disabled" } { $wn state disabled ; $wn configure -state disabled ; $img configure -palette fullcolor -gamma 2.2 }
   	}
  } else {
  # Tile style
  foreach {opt value} $args {
   catch { $wn configure $opt $value }
   }
  if {[info exists arg(-state)]} {
   if {$arg(-state) == "enabled" || $arg(-state) == "normal" } { $wn configure -state normal }
   if {$arg(-state) == "disabled" } { $wn configure -state disabled }
   }
  }
 return $wn
 }

proc flatbutton_ButtonEnter {wn} {
 set ::tclmacbag::flatbuttonpressable($wn) 1
 }
proc flatbutton_ButtonLeave {wn} {
 if {[$wn cget -state] == "disabled"} return
 set img [$wn cget -image] ; $img configure -gamma 1.0
 catch { unset ::tclmacbag::flatbuttonpressable($wn) }
 }
proc flatbutton_ButtonDown {wn} {
 if {[$wn cget -state] == "disabled"} return
 set img [$wn cget -image] ; $img configure -gamma 0.3
 set ::tclmacbag::flatbuttonpressable($wn) 1
 }
proc flatbutton_ButtonUp {wn} {
 set img [$wn cget -image]
 if {[$wn cget -state] == "disabled"} {
  $img configure -palette fullcolor -gamma 2.2
  } else {
  $img configure -palette fullcolor -gamma 1.0
  }
 catch { unset ::tclmacbag::flatbuttonpressable($wn) }
 }

############
# Help Button
############

proc helpbutton {wn args} {
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::helpbutton $wn $args:\nWidget already exists." }
 set req 0 ; foreach {opt value} $args {
  switch -- $opt {
   "-command" { incr req }
   default { bgerror "While executing ::tclmacbag::helpbutton $wn $args:\nUnknown option $opt $value\nMust be -command.\n" }
   }
  }
 if {![info exists req] || $req < 1} { bgerror "While executing ::tclmacbag::helpbutton $wn $args\nRequires -command\n" }
 # Flatbutton as a template
 ::tclmacbag::flatbutton $wn -image TclMacBag.helpbutton -force yes
 # Allocate
 foreach {opt value} $args { set arg($opt) $value }
 if {[info exists arg(-command)]} { ::tclmacbag::helpbutton_Set $wn -command $arg(-command) }
 # Bindings for Mac version
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 if {$ThemeNow=="aqua"} {
  # Mouse bindings
  bind $wn <Enter> { ::tclmacbag::helpbutton_Mac_ButtonEnter %W }
  bind $wn <Leave> { ::tclmacbag::helpbutton_Mac_ButtonLeave %W }
  bind $wn <1> { ::tclmacbag::helpbutton_Mac_ButtonDown %W }
  set img [$wn cget -image] ; $img configure -gamma 1.0
  }
 return $wn
 }

proc helpbutton_Set {wn args} {
 # Check for bad options.
 foreach {opt value} $args {
  switch -- $opt {
   "-command" {}
   default { bgerror "Unknown option while executing ::tclmacbag::helpbutton_Set $wn:\n$opt $value\nMust be -command.\n" }
   }
  }
 # Start
 foreach {opt value} $args { set arg($opt) $value }
 if {[info exists arg(-command)]} {
  bind $wn <ButtonRelease-1> "
   if {\[$wn cget -state\] != \"disabled\" && \[info exists ::tclmacbag::flatbuttonpressable($wn)\]} {
    ::tclmacbag::flatbutton_ButtonUp $wn
    $arg(-command)
    }
   "
  }
 }

proc helpbutton_Mac_ButtonEnter {wn} {
 set ::tclmacbag::flatbuttonpressable($wn) 1
 }
proc helpbutton_Mac_ButtonLeave {wn} {
 if {[$wn cget -state] == "disabled"} return
 set img [$wn cget -image] ; $img configure -gamma 1.0
 catch { unset ::tclmacbag::flatbuttonpressable($wn) }
 }
proc helpbutton_Mac_ButtonDown {wn} {
 if {[$wn cget -state] == "disabled"} return
 set img [$wn cget -image] ; $img configure -gamma 0.4
 set ::tclmacbag::flatbuttonpressable($wn) 1
 }
proc helpbutton_Mac_ButtonUp {wn} {
 if {[$wn cget -state] == "disabled"} {
  $img configure -palette fullcolor -gamma 1.0
  } else {
  $img configure -palette fullcolor -gamma 0.4
  }
 catch { unset ::tclmacbag::flatbuttonpressable($wn) }
 }

############
# Style Button
############

proc stylebutton {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::stylebutton $wn $args:\nWidget already exists.\n" ; return }
 # Collect options
 foreach {opt value} $args { set arg($opt) $value }
 if {![info exists arg(-style)]} { set arg(-style) "pill" } ;# Pill button is our default
 # Is this a supported style?
 if {[lsearch -exact $::tclmacbag::allowedbuttonstyles $arg(-style)] == -1 } {
  bgerror "While executing ::tclmacbag::stylebutton $wn $args:\n$arg(-style) is not a supported style.\nAllowed: $::tclmacbag::allowedbuttonstyles\n\n" ; return
  }
 if {[tk windowingsystem]=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  # If there's no image, we'll use a default one to start off with (extension user can use -text to override it later).
  if {![info exists arg(-image)]} { set arg(-image) TclMacBag.magglass ; set lrborder 10 } else { set lrborder 0 }
  # Carry on
  if {[info exists arg(-background)]} {
   # Create new images with the user specified background.
   set id1 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}1] -height [image height TclMacBag.${arg(-style)}1] -data [TclMacBag.${arg(-style)}1 data -format GIF -background $arg(-background)]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}2] -height [image height TclMacBag.${arg(-style)}2] -data [TclMacBag.${arg(-style)}2 data -format GIF -background $arg(-background)]]
   } else {
   # No background specified. Lets hope the Tile widget defaults are nice.
   set id1 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}1] -height [image height TclMacBag.${arg(-style)}1] -data [TclMacBag.${arg(-style)}1 data -format GIF]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}2] -height [image height TclMacBag.${arg(-style)}2] -data [TclMacBag.${arg(-style)}2 data -format GIF]]
   }
  if {[info exists ::tile::version] && $::tile::version <= "0.7.8" } {
   # Create the style - the Tile 0.7.8 method
   $::tclmacbag::ttkstylecmd configure $wn.${arg(-style)} -relief flat
   $::tclmacbag::ttkstylecmd element create $wn.${arg(-style)}.button image $id2 -map [list disabled $id2 pressed $id1 active $id2] -border [list $lrborder 0 $lrborder] -sticky nsew
   $::tclmacbag::ttkstylecmd layout $wn.${arg(-style)} "$wn.${arg(-style)}.button -children { Button.label } "
   } else {
   # Tile 0.8.x+ method. Given some testing by Joe English and tweaks provided. Should work.
   $::tclmacbag::ttkstylecmd configure $wn.${arg(-style)} -relief flat
   $::tclmacbag::ttkstylecmd element create $wn.${arg(-style)}.button image [list $id2 disabled $id2 pressed $id1 active $id2] -border [list $lrborder 0 $lrborder] -sticky nsew
   $::tclmacbag::ttkstylecmd layout $wn.${arg(-style)} "$wn.${arg(-style)}.button -children { Button.label } "
   }
  # Create button
  if {[tk windowingsystem]=="aqua"} {
   # Mac doesn't support the stippling for greyed images well, so Tile doesn't at all. Lets create a "greyed" user image variant.
   set h [image height $arg(-image)]
   set w [image width $arg(-image)]
   set disabledpic [image create photo -width $w -height $h]
   $disabledpic copy $arg(-image)
   $disabledpic configure -gamma 2.0 -palette 16
   ttk::button $wn -style $wn.$arg(-style) -image "$arg(-image) disabled $disabledpic pressed $arg(-image) active $arg(-image)"
   } else {
   # Other platforms have stippling, so we'll leave it compatible with the default Tile method for easy tclmacbag/ttk co-existence.
   ttk::button $wn -style $wn.$arg(-style) -image $arg(-image)
   }
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-image" && $opt != "-force" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  } else {
  # X11/Windows
  ttk::button $wn
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-force" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  }
 # Using a -text option? Cancel the user image and set the text
 if {[info exists arg(-text)]} { $wn configure -image {} -text $arg(-text) }
 # End of style stuff. Now lets set general options.
 return $wn
 }

############
# View Button
############

proc viewbutton {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::stylebutton $wn $args:\nWidget already exists.\n" ; return }
 # Collect options
 foreach {opt value} $args { set arg($opt) $value }
 if {![info exists arg(-style)]} { set arg(-style) "pill" } ;# Pill button is our default
 # Is this a supported style?
 if {[lsearch -exact $::tclmacbag::allowedbuttonstyles $arg(-style)] == -1 } {
  bgerror "While executing ::tclmacbag::stylebutton $wn $args:\n$arg(-style) is not a supported style.\nAllowed: $::tclmacbag::allowedbuttonstyles\n\n" ; return
  }
 if {[tk windowingsystem]=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  # If there's no image, we'll use a default one to start off with (extension user can use -text to override it later).
  if {![info exists arg(-image)]} { set arg(-image) TclMacBag.magglass ; set lrborder 10 } else { set lrborder 0 }
  # Carry on
  if {[info exists arg(-background)]} {
   # Create new images with the user specified background.
   set id1 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}1] -height [image height TclMacBag.${arg(-style)}1] -data [TclMacBag.${arg(-style)}1 data -format GIF -background $arg(-background)]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}2] -height [image height TclMacBag.${arg(-style)}2] -data [TclMacBag.${arg(-style)}2 data -format GIF -background $arg(-background)]]
   } else {
   # No background specified. Lets hope the Tile widget defaults are nice.
   set id1 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}1] -height [image height TclMacBag.${arg(-style)}1] -data [TclMacBag.${arg(-style)}1 data -format GIF]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.${arg(-style)}2] -height [image height TclMacBag.${arg(-style)}2] -data [TclMacBag.${arg(-style)}2 data -format GIF]]
   }
  if {[info exists ::tile::version] && $::tile::version <= "0.7.8" } {
   # Create the style - the Tile 0.7.8 method
   $::tclmacbag::ttkstylecmd configure $wn.${arg(-style)} -relief flat
   $::tclmacbag::ttkstylecmd element create $wn.${arg(-style)}.button image $id2 -map [list disabled $id2 pressed $id1 active $id2] -border [list $lrborder 0 $lrborder] -sticky nsew
   $::tclmacbag::ttkstylecmd layout $wn.${arg(-style)} "$wn.${arg(-style)}.button -children { Button.label } "
   } else {
   # Tile 0.8.x+ method. Given some testing by Joe English and tweaks provided. Should work.
   $::tclmacbag::ttkstylecmd configure $wn.${arg(-style)} -relief flat
   $::tclmacbag::ttkstylecmd element create $wn.${arg(-style)}.button image [list $id2 disabled $id2 pressed $id1 active $id2] -border [list $lrborder 0 $lrborder] -sticky nsew
   $::tclmacbag::ttkstylecmd layout $wn.${arg(-style)} "$wn.${arg(-style)}.button -children { Button.label } "
   }
  # Create button
  if {[tk windowingsystem]=="aqua"} {
   # Mac doesn't support the stippling for greyed images well, so Tile doesn't at all. Lets create a "greyed" user image variant.
   set h [image height $arg(-image)]
   set w [image width $arg(-image)]
   set disabledpic [image create photo -width $w -height $h]
   $disabledpic copy $arg(-image)
   $disabledpic configure -gamma 2.0 -palette 16
   ttk::button $wn -style $wn.$arg(-style) -image "$arg(-image) disabled $disabledpic pressed $arg(-image) active $arg(-image)"
   } else {
   # Other platforms have stippling, so we'll leave it compatible with the default Tile method for easy tclmacbag/ttk co-existence.
   ttk::button $wn -style $wn.$arg(-style) -image $arg(-image)
   }
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-image" && $opt != "-force" && $opt != "-command" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  } else {
  # X11/Windows
  ttk::button $wn
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-force" && $opt != "-command" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  }
 # Using a -text option? Cancel the user image and set the text
 if {[info exists arg(-text)]} { $wn configure -image {} -text $arg(-text) }
 # Set up the command, ensuring the first thing done is to set the traced variable to the value of this button.
 if {[info exists arg(-command)]} { $wn configure -command "set $arg(-variable) $arg(-onwhen) ; $arg(-command)" }
 # Now we set up our variable trace which sets the button states
 trace variable $arg(-variable) rwu "::tclmacbag::viewbutton_State $wn -variable $arg(-variable) -onwhen $arg(-onwhen)"
 # Any click (including cancelled clicks) also cause us to update the button state:
 # this resets any greyed tristate appearance settings.
 bind $wn <1> "::tclmacbag::viewbutton_State $wn -variable $arg(-variable) -onwhen $arg(-onwhen)"
 # End of style stuff. Now lets set general options.
 return $wn
 }

proc viewbutton_State {wn args} {
 # Collect options
 foreach {opt value} $args { set arg($opt) $value }
 upvar $arg(-variable) val
 if {$val==$arg(-onwhen)} { $wn state pressed } else { $wn state !pressed }
 }

############
# Panther Viewbutton variation
# Unfortunately needed as a work-around as Tile up to 0.8.x doesn't support [style element delete] or [style element configure]
############

proc pnb_viewbutton {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::pnb_viewbutton $wn $args:\nWidget already exists.\n" ; return }
 # Collect options
 foreach {opt value} $args { set arg($opt) $value }
 if {![info exists arg(-style)]} { set arg(-style) "pill" } ;# Pill button is our default
 # Is this a supported style?
 if {[lsearch -exact $::tclmacbag::allowedpnbstyles $arg(-style)] == -1 } {
  bgerror "While executing ::tclmacbag::pnb_viewbutton $wn $args:\n$arg(-style) is not a supported style.\nAllowed: $::tclmacbag::allowedbuttonstyles\n\n" ; return
  }
 if {[tk windowingsystem]=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  # Create button
  if {[info exists arg(-image)]} { bgerror "pnb_viewbutton does not support -image" ; exit }
  ttk::button $wn -style pnb_viewbutton.$arg(-style)
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-image" && $opt != "-force" && $opt != "-command" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  } else {
  # X11/Windows
  ttk::button $wn
  # Set various Tile settings.
  foreach {opt value} $args {
   if {$opt != "-style" && $opt != "-force" && $opt != "-command" && $opt != "-text"} { catch { $wn configure $opt $value } }
   }
  }
 # Using a -text option? Cancel the user image and set the text
 if {[info exists arg(-text)]} { $wn configure -text $arg(-text) }
 # Set up the command, ensuring the first thing done is to set the traced variable to the value of this button.
 if {[info exists arg(-command)]} { $wn configure -command "set $arg(-variable) $arg(-onwhen) ; $arg(-command)" }
 # Now we set up our variable trace which sets the button states
 trace variable $arg(-variable) rwu "::tclmacbag::pnb_viewbutton_State $wn -variable $arg(-variable) -onwhen $arg(-onwhen)"
 # Any click (including cancelled clicks) also cause us to update the button state:
 # this resets any greyed tristate appearance settings.
 bind $wn <1> "::tclmacbag::pnb_viewbutton_State $wn -variable $arg(-variable) -onwhen $arg(-onwhen)"
 # End of style stuff. Now lets set general options.
 return $wn
 }

############
# Search Entry
# Originally based on the search field by Schelete Bron: http://wiki.tcl.tk/18188
# ... who is not to blame for its feature creep ;-).
############

proc searchentry {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::searchentry $wn $args:\nWidget already exists." ; return }
 # Start
 foreach {opt value} $args { set arg($opt) $value }
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 if {$ThemeNow=="aqua" || ([info exists arg(-force)] && $arg(-force)=="yes")} {
  # Mac
  switch $ThemeNow {
   "aqua"      { set color White }
   "winnative" { set color "SystemButtonFace" }
   "xpnative"  { set color "SystemButtonFace" }
   "clam"      { set color "#dcdad5" }
   "step"      { set color "#a0a0a0" }
   default     { set color "#d9d9d9" }
   } ;# Set styles (with care taken to produce images with backgrounds matching their surrounding frames).
  if {[info exists arg(-background)]} {
   # Standard method
   set id1 [image create photo -format GIF -width [image width TclMacBag.search1] -height [image height TclMacBag.search1] -data [TclMacBag.search1 data -format GIF -background $arg(-background)]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.search2] -height [image height TclMacBag.search2] -data [TclMacBag.search2 data -format GIF -background $arg(-background)]]
   } else {
   # Testing this code out at times to see if it produces satisfactory results. Shouldn't be triggered in dist versions yet.
   set id1 [image create photo -format GIF -width [image width TclMacBag.search1] -height [image height TclMacBag.search1] -data [TclMacBag.search1 data -format GIF]]
   set id2 [image create photo -format GIF -width [image width TclMacBag.search2] -height [image height TclMacBag.search2] -data [TclMacBag.search2 data -format GIF]]
   }
  if {[info exists arg(-image)]} {
   # User image
   if {[image width $arg(-image)] != 13 || [image height $arg(-image)] != 13} { bgerror "While executing ::tclmacbag::searchentry $wn $args:\nImages for this widget must be 13x13." ; return }
   $id1 copy $arg(-image) -compositingrule overlay -from 0 0 13 13 -to 7 7
   $id2 copy $arg(-image) -compositingrule overlay -from 0 0 13 13 -to 7 7
   } else {
   # Default image
   $id1 copy TclMacBag.magglass -compositingrule overlay -from 0 0 13 13 -to 7 7
   $id2 copy TclMacBag.magglass -compositingrule overlay -from 0 0 13 13 -to 7 7
   }
  if {[lsearch -exact [style element names] "$wn.Search.field"] == -1 } {
   $::tclmacbag::ttkstylecmd element create $wn.Search.field image $id1 -border {22 4 14} -sticky ew -map "focus $id2"
   $::tclmacbag::ttkstylecmd layout $wn.Search.entry " $wn.Search.field -sticky nswe -border 1 -children { Entry.padding -sticky nswe -children { Entry.textarea -sticky nswe } } "
   } ;# Elements may only be created once and cannot be deleted.
  ttk::entry $wn -style $wn.Search.entry
  foreach {opt value} $args { catch { $wn configure $opt $value } }
  } else {
  # X11/Windows
  if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
  if {$ThemeNow != "xpnative"} { TclMacBag.search3 configure -palette 16 -gamma 0.7 } ;# Grey borders on X11 and Windows Classic.
  set id1 [image create photo -format GIF -width [image width TclMacBag.search3] -height [image height TclMacBag.search3] -data [TclMacBag.search3 data -format GIF]]
  if {[info exists arg(-image)]} {
   $id1 copy $arg(-image) -compositingrule overlay -from 0 0 13 13 -to 3 4
   } else {
   $id1 copy TclMacBag.magglass -compositingrule overlay -from 0 0 13 13 -to 3 4
   }
  if {[lsearch -exact [style element names] "$wn.Search.field"] == -1 } {
   $::tclmacbag::ttkstylecmd element create $wn.Search.field image $id1 -map "focus $id1" -border {18 4 1} -sticky ew
   $::tclmacbag::ttkstylecmd layout $wn.Search.entry " $wn.Search.field -sticky nswe -border 3 -children { Entry.padding -sticky nswe -children { Entry.textarea -sticky nswe } } "
   } ;# Elements may only be created once and cannot be deleted.
  ttk::entry $wn -style $wn.Search.entry
  foreach {opt value} $args {
   catch { $wn configure $opt $value }
   }
  }
 # Return
 return $wn
 }

############
# Colourful frame
# From the Wiki.
############

proc colorframe {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::colorframe $wn $args:\nWidget already exists." }
 # Start
 foreach {opt value} $args { set arg($opt) $value }
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 if {([info exists arg(-background)] && $ThemeNow == "aqua") || ([info exists arg(-background)] && [info exists arg(-force)] && $arg(-force)=="yes")} { frame $wn -background $arg(-background) } else { ttk::frame $wn } ;# #B2B2B2 suggested for Mac
 return $wn
 }

############
# Top Level
# By Schelete Bron http://wiki.tcl.tk/11075
############

proc toplevel {w args} {
 eval [linsert $args 0 ::toplevel $w]
 place [ttk::frame $w.tilebg] -x 0 -y 0 -relwidth 1 -relheight 1
 set w
 }

############
# Wrapped Text Widget
# Many thanks to Bryan Oakley for the suggestions on clt.
############

proc old_text {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::colorframe $wn $args:\nWidget already exists." }
 # We're packing a text widget into a an entry widget to scavenge the entry widget's focus stuff.
 ttk::entry $wn
 ::text ${wn}_Text -borderwidth 0 -highlightthickness 0
 bind ${wn}_Text <FocusIn> "$wn state focus ; ::tclmacbag::tktilewrapBackground_Set $wn Text"
 bind ${wn}_Text <FocusOut> "$wn state {!focus} ; ::tclmacbag::tktilewrapBackground_Set $wn Text"
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 if {$ThemeNow == "aqua"} { set pad 4 } else { set pad 2 }
 pack ${wn}_Text -in $wn -padx $pad -pady $pad -expand true -fill both
 # Apply args
 foreach {opt value} $args {
  if {$opt != "-borderwidth" && $opt != "-highlightthickness" && $opt != "-background" && $opt != "-bg"} { catch { ${wn}_Text configure $opt $value } }
  }
 # Apply background and bind to configure
 ::tclmacbag::tktilewrapBackground_Set $wn Text
 bind ${wn}_Text <Configure> "update idletasks ; ::tclmacbag::tktilewrapBackground_Set $wn Text"
 # Finish up
 return $wn
 }

proc tktilewrapBackground_Set {wn type} {
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 switch $ThemeNow {
  "aqua"      { set bgcolor white ; set dacolor white }
  "winnative" { set bgcolor white ; set dacolor "SystemButtonFace" }
  "xpnative"  { set bgcolor white ; set dacolor "SystemButtonFace" }
  "clam"      { set bgcolor white ; set dacolor "#dcdad5" }
  "step"      { set bgcolor white ; set dacolor "#a0a0a0" }
  default     { set bgcolor white ; set dacolor "#d9d9d9" }
  }
 set state [lindex [${wn}_${type} configure -state] 4]
 if {$state=="disabled"} { ${wn}_${type} configure -background $dacolor } else { ${wn}_${type} configure -background $bgcolor }
 }

############
# Wrapped Listbox Widget
# Many thanks to Bryan Oakley for the suggestions on clt.
############

proc old_listbox {wn args} {
 # Check for bad/incomplete options.
 if {[winfo exists $wn]} { bgerror "While executing ::tclmacbag::colorframe $wn $args:\nWidget already exists." ; exit }
 # We're packing a text widget into a an entry widget to scavenge the entry widget's focus stuff.
 ttk::entry $wn
 ::listbox ${wn}_Listbox -borderwidth 0 -highlightthickness 0
 bind ${wn}_Listbox <FocusIn> "$wn state focus ; ::tclmacbag::tktilewrapBackground_Set $wn Listbox"
 bind ${wn}_Listbox <FocusOut> "$wn state {!focus} ; ::tclmacbag::tktilewrapBackground_Set $wn Listbox"
 if {[info exists ::tile::currentTheme]} { set ThemeNow $::tile::currentTheme } else { set ThemeNow $::ttk::currentTheme }
 if {$ThemeNow == "aqua"} { set pad 4 } else { set pad 2 }
 pack ${wn}_Listbox -in $wn -padx $pad -pady $pad -expand true -fill both
 # Apply args
 foreach {opt value} $args {
  if {$opt != "-borderwidth" && $opt != "-highlightthickness" && $opt != "-background" && $opt != "-bg"} { catch { ${wn}_Listbox configure $opt $value } }
  }
 # Apply background and bind to configure
 ::tclmacbag::tktilewrapBackground_Set $wn Listbox
 bind ${wn}_Listbox <Configure> "update idletasks ; ::tclmacbag::tktilewrapBackground_Set $wn Listbox"
 # Finish up
 return $wn
 }

############
# Removable Toolbar:
# Similar idea to Kevin Walzer's Mac toolbar extension, but, a bit differently done.
############

proc toolbar {wn args} {
 # Check for bad/incomplete options.
 foreach {opt value} $args { set arg($opt) $value }
 # Set up the button, if we're on a Mac and using Aqua.
 if {[tk windowingsystem] == "aqua"} { tk::unsupported::MacWindowStyle style [winfo toplevel $wn] document {toolbarButton standardDocument} }
 set ::tclmacbag::toolbarargs($wn) $args
 eval grid $wn $::tclmacbag::toolbarargs($wn)
 set w [winfo toplevel $wn]
 bind $w <<ToolbarButton>> "::tclmacbag::toolbar_Toggle $wn"
 }

proc toolbar_Toggle {wn} {
 set tl [winfo toplevel $wn]
 if {![info exists ::tclmacbag::toolbarhidden($tl)]} {
  # Hide the toolbar
  set ::tclmacbag::toolbarhidden($tl) 1
  grid forget $wn
  } else {
  # Show the toolbar
  catch { unset ::tclmacbag::toolbarhidden($tl) }
  eval grid $wn $::tclmacbag::toolbarargs($wn)
  }
 }

proc toolbar_ToggleTo {wn args} {
 set tl [winfo toplevel $wn]
 foreach {opt value} $args { set arg($opt) $value }
 if {$arg(-state)=="on"} {
  # Switch on
  catch { unset ::tclmacbag::toolbarhidden($tl) }
  ::tclmacbag::toolbar_Toggle $w
  } else {
  # Switch off
  set ::tclmacbag::toolbarhidden($tl) 1
  ::tclmacbag::toolbar_Toggle $w
  }
 }

############
# Plain Box:
# Cheers to Joe English for the info used for this.
# This is a convenience widget.
############

proc boxframe {w} { ttk::frame $w -style TLabelframe -padding 3 }

############
# Inits and other Miscellanea
############

# Urgh. Tile/Ttk namespace name changes in the switch from 0.7.x to 0.8.x.
if {[info exists ::tile::version] && $::tile::version <= "0.7.8" } { set ::tclmacbag::ttkstylecmd style } else { set ::tclmacbag::ttkstylecmd ttk::style }

# Stylebutton images
set ::tclmacbag::allowedbuttonstyles {}
lappend ::tclmacbag::allowedbuttonstyles pill pill-left pill-middle pill-right
lappend ::tclmacbag::allowedbuttonstyles chrome chrome-left chrome-middle chrome-right
lappend ::tclmacbag::allowedbuttonstyles steel steel-left steel-middle steel-right
lappend ::tclmacbag::allowedbuttonstyles simple simple-left simple-middle simple-right
lappend ::tclmacbag::allowedbuttonstyles gel gel-small

foreach i $::tclmacbag::allowedbuttonstyles {
 image create photo TclMacBag.${i}1 -file [file join [file dirname [info script]] Resources ${i}-down.gif]
 image create photo TclMacBag.${i}2 -file [file join [file dirname [info script]] Resources ${i}-up.gif]
 }

# Pantherbook styles
set ::tclmacbag::allowedpnbstyles {}
lappend ::tclmacbag::allowedpnbstyles tnb-left tnb-middle tnb-right

foreach i $::tclmacbag::allowedpnbstyles {
 image create photo TclMacBag.${i}1 -file [file join [file dirname [info script]] Resources ${i}-up.gif]
 image create photo TclMacBag.${i}2 -file [file join [file dirname [info script]] Resources ${i}-down.gif]
 image create photo TclMacBag.${i}3 -file [file join [file dirname [info script]] Resources ${i}-pressed.gif]
 }

# Helpbutton image. Only need to load one.
switch -- [string tolower [lindex $tcl_platform(os) 0]] {
 "windows" { image create photo TclMacBag.helpbutton -file [file join [file dirname [info script]] Resources help-windows.gif] }
 "darwin"  { image create photo TclMacBag.helpbutton -file [file join [file dirname [info script]] Resources help-mac.gif] }
 default   { image create photo TclMacBag.helpbutton -file [file join [file dirname [info script]] Resources help-x11.gif] }
 }

# PNB specific viewbutton styles
foreach i $::tclmacbag::allowedpnbstyles {
 set id1 TclMacBag.${i}1
 set id2 TclMacBag.${i}2
 set id3 TclMacBag.${i}3
 if {[info exists ::tile::version] && $::tile::version <= "0.7.8" } {
  # Tile 0.7.8 method
  ###################
  # Selected
  $::tclmacbag::ttkstylecmd configure pnb_viewbutton.${i} -relief flat
  $::tclmacbag::ttkstylecmd element create pnb_viewbutton.${i}.button image $id1 -map [list disabled $id1 pressed $id2 active $id1 readonly $id3] -border [list 10 0 10] -sticky nsew
  $::tclmacbag::ttkstylecmd layout pnb_viewbutton.${i} "pnb_viewbutton.${i}.button -children { Button.label } "
  # Unselected - todo
  } else {
  # Tile 0.8.x+ method
  ####################
  # Selected
  $::tclmacbag::ttkstylecmd configure pnb_viewbutton.${i} -relief flat
  $::tclmacbag::ttkstylecmd element create pnb_viewbutton.${i}.button image [list $id1 disabled $id1 pressed $id2 active $id1 readonly $id3] -border [list 10 0 10] -sticky nsew
  $::tclmacbag::ttkstylecmd layout pnb_viewbutton.${i} "pnb_viewbutton.${i}.button -children { Button.label } "
  # Unselected - todo
  }
 }

proc pnb_viewbutton_State {wn args} {
 # Collect options
 foreach {opt value} $args { set arg($opt) $value }
 upvar $arg(-variable) val
 if {$val==$arg(-onwhen)} { $wn state { pressed !active !alternate} } else { $wn state { !pressed !active !alternate} }
 }

# Images for Searchentry
image create photo TclMacBag.search1  -file [file join [file dirname [info script]] Resources search1.gif]
image create photo TclMacBag.search2  -file [file join [file dirname [info script]] Resources search2.gif]
image create photo TclMacBag.search3  -file [file join [file dirname [info script]] Resources search3.gif]
image create photo TclMacBag.magglass -file [file join [file dirname [info script]] Resources search-magglass.gif]

# Creates a plain notebook style for Groupbox and Pamphlet.
$::tclmacbag::ttkstylecmd layout Plain.TNotebook.Tab null
$::tclmacbag::ttkstylecmd layout Plain.TNotebook null
$::tclmacbag::ttkstylecmd configure Groupbox.TLabelframe -labeloutside false
$::tclmacbag::ttkstylecmd configure Groupbox.TMenubutton
$::tclmacbag::ttkstylecmd theme settings default "$::tclmacbag::ttkstylecmd layout Plain.TNotebook.Tab null"

# Convenience aliases
switch -- [lindex $tcl_platform(os) 0] {
 "Darwin" { interp alias {} ::tclmacbag::scrollbar {} ::scrollbar }
 default  { interp alias {} ::tclmacbag::scrollbar {} ttk::scrollbar }
 }

#############################################################################################
}
