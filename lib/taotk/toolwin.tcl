::namespace eval ::taotk::utils {}

###
# topic: f658676b-b1ec-7818-74de-4950d5add6c0
###
proc ::floatingWindow w {
    if [winfo exists $w] {
        destroy {*}[winfo children $w]
        return
    }
    toplevel $w
    $w configure -bg [::ttk::style lookup . -background]
    switch $::tao::platform {
      macosx {
        ::tk::unsupported::MacWindowStyle style $w floating closeBox
      }
      windows {
        wm attributes $w -toolwindow 1
      }
      default {
        wm transient $w .
      }
    }
    #set winsys [tk windowingsystem] 
    #if {$winsys eq "aqua"} {
    #    return
    #}
    #if {$winsys eq "win32" } {
    #    #-topmost 1
    #    return
    #}
    #wm overrideredirect .vis 1
}

###
# topic: 2309fd89-7965-4339-ab27-41eeaf72e691
###
proc ::grabdisplay script {
  appmain lock create grabdisplay
  appmain icon BUSY
  catch [list uplevel 1 $script] err opts
  appmain lock remove grabdisplay
  return -options $opts $err
}

###
# topic: 7679affd-3cbf-baa2-7352-2e78b2fdc5a3
###
proc ::odieCenterWindow {w {parent {}}} {
  ::update
  set ww [winfo reqwidth $w]
  set wh [winfo reqheight $w]
  if {$parent==""} {
    set px 0
    set py 0
    set pw [winfo screenwidth .]
    set ph [winfo screenheight .]
    if {$pw>$ph*1.25} {set pw [expr {int($ph*1.25)}]}
    if {$ph>$pw*1.25} {set ph [expr {int($pw*1.25)}]}
  } else {
    set px [winfo rootx $parent]
    set py [winfo rooty $parent]
    set pw [winfo width $parent]
    set ph [winfo height $parent]
  }
  set x [expr {$px+($pw-$ww)/2}]
  set y [expr {$py+($ph-$wh)/2}]
  if {$x<0} {set x 0}
  if {$y<0} {set y 0}
  wm geometry $w +$x+$y
  ::odieFocus $w
}

###
# topic: 6af76b9e-499a-32df-5be2-2df38c2e1c4f
###
proc ::odieFocus w {
  if {![winfo exists $w]} {set w [appmain organ canvas]}
  set top [winfo toplevel $w]
  if {$top!=$w || [set target [::focus -lastfor $top]]==""} {
    set target $w
  }
  catch {::focus $target}
  wm deiconify $top
  # ::update
  raise $top
  ::focus $target
  after idle [subst -nocommands {catch {
    raise $top
    after idle {catch {::focus $target}}
  }}]
}

###
# topic: 38203760-e5cc-0823-2d77-87675e573faa
# title: Bring up an instructional message
# description:
#    The text of the message is TEXT.  It should be no more than two lines.
#    Additional arguments specify buttons to place at the right together with
#    scripts to run when those buttons are pressed.
#    
#    If TEXT is an empty string, the instructional panel is removed from display
###
proc ::odieInstruct {text args} {
  set w [odieModalWindow .instruct]
  
  if {$text==""} {
    destroy $w
    return
  }
  #$w -bd 1 -relief raised -bg pink
  label $w.x -text $text -justify left -bg pink
  pack $w.x -side left -padx 3
  set i 0
  foreach {btn action} $args {
    incr i
    button $w.b$i -text $btn -command $action -bg pink -activebackground white
    pack $w.b$i -side right -padx {0 3}
  }
}

