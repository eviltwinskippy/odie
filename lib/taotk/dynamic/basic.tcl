###
# Bread and butter widgets: entry, boolean, label
###

###
# topic: 23be090a-197d-43e6-2122-2fee380ae2d1
# description: Provides the ground rules for dynamic widgets
###
tao::class taotk::dynamic {
  superclass taotk::frame
  property options_strict 0

  option unknown      {default 0}
  option showlabels   {default 1}
  option readonly     {default 0}
  option units        {default {}}
  option data_source  {default {}}
  option label        {default {}}
  option description  {default {}}
  option takefocus    {default 0}
  option mode         {
    default static
    values {
      static static {Options cannot be added or removed}
      spec   spec   {Options can be added or remove}
    }
  }
  option command {
    default {}
  }
  ###
  # Place to store an internal representation
  # of the value:
  # variable local_value
  ###

  option object {
    class organ
    description {The object we are representing}
  }
  variable field    {}
  variable arrayvar {::g}
  
  constructor {window fieldname arrayname args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]  
    my variable field arrayvar
    set field $fieldname
    set arrayvar $arrayname

    my graft mainframe $window    
    my graft nativewidget $window
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my bind_widget $window
    ###
    # Store a note for the system to extract my value when saving
    ###
    #if {![my cget readonly]} {
    #  set ${arrayname}(script.$field) [namespace code {my value}]
    #}
  }

  ###
  # topic: 50fbc3aa-fec0-3d03-ccb1-98c32fce5079
  # description:
  #    Handler to allow the progammer to call out
  #    CLASSNAME .tkpath and have the object
  #    answer
  ###
  #class_method unknown args {
  #  set tkpath [lindex $args 0]
  #  if {[string index $tkpath 0] eq "."} {
  #    if {[llength $args]<3} {
  #      error "Usage: [self] tkpath fieldname arrayname ?args?"
  #    }
  #    if {[winfo exists $tkpath]} {
  #      error "Bad path name $tkpath"
  #    }
  #    set field  [lindex $args 1]
  #    set array  [lindex $args 2]
  #    ###
  #    # Embed the widget inside of a frame
  #    ###
  #    ttk::frame $tkpath
  #    set obj [my new $tkpath.native $field $array {*}[lrange $args 3 end] unknown 1]
  #    if {![winfo exists $tkpath]} {
  #      catch {$obj destroy}
  #      return {}
  #    }
  #    $tkpath configure -style [$obj private Style frame] -takefocus [$obj cget takefocus]
  #    $obj tkalias $tkpath
  #    grid $tkpath.native -sticky news
  #    return [string trimleft $tkpath :]
  #  }
  #  next {*}$args
  #}

  ###
  # topic: 23a01b05-a7b1-8e14-cae9-567579a793fc
  ###
  method action::revert_to_default {} {
    set varname [my GlobalVariableName]
    my variable field
    set varname [my <object> cget $field default]
  }

  ###
  # topic: 1331cb23-a735-fff9-5814-200422974000
  ###
  method ApplySelectedValue {newvalue {initial 0}} {
    set varname [my GlobalVariableName]
    set $varname $newvalue
    if {!$initial && [set command [my cget command]] ne {}} {
      my variable field array
      eval {*}[string map [list %field% $field %self% [self] %value% $newvalue] $command]
    }
  }

  ###
  # topic: 22c25dde-33de-1a95-f7bc-39ec6571a472
  ###
  method DefaultValue {} {
    my variable config field
    set getcmd [dictGet $config default-command]
    if {$getcmd ne {}} {
      return [{*}[string map [list %field% $field %widget% [self] %self% [my cget object] %object% [my cget object]] $getcmd]]
    } else {
      return [dictGet $config default]
    }
  }

  ###
  # topic: 0b04dd43-f62d-2710-3d02-5010cbee6a73
  ###
  method GlobalVariableName {} {
    my variable arrayvar field
    return ${arrayvar}($field)
  }

  ###
  # topic: 05349e11-c5a7-ad24-14f8-0f31702f4188
  ###
  method Option_Validate_Not_Null {field value} {
    if { $value eq {} } {
      error "No value specified for: $field"
    }
  }

  ###
  # topic: eef66cd3-c2f0-3bc0-52b5-c3b1f9ca69b8
  ###
  method value {} {
    set var [my GlobalVariableName]
    return [get $var]
  }
}

###
# topic: 884ed25a-75bc-bca5-b789-8baa30e883df
# description: A simple read-only widget for read-only options
###
tao::class taotk::dynamic::label {
  superclass taotk::dynamic

  ###
  # topic: ba2432fb-2ee4-8998-bfa7-55b0cf4d1dde
  ###
  method build_widget window {
    set varname [my GlobalVariableName]
    ::ttk::label $window.native -style [my Style label] -textvariable ${varname} -takefocus 0
    my graft nativewidget $window.native
    grid $window.native -sticky news
  }
}

