###
# topic: ecd6f13a-22bd-b7c0-8299-904e350dfb9d
###
tao::class taotk::dynamic.xylist {
  superclass taotk::dynamic
  

  ###
  # topic: 86ec5d08-387d-7006-7cd0-0b60064974f7
  ###
  method build_custom_widget window {
    set readonly [my cget readonly]
    set variable    [my cget variable]
    if { $readonly } {
      set label View
    } else {
      set label Edit
      if {![info exists $variable]} {
        set label Create
      } elseif {[set $variable] eq {}} {
        set label Create
      }
    }
    ::ttk::button $p -style [my Style button small] -text $label -command [namespace code {my popup}]
    
    xylist_window $p $field $array $readonly"

  }

  ###
  # topic: 672f27a0-ed4e-30ce-73ff-f75eac34e20d
  ###
  method popup {} {
    
  }
}

