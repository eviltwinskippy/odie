###
# This file is loaded as part of the library initialization
###

package provide irm::helpdoc 0.1

package require msgcat
package require sqlite3
package require odie

::namespace eval ::irm {}

###
# topic: 826bd6a9-95af-84fb-ac5a-319d61d695ed
# description:
#    Given the name of an spec, state variable, port, or a behavior
#    return that name contained within an HTML hyperlink to the description
#    of the spec, state, port, or behavior.
###
proc ::irm::_link_map {entryid class args} {
  set refaddr [helpdoc link_detect_address {*}$args]
  helpdoc link_create $entryid $refaddr $class
  return $refaddr
}

###
# topic: 539ccbaa-329b-c963-88e5-99f5f1d02694
###
proc ::irm::behaviorId name {
      variable behavior_name_to_idx
      return $behavior_name_to_idx([string toupper $name])
  }

###
# topic: 296e4244-a259-a97d-697b-e4eff5b97933
###
proc ::irm::behaviorList {} {
  variable behavior_name_to_idx
  return [lsort -dictionary [array names behavior_name_to_idx]]
}

###
# topic: ada119c6-63e1-2133-9631-c188ade7974b
###
proc ::irm::behaviorName id {
  variable behavior_idx_to_name
  set id [expr {int($id)}]
  return [string toupper $behavior_idx_to_name($id)]
}

###
# topic: 92c55450-7418-6348-6df7-5f1c31c385f7
###
proc ::irm::behaviorSet {} {
  variable behavior_idx_to_name
  return [lsort -integer -stride 2 [array get behavior_idx_to_name]]
}

###
# topic: fe8b684b-b04c-204c-f91b-8671ab8175ec
###
proc ::irm::busy args {
  update
  return 0
}

###
# topic: e3481136-fa8c-5d14-7570-7ab625c61b11
###
proc ::irm::cookie_set {} {
  variable cookie_set
  return $cookie_set
}

###
# topic: d9f3dd2c-9b5c-517b-b5ed-cad80130d444
###
proc ::irm::cookie_to_list cookies {
  set cx {}
  foreach {m nm} [::irm::cookie_set] {
    if {$cookies & $m} {lappend cx $nm}
  }
  return $cx
}

###
# topic: 05669d72-ffbe-7fee-ee86-7502f551ae15
###
proc ::irm::cookieId name {
  variable cookie_name_to_idx
  return $cookie_name_to_idx($name)
}

###
# topic: 1d2b9d6b-0eb1-68b4-8a32-1e5eaa649ee3
###
proc ::irm::cookielist_to_int cookielist {
  set cookie 0
  foreach {n nm} [::irm::cookie_set] {
    if { $nm in $cookielist} {
      set cookie [expr {$cookie | $n}]
    }
  }
  return $cookie
}

###
# topic: 8d4226da-573d-74c3-72df-3aeff869f86c
###
proc ::irm::docIndex {type entry} {
  variable typeList
  ladd_sorted typeList($type) $entry
  
  switch $type {
    spec {
      variable specIndex
      variable spec_macro
      
      set info [::helpdoc node_get [list spec $entry]]
      set new {}
      dict with info {
        if { ![info exists scope] } {
          set scope {}
          dict set new scope {}
        }
        if { "mitl" in $scope } {
          dict set new universal 1
        }
        if { "generic" in $scope } {
          dict set new universal 1
        }
        logicset add specIndex($usage) $entry
      }
      if {[dict exists $info behaviors]} {
        if {[llength [dict get $info behaviors]]} {
          dict set new universal 0
        }
      }
      if {[dict exists $info ports]} {
        if {[llength [dict get $info ports]]} {
          dict set new universal 0
        }
      }
      helpdoc node_define spec $entry $new
    }
  }
}

