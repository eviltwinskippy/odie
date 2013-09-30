###
# topic: 4d0fe425-6dec-54ac-1ee7-d5ebd6d8ee42
# description: Selector style widgets based on the combobox
###
tao::class ::taotk::dynamic::combobox {
  superclass taotk::dynamic::entry
  
  option command {
    default {}
  }
  option values {}
  option state {
    class tkoption
    widget select
    values {normal readonly disabled}
    default normal
  }
  option width {
    class tkoption
  }

  ###
  # topic: 648ac836-dc54-2ce5-6f1f-d366884add01
  ###
  method ApplySelectedValue {newvalue {initial 0}} {
    set varname [my GlobalVariableName]
    set value   [my WidgetInputValue $newvalue]
    set $varname $value
    if {[set command [my cget command]] ne {}} {
      my variable field array
      eval {*}[string map [list %object% [my cget object] %self% [self] %field% $field %value% $value] $command]
    }
  }

  ###
  # topic: 2047366d-aeda-8289-d0b0-2dc831ff746d
  ###
  method build_widget window {
    set readonly [my cget readonly]
    if { $readonly } {
      set varname [my GlobalVariableName]
      ::ttk::label $window.native -style [my Style label] -textvariable ${varname}
      grid $window.native -sticky news
      return
    }
    set varname [my varname tempval]
    set values  [my CalculateValues]
    set gvarname [my GlobalVariableName]
    my WidgetInputValue [get $gvarname]
    my variable config
    set state [if_null [dictGet $config state] readonly]
    if {$state ne "normal"} {
      ::ttk::combobox $window.e -textvariable $varname -state $state -values $values  -width [my CalculateValueWidth $values]
      grid $window.e
    } else {
      ::ttk::combobox $window.e -textvariable $varname -state $state -values $values  -width [my CalculateValueWidth $values]
      ::ttk::button $window.b -width 0 -style [my Style button small] -text Apply -command [namespace code {my ApplySelectedValue [my WidgetOutputValue]}]
      grid $window.e $window.b
      bind $window.e <KeyRelease-Return> [namespace code {my ApplySelectedValue [my WidgetOutputValue]}]
    }
    bind $window.e <<ComboboxSelected>> [namespace code {my ApplySelectedValue [my WidgetOutputValue]}]
    
  }

  ###
  # topic: c151e491-4c89-97fa-e92c-be60f944bdf3
  ###
  method CalculateValues {} {
    my variable config
    set values {}
    if {[dict exists $config values]} {
      return [dict get $config values]
    }
    if {[dict exists $config options]} {
      return [dict get $config options]
    }
    if {[dict exists $config options_command]} {
      return [eval [dict get $config options_command]]
    }
    return {}
  }

  ###
  # topic: 7da5a030-df38-aa55-4fcb-e52de744341c
  ###
  method CalculateValueWidth values {
    set w 0
    set n 0
    foreach v $values {
      incr n
      set l [string length $v]
      incr bins($l)
      if {$l > $w} {
        set w $l
      }
    }
    if { $w > 30} {
      set w 30
    }
    return $w
  }

  ###
  # topic: 6d1e6409-36f4-31eb-e920-02a393c4628e
  ###
  method WidgetInputValue value {
    my variable tempval
    set tempval $value
    return $value
  }

  ###
  # topic: 1fadaad5-43fd-7ffc-b93d-a01cd4302bbb
  ###
  method WidgetOutputValue {} {
    my variable tempval
    return $tempval
  }
}

###
# topic: 1435bfb5-e165-9601-c47d-9545c6e7ff08
# description: A {pick from a finite list} widget
###
tao::class ::taotk::dynamic::select {
  superclass taotk::dynamic::combobox
  option state {
    class tkoption
    widget select
    values {normal readonly disabled}
    default readonly
  }
}

###
# topic: 6210ab6b-69b4-0920-dafd-421117031fd3
###
tao::class ::taotk::dynamic::enumerated {
  superclass taotk::dynamic::combobox

  option state {
    widget select
    values {normal readonly disabled}
    default readonly
  }
  option enum {
    default {}
  }

  ###
  # topic: 6122ad9e-bdce-933a-3ada-e730fb2e4ae5
  ###
  method CalculateValues {} {
    set values {}
    my variable config
    foreach {id code comment} [dictGet $config values] {
      lappend values "$id - $code"
    }
    return $values
  }

  ###
  # topic: 764bdc72-18a3-4d15-9d5b-3e2347d33591
  ###
  method WidgetInputValue value {
    set varname [my GlobalVariableName]
    my variable config tempval
    foreach {id code comment} [dictGet $config values] {
      if { [lindex $value 0] == $id } {
        set $varname $id
        set tempval "$id - $code"
        return $id
      }
    }
    return {}
  }

  ###
  # topic: 64e1a9b4-21af-57cd-dab7-f6e846ba4bb3
  ###
  method WidgetOutputValue {} {
    set varname [my GlobalVariableName]
    my variable config tempval
    set value [lindex $tempval 0]
    foreach {id code comment} [dictGet $config values] {
      if {$value == $id } {
        return $id
      }
    }
    return {}
  }
}

###
# topic: c47deae1-9010-8e64-70a2-3ecf66858639
###
tao::class ::taotk::dynamic::history {
  superclass taotk::dynamic::combobox
  option state {
    class tkoption
    widget select
    values {normal readonly disabled}
    default normal
  }

  ###
  # topic: 22b3b919-e7af-13d5-90f9-d454239dc35c
  ###
  method CalculateValues {} {
    my variable field
    return [my stylesheet history $field]
  }
}

