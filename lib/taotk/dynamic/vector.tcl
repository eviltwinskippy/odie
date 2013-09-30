###
# topic: 59291fa1-2e47-8d7a-3b49-f82ce4fd24f3
###
tao::class taotk::dynamic::vector {
  superclass taotk::dynamic::entry
  option command {default {}}
  property vector_fields {
    x {format {%0.6g} widget entry width 10}
    y {format {%0.6g} widget entry width 10}
    z {format {%0.6g} widget entry width 10}
  }

  ###
  # topic: c6966d5d-1b2a-63d1-3cd4-4842f7c1ade5
  ###
  method ApplySelectedValue {newvalue {initial 0}} {
    set varname [my GlobalVariableName]
    if {!$initial} {
      set $varname $newvalue
    }
    my WidgetInputValue $newvalue
    next $newvalue $initial
    set window [my organ nativewidget]
    destroy {*}[winfo children $window]
    set row  [if_null [my cget row] 0]
    ttk::label $window.m -style [my Style label] -textvariable $varname
    if {![my cget readonly]} {
      ttk::button $window.b -style [my Style button] -text Edit -command [namespace code [list my build_widget_edit]]
      pack $window.b -side right
    }
    pack $window.m -side left -expand 1 -fill x
  }

  ###
  # topic: 469b26ac-b2b9-b387-9d9f-e642dc858960
  ###
  method build_widget window {
    set varname [my GlobalVariableName]
    set value [get $varname]
    set row  [if_null [my cget row] 0]
    my ApplySelectedValue $value 1
    #if {[my cget readonly]} {
    #  ttk::label $window.native -style [my Style label] -textvariable $varname
    #  pack $window.native -side left -fill both
    #  return
    #}
    #ttk::label $window.m -style [my Style label] -textvariable $varname
    #ttk::button $window.b -style [my Style button small] -text Edit -command [namespace code [list my build_widget_edit]]
    #pack $window.b -side right
    #pack $window.m -side left -expand 1 -fill x
  }

  ###
  # topic: 0f7beb44-d39c-be1a-dfee-f0c5ac6c5866
  ###
  method build_widget_edit {} {
    set varname [my GlobalVariableName]
    set value [get $varname]
    set window [my organ nativewidget]
    destroy {*}[winfo children $window]
    if [catch {
      my WidgetInputValue $value
    } err] {
      puts "Error generating widget for $window: $err"
      # Punt and behave like an entry
      ttk::entry $window.m -style [my Style entry] -textvariable $varname
      pack $window.m -expand 1 -fill x
      return
    }
    set readonly  [my cget readonly]
    set vectorvar [my varname local_array]
    set labelrow {}
    set widgetrow {}
    set row  [if_null [my cget row] 0]
    foreach {vfield vfieldinfo} [my property vector_fields] {
      ttk::label $window.$vfield#l -style [my stylesheet widget_style label {} $row] -text "$vfield:"
      #set vinfo  [::taotk::option_inferences $vfield $vfieldinfo]
      #set vclass [::taotk::meta::widget_select $vinfo]
      #$vclass $window.$vfield $vfield $vectorvar {*}$vfieldinfo readonly $readonly row $row
      ::taotk::dynamic_widget $window.$vfield $vfield $vectorvar {*}$vfieldinfo readonly $readonly row $row
      foreach key {<Tab> <Return>} {
        bind [$window.$vfield organ nativewidget] $key [namespace code {my ApplySelectedValue [my WidgetOutputValue]}]
      }
      lappend labelrow $window.$vfield#l 
      lappend widgetrow $window.$vfield      

    }
    ttk::button $window.b -text "Set" -command [namespace code {my ApplySelectedValue [my WidgetOutputValue]}]
    grid {*}$labelrow -sticky news
    grid {*}$widgetrow $window.b -sticky news
  }

  ###
  # topic: b9ebccee-424e-0b4a-2717-ffdcfcc37644
  ###
  method WidgetInputValue inputvalue {
    my variable local_array
    set idx -1
    foreach {vfield info} [my property vector_fields] {
      incr idx
      set format [if_null [dictGet $info format] %s]
      set value [lindex $inputvalue $idx]
      if {[dict exists $info default]} {
        if {$value eq {}} {
          set value [dict get $info default]
        }
      }
      if [catch {format $format $value} nvalue] {
        puts "Err: $vfield. Raw: $value. Err: $nvalue"
        set local_array($vfield) $value
      } else {
        set local_array($vfield) $nvalue
      }
    }
  }

  ###
  # topic: 55217fd4-a0c5-3d1d-d5ab-d81cf8d6f469
  ###
  method WidgetOutputValue {} {
    my variable local_array
    set result {}
    foreach {vfield info} [my property vector_fields] {
      set format [if_null [dictGet $info format] %s]
      set newvalue [format $format $local_array($vfield)]
      lappend result $newvalue
    }
    return $result
  }
}

