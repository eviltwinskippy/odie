package provide scrollFrame 1.1

###
# topic: a03a094a-a93b-4bac-56c4-a758472af394
# description:
#    proc scrollFrame {name args}
#    scrollFrame - Returns the name of a frame within a canvas
#    attached to vanishing scrollbars.
#    Arguments
#    name	The name of the parent frame
#    NOTE :: NON-CONVENTIONAL RETURN - RETURNS THE INTERNAL NAME, NOT
#    THE NAME OF THE PARENT WINDOW!!!
#    args	Arguments to be passed to frame and canvas
#    
#    Results
#    Creates 2 frames, a canvas and a two scrollbars.
#    |-------------| <- Outer holding frame
#    | cccccccccc ^| Canvas within outer frame
#    | cffffffffc || Frame within canvas
#    | cf      fc ||
#    | cffffffffc |<-- Vertical Scrollbar within outer frame
#    | cccccccccc V|
#    | <-------->  | Horizontal Scrollbar within outer frame
#    |-------------|
###
proc ::scrollFrame {outerFrame args} {
  ::taotk::scrollframe $outerFrame -locked 0 {*}$args
  set f [$outerFrame organ contentframe]
  return $f
}

###
# topic: f572a3a7-1a67-05b5-51f3-fc2ac657ff47
# description:
#    scrollFrame - Returns the name of a frame within a canvas
#    attached to vanishing scrollbars.
#    Arguments
#    name	The name of the parent frame
#    NOTE :: NON-CONVENTIONAL RETURN - RETURNS THE INTERNAL NAME, NOT
#    THE NAME OF THE PARENT WINDOW!!!
#    args	Arguments to be passed to frame and canvas
#    
#    Results
#    Creates 2 frames, a canvas and a two scrollbars.
#    |-------------| <- Outer holding frame
#    | cccccccccc ^| Canvas within outer frame
#    | cffffffffc || Frame within canvas
#    | cf      fc ||
#    | cffffffffc |<-- Vertical Scrollbar within outer frame
#    | cccccccccc V|
#    | <-------->  | Horizontal Scrollbar within outer frame
#    |-------------|
###
tao::class taotk::meta::scrollframe {
  superclass taotk::meta::widget
  
  option locked {
    default 1
  }
  option text {
    default {}
  }
  option width {
    default 0
  }
  option height {
    default 0
  }
  option usex {
    default 1
    widget boolean
  }
  option usey {
    default 1
    widget boolean
  }
  
  signal resize {
    action {}
  }
  
  variable event_final {}
  
  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    set f [my Build_scrollframe $window {*}$args]
    my build_widget $f
    my build_content
    my bind_widget $window
  }

  method content {} {
    return [my organ contentframe]
  }

  ###
  # topic: 3ca91ba0-495e-d0bb-a05e-f1e797bc2941
  ###
  method Build_scrollframe {outerFrame args} {
    if {[string first "." $outerFrame] != 0} {
        error "$outerFrame is not a legitimate window name - must start with `.'"
    }
    my graft scrollframe $outerFrame
    set parent [winfo parent $outerFrame]
    set height [winfo height $parent]
    set width  [winfo width $parent]
    if { $width < 200 } {
      set width 200
    }
    if { $height < 200 } {
      set height 200
    }
    if {[my cget width]} {
      set width [my cget width]
    }
    if {[my cget height]} {
      set height [my cget height]
    }
    
    # Build the scrollbar commands for the X and Y scrollbar
    # Create and grid the canvas    
    if {[my cget usey]} {
      ttk::scrollbar $outerFrame.sby -orient vertical \
          -command "$outerFrame.c yview"
      set cmdy "$outerFrame.sby set"
    } else {
      set cmdy ""
    }
  
    if {[my cget usex]} {
      ttk::scrollbar $outerFrame.sbx -orient horizontal \
        -command "$outerFrame.c xview"
      set cmdx "$outerFrame.sbx set"
    } else {
        set cmdx ""
    }

    set cvs [canvas $outerFrame.c \
        -width $width -height $height \
        -yscrollcommand $cmdy -xscrollcommand $cmdx \
        -bg [::ttk::style lookup . -background]]
    grid $outerFrame.c -row 0 -column 0 -sticky news
    
    # Create the scrollbars.  Do not grid. They'll be gridded when 
    #  needed
    # Configure the canvas to expand with its holding frame
    grid rowconfigure    $outerFrame 0 -weight 1
    grid columnconfigure $outerFrame 0 -weight 1
  
    # Create a frame to go within the canvas.  The various frame
    #  options are applied here.

    ttk::frame $cvs.f -style [my Style frame]
    #{*}$args
    
    # Place the new frame within the canvas
    $cvs create window 0 0 -window $cvs.f -anchor nw
    return $cvs.f
  }

  ###
  # topic: dbf32a6d-cd3d-168a-af32-eabe323c49bf
  ###
  method clear_content {} {
    foreach organ {contentframe} {
      set obj [my organ $organ]
      if {[winfo exists $obj]} {
        destroy {*}[winfo children $obj]
      }
    }
  }
  
  method bind_widget window {
    next $window
    if {![my cget locked]} {
      my events resume
    }
  }
  
  method Option_set::locked newvalue {
    if { $newvalue } {
      my events resume
    } else {
      my events suspend
    }
  }
  
  method events::resume {} {
    ###
    # Place bindings on the <Configure> event of the toplevel,
    # the scrollframe, and the contentframe to signal that the
    # window may have changed size
    ###
    set f [my organ scrollframe]
   # bind [winfo toplevel $f] <Configure> [namespace code {my EventMotion toplevel}]
    bind $f <Configure> [namespace code {my events resize scrollframe}]
    bind $f.c.f <Configure> [namespace code {my events resize content}]
    my lock remove modify
  }
  
  method events::suspend {} {
    ###
    # Clear out the bindings for the widget to prevent
    # another event from firing off while we are processing the
    # current event
    ###
    set f [my organ scrollframe]
    #bind [winfo toplevel $f] <Configure> {}
    bind $f <Configure> {}
    bind $f.c.f <Configure> {}
  }
  
  method events::resize {{which {}}} {
    ###
    # We dont call resize immediately, as the user could be
    # dragging the window. Instead we cancel any outstanding
    # event and schedule a new one for 100ms in the future
    ###
    my variable event_final
    after cancel $event_final
    set event_final [after 100 [namespace code [list my resize $which]]]
  }

  method resize {{which {}}} {

    if {[my lock create modify]} {
      return
    }
    if [catch {
    my events suspend
    set f [my organ scrollframe]    
    my variable event_final
    after cancel $event_final
    if {![winfo exists $f]} return

    set bbox [$f.c bbox all]
    set opts [list -scrollregion $bbox]
    set cwidth [lindex $bbox 2]
    set cheight [lindex $bbox 3]
    set rwidth [winfo width $f]
    set rheight [winfo height $f]
    if {[my cget usex]} {
      if {![winfo ismapped $f.sbx] && ($cwidth > $rwidth)} {
        grid $f.sbx -row 1 -column 0 -pady 1 -sticky ew
      } elseif {[winfo ismapped $f.sbx] && ( $cwidth <= $rwidth)} {
        grid forget $f.sbx
      }
    }
    if {[my cget usey]} {
      if {![winfo ismapped $f.sby] && ($cheight > $rheight)} {
        grid $f.sby -row 0 -column 1 -padx 1 -sticky ns
      } elseif {[winfo ismapped $f.sby] && ($cheight <= $rheight )} {
        grid forget $f.sby
      }
    }
    if {$which in {toplevel scrollframe}} {
      set height [winfo height $f]
      set width  [winfo width $f]
      set realsize [list $width $height]
    
      if {[my cget usey] && [winfo ismapped $f.sby]} {
        set width [expr {$width - [winfo width $f.sby] - 5}]
      }
      if {[my cget usex] && [winfo ismapped $f.sbx]} {
        set height [expr {$height - [winfo height $f.sbx] - 5}]
      }
  
      if {abs($rwidth - $width)>10} {
        if { $width < [my cget width] } {
          set width [my cget width]
        }
        lappend opts -width $width 
      }
      if {abs($rheight - $height)>10} {
        if { $height < [my cget height] } {
          set height [my cget height]
        }
        lappend opts -height $height 
      }
    }
    $f.c configure {*}$opts
    } err errorInfo] {
      puts "Error: $err"
    }
    update idletasks
    my events resume
  }

  ###
  # topic: e82f7c7e-bcaa-2de9-5f73-27d4bb32f09e
  ###
  method ScrollZero {} {
    set f [my organ scrollframe]
    $f.c xview moveto 0
    $f.c yview moveto 0
    $f.c configure -scrollregion [$f.c bbox all]
  }
}

