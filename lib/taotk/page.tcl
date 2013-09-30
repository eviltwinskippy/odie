###
# A page is a cluster of odie objects presented in one view
###

::namespace eval ::taotk::meta {}

::namespace eval ::taotk::template {}

###
# topic: 4ef02913-d45e-6ba1-d7ad-9ffda2d214d5
###
tao::class taotk::meta::page {
  ###
  # topic: e8e2ce42-f4e6-4c9f-433b-04ca38f82aad
  ###
  method Option_Filter input {
    set result {}
    set optdict [my metadata]
    #foreach {var val} $input {
    #  if {[string range $var 0 6]=="script."} {
    #    if {[catch {eval $val} newvalue]} continue
    #    dict set result [string range $var 7 end] $newvalue
    #  }
    #}
    foreach {var val} $input {
      if {[dict exists $result $var]} continue
      if {![dict exist $optdict $var]} continue
      dict set result $var $val
    }
    return $result
  }
}

###
# topic: 5f47812b-8dd0-5cae-303a-dce509416053
###
tao::class taotk::meta::page.options {
  superclass taotk::meta::page
  option object {
    class organ
    widget label
    description {The object we are representing}
  }
  variable tabfilter {}

  ###
  # topic: 386183dc-eabe-a40b-4d30-faa507207194
  ###
  method action::apply {
    my variable prefs
    set data [my Option_Filter [array get prefs]]
    my <object> configure {*}$data
    my <object> apply_styles {}
  }

  ###
  # topic: 27acb262-2ceb-ef6a-9d8f-f3ae8bdd3725
  ###
  method field_display_option {f row varname field args} {
    set info  [::taotk::option_inferences $field {*}$args]

    set l $f.$field#l
    set u $f.$field#u
    set p $f.$field
    dict with info {}
    #set class [::taotk::meta::widget_select $info]
    dict set info stylesheet [my organ stylesheet]
    dict set info object     [my organ object]
    ttk::label $l -text $label -style [my stylesheet widget_style label {} $row]
    set_balloon $l $description
    if { [dict exists $info units] } { 
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text [dict get $info units]
    } else {
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text {}
    }
    ::taotk::dynamic_widget $f.$field $field $varname {*}$info row $row
    #$class $f.$field $field $varname {*}$info row $row object [self]

    grid $l $p $u -sticky news
    grid configure $u -sticky news

    grid configure $l -sticky news
    grid configure $p -padx 2 -sticky ew
    grid columnconfigure $f $p -minsize 200
  }

  ###
  # topic: 01ed4a4d-1094-9943-473d-c6e6b25b8f2d
  ###
  method load_values {} {
    my variable record
    set option_info 
    array unset record(*)
    foreach {option info} [my metadata] {
      set record($option) [my <object> cget $option]
    }
    return
  }

  ###
  # topic: 6341c9c8-e6df-0c79-6a34-65149d01c509
  ###
  method metadata {} {
    return [my <object> property option dict]
  }
}

###
# topic: eae654f4-36dd-f7bb-b6a2-bf34219aec15
# description:
#    A widget that allows the user to manage
#    the options of an object
###
tao::class taotk::meta::template.preferences {
  superclass taotk::meta::page.options taotk::toplevel

  variable tabfilter general

  option title {
    default "Preferences"
  }
  option label {
    default {}
  }
  option prefdb {
    class organ
    default {}
  }
  

  ###
  # topic: b74ce9c6-6f10-e16a-467d-b2a1c0f738c2
  ###
  method action::apply {
    my variable record
    set data [my Option_Filter [array get record]]
    my <object> configure {*}$data
  }

  ###
  # topic: f77084da-0f07-eba5-191f-9ed51f5c6b17
  ###
  method build_content {} {
    my variable record tabfilter
    set varname [my varname record]
    my clear_content
    set f [my organ contentframe]
    ttk::combobox $f._select#tab -textvariable [my varname tabfilter]
    grid $f._select#tab -columnspan 5
    set tablist general
    set row 0
    set f [my organ contentframe]
    set metadata [my metadata]
    foreach {option info} [lsort -stride 2 -dictionary $metadata] {
      if {![string is false [dictGet $info hidden]]} continue
      set tab [dictGet $info tab]
      if { $tab ni $tablist } {
        lappend tablist $tab
      }
      if { $tabfilter ni {* {} all}} {
        if {![string match $tabfilter $tab]} continue
      }
      
      set ${varname}($option) [my <object> cget $option]
      my field_display_option $f [incr row] $varname $option $info
    }
    lappend tablist all
    $f._select#tab configure -values [lsort $tablist]
    bind $f._select#tab <<ComboboxSelected>> [namespace code {my build_content}]
  }

  ###
  # topic: e55e1db8-b1b1-95ee-b061-156ac2a152f4
  ###
  method Build_controls frame {
    ttk::button $frame.apply -text Apply -command [namespace code {my action apply}]
    ttk::button $frame.revert -text Revert -command [namespace code {my build_content}]
    ttk::button $frame.cancel -text Cancel -command [namespace code {my destroy}]
    pack $frame.cancel $frame.revert -side left
    pack $frame.apply -side right
  }

  ###
  # topic: b57a34af-9641-5ee2-95a7-ae53a0d39b42
  ###
  method build_widget window {
    ttk::frame $window.contents
    ttk::frame $window.buttons
    my Build_controls $window.buttons
    
    my graft contentframe $window.contents

    pack $window.buttons -side bottom -fill x
    pack $window.contents -side top -expand 1 -fill both

    my graft toplevel $window
    my build_title
  }

  ###
  # topic: 0d8e03f6-21e5-7159-d100-3f5f929549e5
  ###
  method clear_content {} {
    set window [my organ contentframe]
    if {[winfo exists $window]} {
      destroy {*}[winfo children $window]
    }
  }

  ###
  # topic: fa017d79-0d0a-8fbf-f64f-3fa206551660
  # description: Return the title of the window
  ###
  method title {} {
    return [my cget title]
  }
}

