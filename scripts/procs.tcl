###
# SBIR DATA RIGHTS
# Contract No.: N00024-11-C-4120
# Contractor Name: Test & Evaluation Solutions, LLC
# Contractor Address: 400 Holiday CT, STE 204, Warrenton, VA 20186
#
# Expiration of SBIR Data Rights Period: 22 May 2017
#   The Government's rights to use, modify, reproduce, release, perform,
#   display, or disclose technical data or computer software marked with
#   this legend are restricted during the period shown as provided in
#   paragraph (b)(4) of the Rights in Noncommercial Technical Data and
#   Computer Software--Small Business Innovative Research (SBIR) Program
#   clause contained in the above identified contract. No restrictions
#   apply after the expiration date shown above. Any reproduction of
#   technical data, computer software, or portions thereof marked with
#   this legend must also reproduce the markings.
#
# Distribution Statement B: Distribution authorized to U.S. Government
# agencies only; (DFARS - SBIR Data Rights); 22 November 2010. Other
# requests for this document shall be referred to Naval Sea Systems
# Command ATTN: Small Business Innovation Research Program Office
# SEA05T1R, 1333 Isaac Hull Ave SE, Washington Navy Yard, DC 20376.
###

###
# This file is loaded as part of the library initialization
###

package require msgcat
package require sqlite3
source [file join [file dirname [file normalize [info script]]] .. plugin odie index.tcl]

###
# namespace: irm
# desc:
#    Define commands used by the scripts to interact
#    with the C modules and datastructures
###
namespace eval ::irm {

}

###
# proc: irm::_link_detect_address args
# title: Detect what type of link
# desc:
###
proc ::irm::_link_detect_address args {
  set args [string tolower $args]
  if {[::irm::nodeExists $args entryid]} {
    return [helpdoc eval {select address from entry where entryid=$entryid}]
  }
  ###
  # If the link contains a / we know it is a hard
  # path
  ###
  if {[llength $args] > 1} {
    set rootentries [helpdoc eval {select title from entry where parent=0 or class='section'}]
    if {[lindex $args 0] in $rootentries} {
      set type [lindex $args 0]
      set name [lindex $args 1]
      return [list $type/[irm::canonical $type $name]]
    }
    if {[lindex $args 1] in $rootentries} {
      set type [lindex $args 1]
      set name [lindex $args 0]
      return [list $type/[irm::canonical $type $name]]
    }
  }
  set addr [lindex $args 0]

  if {[string first / $addr] > 0 } {
    return $addr
  }
  set candidates [helpdoc eval {select address from entry where title like $addr}]
  foreach address $candidates {
    if {[regexp simnode $address]} {
      return $address
    }
  }
  set cnames [helpdoc eval {select class,cname from aliases where alias=$addr}]

  if {[llength $cnames] == 2} {
    return [join $cnames /]
  }

  return [lindex $candidates 0]
}

###
# proc: irm::_link_map entryid args
# desc:
#    Given the name of an spec, state variable, port, or a behavior
#    return that name contained within an HTML hyperlink to the description
#    of the spec, state, port, or behavior.
###
proc ::irm::_link_map {entryid class args} {
  set refaddr [_link_detect_address {*}$args]
  buildLink $entryid $refaddr $class
  return $refaddr
}

###
# proc: irm::addrAlloc address
# desc:
###
proc ::irm::addrAlloc address {
  set address [string tolower $address]
  set row [entryidByAddress $address]
  if {[string is integer -strict $row]} {
    return $row
  }
  if { [string index $address end] eq "/" } {
    append address global
    set row [entryidByAddress $address]
    if {[string is integer -strict $row]} {
      return $row
    }
  }
  set path [split $address /]
  if {[llength $path] < 2 } {
    set parent 0
  } else {
    set paddress [join [lrange $path 0 end-1] /]
    set parent [addrAlloc $paddress]
  }
  set title [lindex $path end]
  set row [::irm::nodeAllocChild $parent $title]
  helpdoc eval {update entry set address=$address where entryid=$row}
  return $row
}

###
# proc: irm::behaviorId name
# desc:
###
proc ::irm::behaviorId name {
      variable behavior_name_to_idx
      return $behavior_name_to_idx([string toupper $name])
  }

###
# proc: irm::behaviorList 
# desc:
###
proc ::irm::behaviorList {} {
  variable behavior_name_to_idx
  return [lsort -dictionary [array names behavior_name_to_idx]]
}

