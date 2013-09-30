###
# Tools to build Tcl/Tk based GUIs
###

::namespace eval ::llama {}

::namespace eval ::llama_widget {}

###
# topic: 97a40893-e890-1ad9-18c7-512ee6cca812
###
proc ::llama::makeWidget {f field value array readonly info} {
  global tnerowcount
  incr tnerowcount
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

  set l $f.$field#l
  set u $f.$field#u
  set p $f.$field
  if {[winfo exists $l]} return

  ttk::label $l -text $label -style [widget_style label]
  
  if {[dict exists $info values-command]} {
    dict set info values [eval [dict get $info values-command]]    
  }
  if {[dict exists $info values]} {
    append description "Values:\n"
    foreach {id code comment} [dict get $info values] {
      dict append info description " * $id - $comment\n"
    }
  }
  set_balloon $l $description

  if { [dict exists $info units] } { 
    ttk::label $u -style [widget_style label] -text [dict get $info units]
  } else {
    ttk::label $u -style [widget_style label] -text {}
  }
  ::llama_widget::[widget_select $field $info] $p $field $value $array $readonly $info
  #if { $u != {} } {
  grid $l $p $u -sticky news
  grid configure $u -sticky news
  #} else {
  #  grid $l $p
  #}
  grid configure $l -sticky news
  grid configure $p -padx 2 -sticky ew
  grid columnconfigure $f 1 -minsize 200
}

###
# topic: bf614e85-7238-1fe9-bd55-99f5a3ed6f7f
# title: Resets the greenbar styling
###
proc ::llama::widget_newpage {} {
  global tnerowcount
  set tnerowcount 0
}

###
# topic: c0618906-50a8-3be7-7bc2-0d7b1bfac5c1
# title: Returns the widget style for the row
###
proc ::llama::widget_style {prim {row {}}} {
  if { $row eq {} } {
    set row $::tnerowcount
  }
  return TneGreenBar[expr {$row % 2}].T[string totitle $prim]
}

###
# topic: f0fb7d69-eafe-c00b-b883-684fdf4ead22
# description: Special widget for algorithms
###
proc ::llama_widget::action {p field value array readonly info} {
  if { $readonly } {
    ::ttk::label $p -style [::llama::widget_style label] -textvariable ${array}($field)
  } else {
    ::ttk::frame $p
    ::ttk::entry $p.e -style [::llama::widget_style entry] -textvariable ${array}($field)
    set script [dictGet $info post_command]
    if { $script ne {} } {
      ttk::button $p.b -text "Apply" -command $script
    }
    grid {*}[winfo children $p]
  }
}

###
# topic: 9c1123b7-871e-dc89-70a0-496eaed8d0a6
###
proc ::llama_widget::boolean {p field value array readonly info} {
  if { $readonly } {
    ::ttk::label $p -style [::llama::widget_style label] -textvariable ${array}($field)
  } else {
    ::ttk::checkbutton $p -style [::llama::widget_style checkbutton] -variable ${array}($field)
    set post_command {}
    dict with info {
      if { $post_command ne {} } {
        $p configure -command "{*}$post_command $field \$${array}($field)"
      }
    }
  }
}

###
# topic: b54ae071-29ea-054e-3acf-3862f2453b29
###
proc ::llama_widget::color {p field value array readonly info} {
  frame $p -bg $value
  
  ttk::button $p.select -style Tne.TButton -textvariable ${array}($field) -width 0 -command [list [namespace current]::color_select $p $field $value $array $info]
  set default {}
  set default_command {}
  dict with info {
    if { $default_command ne {} } {
      set default [eval $default_command]
    }
  }
  if { $default ne {} } {
    ttk::button $p.default -style TneSmall.TButton -text Default -width 0 -command [list [namespace current]::color_set $p $field $default $array $info]
    grid $p.select $p.default
  } else {
    grid $.select
  }

}

###
# topic: 28b2d2fa-05f1-8c4a-7f8a-427c067f48c0
###
proc ::llama_widget::color_select {p field value array info} {
  set newcolor [tk_chooseColor -initialcolor $value]
  if {$newcolor == {} } return
  ::llama_widget::color_set $p $field $newcolor $array $info
}

