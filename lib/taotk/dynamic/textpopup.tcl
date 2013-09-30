###
# topic: 60fd6343-685b-5705-2b83-17fa7c4d0d06
# description: Widgets that enter data through a popup window
###
tao::class taotk::dynamic::custom {
  superclass taotk::dynamic::label
  

  ###
  # topic: 2dfe7e1e-c443-207f-d499-a870763c789c
  ###
  method build_widget window {
    
  }
}

###
# topic: 2eed6fee-7a62-24f6-314b-88e834e5a4f9
###
tao::class taotk::dynamic::script {
  superclass taotk::dynamic::custom
  

  ###
  # topic: 6172978a-004d-f819-3833-af6655602682
  ###
  method build_widget window {
    set readonly [my cget readonly]
    
    set varname [my GlobalVariableName]
    set value [get $varname]

    if { $readonly } {
      if { $value eq {} } {
        #ttk::label $window.txt -text {} -bg [my stylesheet row_color [my cget row]]
        #grid $window.txt
        return
      }
      set label View
    } else {
      if {$value eq {}} {
        set label Create
      } else {
        set label Edit
      }
    }
    ::ttk::button $window.button -style [my Style button small [my cget row]] -text $label -command [namespace code {my InvokePopup}]
    grid $window.button -sticky news
 }

  ###
  # topic: 6fca40ce-ebce-e03a-d41b-3ead1a595557
  ###
  method InvokePopup {} {
    set w [my organ nativewidget].popup
    destroy $w
    set readonly [my cget readonly]
    my variable field
    odieModalWindow $w [list Editing $field] [winfo toplevel [my organ nativewidget]]
    my graft text $w.t
    ttk::label $w.l -text "Editing $field"
    text $w.t -yscrollcommand "$w.vsb set" -xscrollcommand "$w.hsb set" \
      -width 70 -wrap none -font [::simconfig::get font-editor]
    ttk::scrollbar $w.vsb -orient vertical -command "$w.t yview"
    ttk::scrollbar $w.hsb -orient horizontal -command "$w.t xview"
  
    set value {}
    set varname [my GlobalVariableName]
    set value [get $varname]

    my <text> insert end $value
    ttk::frame $w.b
    
    ttk::button $w.b.save -text "Save" -command [namespace code {my Save}]
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
  # topic: a011b740-f55d-fbb2-3651-309937051a2f
  ###
  method Save {} {
    set w [my organ text]
    set value [string trim [my <text> get 0.0 end]]
    set [my GlobalVariableName] $value
  }
}