###
# proc: irm::behaviorName id
# desc:
###
proc ::irm::behaviorName id {
  variable behavior_idx_to_name
  set id [expr {int($id)}]
  return [string toupper $behavior_idx_to_name($id)]
}

###
# proc: irm::behaviorSet 
# desc:
###
proc ::irm::behaviorSet {} {
  variable behavior_idx_to_name
  return [lsort -integer -stride 2 [array get behavior_idx_to_name]]
}

###
# proc: irm::buildLink entry refaddr {type {}}
# desc:
###
proc ::irm::buildLink {entry refaddr {type {}}} {
  if { $entry in {{} 0 -1} } {
      return
  }
  set entryid   [entryidByAddress $entry]
  set to        [entryidByAddress $refaddr]
  if { $entryid eq {} || $to eq {} } {
    return
  }
  if { $type eq {} } {
    set exists [helpdoc one {select count(entry) from link where entry=$entryid and refentry=$to}]
    if {!$exists} {
      helpdoc eval {insert or replace into link (entry,refentry) VALUES ($entryid,$to)}
    }
  } else {
    set exists [helpdoc one {select count(entry) from link where entry=$entryid and refentry=$to and linktype=$type}]
    if {!$exists} {
      helpdoc eval {insert or replace into link (entry,refentry,linktype) VALUES ($entryid,$to,$type)}
    } 
  }
}

###
# proc: irm::canonical type name
# desc:
###
proc ::irm::canonical {type name} {
  variable canonical_name
  set name [string tolower $name]
  if { $type in { {} * any } } {
    set type [dict keys $canonical_name]
  }
  foreach t $type {
    if {[dict exists $canonical_name $t $name]} {
      return [dict get $canonical_name $t $name]
    }
  }
  return
}

###
# proc: irm::canonical_aliases type name
# desc:
###
proc ::irm::canonical_aliases {type name} {
  variable canonical_name
  set result {}
  foreach {alias cname} [dictGet $canonical_name $type] {
    if { $cname eq $name && $alias ne $name } {
      lappend result $alias
    }
  }
  return $result
}

###
# proc: irm::canonical_set type name cname
# desc:
###
proc ::irm::canonical_set {type name cname} {
  set class [string tolower $type]
  set name [string tolower $name]
  set cname [string tolower $cname] 
  variable canonical_name
  dict set canonical_name $class $name $cname
  set address $type/$name
  helpdoc eval {replace into aliases (class,alias,cname) VALUES ($class,$name,$cname)}
}

###
# proc: irm::cookie_set 
# desc:
###
proc ::irm::cookie_set {} {
  variable cookie_set
  return $cookie_set
}

###
# proc: irm::cookieId name
# desc:
###
proc ::irm::cookieId name {
  variable cookie_name_to_idx
  return $cookie_name_to_idx($name)
}

###
# proc: irm::dealias type name
# desc:
###
proc ::irm::dealias {type name} {
  variable canonical_name
  set name [string tolower $name]

  foreach t $type {
    if {[dict exists $canonical_name $t $name]} {
      return [dict get $canonical_name $t $name]
    }
  }
  return $name
}

###
# proc: irm::docDefine type entry properties
# desc:
###
proc ::irm::docDefine {type entry properties} {
  variable canonical
  set type  [string tolower $type]
  set entry [string tolower $entry]
  set typeid [::irm::nodeAllocChild 0 $type]
  canonical_set $type $entry $entry
  set info [::irm::nodeGet $typeid template]
  foreach {field val} $properties {
    dict set info $field $val
  }
  set entryid [::irm::nodeAllocChild $typeid $entry $type]
  set address $type/$entry
  helpdoc eval {update entry set address=$address,class=$type where entryid=$entryid}
  ::irm::nodePut $entryid $info
  
  docIndex $type $entry
  return $entryid
}

