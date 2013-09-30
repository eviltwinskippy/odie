###
# topic: 14028081-7608-40f7-e1dc-b3a6f87b963f
###
tao::class taotk::notetab {
  superclass taotk::frame

  property options_strict 1

  variable topframe
  variable drawn 0
  
  option title {}
  option readonly {
    get-command {my readonly}
    default -1
    widget boolean
  }

  constructor {window shared args} {
    my InitializePublic
    foreach {organ target} $shared {
      my graft $organ $target
    }
    my configurelist [::tao::args_to_options {*}$args]  
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my bind_widget $window
  }

  ###
  # topic: 183661a9-e309-cb47-0806-533f7f7a4166
  # description:
  #    Handler to allow the progammer to call out
  #    CLASSNAME .tkpath and have the object
  #    answer
  ###
  #class_method unknown args {
  #  if {[string index [lindex $args 0] 0] == "."} {
  #    set tkpath [lindex $args 0]
  #    destroy $tkpath
  #    set obj [my new $tkpath {*}[lrange $args 1 end]]
  #    return $obj
  #  }
  #  next {*}$args
  #}

  ###
  # topic: b060ab6a-4e3c-ad44-442d-461cf898440a
  ###
  class_method tab_init {parent config} {
    return 1
  }

  ###
  # topic: f0439216-a3ee-a821-c260-1030ab243df2
  # description:
  #    Action to perform when the user presses
  #    the "save" or "apply" button
  ###
  method action::apply {}

  ###
  # topic: 61a801c9-7df3-cbf6-3a73-8a03b407f66b
  ###
  method action::save {}

  ###
  # topic: 881ba871-b624-bb6d-1dfd-9cec84174d6b
  # description:
  #    Action called when the parent selects
  #    a different tab
  ###
  method action::tabselect dictargs {my build_content}

  ###
  # topic: 3f08ef21-8186-b8cd-37b6-205383aefa8a
  ###
  method action::tabunselect dictargs {}

  ###
  # topic: 480ad149-d779-0eed-36b1-44f007e64d86
  ###
  method build_content {} {
    my variable config
    my clear_content
    my Build_controls [my organ buttonframe]
    set f [my organ contentframe]

    ttk::label $f.text -text "Not implemented"
    grid $f.text
  }

  ###
  # topic: 28648a41-8b41-500d-90c1-f1973f32825d
  # title: Add controls to the master frame
  # description:
  #    As part of the revelation of a new tab,
  #    the tab is given the oppertunity to contribute additional
  #    buttons to the parent's control frame. It is the responsibility
  #    of this widget to pack any widgets created. Also note, this
  #    frame will ALWAYS be managed with the pack function.
  #    <p>
  #    The parent is free to add buttons before or after this call
  ###
  method Build_controls buttonframe {
  }

  ###
  # topic: fa3056db-1515-d6c7-2261-f5036e752ff3
  ###
  method build_widget window {
    ###
    # Empty Implementation
    ###
    my graft contentframe $window
  }

  ###
  # topic: 36889e37-b346-c20a-f0cb-cc29c7a524c6
  ###
  method clear_content {} {
    foreach organ {contentframe buttonframe} {
      set w [my organ $organ]
      if {[winfo exists $w]} {
        destroy {*}[winfo children $w]
      }
    }
  }

  ###
  # topic: da163312-bc4a-c4ff-2889-299d45743e4f
  ###
  method configurelist dictargs {
    my variable config
    set dat [my property option dict]
    ###
    # Validate all inputs
    ###
    foreach {field val} $dictargs {
      set script [dictGet $dat $field validate]
      if {$script ne {}} {
        {*}$script $field $val
      }
    }
    ###
    # Apply all inputs with special rules
    ###
    foreach {field val} $dictargs {
      set script [dictGet $dat $field set-command]
      if {$script ne {}} {
        {*}$script $field $val
      } else {
        dict set config $field $val
      }
    }
  }

  ###
  # topic: 4e56ad0e-7ba7-e594-8697-7105491b1557
  ###
  method readonly args {
    my variable config
    set readonly [dictGet $config readonly]
    if {$readonly in {{} -1}} {
      return [string is true [my parent readonly]]
    }
    return [string is true $readonly]
  }
}

###
# topic: db0082b1-2636-0d32-220e-bccfc17ef0a6
###
tao::class taotk::notetab.frame {
  superclass taotk::notetab taotk::meta::widget

  ###
  # topic: 0e38b7ad-7445-06ad-aad4-ff4604f804a7
  ###
  method build_widget window {
    my graft contentframe $window
  }
}

###
# topic: eb1b9a9e-6a94-5b74-9a38-413d816e3c21
###
tao::class taotk::notetab.text {
  superclass taotk::notetab
  

  ###
  # topic: 5d374d5f-fe02-e16e-2708-8ee8ba8d4e7d
  ###
  method action::apply {}

  ###
  # topic: 721a0f6e-a768-b8c8-abc9-9c8b774b77cd
  ###
  method action::save {}

  ###
  # topic: e39af7a8-9db8-7630-b25e-92b7aca0d2a7
  ###
  method action::tabunselect {}

  ###
  # topic: 35459bef-8ca2-c732-14a2-9382e480597b
  ###
  method build_content {} {}

  ###
  # topic: ab30ca8a-b2b3-2028-5337-405b2609608a
  ###
  method build_widget window {
    text $window.t -bd 2 -relief sunken -bg white -fg black \
       -yscrollcommand "$window.sb set" -width 60 -height 10 \
       -font [my stylesheet cget font-text]
    scrollbar $window.sb -orient vertical -command "$window.t yview"
    pack $window.sb -side right -fill y
    pack $window.t -side left -expand 1 -fill both
    my graft textwidget $window.t
  }

  ###
  # topic: b5687398-e688-1fd7-355d-e00e8eef54e1
  ###
  method clear_content {} {
  }

  ###
  # topic: edeafab6-cf7f-81a4-61ae-a3b26c1c39c7
  ###
  method insert_content txt {
    my textwidget configure -state normal -bg white

    my textwidget delete 0.0 end
    my textwidget insert 0.0 $txt
    if {[my readonly]} {
      my textwidget configure -state disabled -bg grey
    }
  }

  ###
  # topic: 7247212e-8667-9cc4-e1c8-f2a5188ccf3a
  ###
  method retrieve_content {} {
    return [string trim [my textwidget get 0.0 end]] 
  }
}

###
# topic: e2ff5bf4-33da-436a-82c0-9527fcec171d
###
tao::class taotk::notetab.scrollframe {
  superclass taotk::meta::scrollframe taotk::notetab

  constructor {window shared args} {
    my InitializePublic
    foreach {organ target} $shared {
      my graft $organ $target
    }
    my configurelist [::tao::args_to_options {*}$args]  
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    set f [my Build_scrollframe $window {*}$args]
    my build_widget $f
    my bind_widget $window
  }

  ###
  # topic: c0ba05da-f4b8-20b4-3699-af9201d65326
  ###
  method action::tabunselect {}
}

