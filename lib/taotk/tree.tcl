#
# This module is responsible for drawing the tree widget showing
# the xtype hierarchy on the left side of the screen.
#

###
# topic: 106e7d5e-51cc-6f6d-d443-2d8b7e6b35b8
# description:
#    This module is responsible for drawing the tree widget showing
#    the xtype hierarchy on the left side of the screen.
#    
#    
#    Base class for all type tree
#    widgets
###
tao::class taotk::meta::tree {
  superclass taotk::meta::widget
  
  option master {
    class organ
    default ::appmain
  }
  
  destructor {
    next
  }

  ###
  # topic: 56b64914-ea63-59b5-c963-2090e1e775f3
  ###
  method bind {event command} {
    ::bind [my organ tree] $event $command
  }

  ###
  # topic: 72ba5f6c-f250-4675-ad5d-de1c843d270d
  ###
  method build_content {} {
    set tw [appmain organ tree]
    variable map
    ###
    # Capture who is open
    ###
    #array unset open_list *
    set open_list [my currentlyOpen]

    my clear_content
    foreach {name typeid} [lsort -dictionary -stride 2 [my rootNodes]] {
      my redrawNode $typeid 0
    }

    foreach [my columns] $open_list {
      set tag [my nodetag $typeid]
      foreach item [my treewidget tag has $tag] {
        catch {my treewidget item $item -open 1}
      }
    }
    my repaint
    my default
  }

  ###
  # topic: 41cfe3f4-ac90-282f-56da-fc280c9be871
  ###
  method build_widget w {
    my graft treeframe $w
    my graft tree $w.tree
    my graft treewidget $w.tree

    ttk::scrollbar $w.vsb -orient vertical -command "$w.tree yview"
    ::ttk::treeview $w.tree \
      -yscrollcommand "$w.vsb set" -columns [my columns] \
      -displaycolumns [my displaycolumns] -show tree
        
    pack $w.vsb -side left -fill y
    pack $w.tree -side left -fill both -expand 1

    oo::objdefine [self] forward tree $w.tree
  }

  ###
  # topic: b61a3ff6-e274-7f82-927d-bccf3cd99830
  # description: Clear all of the items out of the tree
  ###
  method clear_content {} {
    foreach selection [my treewidget tag has all] {
      catch {my treewidget delete $selection}
    }
    variable map
    array unset map *
  }

  ###
  # topic: ab111ec6-e028-4c8e-9bcf-4bdb73564062
  ###
  method columns {} {
    #return {name xtypeid}
    return name
  }

  ###
  # topic: 880b46a9-0ec8-4d48-3978-b18d36f0aa04
  ###
  method currentlyOpen {} {
    set result {}
    foreach selection [my treewidget tag has all] {
      if { [my treewidget item $selection -open] } {
        lappend result {*}[my treewidget item $selection -values]
      }
    }
    return $result
  }

  ###
  # topic: f5adba7e-599b-68af-ffcf-867d827f9cbc
  ###
  method currentSelection {} {
    set result {}
    variable tree
    foreach selection [my treewidget selection] {
      lappend result {*}[my treewidget item $selection -values]
    }
    return $result
  }

  ###
  # topic: 24dd0ecc-da46-fb33-762c-5d7ff830c1fe
  ###
  method displaycolumns {} {
    return {}
  }

  ###
  # topic: fbcba112-511b-deeb-97e3-1dd630b28cb8
  ###
  method isopen typeid {
    set tag [my nodetag $typeid]
    foreach item [my treewidget tag has $tag] {
      return [my treewidget item $item -open]
    }
  }

  ###
  # topic: 092d5ab0-5f6e-7060-9d24-e6c8b680c459
  ###
  method nodetag unit {
    return $unit
  }

  ###
  # topic: f0f9bf98-5b5c-4875-2f95-935e619b3880
  # title: Draw a tree node
  # description:
  #    If direction=1 decend to recursively draw children
  #    If direction=1 ascend to recursively draw parents
  ###
  method redrawNode {typeid {direction 1}} {
    variable map
    if {[info exists map($typeid)]} {
      return $map($typeid)
    }
    set info [my node_info $typeid]
    if {[llength $info] eq 0} {
      return
    }
    dict with info {}    
    ###
    # Draw any missing parents
    ###
    if { $direction } {
      set p [my redrawNode $parent 1]
      catch {my treewidget item $p -open 1} error
    } else {
      set p [my redrawNode $parent 1]
    }
    set run 1
    set t [my treewidget insert $p end -text $name -image {} -values $row -tags $tags]
    set map($typeid) $t

    ###
    # Add children
    ###
    if {!$direction} {
      foreach {name childid} [lsort -dictionary -stride 2 [my childNodes $typeid]] {
        ###
        # Add children
        ###
        my redrawNode $childid 0
      }
    }
    return $t
  }

  ###
  # topic: 869a7b02-07d4-81dc-ee0a-d1868d3aa959
  # description:
  #    Change the icons displayed next to
  #    nodes and leaves
  ###
  method repaint args {
    
  }

  ###
  # topic: 15eca6b2-302b-a8bd-df38-ac2279a0103a
  ###
  method setbg state {
    my variable tree
    switch $state {
      grey {
        my treewidget configure -style TaoGrey.Treeview 
      }
      default {
        my treewidget configure -style Tao.Treeview 
      }
    }
    update idletasks
  }

  ###
  # topic: b38a09f1-fe94-da1a-9f35-70f34b2a271d
  ###
  method showtype {typeid {select 0}} {
    set tag [my nodetag $typeid]
    foreach item [my treewidget tag has $tag] {
      catch {my treewidget item $item -open 1}
      catch {my treewidget see $item}
      if { $select } {       
        my treewidget selection set $item
      }
    }
  }
}