###
# topic: e6ebe026-b280-bc08-5939-04e8e9ff1a41
###
tao::class taotk::meta::page.dbrecord {
  superclass taotk::meta::page

  option db {class organ}
  

  ###
  # topic: 696d9666-1771-7c42-1172-d19a9ce772bb
  ###
  method field_display_table {f row varname field args} {
    set info  [::taotk::option_inferences $field {*}$args]
    #set class [::taotk::meta::widget_select $info]

    set l $f.$field#l
    set u $f.$field#u
    set p $f.$field
    dict with info {}
    ttk::label $l -text $label -style [my stylesheet widget_style label {} $row]
    set_balloon $l $description
    if { [dict exists $info units] } { 
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text [dict get $info units]
    } else {
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text {}
    }
    set newobj [self]#field#$field
    ::taotk::dynamic_widget $f.$field $field $varname {*}$info row $row
    #$class $f.$field $field $varname {*}$info row $row

    grid $l $p $u -sticky news
    grid configure $u -sticky news

    grid configure $l -sticky news
    grid configure $p -padx 2 -sticky ew
    grid columnconfigure $f $p -minsize 200
  
  }

  ###
  # topic: 7e34e0fc-c148-6d61-89ce-1b4062f714ff
  ###
  method Load_values {} {
    my variable record
    set nodeid [my nodeid]
    set table [my property table]
    set pkey  [my property primary_key]
    my db eval "select * from $table where $pkey=:nodeid" record break;
    unset record(*)
  }

  ###
  # topic: 07a2f42a-3806-2c6a-78cc-b3dc1ddef66f
  ###
  method metadata {} {
    # REPLACE
    #set table [my property table]
    #return [dict get [my db schema_get $table] fields]
  }

  ###
  # topic: 3c487a6b-3cd5-cb37-9e52-5186a66d7470
  ###
  method nodeid {} {
    # REPLACE
  }
}

###
# topic: 366402af-d8d7-1e98-992c-dac484d8eb6c
###
tao::class taotk::meta::page.dbproperty {
  superclass taotk::meta::page

  option db {class organ}

  ###
  # topic: 32492255-5de2-9c8b-107d-68ff9ab42055
  ###
  method field_display_property {f row varname field args} {
    set info  [::taotk::option_inferences $field {*}$args]
    #set class [::taotk::meta::widget_select $info]

    set l $f.$field#l
    set u $f.$field#u
    set p $f.$field
    set x $f.$field#x
    set h $f.$field#h
    
    dict with info {}
    set readonly [string is true -strict [dictGet $info readonly]]

    ttk::label $l -text $label -style [my stylesheet widget_style label {} $row]
    set_balloon $l $description
    if { [dict exists $info units] } { 
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text [dict get $info units]
    } else {
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text {}
    }
    ::taotk::dynamic_widget $f.$field $field $varname {*}$info row $row
    #$class $f.$field $field $varname {*}$info row $row
    
    set src [dictGet $info data_source]
    ttk::button $x -image ::taotk::icon::action-minus -command [namespace code [list my parent action delete_spec spec $field]]

    if { $src ne {} } {
      ttk::label $f.$field#src -text $src -style [my stylesheet widget_style label {} $row] -foreground #8a8
      grid $f.$field#src $l $p $u $x -sticky news
      grid configure $u -sticky news
  
      grid configure $l -sticky news
      grid configure $p -padx 2 -sticky ew
      grid columnconfigure $f 2 -minsize 200
    } else {
      grid $l $p $u $x -sticky news
      grid configure $u -sticky news
  
      grid configure $l -sticky news
      grid configure $p -padx 2 -sticky ew
      grid columnconfigure $f $p -minsize 200
    }
  }
}

###
# topic: 219c3f95-ebe1-a466-7c29-155af76ae6a6
###
tao::class taotk::meta::page.livestatus {
  superclass taotk::meta::page

  ###
  # topic: 6bf45868-b5ce-0c6c-a224-f30574297fb1
  ###
  method field_display_status {f row varname field args} {
    set info  [::taotk::option_inferences $field {*}$args]
    #set class [::taotk::meta::widget_select $info]

    if {[winfo exists $f.$field]} continue
    set l $f.$field#l
    set u $f.$field#u
    set p $f.$field
    set x $f.$field#x
    
    ttk::label $l -text $label -style [my stylesheet widget_style label {} $row]
    set_balloon $l $description
    if { [dict exists $info units] } { 
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text [dict get $info units]
    } else {
      ttk::label $u -style [my stylesheet widget_style label {} $row] -text {}
    }
    ::taotk::dynamic_widget $f.$field $field $varname {*}$arglist row $row
    #$class $f.$field $field $varname {*}$arglist row $row

    if {[dict exists $structInfo $label description]} {
      set_balloon $f.$field#l [dict get $structInfo $label description]
      set_balloon $f.$field   [dict get $structInfo $label description]
    }

    ttk::button $x -image ::taotk::icon::help -command [namespace code [list my launch_help $helpurl]]

    grid $l $p $u $x -sticky news
    grid configure $u -sticky news  
    grid configure $l -sticky news
    grid configure $p -padx 2 -sticky ew
    grid columnconfigure $f $p -minsize 200
  }
}

