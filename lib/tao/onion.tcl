###
# topic: 5128c018-a293-9c88-abeb-986e817169ab
# description:
#    This class is a template for objects that will be managed
#    by an onion class
###
tao::class tao.layer {
  superclass moac
  
  option prefix {}
  option layer_name {}
  property layer_index_order 0
  
  constructor {sharedobjects args} {
    my InitializePublic
    foreach {organ object} $sharedobjects {
      my graft $organ $object
    }
    my graft layer [self]
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
  }

  ###
  # topic: 42df416a-1e8a-cfcb-aa6f-0d7f92220bde
  # description: Action to perform when layer is mapped visible
  ###
  method action::visible {}

  ###
  # topic: bc464594-d3d4-dbc6-d165-6ff68d15ae14
  ###
  method node_is_managed unit {
    return 0
  }

  ###
  # topic: 256f2fd3-33ea-cc66-4209-d402347fbeb4
  ###
  method type_is_managed unit {
    return [expr {$unit eq [my cget prefix]}]
  }
}

###
# topic: d989892a-f782-b8f7-b334-93b402460ec3
# description:
#    A form of megawidget which farms out major functions
#    to layers
###
tao::class tao.onion {
  superclass moac
  variable layers {}
  
  ###
  # Organs that are grafted into our layers
  ###
  property shared_organs {
    
  }

  ###
  # topic: 8385ec1f-acb4-4290-e0e2-b77101b9ed92
  ###
  method action::activate_layers {} {}

  ###
  # topic: 20d20a37-2170-07e2-a740-142b62ea667b
  ###
  method activate_layers {{force 0}} {
    set self [self]
    my variable layers
    set result {}
    set active [my active_layers]

    ###
    # Destroy any layers we are not using
    ###
    set lbefore [get layers]
    foreach {lname obj} $lbefore {
      if {![dict exists $active $lname] || $force} {
        $obj destroy
        dict unset layers $lname
      }
    }

    ###
    # Create or Morph the objects to represent
    # the layers, and then stitch them into
    # the application, and the application to
    # the layers
    ###    
    foreach {lname info} $active {
      set class  [dict get $info class]
      set ordercode [$class property layer_index_order]
      if { $ordercode ni {0 {}} } {
        lappend order($ordercode) $lname $info
      } else {
        lappend order(99) $lname $info
      }
    }
    set shared {}
    dict set shared master [self]
    foreach organ [my property shared_organs] {
      set obj [my organ $organ]
      if { $obj ne {} } {
        dict set shared $organ $obj
      }
    }
    foreach {ordercode objlist} [lsort -stride 2 -integer [array get order]] {
      foreach {lname info} $objlist {
        set created 0
        set prefix [dict get $info prefix]
        set class  [dict get $info class]
        set layer_obj [my SubObject layer $lname]
        dict set layers $lname $layer_obj
        if {[info command $layer_obj] == {} } {
          $class create $layer_obj $shared prefix $prefix layer_name $lname
          set created 1
        } else {
          $layer_obj morph $class
          foreach {organ object} $shared {
            $layer_obj graft $organ $object
          }
        }
        logicset add result $layer_obj
        $layer_obj action visible
      }
    }
    my action activate_layers
    return $result
  }

  ###
  # topic: 5b2c36e4-42e4-940a-89e1-7e0491956ef0
  # description: Returns a list of layers with properties needed to create them
  ###
  method active_layers {} {
    ### Example
    #set result {
    #  xtype     {prefix y class sde.layer.xtype}
    #  eqpt      {prefix e class sde.layer.eqpt}
    #  portal    {prefix p class sde.layer.portal}
    #}
    # return $result
    return {}
  }

  ###
  # topic: c68164a0-faaa-2048-8fe1-20e4df7b607c
  ###
  method layer {item args} {

    set scan [scan $item "%1s%d" class objid]
    switch $scan {
      2 {
        # Search by class/objid
        if { $class eq "y"} {
          foreach {layer obj} [my layers] {
            if { [$obj type_is_managed $item] } {
              if {[llength $args]} {
                return [$obj {*}$args]
              }
              return $obj
            }
          }
        } else {
          # Search my node if we have a prefix/number
          foreach {layer obj} [my layers] {
            if { [$obj node_is_managed $item] } {
              if {[llength $args]} {
                return [$obj {*}$args]
              }
              return $obj
            }
          }
        }
      }
      default {
        # Search my name/prefix
        foreach {layer obj} [my layers] {
          if { [string match $item $layer] } {
            if {[llength $args]} {
              return [$obj {*}$args]
            }
            return $obj
          }
          set data [my active_layers]          
          if { [string match $item [dict get $data $layer prefix]] } {
            if {[llength $args]} {
              return [$obj {*}$args]
            }
            return $obj
          }
        }
        # Search by string
        ###
        # Search by type
        ###
        foreach {layer obj} [my layers] {
          if { [$obj type_is_managed $item] } {
            if {[llength $args]} {
              return [$obj {*}$args]
            }
            return $obj
          }
        }
        ###
        # Search fall back to search by node
        ###
        foreach {layer obj} [my layers] {
          if { [$obj node_is_managed $item] } {
            if {[llength $args]} {
              return [$obj {*}$args]
            }
            return $obj
          }
        }
      }
    }
    return ::noop
  }

  ###
  # topic: c8595366-d672-53ec-94a8-a1dde00dab6f
  # description: Return a list of layers for this application
  ###
  method layers {} {
    set result {}
    my variable layers
    if {![info exists layers]} {
      my activate_layers
    }
    return $layers
  }

  ###
  # topic: f6cc95d0-9f66-1236-5ecc-929b476c7243
  ###
  method SubObject::layer name {
    return [namespace current]::SubObject_Layer_$name
  }
}