###
# topic: aba5eb52-e185-53e7-dc5e-2ae5520e3af0
# title: Follow the links in a rule and cross link the entry in the database
###
proc ::irm::entryFollowLinks {entryid class description} {
  set olddesc $description
  if {![regsub -all {\[} $description "\[_link_map $entryid $class " description]} return  
  if [catch {subst $description} err] {
    puts "Warning: \"$err\" while reading\n$entryid\n$description"
  }
}

###
# topic: 55c5b322-276d-6b28-1273-92232cf06fe0
###
proc ::irm::entryFollowList {atype aidlist btype bidlist} {
  foreach aid $aidlist {
    if {![string is integer $aid]} {
      if {![helpdoc node_exists $aid anode]} continue
    } else {
      set anode $aid
    }
    foreach bid $bidlist {
      if {![string is integer $bid]} {
        if {![helpdoc node_exists $bid bnode]} continue
      } else {
        set bnode $bid
      }
      ::helpdoc link_create $anode $bnode $atype
    }
  }
}

###
# topic: 8146f93c-2725-e06f-1aa4-a4b83c0930bf
###
proc ::irm::eocDefine {name properties} {
  helpdoc node_define  spec $name $properties
}

###
# topic: a80f1ef1-d27c-a237-ffd2-8d92417d5369
###
proc ::irm::helpDocCreate filename {
  set object ::helpdoc
  ###
  # Build the root entries of the helpdoc file
  ###
  if {[info command $object] ne {}} return
  
  set exists [file exists $filename]
  if {![file exists [file dirname $filename]]} {
    file mkdir [file dirname $filename]
  } 
  package require sqlite3
  tao.yggdrasil create ::$object $filename
  
  if {[info command appmain] ne {}} {
    appmain graft helpdoc $object
  }
  $object timeout 10000
  $object busy ::irm::busy
  $object journal_mode 0
  if {!$exists} {
    catch {toplevel .pleasewait
    label .pleasewait.l -text "Creating Documentation Database"
    grid .pleasewait.l -sticky news
    raise .pleasewait
    }
    update
    $object eval [$object property create_sql]
    if [catch {package require irm::simdoc_seed $::irm_version} err] {
      puts "ERROR: $err\n$::errorInfo"
      puts "Building New DB"
      $object eval [::helpdoc property create_sql]
    }
    $object eval [$object property create_index_sql]
    catch {destroy .pleasewait}
  }
  puts "[$object eval {select count(*) from entry}] Nodes Loaded"
  $object reindex
  $object eval {select class,id,name from idset} {
    set ::irm::${class}_name_to_idx($name) $id
    set ::irm::${class}_idx_to_name($id) $name
  }
  ###
  # DEFINE SPECIAL HANDLERS FOR FIELDS
  ###
  foreach {field aliases} {
    behavior algorithm
    unit     units
  } {
    $object property_define $field [list aliases $aliases]
  }
  
  $object property_define aliases {
    script {
      my eval {select class,name from entry where entryid=$entryid} {
        foreach v $value {
          my canonical_set $class $v $name
        }
      }
      return
    }
  }
  foreach field {context references} {
    $object property_define $field {
      script {
        foreach {refid reftype} $value {
          my link_create $entryid $refid $reftype
        }
      }
    }
  }
  foreach {field aliases} {
    behaviors algorithms
    ports {}
    specs {}
    exclusive-to-behavior {}
    intended-ports {}
    required-ports {}
  } {
    $object property_define $field [list aliases $aliases script {set value [string tolower [lsort -dictionary -unique $value]]}]
  }
  
  $object property_define comment {
    aliases {note notes comment comments}
    script {
      set value [string trim $value]
    }
  }
  $object property_define description {
    aliases {desc description entry ruletxt ruletext}
    script {
      set value [string trim $value]
    }
  }
  $object property_define field {
    aliases fields
    script {
      foreach {branch binfo} $value {
        my node_define_child $entryid field $branch $binfo
      }
      return
    }
  }
  $object property_define index {
    aliases indexes
    script {
      foreach {branch binfo} $value {
        my node_define_child $entryid index $branch $binfo
      }
      return
    }
  }
  $object property_define method {
    aliases methods
    script {
      foreach {branch binfo} $value {
        my node_define_child $entryid method $branch $binfo
      }
      return
    }
  }

  $object node_define section behavior {
    title {Behaviors}
    desc {List of behaviors}
    template {
      required-ports {}
      intended-ports {}
      disallowed-ports {}
      power-source 0
      output-source 0
      uses-power 1
      specs {}
      disallowed-specs {}
      description {}
      initialize-function 0
      check-function 0
      step-function 0
      realign-function 0
      power-in-function 0
      power-out-function 0
      hive-function 0
      available-function 0
      operational-function 0
      autohive 1
      hive-connector 0
      propagate-damage-function 0
      react-damage-function 0
      input-scale-function 0
      load-out-function 0
      load-in-function 0
      output-scale-function 0
      loopback-function 0
      hidden 0 
    }
  }
  $object node_define section censemble {
    title {C Ensembles}
    desc {Clusters of related commands for interfaceing with C}
    template {
      key {}
      name {}
      structure {}
      global 0
      keytype int
      hashname {}
      hashtype tcl
      dictstore entity
      location 0
      trace 0
      delta 0
      methods {}
      functions {}
      prefix {}
      description {}
    }
  }
  $object node_define section cookie {
    title Cookies
    desc {Cookies}
  }
  $object node_define section cstruct {
    title {C Data Structures}
    desc {Data Structures used by C}
    template {
      key {}
      name {}
      ensemble {}
      keytype int
      dictstore entity
      location 0
      trace 0
      delta 0
      fields {}
      static {}
      static_bitfield {}
    }
  }
  $object node_define section pages {
    title {Documentation}
    desc {System generated pages}
  }
  $object node_define section port {
    title {Ports}
    desc  {List of Ports}
    template {
      exclusive-to-behavior {}
      exclusive-to-required 0
      input-sink 0
      output-source 0
      output-scale-function 0
      required-ports {}
      specs {}
      disallowed-ports {}
      disallowed-specs {}
      description {}
      initialize-function 0
      loopback-function 0
      check-function 0
      step-function 0
      hive-function 0
      propagate-damage-function 0
      react-damage-function 0
      aliases {}
      output-scale-function 0
      state-function 0
      hidden 0
    }
  }
  $object node_define section report {
    title Reports
    desc {Auto-generated reports}
  }
  $object node_define section rule {
    title Rules
    desc {List of rules. A master list in printable form is available at [report/rules]}
    template {
      rulefile {}
      context {}
      description {}
    }
  }
  $object node_define section schema {
    title {SQL DB Schemas}
    desc {Tables of the READI File}
    template {
      description {}
      create_sql  {}
    }
  }
  
  $object node_define section simconfig {
    title {Simulator Settings}
    desc {list of available simulator configuration settings}
    template {
      advanced 0
      aliases  {}
      command  {}
      default  {}
      default_command {}
      description {Unknown Config Item}
      hidden  0
      history 0
      save  {}
      scope generic
      tab general
      type string
      units {}
      usage {}
      width 10
      value {}
    }
  }
  $object node_define section spec {
    title {Specs}
    desc {
Specs modify an entity<p>
<table>
<tr><td>type</td><td>
<table>
  <tr><Td>constant</td><td>an operating constant used in C</td></tr>
  <tr><td>script</td><td>an operating constant only used on the Tcl level</td></tr>
</table></td></tr>
<tr><td>usage</td><td>Can have multiple values<p>
<table>
  <tr><td>equipment</td><td>Equipment</td></tr>
  <tr><td>conduit</td><td>Conduit</td></tr>
  <tr><td>portal</td><td>Portals</td></tr>
  <tr><td>material</td><td>Materials</td></tr>
  <tr><td>compartment</td><td>Compartments</td></tr>
</table></td></tr>
<tr><td>units</td><td>String to display as units</td></tr>
<tr><td>storage</td><td>Data type
  <table>
  <tr><td>time</td><td>A integer number of seconds</td></tr>
  <tr><td>real</td><td>A floating point number</td></tr>
  <tr><td>int</td><td>An integer number</td></tr>
  <tr><td>bool</td><td>True/False value</td></tr>
  <tr><td>u<i>x</i></td><td>Unsigned integer of <i>x</i> bits</td></tr>
</table></tr></td>
<tr><td>scope</td><td>What tab to file this under</td></tr>
<tr><td>values</td><td>Enumerated list of possible values in the form of [value] [abbrev] [description] ...</td></tr>
<tr><td>description</td><td>Documenation writeup of this parameter</td></tr>
<tr><td>ports</td><td>For equipment specs, what ports use this spec</td></tr>
<tr><td>behaviors</td><td>For equipment specs, what behaviors use this spec</td></tr>
</table>
    }
    template {
      aliases {}
      realm {xtype local}
      behaviors {}
      ports {}
      defined script
      usage all
      scope generic
      type string
      units {}
      universal 0
      usage {}
      description {Unknown Spec}
    }
  }
  #$object node_define section state {
  #  title {SimNode State Variables}
  #  desc {Fields from the SimNode Data Structure}
  #}
  #$object node_define section structure {
  #  title {Data Structures}
  #  desc {List of data structures}
  #}
  $object node_define section system {
    title {Systems}
    desc {List of Systems}
  }
  $object node_define section tclcmd {
    title {Command link} desc {Commands and APIS}
  }
}

###
# topic: 9b74fb11-13b2-bead-2a34-75a7126470a1
###
proc ::irm::indexAll {} {
  variable mitl_specs {}
  foreach {name value} [::helpdoc class_nodes spec] {
    set name [string tolower $name]
    if {![dict exists $value scope]} continue
    set skip 0
    if { "mitl" in [dict get $value scope] } {
      set skip 1
    }
    if { [string range $name 0 3] == "mitl" } {
      set skip 1
    }
    if {$skip} {
      lappend mitl_specs $name
    }
  }

  #puts "Begin index"
  helpdoc eval {select entryid,class from entry where indexed=0} {
    helpdoc eval {select value from property
        where entryid=$entryid and field in ('description','comment') } {
      ::irm::entryFollowLinks $entryid $class $value
    }
    if { $class eq "spec" } {
      helpdoc eval {select value from property
          where entryid=$entryid and field='behaviors'} {
        ::irm::entryFollowList spec $entryid behavior $value
      }
      helpdoc eval {select value from property
          where entryid=$entryid and field='ports'} {
        ::irm::entryFollowList spec $entryid port $value
      }
    }
    if { $class in {port behavior} } {
      helpdoc eval {select value from property
          where entryid=$entryid and field='specs'} {
        ::irm::entryFollowList spec $value $class $entryid
      }
    }
  }
  #puts "END Index"
  helpdoc eval {update entry set indexed=1}
  helpdoc eval [::helpdoc property create_index_sql]
}

###
# topic: 462cf4eb-fdb6-c6fc-309e-cebdf4829d20
# description:
#    The following table lists the available configuration parameters
#    together with some of their properties.
###
proc ::irm::localconfigDefine {name parameters} {
  set info [helpdoc node_empty simconfig]
  dict set info label [string tolower $name]
  dict set info save    prefs
  dict set info export  {}
  foreach {var val} $parameters {
    switch $var {
      local {
        if {!$val} {
          dict set info save {}
        }
      }
      volitile {
        if { $val } {
          dict set info save {}
        }
      }
      default {
        dict set info $var $val
      }
    }
  }
  helpdoc node_define  simconfig $name $info
}

###
# topic: 1f567d16-efd0-5043-cca4-cd2be0b0a57b
# description:
#    The following table lists the available configuration parameters
#    together with some of their properties.
###
proc ::irm::simconfigDefine {name parameters} {
  set info [helpdoc node_empty simconfig]
  dict set info label  [string tolower $name]
  dict set info save   readi
  dict set info export ispec
  foreach {var val} $parameters {
    switch $var {
      local {
        if {$val} {
          dict set info save prefs
          dict set info export {}
        }
      }
      volitile {
        if { $val } {
          dict set info save {}
          dict set info export {}
        }
      }
      default {
        dict set info $var $val
      }
    }
  }
  helpdoc node_define  simconfig $name $info
}

###
# topic: d0c831f0-0c3a-ccc2-dac2-71419ba032ac
###
proc ::irm::specUsedBy {term type name} {
  set term [string trim $term]
  set field [string trimright $type s]s
  
  set eoclist {}
  #foreach t $term {
  #  lappend eoclist {*}[canonical spec $t]
  #}
  #if {![llength $eoclist]} {
  #  set eoclist [string tolower $term]
  #}
  foreach eoc $eoclist {
    ::helpdoc node_property_lappend [::helpdoc node_id [list spec $term]] $field $name
    ::helpdoc node_property_lappend [::helpdoc node_id [list $type $name]] specs $eoc
  }
}

###
# topic: 57343680-c66e-0427-ac2c-217bff50a365
###
tao::class tao.yggdrasil {

}

###
# topic: f23ed533-b611-577b-391c-1cdde4de4f2d
# description:
#    Define commands used by the scripts to interact
#    with the C modules and datastructures
###
namespace eval ::irm {
variable canonical_name
  if {![info exists canonical_name]} {
    set canonical_name {}
  }
  variable docInfo
  if {![info exists docInfo]} {
    set docInfo {}
  }
}

