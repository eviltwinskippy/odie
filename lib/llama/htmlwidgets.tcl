###
# Tools to build Tcl/Tk based GUIs
###

::namespace eval ::llama {}

::namespace eval ::llama_html {}

###
# topic: f27e043c-9c4a-299e-e5af-18c6b4782d65
# title: Resets the greenbar styling
###
proc ::llama::html_newpage {} {
  global tnerowcount
  set tnerowcount 0
}

###
# topic: f06f6551-2be1-4a96-46d2-3047aaf1accf
# title: Returns the widget style for the row
###
proc ::llama::html_style {prim {row {}}} {
  if { $row eq {} } {
    set row $::tnerowcount
  }
  set color #FFFFFF
  if { [expr [incr row] % 2] == 1 } { 
    set color #c8c8c8 
  }
  return "bgcolor=$color"
}

###
# topic: 2f7cce67-46f8-f977-fb53-e255630072b1
###
proc ::llama::html_widget {field value readonly info} {
  set result {}

  if {[dict exists $info values-command]} {
    dict set info values [eval [dict get $info values-command]]    
  }
  return [::llama_html::[html_select $field $info] $field $value $readonly $info]
}

###
# topic: 792590c5-91bd-c461-b444-a97f2d33919b
###
proc ::llama::makeHtmlWidget {field value readonly info} {
  global tnerowcount
  incr tnerowcount
  set result {}
  set label {}
  set description {}
  #if {[dictGet $info hidden]==1} {
  #  return
  #}
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
  set rowstyle [html_style label]
  append result "<th $rowstyle>$label</th>"
  
  if {[dict exists $info values-command]} {
    dict set info values [eval [dict get $info values-command]]    
  }
  #if {[dict exists $info values]} {
  #  append description "Values:\n"
  #  foreach {id code comment} [dict get $info values] {
  #    dict append info description " * $id - $comment\n"
  #  }
  #}
  #set_balloon $l $description
  append result "<TD>"
  append result [::llama_html::[html_select $field $info] $field $value $readonly $info]
  append result "</TD>"
  append result "<td $rowstyle>[dictGet $info units]</td>"
  return "<tr>$result</tr>"
}

###
# topic: 0a46a79d-667a-7e5f-3bf7-13796d42210b
###
proc ::llama_html::boolean {field value readonly info} {
  set trueopt yes
  set falseopt no
  foreach option [dictGet $info options] {
    if [string is true -strict $option] {
      set trueopt $option
    }
    if [string is false -strict $option] {
      set falseopt $option
    }
  }
  if { $readonly } {
    if {[string is true -strict $value]} {
      set value true
    } elseif {[string is false -strict $value]} {
      set value false
    } else {
      set value {}
    }
    return [entry $field $value 1 $info]
  } else {

    append result "<input type=radio name=$field value=\"$trueopt\""
    if [string is true -strict $value] {
        append result " checked "
    }
    append result ">$trueopt"
    append result "<input type=radio name=$field value=\"$falseopt\""
    if [string is false $value] {
        append result " checked "
    }
    append result ">$falseopt"
    return $result 
  }
}

###
# topic: 155c75b4-75c4-c866-a6f5-3d90d6de7783
###
proc ::llama_html::entry {field value readonly info} {
  if { $readonly } {
    return "<input type=hidden name=$field value=$value>$value"
  } else {
    return "<input name=\"$field\" value=\"$value\" size=[html_width $info]>"
  }
}

###
# topic: fd92ab62-e1f2-a7ea-9104-89138b3fe900
###
proc ::llama_html::enumerated {field value readonly info} {
  if { $readonly } {
    return [entry $field $value 1 $info]
  }
  set result {}
  append result "<input name=$field value=\"$value\">"
  append result "<SELECT name=${field}_dropdown [selectjs $field]>"
  append result "<option value=\"\"></option>\n"
  foreach {id code comment} [dictGet $info values] {
    append result "\n<option value=\"$id\" "
    if { $id == $value } { 
      append result " selected "
    }
    append result ">$id - $code</option>"
  }
  foreach {option} [dictGet $info options] {
    append result "\n<option value=\"$option\" "
    if { $option == $value } { 
      append result " selected "
    }
    append result ">$option</option>"
  }
  append result "</select>"
  return $result   
}

###
# topic: 0c47fd51-9977-3cb7-d811-96669b731e75
# title: Resets the greenbar styling
###
proc ::llama_html::html_width info {
  foreach field {
    width length size
  } {
    set size [dictGet $info $field]
    if { $size ne {} } {
      return $size
    }
  }
  return 20
}

###
# topic: 30569941-3e23-cc0b-471d-a66ead5f1941
###
proc ::llama_html::radio {field value readonly info} {
  foreach option [dictGet $info options] {
    append result "<input type=radio name=$field value=\"$option\""
    if {$value eq $option} {
        append result " checked "
    }
    append result ">$option"

  }
  return $result
}

###
# topic: 40844c1e-7355-f9ad-1a3d-9f1aad26ab03
###
proc ::llama_html::selectjs element {
  return "onChange=\"this.form.${element}.value=this.options\[this.options.selectedIndex\].value\""
}