###
# proc: irm::docDump file
# desc:
#    Write out everything in this file
#    such that we can reconstruct our total state
#    later
###
proc ::irm::docDump file {
  set fout [open $file w]
  puts $fout "set ::irm_version $::irm_version"

  puts "... Indexing Helptext ..."
  helpdoc eval {delete from link}
  helpdoc eval {update entry set indexed=0}
  ::irm::indexAll
  puts "... Done ... Building Dumpfile ... $file"
  puts $fout {
sqlite3 helpdoc :memory:
helpdoc eval [::irm::helpdocSchema]
}
  ###
  # Write an sqlite file
  ###
  #exec sqlite3 $::irmRoot/build/simdoc.sqlite .dump > [file rootname $file].sql
  #puts $fout "helpdoc eval \{"
  #set fin [open [file rootname $file].sql r]
  #puts $fout [read $fin]
  #close $fin
  #puts $fout "\}"
  
  ###
  # Serialize nodes
  ###
  helpdoc eval {
    select entryid from entry
    order by class,title
  } {
    puts $fout [nodeSerialize $entryid]
  }

  ###
  # Signal that everything is indexed
  ###
  puts $fout {helpdoc eval {update entry set indexed=1}}

  ###
  # Reconstruct the canonical table
  ###
  variable canonical_name
  helpdoc eval {select class,alias,cname from aliases order by class,cname,alias} {
    puts $fout [list dict set ::irm::canonical_name $class $alias $cname]
  }
  ###
  # Generate indexes
  ###
  helpdoc eval {select class,id,name from idset} {
    puts $fout [list set ::irm::${class}_name_to_idx($name) $id]
    puts $fout [list set ::irm::${class}_idx_to_name($id) $name]
  }

  puts $fout irm::indexAll
  close $fout
}

###
# proc: irm::docEmpty type
# desc:
###
proc ::irm::docEmpty type {
  return [::irm::nodeGet $type template]
}

###
# proc: irm::docEntries type
# desc:
###
proc ::irm::docEntries type {
  set result {}
  helpdoc eval {select entryid,title from entry where class=$type order by title} {
    lappend result $title [entryProps $entryid]
  }
  return $result
}

###
# proc: irm::docIndex type entry
# desc:
###
proc ::irm::docIndex {type entry} {
  variable typeList
  ladd_sorted typeList($type) $entry
  
  switch $type {
    spec {
      variable specIndex
      variable spec_macro
      
      set info [::irm::nodeGet [list spec $entry]]
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
      ::irm::nodePut [list spec $entry] $new
    }
  }
}

###
# proc: irm::docList type
# desc:
###
proc ::irm::docList type {
  return [lsort -dictionary [helpdoc eval {select title from entry where class=$type}]]
}

###
# proc: irm::docReferencesFrom entryid
# desc: Locate all references to a doc entry
###
proc ::irm::docReferencesFrom entryid {
  set result {}
  helpdoc eval {
    select refentry from link where entry=$entryid
  } {
    helpdoc eval {
      select address from entry where entryid=$refentry
    } {
      lappend result $address
    }
  }
  return $result
}

###
# proc: irm::docReferencesTo entryid
# desc: Locate all references to a doc entry
###
proc ::irm::docReferencesTo entryid {
  return [helpdoc eval {select entry.address from entry,link where
    link.refentry=$entryid
    and entry.entryid=link.entry
  }]
}

###
# proc: irm::entryChildren entryid
# desc:
###
proc ::irm::entryChildren entryid {
  set result {}
  return [helpdoc eval {select entryid,class,title from entry where parent=$entryid order by class,title}]
}

###
# proc: irm::entryDefine address title {properties {}}
# desc:
###
proc ::irm::entryDefine {address title {properties {}}} {
  set entryid [addrAlloc $address]
  set result {}
  set indexed 0
  helpdoc eval {update entry set title=$title where entryid=$entryid}
  foreach {field value} $properties {
    switch $field {

      comment {
        set value [string trim [dict get $properties $field]]
        if { $value ne {} } {
          helpdoc eval {update entry set comment=$value where entryid=$entryid}
        }
        dict unset properties $field
      }
      entry -
      ruletext -
      ruletxt -
      description -
      desc {
        if {[dict exists $properties $field]} {
          set value [string trim [dict get $properties $field]]
          if { $value ne {} } {
          }
          dict unset properties $field
        }
      }
  
      default {
        lappend result $var $value
      }
    }
  }

  foreach {field var} $properties {
    helpdoc eval {replace into property (entryid,field,value) VALUES ($entryid,$field,$var)}
  }
  return $entryid
}

