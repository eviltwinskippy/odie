###
# A basic canvas3d object
###

###
# topic: bb7c77db-6e66-5ae5-bb52-3b403a78522d
# description:
#    Methods that the canvas expects to be implemented
#    my the parent container
###
tao::class taotk::meta::canvas3d {
  superclass taotk::meta::megawidget

  ###
  # topic: a3a7bf81-b13d-bb89-2f2e-d94e38afde72
  ###
  method action::motor {
    variable _motor_timer
    variable _motor_cmd
    set start [clock milliseconds]
    my move_camera $_motor_cmd
    set end [clock milliseconds]
    set delay [expr {25+$start-$end}]
    if {$delay<=0} {
      set delay idle
    }
    set _motor_timer [after $delay [list [self] action motor]]
  }

  ###
  # topic: cfff9777-b26b-f3d5-e707-33dd5661cd11
  ###
  method action::position_light {
    my canvas delete light
    my canvas delete distantlight
    my canvas  create light [my canvas cget -cameralocation] -tags light -horizon 0
    my canvas  create light {0 0 100000} -tags distantlight -horizon 0 -diffuse {0.6 0.6 0.4}
    my canvas  create light {0 0 -100000} -tags distantlight -horizon 0 -diffuse {0.4 0.4 0.6}

    #my canvas coords light [my canvas cget -cameralocation]
    #my canvas transform -camera light {lookat all}
    #my canvas transform -camera light {orbitup 50 orbitleft 30}
    #foreach {cx cy cz} [my canvas cget -cameracenter] break
    #foreach {lx ly lz} [my canvas cget -cameralocation] break
    #set x [expr {100.0*($lx-$cx)}]
    #set y [expr {100.0*($ly-$cy)}]
    #set z [expr {100.0*($lz-$cz)}]
    #my canvas coords light [list $x $y $z]
  }

  ###
  # topic: 9fe1e88b-c0c6-d42b-2e50-25432d7cc529
  ###
  method action::reset_shot {
    ###
    # Reset the camara
    ###
    my canvas  config -cameralocation {100 0 0} -cameraup {0 0 1}
    my canvas  transform -camera light {lookat all}
    my canvas  transform -camera light {orbitup 50 orbitleft 30}
    my canvas  config -cameraup {0 0 1} -enablealpha 1
    my canvas  config -saveunder none
    my action position_light
  }

  ###
  # topic: 4ef32595-aedf-cc3a-1747-f43c743e0778
  ###
  method binding_button_magic_eye {x y} {
    
  }

  ###
  # topic: 0bdff556-d5ff-2e4a-830e-c4733e246af1
  ###
  method binding_camera_fly_start {x y} {
    my variable camerabot
    array set camerabot {
      speed 0
    }
    set camerabot(position)    [my canvas cget -cameralocation]
    set camerabot(orientation) [my canvas cget -cameraup]
    
    variable _pan_x 
    variable _pan_y
    variable _pan_z
    set obj [my object_at $x $y]
    if { $obj ne {} } {
      puts [list object $obj]
    }
    set _pan_x $x
    set _pan_y $y
  }

  ###
  # topic: 2b6ce4a6-6818-a12d-eb84-281ab6fae2b3
  ###
  method binding_camera_fly_step {x y} {
    variable _pan_x
    variable _pan_y
    set dx [expr {$x-$_pan_x}]
    set dy [expr {$y-$_pan_y}]
    set _pan_x $x
    set _pan_y $y
    my move_camera "move $dx $dy 0"
  }

  ###
  # topic: 86374c60-d328-4ee3-f18f-6f9309b5a477
  ###
  method binding_camera_fly_wheel step {
    my variable camerabot
    if { $step > 0 } {
      my move_camera [list movein [expr 1.001**$step]]
    }
    if { $step < 0 } {
      my move_camera [list movein [expr 0.999**(-1.0*$step)]]
    }
  }

  ###
  # topic: 698c8318-cc8d-2e34-b236-7c246314069b
  ###
  method binding_camera_move_start {x y} {
    variable _pan_x
    variable _pan_y
    variable _pan_z
    set obj [my object_at $x $y]
    if { $obj ne {} } {
      puts [list object $obj]
    }
    set _pan_x $x
    set _pan_y $y
  }

  ###
  # topic: 3b2233e0-3abb-a88b-3329-d1c91e3c3540
  ###
  method binding_camera_move_step {x y} {
    variable _pan_x
    variable _pan_y
    set dx [expr {$x-$_pan_x}]
    set dy [expr {$y-$_pan_y}]
    set pos [my canvas cget -cameralocation]
    puts [list $pos]
    #set rad [::irmmath::distance {*}$pos]
    puts [list $rad]
    set _pan_x $x
    set _pan_y $y
    my move_camera "move $dx $dy 0"
  }

  ###
  # topic: 60295d15-1ff0-9e08-ba2a-7d36fbad23fb
  ###
  method binding_camera_move_wheel step {
    if { $step > 0 } {
      my move_camera [list movein [expr 1.001**$step]]
    }
    if { $step < 0 } {
      my move_camera [list movein [expr 0.999**(-1.0*$step)]]
    }
  }

  ###
  # topic: c523e73a-06da-db85-0cc6-7a42d91837cf
  ###
  method binding_highlight_object_at {x y} {
    return
    #my variable highlight
    set text {}
    foreach item [my object_at $x $y] {
      foreach {id ntag tags} $item break
      if {[catch {[my nodeLayer $ntag] node_popup_text $ntag [string index $ntag 0] [string range $ntag 1 end]} text]} {
        puts "Error [my nodeLayer $ntag] node_popup_text:\n$text"
      }
    }
    my popup_display $text $x $y
  }

  ###
  # topic: 1ff2584b-f5b4-eee4-c841-24e5a6ddaf43
  ###
  method binding_mag_end {} {
    variable _mag
    global g simconfig
    my actionstack clear
    
    my canvas delete magbox
    if {![info exists _mag(x1)]} {
      my move_camera {movein 1.5}
      return
    }
    set view viewport($_mag(x0),$_mag(y0),$_mag(x1),$_mag(y1))
    set sphere [my canvas boundingsphere $view]
    if {$sphere==""} return
    my move_camera [list lookat $view]
  }

  ###
  # topic: 245258db-19b7-6818-0775-1778234b826c
  ###
  method binding_mag_motion {x y} {
    variable _mag
    set _mag(x1) $x
    set _mag(y1) $y
    set x0 $_mag(x0)
    set y0 $_mag(y0)
    my canvas coords magbox [list $x0 $y0 $x $y0 $x $y $x0 $y $x0 $y0]
  }

  ###
  # topic: 8ef2c413-f49d-b094-6bc6-52e483798bcc
  ###
  method binding_mag_start {x y} {
    variable _mag
    unset -nocomplain _mag
    set _mag(x0) $x
    set _mag(y0) $y
    my canvas create 2dline [list $x $y $x $y $x $y $x $y $x $y] -color green \
       -tags {magbox}
  }

  ###
  # topic: 4801d536-c0e1-895c-bfa0-4b8d9c8919a5
  ###
  method binding_motion {x y} {
  
  }

  ###
  # topic: 57657e78-f2d2-4a40-11b8-1e7eb0b15e86
  ###
  method binding_mouse_enter {} {
    global g simconfig
    variable _info
    my idle_event_cancel popup
    my reset_overlay
    my put location {}
    my put info {}
  }

  ###
  # topic: a594b164-c884-24cf-7f96-863ea1a93095
  ###
  method binding_mouse_leave {} {
    global g simconfig
    variable _info
    my idle_event_cancel popup
    my reset_overlay
    my action clear_location
  }

  ###
  # topic: 61ef33c8-127e-23e6-cd1d-d8a5cc7c0194
  ###
  method binding_pan_start {x y} {
    variable _pan_x
    variable _pan_y
    set _pan_x $x
    set _pan_y $y
  }

  ###
  # topic: 479f4da0-9b8c-9663-2fe2-8d925bfa68ab
  ###
  method binding_pan_step {x y} {
    variable _pan_x
    variable _pan_y
    set dx [expr {$x-$_pan_x}]
    set dy [expr {$y-$_pan_y}]
    set _pan_x $x
    set _pan_y $y
    my move_camera "orbitleft $dx orbitup $dy"
  }

  ###
  # topic: e8fd6f08-982d-f89b-464f-a88e0e31ff6a
  ###
  method binding_pan_wheel step {
    if { $step > 0 } {
      my move_camera [list movein [expr 1.001**$step]]
    }
    if { $step < 0 } {
      my move_camera [list movein [expr 0.999**(-1.0*$step)]]
    }
  }

  ###
  # topic: e189b6f2-36c8-e866-44d3-daeeea860295
  ###
  method build_canvas w {
    ttk::frame $w.controls
    ttk::frame $w.zoom
    
    pack $w.controls -side top -fill x
    pack $w.zoom -side bottom -fill x
    
    set canvas $w.c

    #canvas3d $canvas -width 600 -height 400 -bg #000 -enablealpha 1
    canvas3d $canvas
    $canvas configure -bg #000 -enablealpha 1
    my graft canvas $canvas
    
    ###
    # Generate a canvas for displaying popup info
    ###
    #canvas $canvas.popup \
    #  -highlightthickness 1 -highlightbackground black \
    #  -bg #ff8 -bd 0
    
    pack $canvas -side left -fill both -expand 1
    bind $w <Triple-1> {set DEBUG 1; appmain build_menu .mb}

    my build_canvas_buttons $w.controls
    
    ###
    # The master can call
    # my timeControls later
    ###
    my graft canvasframe $w
    my graft popupframe  $canvas.popup
  }

  ###
  # topic: eb63f89a-3fc5-86a4-d7f0-63f813a7b3f3
  ###
  method build_canvas_buttons f {
    set shellName [self]
    set self $shellName

    $shellName graft buttonbar $f
    $shellName graft viewbar $f
    if {[winfo exists $f]} {
      destroy {*}[winfo children $f]
    } else {
      ttk::frame $f
    }
    ttk::button $f.norm -image icon:norm -command [list $shellName actionstack clear]
    set_balloon $f.norm {Browse}
  
    ttk::separator $f.sep
    my controlButton $f.pan pan {
        comment {Orbit Camera}
        icon icon:pan
        popups 0
        cursor fleur
        modal 1
        main-script {
          set canvas [[self] organ canvas]
          %self% cancel_on_leave
          bind $canvas <MouseWheel> [list [self] binding_pan_wheel %D]
          bind $canvas <ButtonPress-1> [list [self] binding_pan_start %x %y]
          bind $canvas <B1-Motion> [list [self] binding_pan_step %x %y]
          bind $canvas <KeyPress-Escape> [list %self% actionstack pop]
          $button configure -command [list %self% actionstack pop]
          %self% tree unselect
          $button state pressed
        }
        exit-script {
          $button state !pressed
          $button configure -command [list %self% actionstack push pan]
        }            
    }

    ttk::separator $f.focus
    pack \
        $f.norm $f.pan $f.sep \
        -side left -fill y -padx {0 0}


    ttk::separator $f.rowsep
    pack $f.rowsep -side top
    ###
    # Add 3d controls
    ###
    my motor_button $f Down {
      command {orbitdown 2}
      comment {Move the camera down while keeping it pointed at the target}
    }
    my motor_button $f Up {
      command {orbitup 2}
      comment {Move the camera upward while keeping it pointed at the target}
    }
    my motor_button $f Left {
      command {orbitleft 2}
      comment {Move the camera to the left while keeping it pointed at the target}
    }
    my motor_button $f Right {
      command {orbitright 2}
      comment {Move the camera to the right while keeping it pointed at the target}
    }
    my motor_button $f In {
      command {movein 0.96}
      comment {Move the camera inward toward target}
    }
    my motor_button $f Out {
      command {movein 1.04}
      comment {Pull the camera back away from the target}
    }
    my motor_button $f Fore {
      command {move 200 0 0}
      comment {Move the target point foreward on the ship}
    }
    my motor_button $f Aft {
      command {move -200 0 0}
      comment {Move the target point aftward on the ship}
    }
    my motor_button $f Stbd {
      command {move 0 -200 0}
      comment {Move the target point to starboard}
    }
    my motor_button $f Port {
      command {move 0 200 0}
      comment {Move the target point to port}
    }
    my motor_button $f Above {
      command {move 0 0 200}
      comment {Move the target point upward}
    }
    my motor_button $f Below {
      command {move 0 0 -200}
      comment {Move the target point downward}
    }
    
    my control_button $f Ship {
      command {
set _tag {!hidden()}
%self% canvas transform -camera light [list looktoward $_tag]
%self% canvas config -cameraup {0 0 1}
%self% action position_light
      }
      comment {Move the target point that the camera is looking at to the center of the ship}
    }

    my control_button $f Selected {
      command {
set _tag sel
%self% canvas config -cameracenter [lrange [my canvas boundingsphere sel] 1 end]
%self% action position_light
}
      comment {Move the target point that the camera is looking at to the center of the currently selected objects}
    }
    my control_button $f Fit {
      command {
set _tag {!hidden()}
%self% canvas transform -camera light [list lookat $_tag]
%self% canvas config -cameraup {0 0 1}
%self% action position_light
}
      comment {Zoom the camera in or out so that either the whole ship or the currently selected object fulls the screen}
    }
  }

  ###
  # topic: 5c66213b-e5c1-cb7b-b111-b3a14366a64a
  ###
  method build_widget f {
    my build_canvas $f
  }

  ###
  # topic: 3e6b1eb8-c60b-1da9-9f74-a5e97d235cd4
  ###
  method control_button {f name conf} {
    set command {}
    set icon {}
    set comment {}
    set tkconf {}

    if {[dict exists $conf icon]} {
      lappend tkconf -image [dict get $conf icon]
    } elseif {[dict exists $conf label]} {
      lappend tkconf -text [dict get $conf label]
    } else {
      lappend tkconf -text $name
    }
    
    dict with conf {}
    set canvas [my organ canvas]
    set self [self]
    lappend map %self% $self my $self
    lappend map %canvas% $canvas 
    set w [string tolower $name]
    ttk::button $f.$w {*}$tkconf -command [string map $map $command]
    pack $f.$w -side left
    if {$comment!=""} {
      set_balloon $f.$w $comment
    }
  }

  ###
  # topic: 88808304-6d0b-e0b3-406a-36313a76ec55
  ###
  method default_canvas_bindings {} {
    set canvas [my organ canvas]

    foreach action [bind $canvas] {
      if {$action=="<Configure>" || $action=="<Key-Tab>" || $action=="<FocusIn>"} continue
      bind $canvas $action {}
    }
    bind $canvas <Motion> "[self] motion %x %y"
    bind $canvas <Leave>  "[self] leave"
  }

  ###
  # topic: 53f7b186-aaf7-e1b8-847d-d76d8bb26d2e
  ###
  method dump_visible {} {
    foreach item [my canvas find all] {
      if {[string is false [my canvas itemcget $item -hidden]]} {
        puts [list $item [my canvas gettags $item]]
      }  
    }
  }

  ###
  # topic: 3073b012-c51a-2477-7bff-72cfa7e46a58
  ###
  method highlight_selection_do {} {
    my variable selection
    #[self].structure repaint
    my canvas dtag {withtag sel} sel
    foreach item $selection {

      set item [lindex [split $item -] 0]
      set color [lindex [split $item -] 1]

      if { $color eq {} } {
        set color purple
      }
      [my nodeLayer $item] node_highlight $item $color
      my canvas addtag sel withtag $item
    }
    my canvas transform -camera light [list lookat sel]
  }

  ###
  # topic: 366fdbb8-36b5-3cc7-c3e1-24a2a75a4c3b
  ###
  method initialize {} {
    variable selection {}
    variable mode_stack {}
    variable signals {}
    variable modes {}
    variable clearing 0
    next
  }

  ###
  # topic: 363ef3ea-f857-932a-5f59-733af28367fc
  ###
  method layer_update args {}

  ###
  # topic: 8a42a6c9-06f3-bd4f-6943-0d865eed8aeb
  ###
  method leave {} {
    
  }

  ###
  # topic: 75288c8a-f5b3-ec76-8601-7d0e8924a233
  ###
  method motion {x y} {
  }

  ###
  # topic: 2aa8415f-b914-672b-fedd-d5ba901c1c82
  ###
  method motor_button {f name conf} {
    set command {}
    set icon {}
    set comment {}
    set tkconf {}

    if {[dict exists $conf icon]} {
      lappend tkconf -image [dict get $conf icon]
    } elseif {[dict exists $conf label]} {
      lappend tkconf -text [dict get $conf label]
    } else {
      lappend tkconf -text $name
    }
    
    dict with conf {}
    
    set w [string tolower $name]
    ttk::button $f.$w {*}$tkconf
    bind $f.$w <ButtonPress-1> [list [self] motor_start $command]
    bind $f.$w <ButtonRelease-1> [list [self] motor_stop]
    pack $f.$w -side left
    if {$comment!=""} {
      set_balloon $f.$w $comment
    }
  }

  ###
  # topic: 15540fb9-b484-3b49-744f-d76e77324c5b
  ###
  method motor_start command {
    variable _motor_cmd
    set _motor_cmd $command
    variable _motor_timer
    if {[info exists _motor_timer]} return
    set _motor_timer [after idle [list [self] action motor]]
  }

  ###
  # topic: 6520ea1d-5dd3-1954-c2d4-d6f5ce04ddae
  ###
  method motor_stop {} {
    variable _motor_timer
    catch {after cancel $_motor_timer}
    my action position_light
    unset -nocomplain _motor_timer
  }

  ###
  # topic: 5cce6263-b9d8-6423-127b-0ab07f157ece
  ###
  method move_camera xform {
    my canvas transform -camera light $xform
    foreach {cx cy cz} [my canvas cget -cameracenter] break
    foreach {lx ly lz} [my canvas cget -cameralocation] break
    set dx [expr {$lx-$cx}]
    set dy [expr {$ly-$cy}]
    set dz [expr {$lz-$cz}]
    set dxy [expr {sqrt($dx*$dx + $dy*$dy)}]
    set angle [expr {atan2($dz,$dxy)*180.0/3.1415926}]
    if {$angle>80.0} {
      my canvas transform -camera light [list orbitdown [expr {$angle-80.0}]]
    } elseif {$angle<-80.0} {
      my canvas transform -camera light [list orbitup [expr {-$angle-80.0}]]
    }
    my canvas config -cameraup {0 0 1}
    my action position_light
  }

  ###
  # topic: c3b87338-398c-386e-7c9c-580375867f6b
  ###
  method object_at {x y} {
    set x0 [expr {$x-2}]
    set y0 [expr {$y-2}]
    set x1 [expr {$x+2}]
    set y1 [expr {$y+2}]
    set r {}
    global g simconfig
    foreach id [my canvas find -sortbydepth viewport($x0,$y0,$x1,$y1)] {
      set tags [my canvas gettags $id]
      set ntag {}
      set rtags {}
      foreach tag $tags {
        set type [string index $tag 0]
        set id   [string range $tag 1 end]
        if { [string is integer $id] } {
          if { $type ni {d s} && $ntag eq {} } {
            set ntag $type$id
          }
          lappend rtags $type$id

          #if { $type eq "k"} {
          #  set stag [expr {int([my canvas segment $id $x $y])}]
          #}
        }
      }
      lappend r [list $id $ntag $rtags $tags]
      #puts [list $id $tags]
      #if {[set i [lsearch -glob $tags {[a-z][0-9]*}]]>=0} {
      #  set tx [lindex $tags $i]
      #  set type [string index $tx 0]
      #  if {$type=="t" && !$g(selectable-bface)} continue
      #  if {$type=="k"} {
      #    set s [expr {int([my canvas segment $id $x $y])}]
      #    lappend r [list $id $tx $s]
      #  } else {
      #    lappend r [list $id $tx]
      #  }
      #}
    }
    return $r
  }

  ###
  # topic: 20151094-02f4-9c3d-9803-7b3c87f7641c
  ###
  method scroll_to_selection {} {
    set sel [my canvas boundingsphere sel]
    if { $sel eq {} } {
      my variable selection
      set sel [my canvas boundingsphere [get selection]]
    }
    if { $sel eq {} } {
      set sel {X 0.0 0.0 0.0}
    }
    my canvas config -cameracenter [lrange $sel 1 end]
  }
}