###
# topic: b246ae64-a91e-a715-de29-da76e7280e10
###
proc ::llama_widget::color_set {p field newvalue array info} {
  if { $newvalue eq {} } return
  set ${array}($field) $newvalue
  set post_command {}
  $p configure -bg $newvalue
  dict with info {
    if {$post_command ne {}} {
      eval $post_command $field $newvalue
    }
  }
}

###
# topic: 9358af0d-5361-7faf-5506-57e57c1cd8de
###
proc ::llama_widget::entry {p field newvalue array readonly info} {
  if { $readonly } {
    ::ttk::label $p -style [::llama::widget_style label] -textvariable ${array}($field)    
  } else {
    ::ttk::entry $p -style [::llama::widget_style entry] -textvariable ${array}($field)
  } 
}

###
# topic: 0d1ae390-61fa-05ca-3c80-4db14da648bc
###
proc ::llama_widget::enumerated {p field value array readonly info} {
  set ${array}(text.$field) $value
  foreach {id code comment} [dict get $info values] {
    lappend values "$id - $code"
    if { $value == $id } {
      set ${array}(text.$field) "$id - $code"
    }
  }
  if { $readonly } {
    set ${array}($field) $value
    ::llama_widget::label $p $field $value $array $readonly $info
    return
  }
  ::ttk::combobox $p -textvariable ${array}(text.$field) -width [::llama::comboWidth $values] -state readonly -values $values
  bind $p <<ComboboxSelected>> "[namespace current]::enumerated_widget_decode $array $field"
}

###
# topic: 72966ff2-1cb4-aa27-8ccb-f69ffe24b4be
###
proc ::llama_widget::enumerated_widget_decode {array field} {
  set val [set ${array}(text.$field)]
  set val [lindex $val 0]
  set ${array}($field) $val
}

###
# topic: d7cf2bdf-1980-4dca-49aa-c6f2f3d69252
###
proc ::llama_widget::filename {p field value array readonly info} {
  
  set values [::simconfig::history $field]
  if { $readonly } {
    ::llama_widget::label $p $field $value $array $readonly {}
    return
  }
  set ${array}($field) $value
  ::ttk::frame $p
  ::ttk::combobox $p.drop -textvariable ${array}($field) -values $values  -width 60

  set filetype "findcreate"
  dict with info {}

  switch [lindex $filetype 0] {
    create {
      ::ttk::button $p.select -text "Browse" \
        -command [list ::llama_widget::filename_browse create $field $array $info] \
        -style TneSmall.TButton -width 0
      grid $p.drop $p.select

    }
    default {
      ::ttk::button $p.select -text "Browse" \
        -command [list ::llama_widget::filename_browse browse $field $array $info] \
        -style TneSmall.TButton -width 0
      #::ttk::button $p.create -text "Create" \
      #  -command [list ::llama_widget::filename_browse create $field $array $info] \
      #  -style TneSmall.TButton -width 0
      grid $p.drop $p.select
      #$p.create
    }
  }
}

###
# topic: 8d1c0559-e4b6-fa3e-0909-3c61d8faa1a4
###
proc ::llama_widget::filename_browse {mode field array info} {
  set filetypes [dictGet $info filetypes]
  lappend filetypes {{Any File} *.*}

  if { $filetypes ne {} } {
    set filearg [list -filetypes $filetypes]
  } else {
    set filearg {}
  }
  #lappend filetypes {Any File} {.*}
  #lappend filetypes {{Any File} *.*}
  #if {[dictGet $info filetypes]} {
  #  set filetypes [dict get $info filetypes]
  #  lappend filetypes {{Any File} *.*}
  #} else {
  #  set filetypes [list {Any File} *.*]
  #}

  if {[get ${array}($field)] eq {} } {
    set initdir [::simconfig::get readi_initdir]
    if { $initdir eq {} } {
      set initdir [pwd]
    }
  } else {
    set initdir [file dirname [get ${array}($field)]]
  }
  if {[dict exists $info title]} {
    set title [dict get $info title]
  } else {
    set title "Select a file for $field"
  }
  if { $mode eq "create" } {
    set px tk_getSaveFile
  } else {
    set px tk_getOpenFile
  }
  set fn [$px {*}$filearg -parent . -title $title -initialdir $initdir]
  if { $fn ne {} } {
    set ${array}($field) $fn
    set ::simconfig(readi_initdir) [file dirname $fn]
  }
}

