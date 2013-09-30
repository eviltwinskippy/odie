###
# topic: 6aecca05-3ec1-31b9-b987-e9af87ee7a4a
# description: An IRM standard selector megawidget
###
tao::class taotk::selector {
  superclass taotk::toplevel
  

  option array {}
  option field {}

  ###
  # topic: cdfbbffb-3bee-4310-696d-a2db5b5739c5
  ###
  method build_content {} {
    my variable matrix
    set f [my organ contentframe]
    destroy {*}[winfo children $f]

    set current [my values_current]    
    set array [my varname matrix]
    set manditory [my values_manditory]
    set row 0
    foreach {name comment} [my values_all] {
      if { $name in $current } {
        set matrix($name) 1
      } else {
        set matrix($name) 0
      }
      set style TneGreenBar[expr {[incr row] % 2}]
      ttk::checkbutton $f.skill$row -style $style.TCheckbutton \
        -variable ${array}($name) \
        -command [list [self] selection_toggle $name]
      if {[dict exists $manditory $name]} {
        $f.skill$row state disabled
      }        
  
      ttk::label $f.skill$row#l -style $style.TLabel -width 20 -text $name 
      ttk::label $f.skill$row#desc -style $style.TLabel -text $comment -wraplength $::crewedit::wraplength
      grid $f.skill$row $f.skill$row#l $f.skill$row#desc -sticky nsew
    }
    
  }

  ###
  # topic: c724b9d8-5fc3-81c9-4d96-d3ea5945395d
  ###
  method check_required_args {} {
    if { [my cget array] eq {} } {
      error "Destination array not given"
    }
    if {[my cget field] eq {} } {
      error "Destination field not given"
    }
  }

  ###
  # topic: 84fc92d3-4235-ae30-4f20-47eee5f263c9
  ###
  method selection_toggle name {
    if {[string is false $matrix($name)]} {
      logicset remove current $name
    } else {
      logicset add current $name
    }
    set ::[my cget array]([my cget field]) [join $current ,]
  }

  ###
  # topic: d7c6f245-4ae9-5ba2-19e6-a61295ee163d
  ###
  method values_all {} {
    return {}
  }

  ###
  # topic: f7cccda5-62f1-dd44-5a9a-e64f69b1f926
  ###
  method values_current {} {
    set array ::[my cget array]
    set raw [get ${array}([my cget field])]
    set current [string map {, { } / { } : { } + { }} [string tolower $raw]]
    foreach {var val} [my values_manditory] {
      if {[string is false $var]} {
        logicset remove current $var
      } else {
        logicset add current $var
      }
    }
    return $current
  }

  ###
  # topic: b7991d2e-e236-86b4-2c40-ae4c4c026e66
  ###
  method values_manditory {} {
    return {}
  }
}

###
# topic: 19315326-9843-abf7-1efa-84e75445e757
# description: An IRM standard selector megawidget
###
tao::class taotk::selector.test {
  superclass taotk::selector
  

  ###
  # topic: 320cab74-d60d-afbd-b3a0-c993854bc8d2
  ###
  method values_all {} {
    return {
      foo {The frroodiest}
      bar {The best bar none}
      baz {The bazzt}
      bang {The banginest}
    }
  }
}