###
# topic: 0154f499-f3ea-8bda-6835-2f074be7410c
###
tao::class taotk::dynamic::entry {
  superclass taotk::dynamic::label
  
  option width {default {}}

  ###
  # topic: c888bfa8-9f80-d78b-4da0-17f25d62ae91
  ###
  method build_widget window {
    set readonly [my cget readonly]
    set varname [my GlobalVariableName]
    set opts [list -textvariable ${varname}]
    if {[string is integer -strict [my cget width]]} {
      lappend opts -width [my cget width]
    }
    if { $readonly } {
      ::ttk::label $window.native -style [my Style label] {*}$opts -takefocus 1
    } else {
      ::ttk::entry $window.native -style [my Style entry] {*}$opts
    }
    my graft nativewidget $window.native
    grid $window.native -sticky news
  }
}

###
# topic: 0ba65bf3-b2a7-bd49-8fc9-866559df7b4d
###
tao::class taotk::dynamic::real {
  superclass taotk::dynamic::entry
}

###
# topic: df091a03-bbe5-9eff-33e9-7b39d4d9e2e5
###
tao::class taotk::dynamic::button {
  superclass taotk::dynamic

  ###
  # topic: 7d70d2d7-e825-87a3-be72-03f369fa1196
  ###
  method build_widget window {
    set readonly [my cget readonly]
    set varname [my GlobalVariableName]
    if { $readonly } {
      ::ttk::label $window.native -style [my Style label] -textvariable ${varname} -takefocus 0
    } else {
      ::ttk::button $window.native -style [my Style button] -variable ${varname} -command [my cget command] -takefocus 1
    }
    my graft nativewidget $window.native
    grid $window.native -sticky news
  }
}

###
# topic: da26ee5d-f357-4e95-a77c-b54a58d19ed9
###
tao::class taotk::dynamic::checkbutton {
  superclass taotk::dynamic::button

  option onValue {
    default 1
  }
  option offValue {
    default 0
  }
  

  ###
  # topic: f33b2a75-b6e8-c384-71e9-bf9545624f25
  ###
  method ApplySelectedValue {} {
    set varname [my GlobalVariableName]
    set value   [get $varname]
    if {[set command [my cget command]] ne {}} {
      my variable field array
      eval {*}[string map [list %self% [self] %field% $field %value% $value] $command]
    }
  }

  ###
  # topic: 4386ff08-61ef-ef34-f74b-51f8f3d7d43a
  ###
  method build_widget window {
    set readonly [my cget readonly]
    set varname [my GlobalVariableName]
    if { $readonly } {
      ::ttk::label $window.native -style [my Style label] -textvariable ${varname} -takefocus 0
    } else {
      ::ttk::checkbutton $window.native -style [my Style checkbutton] -variable ${varname} -command [namespace code {my ApplySelectedValue}] -takefocus 1
    }
    my graft nativewidget $window.native
    grid $window.native -sticky news
  }

  ###
  # topic: de5a9be0-535d-87f3-318d-301343bb9c16
  ###
  method WidgetInputValue value {
    set varname [my GlobalVariableName]
    set $varname $value
  }
}

###
# topic: 3175e101-e727-c4e1-fdc2-4850f4da0c49
###
tao::class taotk::dynamic::boolean {
  superclass taotk::dynamic::checkbutton
}

###
# topic: 5298a8e9-ecbd-5db4-d615-93e9c9c89ca1
###
tao::class taotk::dynamic::scale {
  superclass taotk::dynamic::entry
  
  option range {
    default {0 1}
  }
  option takefocus {
    widget boolean
    default 0
  }

  ###
  # topic: 59f6c160-0580-de6c-6376-8fabe506d8f1
  ###
  method build_widget window {
    set readonly [my cget readonly]
    set varname [my GlobalVariableName]
    if { $readonly } {
      ::ttk::label $window -style [my Style label] -textvariable ${varname} -takefocus 0
      return
    }
    my variable config internal field

    set range [dictGet $config range]
    set from [lindex $range 0]
    set to   [lindex $range 1]
    if { $to eq {} } {
      set to 1.0
    }
    if { $from eq {} } {
      set from 0.0
    }
    set storage [dictGet $config storage]
    
    set value [if_null [get $varname] [dictGet $config default]]
    if { $storage in {integer int time timer} } {
      set command [namespace code {my Scale_round}]
      my Scale_round $value
    } else {
      set command [namespace code {my Scale_set}]
      my Scale_set $value
    }
    
    ::ttk::scale $window.scale -variable [my varname internal] -length 150 -orient horizontal -from $from -to $to -command $command -takefocus 1
    ::ttk::entry $window.e -textvariable $varname -width 6 -takefocus 1
    if {[dict exists $config command]} {
      ::ttk::button $window.apply -text "Apply" -command "{*}[dict get $config command] [list $field] \[set $varname\]"  -takefocus 1
      grid $window.e $window.apply -sticky news
      grid $window.scale -columnspan 2
  
    } else {
      grid $window.e
      grid $window.scale
    }
  }

  ###
  # topic: 29f31444-babd-8f2a-e7ad-713e02dccf93
  ###
  method Scale_round value {
    set varname [my GlobalVariableName]
    set $varname [expr round($value)]
    my variable internal
    set internal [expr round($value)]
  }

  ###
  # topic: b483194d-f9bd-712f-951f-3f6a44a2a47d
  ###
  method Scale_set value {
    set varname [my GlobalVariableName]
    set $varname $value
    my variable internal
    set internal $value
  }
}