###
# topic: 1af7ed27-dc88-88e3-53d4-83a54034625d
# description:
#    proc ::messagebox
#    A replacement for odieMessageBox, it
#    pops up a message without being a modal dialog box
###
proc ::odieMessageBox args {
  #destroy .question
  #set w .question
  #floatingWindow $w
  #wm protocol $w WM_DELETE_WINDOW {set response cancel}

  array set opt {
    -title {} -detail {} -icon info -message {Whaddya want?} -type ok
    -parent .
  }
  array set opt $args
  set image ::tk::icons::information
  switch $opt(-icon) {
    error {
      set image ::tk::icons::error
    }
    question {
      set image ::tk::icons::question
    }
    warning {
      set image ::tk::icons::warning
    }
  }
  if { $opt(-parent) eq "."} {
    set w [odieModalWindow .prompt $opt(-title)]
  } else {
    set w [odieModalWindow $opt(-parent).prompt $opt(-title) $opt(-parent)]

  }

  ttk::label $w.icon -image $image
  ttk::frame $w.info
  message $w.info.message -text $opt(-message) -justify left
  #-wraplength 500
  grid $w.info.message
  if { $opt(-detail) ne {} } {
    message $w.info.detail -text $opt(-detail)
    grid $w.info.detail
  }
  grid $w.icon $w.info
  ttk::frame $w.buttons
  switch $opt(-type) {
    abortretryignore {
      ttk::button $w.buttons.abort -text Abort -command "set response abort"  -width 0
      ttk::button $w.buttons.retry -text Retry -command "set response retry"  -width 0
      ttk::button $w.buttons.ignore -text Cancel -command "set response ignore"  -width 0
      pack $w.buttons.ignore -side left
      pack $w.buttons.abort $w.buttons.retry -side right
    }
    ok {
      ttk::button $w.buttons.ok -text Ok -command "set response ok"  -width 0
      pack $w.buttons.ok -side right  
    }
    okcancel {
      ttk::button $w.buttons.ok -text Ok -command "set response ok"  -width 0
      ttk::button $w.buttons.cancel -text Cancel -command "set response cancel"  -width 0
      pack $w.buttons.ok $w.buttons.cancel -side right      
    }
    retrycancel {
      ttk::button $w.buttons.retry -text Retry -command "set response retry"  -width 0
      ttk::button $w.buttons.cancel -text Cancel -command "set response cancel"  -width 0
      pack $w.buttons.retry $w.buttons.cancel -side right
    }
    yesno {
      ttk::button $w.buttons.yes -text Yes -command "set response yes"  -width 0
      ttk::button $w.buttons.no -text No -command "set response no"  -width 0
      pack $w.buttons.yes $w.buttons.no -side right
    }
    yesnocancel {
      ttk::button $w.buttons.yes -text Yes -command "set response yes"  -width 0
      ttk::button $w.buttons.no -text No -command "set response no"  -width 0
      ttk::button $w.buttons.cancel -text Cancel -command "set response cancel"  -width 0
      pack $w.buttons.cancel -side left
      pack $w.buttons.yes $w.buttons.no -side right
    }
  }
  grid $w.buttons -columnspan 2 -sticky ew

  vwait response
  destroy $w
  return $::response
}

###
# topic: eed0e882-9acb-87d3-0f9f-a68e7c9301df
###
proc ::odieMiniButton {f args} {
  set opts {
    bg {}
    image ::taotk::gel-up
    command {}
  }
  foreach {field val} [::tao::args_to_options {*}$args] {
    dict set opts $field $val
  }
  dict with opts {}
  label $f -image $image -bg $bg
  if {$command ne {} } {
    bind $f <Enter> {%W configure -relief raised}
    bind $f <Leave> {%W configure -relief flat}
    bind $f <ButtonRelease> $command
  }
}

###
# topic: 9bd9495f-9cc6-424f-193e-83e0cac157f7
###
proc ::odieModalWindow {w {title {}} {parent .}} {
  #if {[catch {appmain organ canvas} can2d]} {
    #set w .message
    destroy $w
    floatingWindow $w
    foreach {size x y} [split [wm geometry $parent] +] break;
    wm geometry $w +$x+$y
    if { $title != {} } {
      wm title $w $title
    }
    #odieCenterWindow $w
    return $w
  #} else {
  #  set w $can2d$name    
  #  if {[winfo exists $w]} {destroy $w}
  #}
  
  if { $title eq {} } {
    ttk::frame $w
  } else {
    ttk::labelframe $w -text $title
  }

  #$can2d create window [$can2d canvasx 5] [$can2d canvasy 5] -anchor nw -window $w -tags gui
  return $w
}

###
# topic: b83ceefa-fe3a-fee0-ddb5-45887e55e23f
# description:
#    Create a visual control dialog
#    
#    
#    Useful utility routines
###
proc ::odieToplevel {w args} {
  if [winfo exists $w] {
      destroy {*}[winfo children $w]
      return
  }
  toplevel $w -bg [::ttk::style lookup . -background] {*}$args
  return $w
  #wm overrideredirect .vis 1
}

###
# topic: 2f1c2a70-0500-05c9-6438-270cb3a7b6ef
# title: Sizes a combobox to fit widest element
###
proc ::taotk::utils::options_width values {
  set w 0
  foreach v $values {
    if {[set l [string length $v]] > $w} {
      set w $l
    }
  }
  return $w
}

