###
# This file defines "dynamic" tk widgets. These widgets
# are intended to be produced on the fly, and configured from
# a standard configuration dict.
###

::namespace eval ::taotk {}

::namespace eval ::taotk::dynamic {}

::namespace eval ::taotk::meta {}

###
# topic: 1f170cae-fa12-65e9-8af1-1695a001720b
###
proc ::taotk::dynamic_widget {tkpath field varname args} {
  set config [::taotk::option_inferences $field {*}$args]
  set widget_class [::taotk::meta::widget_select $config]
  set obj [$widget_class create new $tkpath $field $varname {*}$config]
  $obj tkalias $tkpath
}

###
# topic: b696419e-ea1c-4e65-13a3-85b957f7725e
###
proc ::taotk::meta::widget_select info {
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
  if {[info command ::taotk::dynamic::$widget] ne {} } {
    return ::taotk::dynamic::$widget
  }
  if { $widget ne {} } {
    switch $widget {
      bool - boolean - u1 {
        return ::taotk::dynamic::boolean
      }
      generic - string - text {
        return ::taotk::dynamic::entry
      }
      vector {
        return ::taotk::dynamic::vector
      }
      longtext -
      blob -
      script {
        return ::taotk::dynamic::script
      }
    }
  }
  if {[dict exists $info field]} {
    # Guess based on field name
    set field [dict get $info field]
    
    if {[info command ::taotk::dynamic::$field] ne {} } {
      return ::taotk::dynamic::$field
    }
    ###
    # Look for field specific code
    ###
    switch $field {
      mitl_skillset_2 {
        return ::taotk::dynamic::mitl_skillset
      }
      algorithm {
        return ::taotk::dynamic::behavior
      }
      center {
        return ::taotk::dynamic::location
      }
      note -
      notes {
        return ::taotk::dynamic::script
      }
    }
  }
  if {[dict exists $info values-format]} {
    switch [dict get $info values-format] {
      enum -
      enumerated {
        return ::taotk::dynamic::enumerated        
      }
      list {
        return ::taotk::dynamic::select
      }
    }
  }

  if {[dict exists $info values]} {
    return ::taotk::dynamic::select
  }
  if {[dict exists $info range]} {
    return ::taotk::dynamic::scale
  }

  if {[dict exists $info history]} {
    if {[string is true [dict get $info history]]} {
      return ::taotk::dynamic::::history
    }
  }
  return ::taotk::dynamic::entry
}

###
# topic: 1ba167e2-7e67-4372-c122-f466ce3d90a5
###
proc ::taotk::option_inferences {field args} {
  set info   [::tao::args_to_options {*}$args]
  if {![dict exists $info labels]} {
    dict set result labels 1
  }
  set field [string tolower $field]
  set label {}
  set description {}
  set values {}
  
  set result $info
  if {![dict exists $info units]} {
    dict set result units {}
  }
  foreach mf {desc description comment} {
    if {[dict exists $info $mf]} {
      append description [string trim [dict get $info $mf]]
    }
  }
  if {[dict exists $info label]} {
    set label [dict get $info label]
  }
  if { $label == {} } {
    set label $field
  } else {
    set description "Full Name: $field\n$description"
  }
  if {[dict exists $info values-format]} {
    # Enumerated values were calculated on a prior pass
  } elseif {[dict exists $info values-command]} {
    set script [string map [list %field% $field %config% $info] [dict get $info values-command]]
    set values [eval $script]
    if {[llength $values]} {
      dict set result values $values
      dict set result values-format list
      dict unset result options 
    }
  } elseif {[dict exists $info values]} {
    set values [dict get $info values]
    if {[string is integer [lindex $values 0]] && [expr {[llength $values] % 3}]==0} {
      dict set result values [dict get $info values]
      set evalues {}
      append description "\nValues:"
      foreach {id code comment} [dict get $info values] {
        append description "\n * $id ($code) - $comment"
        lappend evalues $id
      }
      dict set result values-format enum
      dict set result values-list $evalues
    } else {
      if {[llength $values]} {
        dict set result values $values
        dict set result values-format list
      }
    }    
  } elseif {[dict exists $info options]} {
    set values [dict get $info options]
    if {[string is integer [lindex $values 0]] && [expr {[llength $values] % 3}]==0} {
      dict set result values [dict get $info values]
      set evalues {}
      append description "\nValues:"
      foreach {id code comment} [dict get $info values] {
        append description "\n * $id ($code) - $comment"
        lappend evalues $id
      }
      dict set result values-format enum
      dict set result values-list $evalues
    } else {
      if {[llength $values]} {
        dict set result values $values
        dict set result values-format list
      }
    }
  }

  switch {[dictGet $info mode]} {
    dynamic -
    spec -
    specs {
      dict set result mode  dynamic
    }
    default {
      dict set result mode  static
    }
  }
  if {[dict exists $info post_command] && ([dictGet $info command] eq {})} {
    dict set result command [dict get $info post_command]
    dict unset result post_command
  }
  dict set result field $field
  dict set result label $label
  dict set result description $description
  return $result
}