###
# topic: 005ef60e-3f34-8525-d351-e441935efcae
###
proc ::llama_widget::font {p field value array readonly info} {
  set default {}
  set default_command {}
  dict with info {
    if { $default_command ne {} } {
      set default [eval $default_command]
      dict set info default $default
    }
  }
  if {$value eq {}} {
    set value $default
  }
  if { $readonly } {
    ::llama_widget::label $p $field $value $array $readonly {}
    return
  }
  #set ${array}($field) $value
  ::ttk::frame $p
  ::tk::label $p.font -textvariable ${array}($field) -font $value -width 20
  ::ttk::button $p.select -text "Choose" -width 0 -style TneSmall.TButton -command [list ::llama_widget::font_select $p $field $array $info $value]
  ::ttk::button $p.default -text "Dflt" -width 0 -style TneSmall.TButton -command [list ::llama_widget::font_finish $p $field $array $info $default]
  grid $p.select $p.default $p.font
}

###
# topic: 3ec6639c-c925-0964-1432-52491f789638
###
proc ::llama_widget::font_finish {p field array info newvalue} {
  #catch {
  #set post_command {}
  #dict with info {
  #  if { $post_command ne {} } {
  #    eval $post_command $field $newvalue
  #  }
  #}
  #} err
  #puts $err
  if [catch {
    $p.font configure -font $newvalue -text $newvalue    
  } err] {
    set newvalue [dict get $info default]
    $p.font configure -font $newvalue -text $newvalue    
  }
  set ${array}($field) $newvalue
  tk fontchooser hide
}

###
# topic: 25d104c6-66be-dff5-4210-2a88ff9123a6
###
proc ::llama_widget::font_select {p field array info value} {
  tk fontchooser configure -font $value -command [list [namespace current]::font_finish $p $field $array $info]
  tk fontchooser show
}

###
# topic: dba677fa-8d81-ed40-b10e-9cd8b4752c78
###
proc ::llama_widget::history {p field value array readonly info} {
  set ${array}(text.$field) $value
  set values [::simconfig::history $field]
  ::ttk::frame $p 
  ::ttk::combobox $p.e -textvariable ${array}($field) -width [::llama::comboWidth $values] -values $values
  set script [dictGet $info post_command]
  if { $script ne {} } {
    ttk::button $p.b -text "Apply" -command $script
  }
  grid {*}[winfo children $p]
}

###
# topic: 17fe57e1-b765-ef38-a397-f45d389e7634
###
proc ::llama_widget::label {p field value array readonly info} {
  ::ttk::label $p -style [::llama::widget_style label] -textvariable ${array}($field)
}

###
# topic: 8104b89b-df81-5569-0811-c7bb553fc5cf
###
proc ::llama_widget::object_shape {p field value array readonly info} {
  set values [string tolower [::shapes::shapelist]]
  ::llama_widget::select $p $field [string tolower $value] $array $readonly [list values $values]
}

###
# topic: 707ecc6d-f07c-a684-71b5-2c25949f49bf
###
proc ::llama_widget::object_size {p field value array readonly info} {
  if { $readonly } {
    ::ttk::label $p -style [::llama::widget_style label] -text "[join [lrange $value 0 2] x] [lindex $value end]"
    return
  }
  ::ttk::frame $p
  set idx -1
  set row {}
  foreach item {length width height} {
    set ${array}($field.$item) [lindex $value [incr idx]]     
    ::ttk::label $p.$item#l -text "$item:" -width 0
    if { $readonly } {
      ::ttk::label $p.$item -textvariable ${array}($field.$item) -width 6
    } else {
      ::ttk::entry $p.$item -textvariable ${array}($field.$item) -width 6
    }
    lappend row $p.$item#l  $p.$item
  }
  if { [llength $value] == 4 } {
    set ${array}($field.units)  [lindex $value end]
  } else {
    set ${array}($field.units) mm
  }
  ttk::combobox $p.unit -textvariable  ${array}($field.units) -values [::units::list]  -width [::llama::comboWidth [::units::list]]
  lappend row $p.unit
  grid {*}$row
  set ${array}(script.$field)  "[namespace current]::object_size_set $array $field"
}

