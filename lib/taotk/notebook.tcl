###
# topic: 2ab2c4ec-bbb2-d563-c3df-14880408221b
# title: An ODIE standard notebook megawidget
# description:
#    The [class taotk::notebook] class defines a megawidget
#    by which on master object controls one or more objects
#    decended from [class taotk::notetab]. This class defines
#    a bare minimum of notebook/notetab interactions, it is intended for
#    the user to add his/her own that are application specific.
###
tao::class taotk::notebook {
  superclass taotk::meta::widget

  signal resize {
    follows build_content
    action {my action resize}
  }

  ###
  # Organs that are grafted into our layers
  ###
  property shared_organs {
    notebook buttonframe infoframe stylesheet
  }
  
  variable tab_prior {}

  option readonly {
    widget boolean
    default 0
  }

  ###
  # topic: 30840ad8-0a33-0658-b734-82a006a711b6
  # description: Routine to run when the user changes tabs
  ###
  method action::notebook_select {} {
    my variable tab_prior
    set nbtab [my notebook select]
    if { $nbtab eq $tab_prior } return
    if { $tab_prior ne {} } {
      $tab_prior action tabunselect
    }
    if { $nbtab ne {} } {
      $nbtab action tabselect
    }
    set tab_prior $nbtab
  }

  ###
  # topic: f446c1ff-9741-791c-700b-e95382e87d6a
  ###
  method action::save {
    my tab_active build_content
  }

  ###
  # topic: c733b28e-d454-6dab-bb28-eec5b2b72248
  ###
  method build_widget window {
    my graft stylesheet [my cget stylesheet]
    my graft topframe $window
    set inFrame $window

    ::ttk::frame $inFrame.buttons    
    ::ttk::frame $inFrame.info
    ::ttk::notebook $inFrame.content

    my graft buttonframe  $inFrame.buttons
    my graft infoframe    $inFrame.info
    my graft notebook     $inFrame.notebook
    
    bind $inFrame.content <<NotebookTabChanged>> [namespace code {my action notebook_select}]

    pack $inFrame.buttons -side bottom  -fill x     
    pack $inFrame.info -side top -fill x
    pack $inFrame.content -side left -fill both -expand 1
  }

  ###
  # topic: 905fe83f-0f02-5540-66b5-b81da25fed31
  ###
  method clear_content {} {
    foreach organ {notebook buttonframe infoframe} {
      set w [my organ $organ]
      if {[winfo exists $w]} {
        destroy {*}[winfo children $w]
      }
    }
  }

  ###
  # topic: e6625c84-0a19-7b2e-cb0d-d6864ff87ef4
  ###
  method readonly {} {
    my variable readonly
    if {![info exists readonly]} {
      return 0
    }
    return [string is true $readonly]
  }

  ###
  # topic: b93a09dc-21bd-8bb3-d613-921d32b8c1bb
  ###
  method tab_active args {
    set obj [my notebook select]
    if { $obj != {} } {
      $obj {*}$args
    }
  }

  ###
  # topic: db511187-ca9a-b1ac-e138-5a72327c8fa8
  ###
  method tab_active_debug args {
    set obj [my notebook select]
    if { $obj != {} } {
      $obj {*}$args
    }
  }

  ###
  # topic: 5d2eb3b6-e221-736e-5d11-c5c759dcb60d
  ###
  method tab_add {name confinfo} {
    if [catch {
    set title $name
    set command {}
    set class {}
    dict set confinfo name $name
    dict with confinfo {}
    set nb [my organ notebook]

    set f $nb.$name
    dict with confinfo {}
    set shared {}
    dict set shared parent [self]
    foreach organ [my property shared_organs] {
      set obj [my organ $organ]
      if { $obj ne {} } {
        dict set shared $organ $obj
      }
    }
    if { $class eq {} } {
      set class taotk::notetab.frame
    }
    if {![$class tab_init [self] $confinfo]} continue
    $class $f $shared {*}$confinfo
    $nb add $f -text $title
    } err] {
      if { $err ne {} } {
        puts ***
        puts [list [self] error creating tab $name $confinfo]
        puts $err
        puts $::errorInfo
      }
      return {}
    }
    return $f
  }
}

