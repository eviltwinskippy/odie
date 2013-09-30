###
# Structure that manages an interactive help system
###
package provide ::tao::helpdoc 0.1

###
# topic: 5e9545ad-053c-57e5-9667-02451c88fb57
###
tao::class tao.yggdrasil {
  superclass moac.sqliteDb
  property create_sql {
    create table if not exists entry (
      entryid string default (uuid_generate()),
      indexed integer default 0,
      parent integer references entry (entryid),
      class string,
      name string,
      mtime integer,
      primary key (entryid)
    );
    create table if not exists property (
      entryid    string references entry (entryid),
      field      string,
      value      string,
      primary key (entryid,field)
    );
    create table if not exists link (
      linktype string,
      entry integer references entry (entryid),
      refentry integer references entry (entryid)
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
      cname string references entry (name),
      primary key (class,alias)
    );
    create table if not exists repository (
      handle string,
      localpath string,
      primary key (handle)
    );
    create table if not exists file (
      fileid         string default (uuid_generate()),
      repo           string references repository (handle),
      path           string,  --path relative to repo
      localpath      string,  --cached path to local file
      filename       string,  --filename
      content_type   string,  --Content/Type of file
      package        string,  --Name of any packages provided,
      size           integer, --File size in bytes
      mtime          integer, --mtime in unix time
      hash           string,   --md5 hash of file
      primary key (fileid)
    );
    create table if not exists filelink (
      linktype string,
      entryid integer references entry (entryid),
      fileid integer references file   (fileid)
    )
  }
  property create_index_sql {
    create index if not exists nameidx on entry (entryid,name);
    create index if not exists parentidx on entry (parent,entryid);
  }
  
  constructor filename {
    package require sqlite3
    
    if [catch {
      my Database attach $filename
      ###
      # Allow up to 2 seconds of
      # slack time for another process to
      # write to the database
      ###
      my <db> timeout 2000
    }] {
      puts "Falling back to temporary storage"
      my Database attach {}
    }
    return 0
  }

  ###
  # topic: 748eb6da-9fba-101c-b557-71bdb63b115a
  ###
  method alias_list class {
    return [my <db> eval {select alias,cname from aliases where class=:class order by cname,alias}]
  }

  ###
  # topic: 76dcac71-e9c3-19f1-f9e9-a38c2348f651
  ###
  method canonical {class name} {
    set name [string tolower $name]
    if { $class in {{} * any}} {
      return [my <db> eval {select distinct class from aliases order by class}]
    }
    if { $name in {{} * any}} {
      return [my <db> eval {select alias,cname from aliases where class=:class order by cname,alias}]
    }
    set rows [my <db> eval {select entryid from entry where class=:class and name=:name}]
    if {[llength $rows] == 1} {
      return $name
    }
    if {[my <db> exists {select cname from aliases where class=:class and (alias=:name or cname=:name)}]} {
      return [my <db> one {select cname from aliases where class=:class and (alias=:name or cname=:name) limit 1}]
    }
  }

  ###
  # topic: 363b648c-bc73-45d4-6d41-316d91c32c86
  ###
  method canonical_aliases {class name} {
    set name [string tolower $name]
    return [my <db> eval {select distinct alias from aliases where class=:class and cname=:name and alias!=:name}]
  }

  ###
  # topic: 751d50a0-c4ee-d66c-6e6e-4f30a3d12e74
  ###
  method canonical_id {class name} {
    return [my <db> eval {select id from idset where class=:class and name=:name}]
  }

  ###
  # topic: bd6a8a6d-38f1-2a03-80e6-334704db0028
  ###
  method canonical_set {type name cname} {
    set class [string tolower $type]
    set name [string tolower $name]
    set cname [string tolower $cname] 
    variable canonical_name
    dict set canonical_name $class $name $cname
    set address $type/$name
    my <db> eval {replace into aliases (class,alias,cname) VALUES ($class,$name,$cname)}
  }

  ###
  # topic: ddf550f9-b4bf-4678-f0de-dcb270af2c57
  ###
  method class_list class {
    return [lsort -dictionary [my <db> eval {select name from entry where class=:class}]]
  }

  ###
  # topic: f91703a2-c625-8700-7476-b159fc2bcabc
  ###
  method class_nodes class {
    set result {}
    foreach {entryid name} [my <db> eval {select entryid,name from entry where class=:class order by name}] {
      lappend result $name [my node_properties $entryid]
    }
    return $result
  }

  ###
  # topic: 9515a95d-6a40-311a-3f84-e58d44d43ccc
  ###
  method Database::create {} {
    my <db> eval [my property create_sql]
  }

  ###
  # topic: eaa352f6-4e6d-dbbd-d325-62c8827aaed3
  ###
  method Database::functions {} {
    my <db> function uuid_generate ::tao::uuid_generate
  }

  ###
  # topic: cdf510c2-89e7-2b34-f033-50d16aa6cb9b
  ###
  method enum_dump class {
    return [my <db> eval {select id,name from idset where class=:class order by id}]
  }

  ###
  # topic: e7cd2ac8-99ee-d3bf-0203-31380a47457e
  ###
  method enum_id {class name} {
    set arr ::irm::${class}_name_to_idx
    if {![info exists $arr]} {
      my <db> eval {select name as aname,id as aid from idset where class=:class} {
        set ${arr}($aname) $aid
      }
    }
    set cname [my canonical $class $name]
    if {![info exists ${arr}($cname)]} {
      error "Invalid $class $name"
    }
    return [set ${arr}($cname)]
  }

  ###
  # topic: 73e7b188-eb44-0f00-e627-330a699bdb81
  ###
  method enum_name {class id} {
    return [my <db> one {select name from idset where class=:class and id=:id}]
  }

  ###
  # topic: 11a3fc70-7870-4607-a9c8-ee86fcccf8c7
  ###
  method enum_set {class name id} {
    set class [string tolower $class]
    set name [string tolower $name]
    set ::irm::${class}_name_to_idx($name) $id
    set ::irm::${class}_idx_to_name($id) $name
    my <db> eval {insert or replace into idset (class,id,name) VALUES ($class,$id,$name)}
  }

  ###
  # topic: 37f93c5c-86aa-bca5-9cfd-9aebe24b2918
  ###
  method file_hash {fileid {newhash {}}} {
    set fileid [my file_id $fileid]
    if {$fileid ne {}} {
      return [my <db> one {select hash from file where fileid=:fileid}]
    }
    return {}
  }

  ###
  # topic: f9b5c275-51df-5b39-d675-10ca4864cead
  ###
  method file_id {addr {create 0}} {
    if {[string is integer $addr]} {
      return $addr
    }
    if {[my <db> exists {select fileid from file where hash=:addr}]} {
      return [my <db> one {select fileid from file where hash=:addr}]
    }
    if {[llength $addr]==2} {
      set repo [lindex $addr 0]
      set path [lindex $addr 1]
      if {[my <db> exists {select fileid from file where repo=:repo and path=:path}]} {
        return [my <db> one {select fileid from file where repo=:repo and path=:path}]
      }
    }
    if {[my <db> exists {select fileid from file where path=:addr}]} {
      return [my <db> one {select fileid from file where path=:addr}]
    }
    if {[my <db> exists {select fileid from file where localpath=:addr}]} {
      return [my <db> one {select fileid from file where localpath=:addr}]
    }
    return {}
  }

  ###
  # topic: 665da067-d194-594e-c376-dbbdf755de56
  ###
  method file_restore {nodeid info} {
    set stmtl {}
    dict with info {}
    if {[string is integer $nodeid]} {
      set _fileid $nodeid
    } else {
      set _fileid [my file_id $nodeid]
      if {$_fileid eq {}} {
        set _fileid {}
      }
    }
    if {$_fileid ne {}} {
      set fields fileid
      set values "\$_fileid"
    } else {
      set fields {}
      set values {}
    }
    foreach {field value} $info {
      switch $field {
        repo -
        path -
        localpath -
        filename -
        content_type -
        package -
        size -
        mtime -
        hash {
          if { $value ne {} } {
            lappend fields $field
            lappend values :_$field
            set _$field $value
          }
        }
      }
    }
    my <db> eval "insert or replace into file ([join $fields ,]) VALUES ([join $values ,]);"
  }

  ###
  # topic: bd67546a-0b2b-26ae-40f8-c901e01afed0
  ###
  method file_serialize nodeid {
    set result {}
    my <db> eval {
      select * from file
      where fileid=$nodeid
    } record {
      set fileid $record(fileid)
      append result "[list [self] file_restore [list $record(repo) $record(path)]] \{" \n
      
      foreach {field value} [array get record] {
        if { $field in {* fileid indexed export} } continue
        append result "  [list $field $value]" \n
      }
      append result "\}"
    }
    return $result
  }

  ###
  # topic: 84e7a227-9f4f-2dfa-4052-46eed99925fb
  ###
  method link_create {entryid to {type {}}} {
    if { $type eq {} } {
      set exists [my one {select count(entry) from link where entry=$entryid and refentry=$to}]
      if {!$exists} {
        my <db> eval {insert or replace into link (entry,refentry) VALUES ($entryid,$to)}
      }
    } else {
      set exists [my one {select count(entry) from link where entry=$entryid and refentry=$to and linktype=$type}]
      if {!$exists} {
        my <db> eval {insert or replace into link (entry,refentry,linktype) VALUES ($entryid,$to,$type)}
      } 
    }
  }

  ###
  # topic: 87d3f7df-ab5d-9e72-bd60-484e2cc3d943
  ###
  method link_detect_address args {
    set args [string tolower $args]
    if {[my node_exists $args entryid]} {
      return [my <db> eval {select entryid from entry where entryid=$entryid}]
    }
    ###
    # If the link contains a / we know it is a hard
    # path
    ###
    if {[my node_exists $args entryid]} {
      return $entryid
    }
    if {[llength $args] > 1} {
      set rootentries [my <db> eval {select name from entry where class='section'}]
      
      if {[lindex $args 0] in $rootentries} {
        set type [lindex $args 0]
        set name [my canonical $type [lindex $args 1]]
        if {[my node_exists [list $type $name] entryid]} {
          return $entryid
        }
      }
      if {[lindex $args 1] in $rootentries} {
        set type [lindex $args 1]
        set name [my canonical $type [lindex $args 0]]
        if {[my node_exists [list $type $name] entryid]} {
          return $entryid
        }
      }
    }
    set addr [lindex $args 0]
    set cnames [my <db> eval {select class,cname from aliases where alias=$addr}]
  
    if {[llength $cnames] == 2} {
      if {[my node_exists $cnames entryid]} {
        return $entryid
      }
    }
    #if {[string first / $addr] > 0 } {
    #  return $addr
    #}
    set candidates [my <db> eval {select entryid,name from entry where name like '%$addr%'}]
    foreach address $candidates {
      if {[regexp simnode $address]} {
        return $address
      }
    }
    #puts [list CAN'T RESOLVE $args]
    return $args
  }

  ###
  # topic: 36a96fa1-90b0-cc87-f14f-96f9e890b41f
  # description:
  #    Return a list of all children of node,
  #    Filter is a key/value list that understands
  #    the following:
  #    type - Limit children to type
  #    dump - Output the contents of the child node, not their id
  ###
  method node_children {nodeid class} {
    set dump 1
    set entryid [my node_id $nodeid]
    if { $class eq {} } {
      set nodes [my <db> eval {select name,entryid from entry where parent=$entryid}]
    } else {
      set nodes [my <db> eval {select name,entryid from entry where parent=$entryid and class=$class}]
    }
    if {!$dump} {
      return $nodes
    }
    set result {}
    foreach {cname cid} $nodes {
      dict set result $cname [my <db> eval {select field,value from property where entryid=$cid order by field}]
    }
    return $result
  }

  ###
  # topic: 3e015a1e-45af-d4e8-ab6d-8f7f404b6f0b
  ###
  method node_define {class name info {nodeidvar {}}} {
    if {$nodeidvar ne {}} {
      upvar 1 $nodeidvar nodeid
    }
    set class [string tolower $class]
    set name  [string tolower $name]
    if { $class eq {} || $class eq "section" } {
      set nodeid $name
    } else {
      set nodeid {}
      if {[dict exists $info topic]} {
        set nodeid [dict get $info topic]
        dict unset info topic
      }
    }    
    if { $nodeid eq {} } {
      if {![my node_exists [list $class $name] nodeid]} {
        set nodeid [helpdoc node_id [list $class $name] 1]
        foreach {var val} [my node_empty $class] {
          my node_property_set $nodeid $var $val        
        }
      }
    } elseif {![my node_exists $nodeid]} {
      my canonical_set $class $name $name
      my <db> eval {insert into entry (entryid,class,name) VALUES (:nodeid,:class,:name)}
      foreach {var val} [my node_empty $class] {
        my node_property_set $nodeid $var $val        
      }
    }
  
    foreach {var val} $info {
      my node_property_set $nodeid $var $val
    }
  }

  ###
  # topic: d6873cd2-a1f0-a0cb-73c6-16b79be848ef
  ###
  method node_define_child {parent class name info {nodeidvar {}}} {
    if {$nodeidvar ne {}} {
      upvar 1 $nodeidvar nodeid
    }
    ###
    # Return an already registered node with this address
    ###
    if {[my <db> exists {select entryid from entry where parent=:parent and class=:class and name=:name}]} {
      set nodeid [my <db> one {select entryid from entry where parent=:parent and class=:class and name=:name}]
    } else {
      set nodeid {}
  
      if {[dict exists $info topic]} {
        set topicid [dict get $info topic]
        dict unset info topic
        if {![my <db> exists {select entryid from entry where entryid=:topicid}]} {
          # If we are recycling an unused UUID re-create the entry in the table
          my <db> eval {insert or replace into entry (entryid,parent,class,name) VALUES (:topicid,:parent,:class,:name)}
          set nodeid $topicid
        }
      }
      if { $nodeid eq {} } {
        set nodeid [::tao::uuid_generate $parent $class $name]
      }
      if {[my <db> exists {select entryid from entry where entryid=:nodeid and class=:class and name=:name}]} {
        ###
        # Correct a misfiled node
        ###
        my <db> eval {update entry set parent=:parent where entryid=:nodeid}
      } else {
        my <db> eval {insert or replace into entry (entryid,parent,class,name) VALUES (:nodeid,:parent,:class,:name)}
      }
      foreach {var val} [my node_empty $class] {
        if {![dict exists $info $var]} {
          dict set info $var $val
        }
      }
    }
    foreach {var val} $info {
      my node_property_set $nodeid $var $val        
    }
    return $nodeid
  }

  ###
  # topic: 9cc273d5-bb08-3a02-a149-25ff251e31eb
  ###
  method node_empty class {
    set id [my <db> one {select entryid from entry where name=:class and class='section'}]
    return [my <db> one {select value from property where entryid=:id and field='template'}]
  }

  ###
  # topic: 668d848e-a9f0-9456-8af8-12d8037f31be
  ###
  method node_exists {node {resultvar {}}} {
    set parent 0
    if { $resultvar != {} } {
      upvar 1 $resultvar row
    }
    if {[llength $node]==1} {
      set name [lindex $node 0]
      if {[my <db> exists {select entryid from entry where name=:name or entryid=:name}]} {
        set row [my <db> one {select entryid from entry where name=:name or entryid=:name}]
        return 1
      }
    } elseif {[llength $node]==2} {
      set class [lindex $node 0]
      set name [lindex $node 1]
      if {[my <db> exists {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]} {
        set row [my <db> one {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]
        return 1
      }
    }
    set class [lindex $node 0]
    set name [lindex $node 1]
    if {[my <db> exists {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]} {
      set parent [my <db> one {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]
    } else {
      return 0
    }
    foreach {eclass ename} [lrange $node 2 end] {
      set row {}
      if {$eclass eq {}} {
        if {[my <db> exists {select entryid from entry where parent=:parent and (entryid=:ename or name=:ename)}]} {
          set row [my <db> one {select entryid from entry where parent=:parent and (entryid=:ename or name=:ename)}]
        }
      } else {
        if {[my <db> exists {select entryid from entry where parent=:parent and class=:eclass and (entryid=:ename or name=:ename)}]} {
          set row [my <db> one {select entryid from entry where parent=:parent and class=:eclass and (entryid=:ename or name=:ename)}]
        }
      }
      if { $row eq {} } {
        return 0
      }
      set parent $row
    }
    return 1
  }

  ###
  # topic: 159cca09-6137-91d8-438e-e627bbd8bb8a
  ###
  method node_get {nodeid {field {}}} {
    set result {}
    if {[my node_exists $nodeid entryid]} {
      set result [helpdoc node_properties $entryid]
    } else {
      if {[llength $nodeid] > 1} {
        set type [lindex $nodeid 0]
        set result [my node_empty $type]
      }
    }
    if { $field eq {} } {
      return $result    
    }
    return [dictGet $result $field]
  }

  ###
  # topic: 64ca8873-8309-5687-bbd3-e6d10e57928b
  ###
  method node_id {node {create 0}} {
    if {[my <db> exists {select entryid from entry where entryid=:node;}]} {
      return [my <db> one {select entryid from entry where entryid=:node;}]
    }
    if {[llength $node]==1} {
      set name [lindex $node 0]
      if {[my <db> exists {select entryid from entry where name=:name or entryid=:name}]} {
        return [my <db> one {select entryid from entry where name=:name or entryid=:name}]
      }
      if { $create } {
        my <db> eval {insert into entry (class,name) VALUES ('section',:name)}
        return $name
      } else {
        error "Node $node does not exist"
      }
    } elseif {[llength $node]==2} {
      set class [lindex $node 0]
      set name [lindex $node 1]

      if {[my <db> exists {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]} {
        set row [my <db> one {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]
        return $row
      }
    }
    set class [lindex $node 0]
    set name [lindex $node 1]
    if {[my <db> exists {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]} {
      set parent [my <db> one {select entryid from entry where (class=:class or parent=:class) and (name=:name or entryid=:name)}]
    } else {
      if {!$create} {
        error "Node $node does not exist"
      }

      ###
      # If the name contains no spaces, dots, slashes, or ::
      ###
      set row [::tao::uuid_generate $class $name]
      my <db> eval {insert into entry (entryid,class,name) VALUES (:row,:class,:name)}
      set parent $row
    }
    if { $create } {
      set classes [my <db> eval {select distinct class from entry}]
    }
    set eclass {}
    foreach token [lrange $node 2 end] {
      set ename $token
      set row {}
      if {$eclass eq {}} {
        if {[my <db> exists {select entryid from entry where parent=:parent and (entryid=:ename or name=:ename)}]} {
          set row [my <db> one {select entryid from entry where parent=:parent and (entryid=:ename or name=:ename)}]
        }
      } else {
        if {[my <db> exists {select entryid from entry where parent=:parent and class=:eclass and (entryid=:ename or name=:ename)}]} {
          set row [my <db> one {select entryid from entry where parent=:parent and class=:eclass and (entryid=:ename or name=:ename)}]
        }
      }
      if { $row eq {} } {
        if { $create } {
          if { $ename in $classes } {
            set eclass $token
            continue            
          } else {
            set eclass {}
            my node_define_child $parent $eclass $ename {} row
          }          
        } else {
          error "Node $node does not exist"
        }
      }
      set parent $row
    }
    return $row
  }

  ###
  # topic: e5f736cc-b9bb-cc7f-b2b0-36dadb69ceee
  ###
  method node_properties entryid {
    return [my <db> eval {select field,value from property where entryid=$entryid}]
  }

  ###
  # topic: f0aa625a-4491-6dda-7e99-13128b6c5ce8
  ###
  method node_property_append {nodeid field text} {
    set buffer [my one {select value from property where entryid=:nodeid and field=:field}]
    append buffer " " [string trim $text]
    my <db> eval {insert or replace into property (entryid,field,value) VALUES (:nodeid,:field,:buffer)}
  }

  ###
  # topic: 769d5a1a-c7f9-6f59-204c-3d7498ab3e6f
  ###
  method node_property_get {nodeid field} {
    return [my <db> one {select value from property where entryid=:nodeid and field=:field}]
  }

  ###
  # topic: 6c133099-ca7c-055e-dc43-9bb6a803742a
  # description: nodeid is any value acceptable to {[my node_alloc]}
  ###
  method node_property_lappend {entryid field args} {
    if {![llength $args]} return
    set dbvalue [my <db> eval {select value from property where entryid=$entryid and field=$field}]
    foreach value $args {
      if { $value eq {} } continue
      logicset add dbvalue $value
    }
    my <db> eval {update property set value=$dbvalue where entryid=$entryid and field=$field}
  }

  ###
  # topic: fda2e0af-2053-bc68-8a94-5bcfb5f3c5d4
  ###
  method node_property_set {entryid args} {
    my variable property_info property_cname
    if {[llength $args]==1} {
      set arglist [lindex $args 0]
    } else {
      set arglist $args
    }
    foreach {field value} $arglist {
      if {[info exists property_cname($field)]} {
        set cname $property_cname($field)
        set rawvalue $value
        eval [dictGet $property_info $cname script]
      } else {
        set cname $field
      }
      if {![my <db> exists {select value from property where entryid=:entryid and field=:cname and value=:value}]} {
        my <db> eval {insert or replace into property (entryid,field,value) VALUES (:entryid,:cname,:value)}
      }
    }
  }

  ###
  # topic: 93684be5-5ce4-9d0e-e494-abd30becefe9
  ###
  method node_restore {nodeid info} {
    set stmtl {}
    dict with info {}
    set fields entryid
    set _entryid $nodeid
    set values "\$_entryid"
    
    foreach {field value} $info {
      switch $field {
        properties {
          foreach {var val} $value {
            my node_property_set $_entryid $var $val
          }
        }
        references {
          foreach {refid reftype} $references {
            my link_create $_entryid $refid $reftype
          }
        }
        enumid {
          my enum_set [lindex $value 0] [dict get $info name] [lindex $value 1]
        }
        aliases {
          foreach a $value {
            my canonical_set $_class $a $_name
          }
        }
        parent {
          if {![string is integer $value]} {
            set value [my node_id $value 1]
          }
          lappend fields $field
          lappend values "\$_$field"
          set _$field $value            
        }
        class -
        address -
        name {
          if { $value ne {} } {
            lappend fields $field
            lappend values "\$_$field"
            set _$field $value
          }
        }
      }
    }
    my <db> eval "insert or replace into entry ([join $fields ,]) VALUES ([join $values ,]);"
  }

  ###
  # topic: a827c417-66f4-2062-0768-f61722b8f02f
  ###
  method node_serialize nodeid {
    set result {}
    my <db> eval {
      select * from entry
      where entryid=$nodeid
    } record {
      set entryid $record(entryid)
      append result "[list [self] node_restore $entryid] \{" \n
      
      foreach {field value} [array get record] {
        if { $field in {* entryid indexed export} } continue
        append result "  [list $field $value]" \n
      }
      set class $record(class)
  
      set id [my canonical_id $class $record(name)]
      if { $id ne {} } {
          append result "  [list enumid [list $class $id]]" \n
      }
      
      append result "  properties \{" \n
      set info [my node_empty $record(class)]
      foreach {var val} [my node_properties $entryid] {
        dict set info $var $val
      }

      foreach {var} [lsort -dictionary [dict keys $info]] {
        if { $var in {aliases field method fields methods references id} } continue
        append result "    [list $var [string trim [dict get $info $var]]]" \n
      }
      
      append result "  \}" \n
      set references [my <db> eval {select refentry,linktype from link where entry=$entryid}]
      if {[llength $references]} {
        append result "  [list references $references]" \n
      }
      set aliases [my canonical_aliases $record(class) $record(name)]
      if {[llength $aliases]} {
        append result "  [list aliases $aliases]" \n
      }
      set attachments [my <db> eval {select file.hash,filelink.linktype from file,filelink where filelink.entryid=$entryid and filelink.fileid=file.fileid}]
      if {[llength $attachments]} {
        append result "  [list attachments $attachments]" \n
      }
      append result "\}"
    }
    return $result
  }

  ###
  # topic: bfabdbab-d3ab-fb5c-de3f-100c53499342
  ###
  method property_define {property info} {
    my variable property_info property_cname
    foreach {f v} $info {
      dict set property_info $property $f $v
    }
    foreach alias [dictGet $property_info $property aliases] {
      set property_cname($alias) $property
    }
    set property_cname($property) $property
  }

  ###
  # topic: 8415be88-5874-9d8e-5458-dd0b784bf2ab
  ###
  method reindex {} {
    my variable canonical_name
    my <db> eval {select class,alias,cname from aliases order by class,cname,alias} {
      dict set canonical_name $class $alias $cname
    }
  }

  ###
  # topic: 8f48cff1-daf9-f81d-0730-ee7d270240ca
  ###
  method repository_restore {handle info} {
    set stmtl {}
    dict with info {}
    set fields handle
    set _handle $handle
    set values "\$_handle"
    foreach {field value} $info {
      switch $field {
        localpath {
          if { $value ne {} } {
            lappend fields $field
            lappend values "\$_$field"
            set _$field $value
          }
        }
      }
    }
    my <db> eval "insert or replace into repository ([join $fields ,]) VALUES ([join $values ,]);"
  }
}

if {[info command ::md5] eq {}} {
package require md5
###
# topic: 68488727-ef91-1687-a68e-d0c4922de68a
# description:
#    Because the tcllib version of uuid generate requires
#    network port access (which can be slow), here's a fast
#    and dirty rendition
###
proc ::tao::uuid_generate args {
  if {![llength $args]} {
    set block [list {*}$::tao::UUID_Seed [clock seconds] [clock microseconds]]
  } else {
    set block $args
  }
  set tok [md5::MD5Init]  
  foreach item $block {
    md5::MD5Update $tok $item
  }
  set uuid [md5::MD5Final $tok]
  binary scan $uuid H* s
  foreach {a b} {0 7 8 11 12 15 16 19 20 end} {
      append r [string range $s $a $b] -
  }
  return [string tolower [string trimright $r -]]
}
} else {
###
# Implementation the uses a compiled in ::md5 implementation
# commonly used by embedded application developers
###
###
# topic: 68488727-ef91-1687-a68e-d0c4922de68a
# description:
#    Because the tcllib version of uuid generate requires
#    network port access (which can be slow), here's a fast
#    and dirty rendition
###
proc ::tao::uuid_generate args {
  if {![llength $args]} {
    set block [list {*}$::tao::UUID_Seed [clock seconds] [clock microseconds]]
  } else {
    set block $args
  }
  set uuid [md5 [join $block ""]]
  binary scan $uuid H* s
  foreach {a b} {0 7 8 11 12 15 16 19 20 end} {
      append r [string range $s $a $b] -
  }
  return [string tolower [string trimright $r -]]
}
}

