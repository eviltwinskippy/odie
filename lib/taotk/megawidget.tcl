###
# topic: d97f2d16-3890-a2e8-70ec-fdf2467197a3
###

###
# topic: 44d9c478-dd48-9421-8135-63e74b0f445c
###
tao::class taotk::meta::megawidget {
  superclass taotk::meta::widget tao.controller

  option logo {default ::taotk::glider-logo}
  variable selection {}

  constructor args {
    my InitializePublic
    my graft master [self]
    my configurelist [::tao::args_to_options {*}$args]  
    my init_stack
    my initialize
    my BuildDynamicMethods
  }
  
  destructor {
    my idle_event_cancel *
    my Widget_destructor
  }
  

  ###
  # topic: b2425da0-0796-590d-6f7c-68ccd9cea0ac
  ###


  

  ###
  # topic: e1af68de-9460-f40d-402f-01c08415adcd
  ###
  method action::clear_modebar {} {
    destroy {*}[winfo children [my organ modebar]]
  }

  ###
  # topic: 27fb117e-5794-08d2-5a1e-15336feafc68
  ###
  method action::icon {} {}

  ###
  # topic: 87154a7f-25b8-4cde-2056-891b3dbd4a12
  ###
  method actionstack::splash_cancel args {
    set master [my organ topframe]
    if { $master eq {} } {
      set master .
    }
    set steps 1
    foreach {var val} $args {
      set field [string trimleft $var -]
      switch $field {
        master {
          set master $val
        }
      }
    }
    set w [winfo parent $master].splash
    if {[winfo exists $w]} {
      bind $w <Destroy> {}  
      destroy $w
      catch {image delete splash}
    }
    if {[get ::irm::oldprogress] eq {}} {
      set ::irm::oldprogress {puts $msg}
    }
    proc ::progress {msg} {
      puts $msg
      update
    }
    #wm deiconify $master
    #raise $master
  }

  ###
  # topic: 497df57a-9655-c28c-bc73-2bbb68e2418c
  ###
  method actionstack::splash_configure args {
    set steps  0
    my action busy
    set master [my organ topframe]
    if { $master eq {} } {
      set master .
    }
    set withdraw 1
    set w [winfo parent $master].splash
    if {![winfo exists $w]} return


    foreach {var val} $args {
      set field [string trimleft $var -]
      switch $field {
        text {
          set text $val
          $w.l configure -text $text
          ::progress $text
        }
        steps {
          set steps $val
          my variable progress
          set progress 0
          if { $steps > 0 } {
            $w.progress configure -mode determinate -maximum $steps -length 250 -variable [my varname progress]
          } else {
            $w.progress configure -mode indeterminate        
          }
        }
      }
    }
    update
  }

  ###
  # topic: 6e365d1d-466c-c9fb-4bd8-0ac87218f010
  ###
  method actionstack::splash_progress args {
    set steps [if_null [lindex $args 0] 1]
    set master [my organ topframe]
    if { $master eq {} } {
      set master .
    }
    set w [winfo parent $master].splash
    if {[winfo exists $w]} {
      $w.progress step $steps
      update idletasks
    }
  }

  ###
  # topic: 4e5168ed-785d-8edc-d91f-97fd360d9159
  ###
  method actionstack::splash_start args {
    set steps  0
    my action busy
    set master [my organ topframe]
    if { $master eq {} } {
      set master .
    }
    set withdraw 1
    set text "Working..."
    set lock {}
    foreach {var val} $args {
      set field [string trimleft $var -]
      switch $field {
        text {
          set text $val
        }
        steps {
          set steps $val
        }
        master {
          set master $val
        }
        withdraw {
          set withdraw [string is true $val]
        }
        lock {
          my lock create $val
          set lock $val
        }
      }
    }
    my variable progress
    set progress 0
    # Prevent the GUI from acting while the splash screen is running    
    set w [winfo parent $master].splash
    if {[winfo exists $w]} {
      $w.l configure -text $text
      
      if { $steps > 0 } {
        $w.progress configure -mode determinate -maximum $steps -length 250 -variable [my varname progress]
      } else {
        $w.progress configure -mode indeterminate        
      }
      
      ::progress $text
      update
      return
    }
    odieModalWindow $w $text [winfo toplevel $master]
    #if { $withdraw } {
    #  wm withdraw $master
    #}
    
    proc ::progress msg [string map [list %w $w] {
      if {![winfo exists %w]} {
        puts stdout $msg
        return
      }
      if { $msg != {} } {
        set ::g(progress_text) $msg
      }
      foreach line [split $msg \n] {
        puts "$line"
        set l [string length $line]
        for {set x 0} {$x < $l} {incr x 80} {
          %w.list insert end [string range $line $x [expr {$x+79}]]
          %w.list see end
        }
      }
      %w.progress step 1
      update
    }]
    
    bind $w <Destroy> [namespace code "my actionstack splash_cancel ; my lock remove $lock"]

    ttk::frame $w.title
    wm title $w "Please stand by..."
    
    ttk::label $w.logo -image [my cget logo]
    grid $w.logo -columnspan 2
    ttk::label $w.l -text $text
    listbox $w.list -width 80  -height 10 \
        -yscrollcommand "$w.sb set"
    ttk::scrollbar $w.sb -orient vertical \
        -command "$w.list yview"

    if { $steps > 0 } {
        ttk::progressbar $w.progress -mode determinate -maximum $steps -length 250 -variable [my varname progress]
    } else {
        ttk::progressbar $w.progress -mode indeterminate        
    }
    grid $w.l -columnspan 2 -sticky ew
    grid $w.list $w.sb -sticky ns
    grid $w.progress -columnspan 2 -sticky ew
  
    ::progress $text
    update
  }

  ###
  # topic: 1c2d0136-3d70-e95f-7bc5-ebe753b07bc9
  # title: Wrapper to create a new function button that controls this object
  ###
  method controlButton {w name def} {
    set object [self]
    set conf {}
    set tkconf {}
    ###
    # Set up some sensible behaviors
    ###
    
    ###
    # Replace all references to "appmain" to
    # this object
    ###
    set def [string map [list appmain $object %object% $object %self% $object %button% $w] $def]
    set conf {
      popups 1
      cursor arrow
      force_2d 1
      exit-script {
        $button state !pressed
        $button configure -command [namespace code [list my actionstack push $thismode]] -state normal
      }
    }
    dict set conf button $w
    foreach {var val} $def {
        dict set conf $var $val
    }
    dict set conf thismode $name
    dict set conf object $object
        
    if {[dict exists $conf icon]} {
        lappend tkconf -image [dict get $conf icon]
    } elseif {[dict exists $conf label]} {
        lappend tkconf -text [dict get $conf label]
    } else {
        lappend tkconf -text $name
    }
    ttk::button $w {*}${tkconf} -command [namespace code [list my actionstack push $name $conf]]
    if {[dict exists $conf comment]} {
        set_balloon $w [dict get $conf comment]
    }
    dict set conf button $w
  }

  ###
  # topic: e0698005-c0f6-a6ac-42d0-1d0699daef22
  ###
  method cursor {{cursor {}}} {
    if { $cursor == {} } {
        set cursor arrow1
    }
    my canvas configure -cursor $cursor
  }

  ###
  # topic: b137dead-84ca-bd18-a1c0-03800b44d3d4
  ###
  method idle_event_cancel {{task *}} {
    my variable idle_event
    foreach {id event} [array get idle_event $task] {
      ::after cancel $event
      set idle_event($id) {}
    }
  }

  ###
  # topic: 51fe6295-586d-7d5c-8815-5a5a642441fd
  ###
  method idle_event_schedule {handle interval script} {
    my variable idle_event
    if {[info exists idle_event($handle)]} {
      ::after cancel $idle_event($handle)
    }
    set idle_event($handle) [::after $interval [namespace code $script]]
  }

  ###
  # topic: 2aeff825-cbfc-2d82-3adf-9acb47a8a0e8
  ###
  method init_stack {} {
    variable mode_stack {}    
    variable modes {}
    variable clearing 0
    
    my variable popups_enabled currentclass mode_stack viewconfig
    set mode_stack {}
    set currentclass {}
    set popups_enabled 1
    set viewconfig(popups) 1
  }

  ###
  # topic: 4fc015fa-cf1a-c8a1-3907-ac1f82060936
  ###
  method initialize {} {
    my lock remove initialize
  }

  ###
  # topic: 815412ed-48f5-82b0-6f67-33d2941c0133
  ###
  method lock::remove args {
    my variable ActiveLocks
    if {![llength $ActiveLocks]} {
      return 0
    }
    logicset remove ActiveLocks {*}$args
    if {![llength $ActiveLocks]} {
      my Signal_pipeline
      my actionstack splash_cancel
      return 1
    }
    return 0
  }

  ###
  # topic: 87033871-8391-9409-e12c-60c9c52e630b
  ###
  method lock::remove_all {} {
    my variable ActiveLocks
    set ActiveLocks {}
    my Signal_pipeline
    my actionstack splash_cancel
  }

  ###
  # topic: cc5cd2b7-43f4-6420-b2c2-260dc9cc0fad
  ###
  method setting {field args} {
    my variable $field
    if {[llength $args]} {
      set $field [lindex $args 0]
    }
    return [if_null [::get $field] 0]
  }
}