###
# proc: irm::entryFollowLinks entryid description
# title: Follow the links in a rule and cross link the entry in the database
# desc:
###
proc ::irm::entryFollowLinks {entryid class description} {
  set olddesc $description
  if {![regsub -all {\[} $description "\[_link_map $entryid $class " description]} return  
  if [catch {subst $description} err] {
    puts "Warning: \"$err\" while reading\n[nodeAddress $entryid]\n$description"
  }
}

proc ::irm::entryFollowList {atype aidlist btype bidlist} {
  foreach aid $aidlist {
    if {![string is integer $aid]} {
      if {![irm::nodeExists $aid anode]} continue
    } else {
      set anode $aid
    }
    foreach bid $bidlist {
      if {![string is integer $bid]} {
        if {![irm::nodeExists $bid bnode]} continue
      } else {
        set bnode $bid
      }
      ::irm::buildLink $anode $bnode $atype
    }
  }
}

###
# proc: irm::entryidByAddress address
# desc:
###
proc ::irm::entryidByAddress address {
  if {[string is integer $address]} {
    return $address
  }
  if {[::irm::nodeExists $address entryid]} {
    return $entryid
  }
  set address [string tolower $address]
  if { [string tolower $address] in {:: / {} home} } {
    return 0
  }
  return [helpdoc one {select entryid from entry where address=$address}]
}

###
# proc: irm::entryProps entryid
# desc:
###
proc ::irm::entryProps entryid {
  return [helpdoc eval {select field,value from property where entryid=$entryid}]
}

###
# proc: irm::enum_dump type
# desc:
###
proc ::irm::enum_dump type {
  return [lsort -integer -stride 2 [array get ::irm::${type}_idx_to_name]]
}

###
# proc: irm::enum_id type name
# desc:
###
proc ::irm::enum_id {type name} {
  set arr ::irm::${type}_name_to_idx
  set cname [canonical $type $name]
  if {![info exists ${arr}($cname)]} {
    error "Invalid $type $name"
  }
  return [set ${arr}($cname)]
}

###
# proc: irm::enum_name type id
# desc:
###
proc ::irm::enum_name {type id} {
  set arr ::irm::${type}_idx_to_name
  return [set ${arr}($id)]
}

###
# proc: irm::enum_put class title id
# desc:
###
proc ::irm::enum_put {class title id} {
  array set ::irm::${class}_name_to_idx [list $title $id]
  array set ::irm::${class}_idx_to_name [list $id $title]
  helpdoc eval {insert or replace into idset (class,id,name) VALUES ($class,$id,$title)}
}

###
# proc: irm::eocDefine name properties
# desc:
###
proc ::irm::eocDefine {name properties} {
  docDefine spec $name $properties
}

###
# proc: irm::helpdocSchema 
# desc:
###
proc ::irm::helpdocSchema {} {
  return {
    create table if not exists entry (
      entryid integer PRIMARY KEY,
      indexed integer default 0,
      parent integer references entry (entryid),
      class string,
      address string,
      title string,
      unique (address)
    );

    create table if not exists property (
      entryid integer,
      field string,
      value string,
      primary key (entryid,field)
    );
    
    create table if not exists link (
      linktype string,
      entry integer references entry (address),
      refentry integer references entry (address)
    );
    create table if not exists idset (
      class string,
      id    integer,
      name  string,
      primary key (class,id)
    );
    create table if not exists aliases (
      class string,
      alias string,
      cname string references entry (title),
      primary key (class,alias)
    );
  }
}

###
# proc: irm::helpdocSchemaIndex 
# desc:
###
proc ::irm::helpdocSchemaIndex {} {
  return  {
    create index if not exists addridx on entry (entryid,address);
    create index if not exists titleidx on entry (entryid,title);
    create index if not exists parentidx on entry (parent,entryid);
    create index if not exists propidx on property (entryid,field);
  }
}

###
# proc: irm::indexAll 
# desc:
###
proc ::irm::indexAll {} {



  variable mitl_specs {}
  foreach {name value} [::irm::docEntries spec] {
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
  variable non_auto_algs {}
  foreach alg {ABT BREAKER FIRESENSOR FITTING LOOPCONTROL MBT NOZZLE REMOTEOP SLAVEVALVE VALVE XCONNECT} {
    lappend non_auto_algs [::irm::enum_id behavior $alg]
  }
  
  variable cookie_set
  foreach {cookie info} [docEntries cookie] {
    dict with info {
      dict set cookie_set $value $cookie
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
  helpdoc eval [::irm::helpdocSchemaIndex]
}

###
# proc: irm::localconfigDefine name parameters
# desc:
#    The following table lists the available configuration parameters
#    together with some of their properties.
###
proc ::irm::localconfigDefine {name parameters} {
  set info [irm::docEmpty simconfig]
  dict set info label [string tolower $name]
  dict set info save  prefs
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
  docDefine simconfig $name $info
}

###
# proc: irm::nodeAddress entryid
# desc:
###
proc ::irm::nodeAddress entryid {
  helpdoc eval {select address,class,title from entry where entryid=$entryid} {
    if { $address ne {} } {
      return $address
    }
    if { $class ne {} } {
      return $class/$title
    }
    error "Node $entryid has no address"
    return {}
  }
  error "Invalid node $entryid"
}

###
# proc: irm::nodeAddToField entryid field args
# desc: nodeid is any value acceptable to {[::irm::nodeAlloc]}
###
proc ::irm::nodeAddToField {entryid field args} {
  if {![llength $args]} return
  set dbvalue [helpdoc eval {select value from property where entryid=$entryid and field=$field}]
  foreach value $args {
    if { $value eq {} } continue
    ladd_sorted dbvalue $value
  }
  helpdoc eval {update property set value=$dbvalue where entryid=$entryid and field=$field}
}

###
# proc: irm::nodeAlloc args
# desc:
###
proc ::irm::nodeAlloc args {
  set args [string tolower $args]
  if {[llength $args] == 2} {
    set type [lindex $args 0]
    set entry [::irm::canonical $type [lindex $args 1]]
    if { $type eq {} && $entry in {home root} } {
      return 0
    }
    set row [helpdoc one {select entryid from entry where class=$type and title=$entry}]
    if { $row ne {} } {
      return $row
    }
    set parent [::irm::nodeAlloc $type]
    set row [::irm::nodeAllocChild $parent $entry]
    set address $type/$entry
    if [catch {
      helpdoc eval {update entry set address=$address,class=$type where entryid=$row}
    } err] {
      puts [list Couldn't build $args $address : $err]
      error [list Couldn't build $args $address : $err]
    }
    return $row
  }
  ###
  # For longer addresses, nest
  ###
  set parent 0
  foreach entry [string tolower $args] {
    if {[string is integer $entry]} {
      set row $entry
    } else {
      set row [::irm::nodeAllocChild $parent $entry]
    }
    set parent $row
  }
  return $row
}

###
# proc: irm::nodeAllocChild parent entry {class {}}
# desc:
###
proc ::irm::nodeAllocChild {parent entry {class {}}} {
  set entry [string tolower $entry]
  if { $class ne {} } {
    set row [helpdoc one {select entryid from entry where parent=$parent and class=$class and title=$entry}]    
  } else {
    set row [helpdoc one {select entryid from entry where parent=$parent and title=$entry}]    
  }
  if {[string is integer $row] && $row > 0 && $row != $parent } {
    return $row
  }
  set row [helpdoc one {select max(entryid)+1 from entry}]
  if { $class ne {} } {
    helpdoc eval {insert into entry (entryid,parent,class,title) VALUES ($row,$parent,$class,$entry)}    
  } else {
    helpdoc eval {insert into entry (entryid,parent,title) VALUES ($row,$parent,$entry)}
  }
  return $row
}

###
# proc: irm::nodeChildDefine entryid class branch properties
# desc:
###
proc ::irm::nodeChildDefine {entryid class branch properties} {
  set branchid [::irm::nodeAllocChild $entryid $branch $class]
  set branchaddr [nodeAddress $entryid].$class/$branch
  helpdoc eval {update entry set address=$branchaddr, class=$class where entryid=$branchid}
  foreach {var val} $properties {
    if [catch {nodePutField $branchid $var $val} err] {
      puts "WARNING, error setting $var to $val in $branchaddr: $err"
    }
  }
  return $branchid
}

###
# proc: irm::nodeChildren nodeid class
# desc:
#    Return a list of all children of node,
#    Filter is a key/value list that understands
#    the following:
#    type - Limit children to type
#    dump - Output the contents of the child node, not their id
###
proc ::irm::nodeChildren {nodeid class} {
  set dump 1
  set entryid [::irm::nodeId $nodeid]
  if { $class eq {} } {
    set nodes [helpdoc eval {select title,entryid from entry where parent=$entryid}]
  } else {
    set nodes [helpdoc eval {select title,entryid from entry where parent=$entryid and class=$class}]
  }
  if {!$dump} {
    return $nodes
  }
  set result {}
  foreach {cname cid} $nodes {
    dict set result $cname [helpdoc eval {select field,value from property where entryid=$cid order by field}]
  }
  return $result
}

###
# proc: irm::nodeExists node {resultvar {}}
# desc:
###
proc ::irm::nodeExists {node {resultvar {}}} {
  set parent 0
  if { $resultvar != {} } {
    upvar 1 $resultvar row
  }
  foreach entry [string tolower $node] {
    if {[string is integer $entry]} {
      set row [helpdoc one {select entryid from entry where entryid=$entry}]
    } else {
      set row [helpdoc one {select entryid from entry where parent=$parent and title=$entry}]
    }
    if { $row eq {} } {
      return 0
    }
    set parent $row
  }
  return 1
}

###
# proc: irm::nodeFieldAppend nodeid field text
# desc:
###
proc ::irm::nodeFieldAppend {nodeid field text} {
  set buffer [helpdoc one {select value from property where entryid=$nodeid and field=$field}]
  append buffer " " [string trim $text]

  ::irm::nodePut $nodeid $field $buffer
}

###
# proc: irm::nodeGet nodeid {field {}}
# desc: nodeid is any form acceptable to {[::irm::nodeId]}
###
proc ::irm::nodeGet {nodeid {field {}}} {
  set result {}
  if {[::irm::nodeExists $nodeid entryid]} {
    set result [entryProps $entryid]
  } else {
    if {[llength $nodeid] > 1} {
      set type [lindex $nodeid 0]
      set result [::irm::nodeGet $type template]
    }
  }
  
  if { $field eq {} } {
    return $result    
  }
  return [dictGet $result $field]
}

###
# proc: irm::nodeId node {create 0}
# desc:
###
proc ::irm::nodeId {node {create 0}} {
  set parent 0
  if {[string is integer -strict $node]} {
    return $node
  }
  foreach entry [string tolower $node] {
    if {[string is integer $entry]} {
      set row [helpdoc one {select entryid from entry where parent=$parent and entryid=$entry}]
    } else {
      set row [helpdoc one {select entryid from entry where parent=$parent and title=$entry}]
    }
    if { $row eq {} } {
      if { $create } {
        set row [::irm::nodeAllocChild $parent $entry]
      } else {
        error "Node $node does not exist"
      }
    }
    set parent $row
  }
  return $row
}

###
# proc: irm::nodeName entryid
# desc:
###
proc ::irm::nodeName entryid {
  return [helpdoc one {select title from entry where entryid=$entryid}]
}

###
# proc: irm::nodePut node args
# desc: nodeid is any value acceptable to {[::irm::nodeAlloc]}
###
proc ::irm::nodePut {node args} {
  #variable docInfo
  set entryid [::irm::nodeId $node 1]
  if {[llength $args] == 2} {
    nodePutField $entryid {*}$args
    return
  }
  ###
  # Build a dict of properties to be inserted
  ###
  set result {}
  foreach {var val} [lindex $args 0] {
    nodePutField $entryid $var $val
  }
  return $entryid
}

###
# proc: irm::nodePutField entryid field value
# desc: nodeid is any value acceptable to {[::irm::nodeAlloc]}
###
proc ::irm::nodePutField {entryid field value} {
  switch $field {
      fields -
      methods {
        set field [string trimright $field s]
        foreach {branch binfo} $value {
          ::irm::nodeChildDefine $entryid $field $branch $binfo
        }
        return
      }
      aliases {
        helpdoc eval {select class,title from entry where entryid=$entryid} {
          foreach v $value {
            canonical_set $class $v $title
          }
        }
        return
      }
      algorithm {
        set field behavior
      }
      desc -
      description -
      entry -
      ruletxt -
      ruletext {
        set field description
        set value [string trim $value]
      }
      note -
      notes -
      comment -
      comments {
        set field comment
        set value [string trim $value]
      }
      enumid {
        enum_put [lindex $value 0] $title [lindex $value 1]
      }
      id {
        helpdoc eval {select class,title from entry where entryid=$entryid} {
          enum_put $class $title $value
        }
      }
      algorithms {
        set field behaviors
        set value [string tolower [lsort -dictionary -unique $value]] 
      }
      behaviors -
      ports -
      specs -
      exclusive-to-behavior -
      intended-ports -
      required-ports {
        set value [string tolower [lsort -dictionary -unique $value]]
      }
      context -
      references {
        foreach {refid reftype} $value {
          buildLink $entryid $refid $reftype
        }
      }
      unit -
      units {
        set field units
      }
  }
  helpdoc eval {insert or replace into property (entryid,field,value) VALUES ($entryid,$field,$value)}
}

###
# proc: irm::nodeRestore nodeid info
# desc:
###
proc ::irm::nodeRestore {nodeid info} {
  set stmt "update entry "
  set stmtl {}
  dict with info {}
  set fields entryid
  set _entryid $nodeid
  set values "\$_entryid"
  foreach {field value} $info {
    if { $field ni {parent class address title} } continue
    lappend fields $field
    lappend values "\$_$field"
    set _$field $value
  }
  helpdoc eval "insert or replace into entry ([join $fields ,]) VALUES ([join $values ,]);"

  foreach {field value} $info {
    switch $field {
      properties {
        ::irm::nodePut $nodeid $value
      }
      references {
        foreach {refid reftype} $references {
          ::irm::buildLink $nodeid $refid $reftype
        }
      }
      enumid {
        ::irm::enum_put [lindex $value 0] [dict get $info title] [lindex $value 1]
      }
      aliases {
        foreach a $value {
          ::irm::canonical_set $_class $a $_title
        }
      }
    }
  }
}

###
# proc: irm::nodeSerialize nodeid
# desc:
###
proc ::irm::nodeSerialize nodeid {
  set result {}
  helpdoc eval {
    select * from entry
    where entryid=$nodeid
  } record {
    set entryid $record(entryid)
    append result "[list ::irm::nodeRestore $nodeid] \{" \n
    
    foreach {field value} [array get record] {
      if { $field in {* entryid indexed export} } continue
      append result "  [list $field $value]" \n
    }
    set class $record(this_class)

    if {[info exists ::irm::${class}_name_to_idx]} {
      set id [lindex [array get ::irm::${class}_name_to_idx $record(title)] 1]
      if { $id ne {} } {
        append result "  [list enumid [list $class $id]]" \n
      }
    }
    
    append result "  properties \{" \n
    if {[string is integer -strict $record(parent)]} {
      set empty [::irm::nodeGet $record(parent) template]
    } else {
      set empty {}
    }
    set info [entryProps $nodeid]
    foreach {var val} [lsort -stride 2 -dictionary $info] {
      if { $var in {aliases field method fields methods references id} } continue
      if { $empty eq {} } {
        if { $val eq {} } continue
      } elseif {[dictGet $empty $var] eq $val } continue

      append result "    [list $var [string trim $val]]" \n
    }
    append result "  \}" \n
    set references [helpdoc eval {select refentry,linktype from link where entry=$entryid}]
    if {[llength $references]} {
      append result "  [list references $references]" \n
    }
    set aliases [::irm::canonical_aliases $record(this_class) $record(title)]
    if {[llength $aliases]} {
      append result "  [list aliases $aliases]" \n
    }

    append result "\}"
  }
  return $result
}

###
# proc: irm::sectionDefine section parameters
# desc:
#    Marks up a "section" stub under the root
#    node with human friendly text
###
proc ::irm::sectionDefine {section parameters} {
  set info [irm::docEmpty section]
  set section [string tolower $section]
  dict set info title [string tolower $section]
  dict set info template {
    aliases {}
  }
  foreach {field val} $parameters {
    dict set info $field $val
  }
  set entryid [::irm::nodeAllocChild 0 $section]
  ::irm::nodePut $entryid $info
  helpdoc eval {update entry set address=$section where entryid=$entryid}
  return $entryid
}

###
# proc: irm::simconfigDefine name parameters
# desc:
#    The following table lists the available configuration parameters
#    together with some of their properties.
###
proc ::irm::simconfigDefine {name parameters} {
  set info [irm::docEmpty simconfig]
  dict set info label [string tolower $name]
  dict set info save  readi
  foreach {var val} $parameters {
    switch $var {
      local {
        if {$val} {
          dict set info save prefs
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
  docDefine simconfig $name $info
}

###
# proc: irm::specUsedBy term type name
# desc:
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
    ::irm::nodeAddToField [::irm::nodeId [list spec $term]] $field $name
    ::irm::nodeAddToField [::irm::nodeId [list $type $name]] specs $eoc
  }
}

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

foreach type {
  behavior
  cookie
  port
  rule
  spec
  system
  tclcmd
} {
  proc ::irm::${type}Define {name info} "docDefine $type \$name \$info"
}