###
# topic: 4f5d958f-a8ae-8ca7-4bd4-4e8082b5880b
# description: Intended
###
proc ::llama_widget::object_size_set {array field} {
  if {![string is double -strict [set ${array}($field.length)]]} {
    error "Length is missing"
  }
  set ${array}($field) [list [set ${array}($field.length)] [set ${array}($field.width)] [set ${array}($field.height)] [set ${array}($field.units)]]
  #array unset ${array} $field.*
  #unset ${array}(script.$field)
}

###
# topic: 2ce3e658-6c52-e45d-24a3-c66641a581a6
###
proc ::llama_widget::pathname {p field value array readonly info} {
  
  set values [::simconfig::history $field]
  if { $readonly } {
    ::llama_widget::label $p $field $value $array $readonly {}
    return
  }
  set ${array}($field) $value
  ::ttk::frame $p
  ::ttk::combobox $p.drop -textvariable ${array}($field) -values $values  -width 60

  set filetype "findcreate"
  dict with info {}

  switch [lindex $filetype 0] {
    create {
      ::ttk::button $p.select -text "Browse" \
        -command [list ::llama_widget::pathname_browse create $field $array $info] \
        -style TneSmall.TButton -width 0
      grid $p.drop $p.select

    }
    default {
      ::ttk::button $p.select -text "Browse" \
        -command [list ::llama_widget::pathname_browse browse $field $array $info] \
        -style TneSmall.TButton -width 0
      ::ttk::button $p.zip -text "Zip" \
        -command [list ::llama_widget::pathname_browse zip $field $array $info] \
        -style TneSmall.TButton -width 0 
      grid $p.drop $p.select $p.zip
      #$p.create
    }
  }
}

###
# topic: cc3d3319-581c-3c72-35aa-18a4208399d0
###
proc ::llama_widget::pathname_browse {mode field array info} {
  set value  [get ${array}($field)]
  if {![file exists $value]} {
    set value {}
  }
  if {$value eq {} } {
    set initdir [::simconfig::get readi_initdir]
    if { $initdir eq {} } {
      set initdir [pwd]
    }
  } else {
    if ![file isdirectory $value] {
      set initdir [file dirname $value]
    } else {
      set initdir $value
    }
  }
  if {[dict exists $info title]} {
    set title [dict get $info title]
  } else {
    set title "Select a path for $field"
  }
  switch $mode {
    "create" {
      set px {tk_chooseDirectory -mustexist 0}
    }
    zip {
      if {[dict exists $info filetypes]} {
        set filetypes [dict get $info filetypes]
      } else {
        set filetypes {{{Zip Files} *.zip} {{Kit Files} *.kit}}
      }
      set px [list tk_getOpenFile -filetypes {*}[list $filetypes]]
    }
    default {
      set px {tk_chooseDirectory -mustexist 1}
    }
  }
  set fn [{*}$px -parent . -title $title -initialdir $initdir]
  if { $fn ne {} } {
    set ${array}($field) $fn
    set ::simconfig(readi_initdir) [file dirname $fn]
    if [dict exists $info post_command] {
      {*}[dict get $info post_command] $fn
    }
  }
}

###
# topic: c8d306a8-9358-6994-fdef-0c382d49b523
###
proc ::llama_widget::scale {p field value array readonly info} {
  set ${array}(text.$field) $value
  if { $readonly } {
    set ${array}($field) $value
    ::llama_widget::label $p $field $value $array $readonly $info
    return
  }
  set range [dictGet $info range]
  set from [lindex $range 0]
  set to   [lindex $range 1]
  if { $to eq {} } {
    set to 1.0
  }
  if { $from eq {} } {
    set from 0.0
  }
  set storage [dictGet $info storage]
  if { $storage in {integer int} } {
    set command [list ::llama_widget::scale_round $array $field]
  } else {
    set command [list ::llama_widget::scale_set $array $field]

  }
  ttk::frame $p
  ::ttk::scale $p.scale -variable ${array}(text.$field) -length 300 -orient horizontal -from $from -to $to -command $command
  ::ttk::entry $p.e -textvariable ${array}($field) -width 6
  grid $p.e $p.scale
  eval $command $value
}

