::namespace eval ::taotk {}

::namespace eval ::taotk::meta {}

###
# topic: f51344ff-c294-19d2-f5d7-5d4d12a23eea
###
tao::class taotk::meta::widget {
  superclass moac
  property widget 1
  property options_strict 1

  option_class tkoption {
    set-command {my nativewidget configure -%field% %value%}
    get-command {my nativewidget cget -%field%}
  }
  option colorstate   {default normal}
  option row          {default {}}
  option stylesheet   {
    hidden 1
    default ::taotk::stylesheet
    widget odie_object
    object_isa ::taotk::stylesheet
    class organ
  }
  variable tkalias {}


  destructor {
    my Widget_destructor
  }

  ###
  # topic: 593b8b34-ad69-544a-1526-4f3a6b9d93ca
  # description:

  ###
  # topic: 1fc9fc02-5b1d-bd70-3818-f4514174f7e6
  # description:
  #    Called during the destructor of taotk widgets prior
  #    to the destruction of tk objects and the unlinking and
  #    destruction of the object and it's subobjects. It gives
  #    complex UIs an easy to maintain shim with which to respond
  #    to the object's destruction, without having to modify the
  #    the (admitedly) complex taotk object destructor.
  ###
  method action::destroy {} {}

  ###
  # topic: 3dc026c0-adb1-ab91-145b-fc080b1635a4
  ###
  method bind_widget window {
    my graft topframe $window
    my graft toplevel [winfo toplevel $window]
    my graft nativewidget $window
    bind $window <Destroy> [namespace code {my EventDestroy %W}]
  }

  ###
  # topic: 83d1f31d-f3b9-d02b-b809-d75bf6531ff4
  # description: Fill the screen with content. The default is an empty method.
  ###
  method build_content {} {}

  ###
  # topic: 40b4d051-b508-289f-8bd7-12964dca4893
  # description:
  #    Build the basic UI framework of the widget, below
  #    the level of the topmost frame or window.
  ###
  method build_widget window {}

  ###
  # topic: 79dedb51-4f2e-357a-929d-05bbc1d6d3f0
  ###
  method BuildDynamicMethods {} {
    if {[my organ stylesheet] eq {}} {
      my graft stylesheet ::taotk::stylesheet
    }
    oo::objdefine [self] method Style [list primitive [list substyle [my cget colorstate]] [list row [my cget row]]] "
return \[[my organ stylesheet] widget_style \$primitive \$substyle \$row\]
"
    my forward widget_style [my organ stylesheet] widget_style
  }

  ###
  # topic: 7c1dbe5b-2e16-5c1d-e472-3d60fdf305aa
  # description:
  #    This command is run after the arguments are inputted
  #    internally, and should throw an error if a needed argument
  #    was not given a value.
  ###
  method check_required_args {} {
    return {}
  }

  ###
  # topic: 199ee5fb-6ea0-b8dd-87b3-d9e1c905ab83
  # title: Return true of the object was drawn
  ###
  method drawn {} {
    return [winfo exists [my organ topframe]]
  }

  ###
  # topic: c333e320-178d-22e7-f459-71ba4e7ed0f9
  # description:
  #    A private method that catches tk events and ensures
  #    the <Destroy> we are seeing is intended for us.
  ###
  method EventDestroy window {
    set w [my organ topframe]
    #puts [list [self] EventDestroy $window $w [string match "${window}*" $w]]
    if { [string match "${window}*" $w] } {
      my destroy
    }
  }

  ###
  # topic: 7135d501-9594-5d4e-33b9-e6fe3979a979
  ###
  method nativewidget args {
    ### Empty implememtation that will be replace later
  }

  ###
  # topic: 0a7d7c1a-f7d3-5ba6-bd5b-cc3950527a0e
  ###
  method Option_set::colorstate newvalue {
    my BuildStyleMethod
  }

  ###
  # topic: 0a4569f4-8953-8550-cf96-cf1604a9e194
  ###
  method Option_set::row newvalue {
    my BuildStyleMethod
  }

  ###
  # topic: c03ad49f-d65d-f843-a169-47e7118312a8
  ###
  method Option_set::stylesheet newvalue {
    my BuildStyleMethod
  }

  ###
  # topic: 15950869-71de-fabf-6495-eed3c4099c54
  # description:
  #    Renames the tcl command that represents the widget to
  #    one that resides in the object's namespace. It then renames
  #    the object to catch calls to the tk path.
  ###
  method tkalias tkname {
    set oldname $tkname
    my variable tkalias
    set tkalias $tkname
    set self [self]
    set nativewidget [::info object namespace $self]::tkwidget
    my graft nativewidget $nativewidget
    rename ::$tkalias $nativewidget
    ::tao::object_rename [self] ::$tkalias
    my bind_widget $tkalias
    return $nativewidget
  }

  ###
  # topic: 569d5da6-4d09-4c14-30df-5ca054fbf2cb
  # description: Defuses the <Destroy> binding in this object's tk window.
  ###
  method unbind_widget window {
    my variable tkalias
    if {[winfo exists $window]} {
      bind $window <Destroy> {}
    }
    set tkalias {}
  }

  ###
  # topic: 56cde411-ca02-a08a-9e8c-466d7e3ea6ee
  ###
  method Widget_destructor {} {
    ###
    # Destroy our Tk representation
    ###
    my variable tkalias
    set alias $tkalias

    if {$alias ne {}} {
      my unbind_widget $alias
    }
    catch {my action destroy}
    # Destroy an alias we may have created
    if { $alias ne {} && [winfo exists $alias] } {
      catch {rename [namespace current]::tkwidget {}}
    } else {
      catch {::destroy [my organ nativewidget]}
    }
    
    ###
    # Clean up children
    ###
    foreach subobj [info command [self]/*] {
      catch {$subobj destroy}
    }
    foreach subobj [info command [self].*] {
      if {[winfo exists $subobj]} continue
      catch {$subobj destroy}
    }
  }
}

###
# topic: 8021b360-be13-ef2a-487a-52b7c78f263c
###
tao::class taotk::meta::toplevel {
  superclass taotk::meta::widget

  ###
  # topic: 0a42d944-0689-ae65-f15a-17f58aa04bd1
  ###
  method action::resize {
    ::update idletasks
    set toplevel [my organ toplevel]
    # Stretch the toplevel out to where it wants to be
    set wid [winfo reqwidth $toplevel]
    set hgt [winfo reqheight $toplevel]
    if { $wid < 400 } {
      set wid 400
    }
    if { $wid > 800 } {
      set wid 800
    }
    if { $hgt < 400 } {
      set hgt 400
    }
    if { $hgt > 800 } {
      set hgt 800
    }
    wm geometry $toplevel ${wid}x${hgt}
  }

  ###
  # topic: aa5280ca-49c5-0362-d965-c5826f09e583
  # title: Place the title on the top
  ###
  method build_title {} {
    set tl [my organ topframe]
    wm title $tl [my title]
    wm iconname $tl [my title]    
  }

  ###
  # topic: ba94de9d-e55d-205a-cbef-c696d0001d1e
  # description: Return the title of the window
  ###
  method title {} {
    return [lindex [split [my organ toplevel] .] end]
  }
}

###
# topic: 5f4a24b0-3910-effa-4458-c0440b0af6b6
# title: Mother of all widgets
# description: Progenitor of all TclOO megawidgets in IRM
###
tao::class taotk::frame {
  superclass taotk::meta::widget
  
  option takefocus {default 1}
  option state {
    class tkoption
  }
  option text {
    default {}
  }

  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my build_content
    my bind_widget $window
  }

  ###
  # topic: 5d80dd8d-be58-2e65-6cd0-6373846e0c5b
  ###
  class_method unknown args {
    set tkpath [lindex $args 0]
    if {[string index $tkpath 0] eq "."} {
      if {[winfo exists $tkpath]} {
        error "Bad path name $tkpath"
      }
      set obj [my new $tkpath {*}[lrange $args 1 end]]
      if {![winfo exists $tkpath]} {
        catch {$obj destroy}
        return {}
      }
      $obj tkalias $tkpath
      return $tkpath
    }
    next {*}$args
  }

  ###
  # topic: 1fc7b2d1-3c32-3b51-d88b-31997933670b
  ###
  method Build_topframe tkpath {
    if {[my cget text] ne {} } {
      ::ttk::labelframe $tkpath -text [my cget text] -style [my Style frame]      
    } else {
      ::ttk::frame $tkpath -style [my Style frame]
    }
  }
  

  method Option_set::text newvalue {
    my topframe configure -text $newvalue
  }

  ###
  # topic: eac448e7-c117-13b7-021b-05e04467ea9d
  ###
  method Option_set::takefocus value {
    my nativewidget configure -takefocus $value
  }
}

###
# topic: ab54a510-2c13-86a5-c2b3-be3ecb248bf9
# title: Mother of all widgets
# description: Progenitor of all TclOO megawidgets in IRM
###
tao::class taotk::widget {
  superclass taotk::frame


  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my build_content
    my bind_widget $window
  }
}

###
# topic: 4f81708c-b2d0-a08e-4695-39b7daa1fd2d
# title: Tao widget encased in a toplevel window
# description: Sprinkle
###
tao::class taotk::toplevel {
  superclass taotk::meta::toplevel

  option windowstyle {
    default standard
    values {standard floating help modal}
    widget select
  }
  
  option parentwindow {
    default {}
  }
  option title {
    default {}
  }

  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my build_content
    my bind_widget $window
  }

  ###
  # topic: 5789ee10-8935-c78b-1e57-3b677e9aae63
  ###
  class_method unknown args {
    set tkpath [lindex $args 0]
    if {[string index $tkpath 0] eq "."} {
      if {[winfo exists $tkpath]} {
        error "Bad path name $tkpath"
      }
      set obj [my new $tkpath {*}[lrange $args 1 end]]
      if {![winfo exists $tkpath]} {
        catch {$obj destroy}
        return {}
      }
      $obj tkalias $tkpath
      return $tkpath
    }
    next {*}$args
  }

  ###
  # topic: dd2074d1-19cf-ea02-e89f-a003fad79c02
  ###
  method Build_topframe tkpath {
    set style standard
    set parent [if_null [my cget parentwindow] .]
    set style  [my cget windowstyle]
    my graft toplevel $tkpath
    my graft topframe $tkpath
    toplevel $tkpath
    switch $style {
      modal {
        switch $::tao::platform {
          macosx {
            ::tk::unsupported::MacWindowStyle style $tkpath floating closeBox
          }
          windows {
            wm attributes $tkpath -toolwindow 1
          }
          default {
            wm transient $tkpath .
          }
        }
        foreach {size x y} [split [wm geometry $parent] +] break;
        wm geometry $tkpath +$x+$y
      }
      help {
        switch $::tao::platform {
          macosx {
            ::tk::unsupported::MacWindowStyle style $tkpath help closeBox
          }
          windows {
            wm attributes $tkpath -toolwindow 1
          }
          default {
            wm transient $tkpath .
          }
        }
      }
      floating {
        switch $::tao::platform {
          macosx {
            ::tk::unsupported::MacWindowStyle style $tkpath floating closeBox
          }
          windows {
            wm attributes $tkpath -toolwindow 1
          }
          default {
            wm transient $tkpath .
          }
        }
      }
      standard -
      default {
      }
    }
    $tkpath configure -bg [::ttk::style lookup . -background]
  }
}