###
# topic: 5b54c884-f108-45b0-d07a-8c755027dac7
###
tao::class taotk::scrollframe {
  superclass taotk::meta::scrollframe taotk::frame
  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    set f [my Build_scrollframe $window {*}$args]
    my graft contentframe $f
    my build_widget $f
    my build_content
    my bind_widget $window
    after idle [namespace code {my lock remove_all}]
  }
}

###
# topic: f807758a-ebfd-e34b-b764-d54b7a571529
###
tao::class taotk::scrollwindow {
  superclass taotk::meta::scrollframe taotk::toplevel
  
  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    set f [my Build_scrollframe $window {*}$args]
    my graft contentframe $f
    my build_widget $f
    my build_content
    my bind_widget $window
    after idle [namespace code {my lock remove_all}]
  }
}

namespace eval ::taotk::test {}
proc ::taotk::test::scrollframe {} {
  destroy .test
  toplevel .test
  taotk::scrollframe .test.frame -text "TAOTK SCROLLFRAME TEST"
  set c [.test.frame organ contentframe]
  for {set x 0} {$x < 10} {incr x} {
    for {set y 0} {$y < 10} {incr y} {
      button $c.r${x}#c${y} -text "Col $x Row $y"
      grid  $c.r${x}#c${y}  -row $y -column $x
    }
  }
  grid .test.frame
}