###
# topic: d7478f6f-3ee7-86de-10a0-31849b772d30
###
proc ::llama_widget::scale_round {array field value} {
  set ${array}($field) [expr round($value)]
  set ${array}(text.$field) [expr round($value)]
}

###
# topic: 4bb2500e-40f0-f4c4-c7ef-95f82cd89ef8
###
proc ::llama_widget::scale_set {array field value} {
  set ${array}($field) $value
  set ${array}(text.$field) $value
}

###
# topic: 15899baa-16b0-747a-c9ea-7d881cfd4f9b
###
proc ::llama_widget::script {p field value array readonly info} {
    if { $readonly } {
      set label View
    } else {
      set label Edit
      if {![info exists ${array}($field)]} {
        set label Create
      } elseif {[set ${array}($field)] eq {}} {
        set label Create
      }
    }
    ::ttk::button $p -style TneSmall.TButton -text $label -command "[namespace current]::script_window $p $field $array $readonly"
 }

###
# topic: 12a0e4ef-27cf-5dc9-17b5-5223c3c2bb32
###
proc ::llama_widget::script_window {p field array readonly} {
  set w [winfo toplevel $p].table
  destroy $w
  floatingWindow $w

  wm title $w "Editing $field"

  ttk::label $w.l -text "Editing $field"
  text $w.t -yscrollcommand "$w.vsb set" -xscrollcommand "$w.hsb set" -width 70 -wrap none
  ttk::scrollbar $w.vsb -orient vertical -command "$w.t yview"
  ttk::scrollbar $w.hsb -orient horizontal -command "$w.t xview"

  set value {}
  if {[info exists ${array}($field)]} {
    set value [set ${array}($field)]
  }
  $w.t insert end $value
  ttk::frame $w.b
  
  ttk::button $w.b.save -text "Save" -command "::llama_widget::script_windowsave  $p $field $array"
  ttk::button $w.b.close -text "Close" -command "destroy $w"
  if {$readonly} {
    grid $w.b.close -sticky e
  } else {
    grid $w.b.save $w.b.close -sticky ew
  }

  pack $w.l -side top -fill x
  pack $w.b -side bottom -fill x
  pack $w.hsb -side bottom -fill x -padx [list 0 [winfo reqwidth $w.vsb]]
  pack $w.t -side left -fill both -expand 1
  pack $w.vsb -side left -fill y


}

###
# topic: 82735f90-b809-70f0-0267-d447536806b4
###
proc ::llama_widget::script_windowsave {p field array} {
  set w [winfo toplevel $p].table
  set value [string trim [$w.t get 0.0 end]]
  set ${array}($field) $value
}

###
# topic: 17dcd5cf-46c6-ec00-e8dd-0b4e1f7359f6
###
proc ::llama_widget::select {p field value array readonly info} {
  if { $readonly } {
    ::llama_widget::label $p $field $value $array $readonly {}
    return
  }
  set values {}
  if {[dict exists $info values]} {
    set values [dict get $info values]
  }
  if {[dict exists $info options]} {
    set values [dict get $info options]
  }
  if {[dict exists $info options_command]} {
    set values [eval [dict get $info options_command]]
  }
  set ${array}($field) $value
  ::ttk::combobox $p -textvariable ${array}($field) -state readonly -values $values  -width [::llama::comboWidth $values]
  if {[dict exists $info select_command]} {
    bind $p <<ComboboxSelected>> "[dict get $info select_command] $field $array"
  }
}

