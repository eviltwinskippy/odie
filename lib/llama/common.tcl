###
# Common routines needed by all generations of llama
###

::namespace eval ::llama {}

###
# topic: 9fbc7534-0dd6-57b8-1d38-942fa81dbed7
# title: Sizes a combobox to fit widest element
###
proc ::llama::comboWidth values {
  set w 0
  foreach v $values {
    if {[set l [string length $v]] > $w} {
      set w $l
    }
  }
  return $w
}

###
# topic: e0652030-ec13-b32f-95a0-440a4680e7e7
###
proc ::llama::html_select {field info} {

  ###
  # Look for storage specific codes
  ###
  set widget {}
  if {[dict exists $info widget]} {
    set widget [dict get $info widget]
  } else {
    set widget {}
    if {[dict exists $info storage]} {
      set widget [dict get $info storage]
    } else {
      if {[dict exists $info type]} {
        set widget [dict get $info type]
      }
    }
  }
  if {[info proc ::llama_html::$widget] ne {} } {
    return $widget
  }
  if { $widget ne {} } {
    switch $widget {
      bool - boolean - u1 {
        return boolean
      }
      generic - string - text {
        return entry
      }
      longtext -
      blob -
      script {
        return script
      }
    }
  }
  if {[info proc ::llama_widget::$field] ne {} } {
    return $field
  }
  ###
  # Look for field specific code
  ###
  switch $field {
    note -
    notes {
      return script
    }
  }

  if {[dict exists $info options]} {
    return enumerated
  }
  if {[dict exists $info values]} {
    return enumerated
  }
  if {[dict exists $info range]} {
    return scale
  }

  if {[dict exists $info history]} {
    if {[string is true [dict get $info history]]} {
      return history
    }
  }
  return entry
}

###
# topic: adc066bb-6ac7-0f44-fafb-ba8b5262550a
###
proc ::llama::widget_select {field info} {

  ###
  # Look for storage specific codes
  ###
  set widget {}
  if {[dict exists $info widget]} {
    set widget [dict get $info widget]
  } else {
    set widget {}
    if {[dict exists $info storage]} {
      set widget [dict get $info storage]
    } else {
      if {[dict exists $info type]} {
        set widget [dict get $info type]
      }
    }
  }
  if {[info proc ::llama_widget::$widget] ne {} } {
    return $widget
  }
  if { $widget ne {} } {
    switch $widget {
      bool - boolean - u1 {
        return boolean
      }
      generic - string - text {
        return entry
      }
      longtext -
      blob -
      script {
        return script
      }
    }
  }
  if {[info proc ::llama_widget::$field] ne {} } {
    return $field
  }
  ###
  # Look for field specific code
  ###
  switch $field {
    mitl_skillset_2 {
      return mitl_skillset
    }
    algorithm {
      return behavior
    }
    center {
      return location
    }
    note -
    notes {
      return script
    }
  }

  if {[dict exists $info values]} {
    return enumerated
  }
  if {[dict exists $info range]} {
    return scale
  }

  if {[dict exists $info history]} {
    if {[string is true [dict get $info history]]} {
      return history
    }
  }
  return entry
}

