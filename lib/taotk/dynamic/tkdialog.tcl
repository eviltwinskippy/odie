###
# Widgets that use the output of tk dialog boxes
###

###
# topic: 6707f50b-708f-f82b-49d7-0304da375d84
###
tao::class taotk::dynamic::tkpopup {
  superclass taotk::dynamic::label

  ###
  # topic: afa4c129-2d29-b591-781a-872f39530399
  ###
  method action::revert_to_default {} {
    my variable field
    set value [my <object> cget $field default]
    my ApplySelectedValue $value
  }

  ###
  # topic: 58bb9985-86f3-84e0-a7fd-632976353d30
  ###
  method build_widget window {
    set readonly [my cget readonly]
    if { $readonly } {
      nextto taotk::dynamic::label $window
      return
    }
    set p $window
    my variable field
    my graft colorframe $p
    set varname [my GlobalVariableName]
    set value   [get $varname]
    my graft topframe $window
    ::tk::label $p.widget -textvariable $varname -width 20
    ::ttk::button $p.select -text "Select" -width 0 -style [my Style button small] -command [namespace code {my InvokeChooser}]
    ::ttk::button $p.default -text "Default" -width 0 -style [my Style button small] -command  [namespace code {my action revert_to_default}]
    grid $p.select $p.default $p.widget
    my ApplySelectedValue $value 1

    return $p
  }

  ###
  # topic: b336f268-f3d8-ce38-7248-3311da3d75b0
  ###
  method InvokeChooser {} {
  }
}

###
# topic: a48ce1a7-a4ba-c595-c055-45b3d79ff5bd
###
tao::class taotk::dynamic::color {
  superclass taotk::dynamic::tkpopup

  ###
  # topic: 68df576a-5bdb-f6cd-9bb6-e9b1eb6eaf00
  ###
  method ApplySelectedValue {newvalue {initial 0}} {
    if { $newvalue eq {} } return
    set frame [my organ colorframe]
    $frame.widget configure -bg $newvalue

    next $newvalue $initial
  }

  ###
  # topic: 06f45f52-dd64-8411-e4f7-95c6d84925d3
  ###
  method InvokeChooser {} {
    set varname [my GlobalVariableName]
    set value [get $varname]
    my variable field
    if { $value eq {} } {
      if [catch {my <object> cget $field default} value] {
        set value {}
      }
    }
    if { $value eq {} } {
      set newcolor [tk_chooseColor]
    } else {
      set newcolor [tk_chooseColor -initialcolor $value]
    }
    if {$newcolor == {} } return
    my ApplySelectedValue $newcolor
  }
}

###
# topic: a5dd18b1-4378-4234-df90-347d26fec585
###
tao::class taotk::dynamic::filename {
  superclass taotk::dynamic::tkpopup

  ###
  # topic: 4d2b7388-d7f8-0001-b287-b8f7dee54397
  ###
  method build_widget window {
    set readonly [my cget readonly]
    if { $readonly } {
      nextto taotk::dynamic::label $window
      return
    }
    set p $window
    my variable field
    my graft topframe $p
    set varname [my GlobalVariableName]
    set value   [get $varname]
    if { $value eq {} } {
      set value [my <object> cget $field default]
    }
    ::tk::label $p.widget -textvariable $varname -width 20
    ::ttk::button $p.select -text "Select" -width 0 -style [my Style button small] -command [namespace code {my InvokeChooser}]
    ::ttk::button $p.default -text "Default" -width 0 -style [my Style button small] -command  [namespace code {my action revert_to_default}]
    grid $p.select $p.default $p.widget
    return $p
  }

  ###
  # topic: ec385f8c-0113-066d-3df0-1ebf3b40f539
  ###
  method InvokeChooser mode {
    my variable field
    set info [my get config]
    set ftypes {}
    set types [dictGet $info filetypes]
    if {[llength $types]==1} {
      set types [lindex $types 0]
    }
    foreach {type ext} $types {
      lappend ftypes [list $type $ext]
    }
    lappend ftypes [list {Any File} *.*]
  
    if { $ftypes ne {} } {
      set filearg [list -filetypes $ftypes]
    } else {
      set filearg {}
    }
    set varname [my GlobalVariableName]
    set value   [get $varname]
    
    if {$value eq {} } {
      set initdir [my stylesheed cget initial-filepath]
      if { $initdir eq {} } {
        set initdir [pwd]
      }
    } else {
      set initdir [file dirname $value]
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
      my ApplySelectedValue $fn
      my stylesheet configure initial-filepath [file dirname $fn]
    }
  }
}

###
# topic: 1ef8a54d-f5be-e5bd-1d25-1b01b664b664
###
tao::class taotk::dynamic::font {
  superclass taotk::dynamic::tkpopup

  ###
  # topic: e717f101-bbe1-dd04-77aa-dd014faf6243
  ###
  method ApplySelectedValue {newvalue {initial 0}} {
    set topframe [my organ topframe]
    if [catch {
      $topframe.widget configure -font $newvalue -text $newvalue    
    } err] {
      my variable field
      set newvalue [my <object> cget $field default]
      $topframe.widget configure -font $newvalue -text $newvalue    
    }
    tk fontchooser hide
    next $newvalue $initial
  }

  ###
  # topic: b198e22e-3d07-1d31-cfee-7b4a59525a49
  ###
  method InvokeChooser {} {
    set varname [my GlobalVariableName]
    tk fontchooser configure -font [set $varname] -command [namespace code {my ApplySelectedValue}]
    tk fontchooser show
  }
}