###
# topic: 6c7756a6-5bfc-fc6b-0d7a-ec3d62675fef
###
proc ::llama_widget::xtype {p field value array readonly info} {
  set filter true
  if {[dict exists $info filter]} {
    set filter  [dict get $info filter]
  }
  set ${array}($field) $value
  if {[catch {simtype get $value fullname} fullname]} {
    set fullname $value
  } else {
    append fullname " ($value)"
  }
  set ${array}($field.text) $fullname

  if { $readonly } {
    ::llama_widget::label $p $field $fullname $array $readonly $info
    return
  }
  ::ttk::frame $p
  ::ttk::label $p.full -textvariable ${array}($field.text)
  grid $p.full -columnspan 4
  ::ttk::label $p.l -textvariable ${array}($field)
  ::ttk::button $p.select -style TneSmall.TButton -text "Select" -command [list [namespace current]::xtype_pick $field $array $filter [string is true [dictGet $info only_leaf]]]
  ::ttk::button $p.goto -style TneSmall.TButton -text "Goto" -command [list [namespace current]::xtype_goto $field $array $filter]
  ::ttk::button $p.clear -style TneSmall.TButton -text "X" -command [list [namespace current]::xtype_null $field $array $filter]
  set_balloon $p.clear {Set this value to null}
  grid $p.l $p.select $p.goto $p.clear
}

###
# topic: 798de3d5-b531-8b9a-cea7-944fcfd326d3
###
proc ::llama_widget::xtype_goto {field array filter} {
  set type [if_null [get ${array}($field)] 0]
  if {$type} {
    ::typeditor::start $type
  }
}

###
# topic: fc635280-fd75-731d-a39b-6a068920ee29
###
proc ::llama_widget::xtype_null {field array filter} {
  set ${array}($field) {}
  set ${array}($field.text) {NULL}
}

###
# topic: dd7b8e91-897c-ee92-c719-9b15e9a4ead0
###
proc ::llama_widget::xtype_pick {field array filter {only_leaf 0}} {
  set newtype [::tree::typeSelectPopup {Select a type} $filter [list only_leaf $only_leaf]]
  if { $newtype == {} } return
  set ${array}($field) $newtype
  set ${array}($field.text) [db one {select fullname from xtype where typeid=$newtype}]
}

###
# topic: 50ac2780-9005-fb9e-78a5-8407ea4545e1
###
proc ::llama_widget::xylist {p field value array readonly info} {
    if { $readonly } {
      set label View
    } else {
      set label Edit
      if {![info exists ${array}($field)]} {
        set label Create
      } elseif {[set ${array}($field)] eq {}} {
        set label Create
      }
    }
    ::ttk::button $p -style TneSmall.TButton -text $label -command "[namespace current]::xylist_window $p $field $array $readonly"
 }

###
# topic: 977ce8da-5ed6-a2a4-7346-0fd955af6129
###
proc ::llama_widget::xylist_window {p field array readonly} {
  set w [winfo toplevel $p].table
  destroy $w
  floatingWindow $w
  ttk::label $w.l -text "Editing $field"
  wm title $w "Editing $field"
  text $w.t -yscrollcommand "$w.sb set" -width 20
  ttk::scrollbar $w.sb -orient vertical -command "$w.t yview"
  set value {}
  if {[info exists ${array}($field)]} {
    set value [set ${array}($field)]
  }
  foreach xy $value {
    $w.t insert end "$xy\n"
  }
  ttk::frame $w.b
  
  ttk::button $w.b.save -text "Save" -command "::llama_widget::xylist_windowsave  $p $field $array"
  ttk::button $w.b.close -text "Close" -command "destroy $w"
  if {$readonly} {
    grid $w.b.close
  } else {
    grid $w.b.save $w.b.close
  }
  
  grid $w.t $w.sb -sticky ns
  grid $w.b
}

###
# topic: 5879293d-2f67-af64-6111-1493521e3b19
###
proc ::llama_widget::xylist_windowsave {p field array} {
  set w [winfo toplevel $p].table
  set text [$w.t get 0.0 end]
  set value {}
  foreach xy $text {
    if {[string first , $xy] < 0 } {
      bell
      irmMessageBox -type ok -icon error -message "Format all values as X,Y"
      return
    }
    lappend value $xy
  }
  set ${array}($field) $value
}

