###
# Base classes for Model/View/Controller architecture
###

###
# topic: 71b9a2bf-1f9b-9e1c-8b1e-06ceaa088b1d
# description:
#    This class implements a common data store used by
#    a model view controller
###
tao::class tao.mvcstore {

}

###
# topic: f9279c5b-e057-cc75-b1f1-fd3bd4ee3052
###
tao::class tao.model {

}

###
# topic: 2927c0b0-fc54-227b-3538-f26e3bd0323b
###
tao::class tao.view {

}

###
# topic: 2d337edf-2d1b-9042-d4ee-2510fcc4c99d
###
tao::class tao.controller {
  superclass moac
  
  variable mode_stack {}
  variable modes {}
  variable clearing 0

  property default_context {
    class action
    button {}
    main-script {my actionstack clear}
    exit-script {}
    push-script {}
    appswitch-script {}
    popups 1
    cursor arrow
    force_2d 1
    usermode 0
    icon {}
    auto-pop 0
    edit-ok  0
    interactive 0
    modal 0
  }

  signal busy {
    apply_action {my action busy}
    triggers {idle}
  }
  signal idle {
    apply_action {my action idle}
    follows  *
    triggers {}
  }
  
  destructor {
    my idle_event_cancel *
  }
  

  ###
  # topic: e458dd2b-e7ca-1ac3-6819-4dacc8196bcf
  # description:
  #    Code to run when the application is about to enter a
  #    busy phase
  ###
  method action::busy {} {}

  ###
  # topic: a689f9c4-ec6d-9bd7-473a-c95ea18009fa
  # description: Commands to run when the system ceases to be busy
  ###
  method action::idle {} {}

  ###
  # topic: 4411d297-e2fe-3159-5d36-29845019dcb5
  # description:
  #    Action to perform at the top of every "peek"
  #    onto the stack
  ###
  method action::mode_peek {
  }

  ###
  # topic: 9bdf14ac-5b05-40d1-3859-66a8d5f3b561
  # description:
  #    Action to perform when a mode is popped off
  #    the stack/exited
  ###
  method action::mode_pop {
  }

  ###
  # topic: ae389fc6-651e-d57f-799b-354651e0728b
  # title: method to execute when we enter the mode from another mode
  # description:
  #    Action to perform when a mode is pushed onto
  #    the stack/entered
  ###
  method action::mode_push {
  }

  ###
  # topic: edba2228-11d4-26ca-1e88-0423c21c70f7
  ###
  method action::stack_cleared {
  }

  ###
  # topic: 8d8f9331-afd2-27c3-a763-cddad50c9902
  ###
  method actionstack::clear {} {
    my lock create [self method].$method
    set cleared 0
    variable mode_stack
    while {[llength $mode_stack] > 0} {
      incr cleared
      if {[catch {my actionstack pop} err options]} {
        my action mode_peek
        return -options $options $err
      }
    }
    set mode_stack {}
    my action mode_peek
    if { $cleared } {
      my signal  layer_update
    }
    my lock remove [self method].$method
  }

  ###
  # topic: a18c4b0e-f8cd-c757-2549-ae7ed3862950
  ###
  method actionstack::define {name settings} {
    my variable modes organs
    if {![info exists modes]} {
      set modes {}
    }
    if {![dict exists $modes $name]} {
      set context [my property default_context]
    } else {
      set context [dict get $modes $name]
    }
    foreach {var val} $settings {
      dict set context $var $val
    }
    dict set modes $name $context
    return $name
  }

  ###
  # topic: ba196090-e6fd-2be2-1ee9-c9ac1fae3f9e
  # description:
  #    A varient of action that clears the stack and establishes
  #    new base-behaviors. Used to implement the different "modes"
  #    in the visualization (i.e. runmode, playback, etc)
  ###
  method actionstack::morph newclass {
    ###
    # Tell runmode to cease
    ###
    my lock create [self method].$method
    set currentclass [my get currentclass]
    if { $currentclass eq $newclass } {
      my actionstack clear
      return
    }
    ###
    # After we have cleared the stack, destroy layers
    # we are not using and add layers that we are
    ###
    global g simconfig
    #puts [list [self] [info object class [self]] mode_pop]
    my action mode_pop
    #puts [list [self] [info object class [self]] /mode_pop]
    my morph $newclass
    my activate_layers

    set currentclass $newclass
    #puts [list [self] [info object class [self]] mode_push]
    my action mode_push [list prev_class $currentclass class $newclass]
    #puts [list [self] [info object class [self]] /mode_push]
    ###
    # Publish that we have changed modes
    ###
    my event generate mode_change prev_class $currentclass class $newclass
    #puts [list [self] [info object class [self]] mode_peek]
    my action mode_peek
    my lock remove [self method].$method
    #puts [list [self] [info object class [self]] /mode_peek]
  }

  ###
  # topic: 8aad9027-abfa-3f69-9205-c699e550f748
  ###
  method actionstack::peek {} {
    my lock create [self method].$method
    #puts [list [self] [info object class [self]] mode_peek]
    my action mode_peek
    #puts [list [self] [info object class [self]] /mode_peek]
    my variable mode_stack organs
    if {[llength $mode_stack]==0} {
      #puts [list [self] [info object class [self]] * mode_peek]
      my action mode_peek      
      #puts [list [self] [info object class [self]] * /mode_peek]

      set context [my property default_context]
      set doPop 0
      set force_interactive 1
    } else {
      set context [lindex [get mode_stack] end]
      set doPop 0
      set force_interactive 0
    }
    set code [catch {
      dict with organs {}
      dict with context {}
      my popups_enabled ${popups}
      my cursor $cursor
      my action icon [list icon $icon]
      if { $button != {} } {
        catch {$button configure -state pressed}
      }
      eval ${main-script}
      if { ${auto-pop} } {
        set doPop 1
      }
    } result returnInfo]
    if { $code ni {0 2} } {
      my actionstack pop
      set ::errorInfo [list Evaluating object [self] context $context]\n${::errorInfo}
      return {*}${returnInfo} $result
    }
    if { $doPop } {
      my actionstack pop
    }
    my lock remove [self method].$method
    if {$force_interactive || $interactive} {
      my Signal_pipeline
    }
  }

  ###
  # topic: 3e52d373-bdba-03d8-decb-1bb01b069fdb
  ###
  method actionstack::pop {} {
    my lock create [self method].$method
    my variable mode_stack organs
    set context [lindex $mode_stack end]
    if { $context ne {} } {
      if {![dict get $context usermode]} {
        set mode_stack [lrange $mode_stack 0 end-1]
        dict with organs {}
        dict with context {}
        if [catch ${exit-script} result returnInfo] {
          set ::errorInfo [list Evaluating object [self] context $context]\n${::errorInfo}
          return {*}${returnInfo} $result
        }
      }
    }
    my lock remove [self method].$method
    my actionstack peek
  }

  ###
  # topic: b4b837a3-c645-ad23-380b-740f7ede7fcd
  ###
  method actionstack::push {mode {inputcontext {}}} {
    my variable mode_stack modes organs
    my action busy
    my lock create [self method].$method
    set script {}
    ###
    # Load our organs as the local context
    ###
    set context [my property default_context]
    if {[dict exists $modes $mode]} {
      foreach {var val} [dict get $modes $mode] {
        dict set context $var $val
      }
    }
    foreach {var val} $inputcontext {
      dict set context $var $val
    }
    dict set context mode $mode
    dict set modes $mode $context
    set stack_clear 0
    
    if {[dict exists $context exclusive]} {
      ###
      # If we have certain modes that are mutually exclusive on
      # the task stack, clear the stack
      ###
      set exclusive [dict get  $context exclusive]
      set top [lindex $mode_stack end]
      if {[dict exists $top mode]} {
        if {[dict get $top mode] in $exclusive} {
          set stack_clear 1
        }
      }
    }
    ####
    # Modal actions want to be the
    # top thing on the stack
    # so cancel anything else going on
    ###
    if {[dict get $context modal]} {
      set stack_clear 1
    }

    if { $stack_clear } {
      my actionstack clear
    }
    lappend mode_stack $context
    dict with organs {}
    dict with context {}
    if [catch ${push-script} result returnInfo] {
      set ::errorInfo [list Evaluating object [self] context $context]\n${::errorInfo}
      return {*}${returnInfo} $result
    }
    my lock remove [self method].$method
    my actionstack peek
  }

  ###
  # topic: 05f33ae8-41ed-5252-dbb8-4aa7c94d34a9
  ###
  method configurelist_triggers dictargs {
    set dat [my property option dict]
    ###
    # Apply normal inputs
    ###
    foreach {field val} $dictargs {
      my Option_set $field $val
    }
    ###
    # Generate all signals
    ###
    foreach {field val} $dictargs {
      set signal [dictGet $dat $field signal]
      if {$signal ne {}} {
        my signal  $signal
        my event generate {*}$signal [list value $val]
      }
    }
  }
}

