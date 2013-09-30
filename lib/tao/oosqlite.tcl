###
# topic: cceceb5d-a991-e07b-6eeb-21375178fa46
# description: Modify sqlite containers to display a console
###
tao::class moac.sqliteDb {
  superclass moac
  property docentry {}

  option filename {
    widget filename
    extensions {.sqlite {Sqlite Database}}
  }

  option read-only {
    default 0
    widget boolean
  }

  ###
  # topic: 080a0a01-e018-a81c-9f3d-7a696a0698c9
  ###
  method attach_sqlite_methods sqlchan {
    my graft db $sqlchan
foreach func {
authorizer
backup
busy
cache
changes
close
collate
collation_needed
commit_hook
complete
copy
enable_load_extension
errorcode
eval
exists
function
incrblob
last_insert
last_insert_rowid
nullvalue
one
onecolumn
profile
progress
restore
rollback_hook
status
timeout
total_changes
trace
transaction
unlock_notify
update_hook
version
    } {
        my forward $func $sqlchan $func
    }
  }

  ###
  # topic: d4ac9357-de80-79b0-24a8-a48c07ceac06
  # title: Evaluate an SQL expression that alters the database
  # description:
  #    This method is a wrapper around "eval" that will catch
  #    "not authorized" messages and give the user some notice that
  #    they should rename the file before altering it.
  ###
  method change args {
    if {[my cget read-only]} {
      my message readOnlyDatabase
      return
    }
    uplevel 1 [list [self] eval {*}$args]
  }

  ###
  # topic: 1d9b0f6a-8c1c-ef3d-9b88-1543e6d5931a
  ###
  method Database::attach filename {
    set alias db
    if { $filename in {:memory: {}}} {
      set exists 0
    } else {
      set exists [file exists $filename]
    }
    my put filename $filename
    set objname [my SubObject $alias]
    sqlite3 $objname $filename
    my graft $alias $objname
    my Database functions
    my attach_sqlite_methods $objname
    if {!$exists} {
      my Database create
    }
    ###
    # Wait up to 2 seconds for
    # a busy database
    ###
    my timeout 2000
  }

  ###
  # topic: 04fdd322-8b3f-d0f2-1c41-7c7e8085b934
  ###
  method Database::create {} {
    
  }

  ###
  # topic: 1a1e7eb0-906e-888d-3a49-b430d6fb7dde
  ###
  method Database::functions sqlchan {
  }

  ###
  # topic: 91819552-8443-d838-3f92-ef0c06a5f281
  # description:
  #    Deep wizardry
  #    Disable journaling and disk syncronization
  #    If the app crashes, we really don't give a
  #    rat's ass about the output, anyway
  ###
  method Database::journal_mode onoff {
    if {[string is false $onoff]} {
      my <db> eval {PRAGMA synchronous=OFF}
      my <db> eval {PRAGMA journal_mode=OFF}
    } else {
      my <db> eval {PRAGMA synchronous=ON}
      my <db> eval {PRAGMA journal_mode=ON}      
    }
  }

  ###
  # topic: 9e2ad9b4-d953-81ff-73e3-a481d3cb9b98
  ###
  method message::readonly {} {
    error "Database is read-only"
  }

  ###
  # topic: af76cd3e-8d30-4841-95d5-99d44e4a00b3
  ###
  method native_tableget table {
    set info {}
    my one {select type,sql from sqlite_master where tbl_name=$table} {
      foreach {type field value} [::schema::createsql_to_dict $sql] {
        dict set info $type $field $value
      }
    }
    return $info
  }

  ###
  # topic: e1811960-ced8-4756-76b4-64def58a2a1c
  ###
  method native_tablelist {} {
      return [my eval {SELECT name FROM sqlite_master WHERE type ='table'}]
  }

  ###
  # topic: 175cfad3-c734-5d4f-0dfd-6865ab69c804
  ###
  method Option_set::filename filename {
    my Database attach $filename
  }

  ###
  # topic: cac2e473-a72e-f1d2-180a-fdd417117b0d
  ###
  method schema_dump {} {
    set result {}
    foreach table [my schema_tablelist] {
      dict set result $table [my schema_get $table]
    }
    return $result
  }

  ###
  # topic: 60cc2296-f2e2-4a12-24b7-4dd459d8b49b
  ###
  method schema_fields table {
    set dentry [my property docentry]
    if {![::helpdoc node_exists [list schema $dentry sqltable $table] entryid]} {
      return {}
    }
    set result {}
    helpdoc eval {select name,entryid as fieldid from entry where parent=:entryid and class='field' order by name} {
      dict set result $name [helpdoc node_get $fieldid]
    }
    return $result
  }

  ###
  # topic: a601c2ea-28ad-4dc6-40b6-b6be22cd590e
  ###
  method schema_get table {
    set dentry [my property docentry]
    if {![::helpdoc node_exists [list schema $dentry sqltable $table] entryid]} {
      return {}
    }
    set info [::helpdoc node_get $entryid]
    dict set info fields [my schema_fields $table]
    return $info
  }

  ###
  # topic: ba74ec88-9d25-c62c-fcd0-a50d61c36a99
  ###
  method schema_sql {} {
    set result {}
    foreach table [my schema_tablelist] {
      set info [my schema_get $table]
      append result "-- BEGIN $table" \n
      append result [dict get $info create_sql] \n
      append result "-- END $table" \n
    }
    return $result
  }

  ###
  # topic: f8feb545-51d7-1c81-3ed8-1fb468cb0f6a
  ###
  method schema_tablelist {} {
    set dentry [my property docentry]
    if {![::helpdoc node_exists [list schema $dentry] did]} {
      return {}
    }
    return [helpdoc eval {select name from entry where parent=:did order by name}]
  }

  ###
  # topic: ab1efd74-b7ca-a115-b24b-e1ecf0a36d8d
  ###
  method SubObject::db {} {
    return [namespace current]::Sqlite_db
  }
}

###
# topic: 19202636-410f-00cd-adb6-a4594d6280d9
# description:
#    This class abstracts the normal operations undertaken
#    my containers and nodes that write to a single data table
###
tao::class moac.sqliteTable {
  superclass moac
  
  # Properties that need to be set:
  # table - SQL Table
  # primary_key - Primary key for the sql table
  # default_record - Key/value list of defaults
  

  ###
  # topic: 642306cf-efe7-d9b7-5763-a581959e8d30
  # title: Delete a record from the database backend
  ###
  method db_record_delete nodeid {
    set table [my property table]
    set primary_key [my property primary_key]
    my db change "delete from $table where $primary_key=:nodeid"
  }

  ###
  # topic: 3da88c8f-861e-5d6b-7e56-a826d79a7b5d
  ###
  method db_record_exists nodeid {
    set table [my property table]
    set primary_key [my property primary_key]
    return [my db exists "select $primary_key from $table where $primary_key=:nodeid"]
  }

  ###
  # topic: 4261522a-c3b6-a06f-ff4f-af7ee3ddf129
  # description: Read a record from the database
  ###
  method db_record_load {nodeid {arrayvar {}}} {
    if { $arrayvar ne {} } {
      upvar 1 $arrayvar R
    }
    set table [my property table]
    if {$nodeid eq {}} {
      return {}
    }
    my db eval "select * from $table where rowid=:nodeid" R {}
    unset -nocomplain R(*)
    return [array get R]
  }

  ###
  # topic: b68c1830-ad8d-867b-fae0-fbb3ecfa62fe
  # title: Return a record number for a new entry
  ###
  method db_record_nextid {} {
    set primary_key [my property primary_key]
    set maxid [my db one "select max($primary_key) from [my property table]"]
    if { ![string is integer -strict $maxid]} {
      return 1
    } else {
      return [expr {$maxid + 1}]
    }
  }

  ###
  # topic: 85090c61-d508-0c6c-12e7-e4ba2caf8f5f
  # description:
  #    Write a record to the database. If nodeid is negative,
  #    create a new record and return its ID.
  #    This action will also perform any container specific prepwork
  #    to stitch the node into the model, as well as re-read the node
  #    from the database and into memory for use by the gui
  ###
  method db_record_save {nodeid record} {
    appmain signal  dbchange

    set table [my property table]
    set primary_key [my property primary_key]
    
    set now [clock seconds]
    if { $nodeid < 1 || $nodeid eq {} } {
      set nodeid [my db_record_nextid]
    }
    if {![my db exists "select $primary_key from $table where rowid=:nodeid"]} {
      my db change "INSERT INTO $table ($primary_key) VALUES (:nodeid)"
      foreach {var val} [my property default_record] {
        if {![dict exists $record $var]} {
          dict set record $var $val
        }
      }
    }
    set oldrec [my db_record_load $nodeid]
    set fields {}
    set values {}
    set stmt "UPDATE $table SET "
    set stmtl {}
    set columns [dict keys $oldrec]
    
    foreach {field value} $record {
        if { $field in [list $primary_key mtime uuid] } continue
        if { $field ni $columns } continue
        if {[dict exists $oldrec $field]} {
            # Screen out values that have not changed
            if {[dict get $oldrec $field] eq $value } continue
        }
        lappend stmtl "$field=\$rec_${field}"
        set rec_${field} $value
    }
    if { $stmtl == {} } {
        return 0
    }
    if { "mtime" in $columns } {
      lappend stmtl "mtime=now()"
    }
    append stmt [join $stmtl ,]
    append stmt " WHERE $primary_key=:nodeid"
    my db change $stmt
    return $nodeid
  }
}

###
# topic: 7b660566-1ce2-82c1-f728-d5f48d4ebb6d
# description:
#    Managing records for tables that consist of a primary
#    key and a blob field that contains a key/value list
#    that represents the record
###
tao::class moac.sqliteTable.blob {
  ###
  # topic: b0c8c8f5-4fdb-ba71-0d33-8b6ad136c8bf
  ###
  method db_record_delete nodeid {
    set table        [my property table]
    set primary_key  [my property primary_key]
    my db one "delete from $table where $primary_key=:nodeid"
  }

  ###
  # topic: ae654936-fb9a-773a-9d3e-12153c1890e4
  ###
  method db_record_load {nodeid {arrayvar {}}} {
    set table  [my property table]
    set vfield [my property field_value]
    set primary_key [my property primary_key]
    
    if { $arrayvar ne {} } {
      upvar 1 $arrayvar R
      array set R [my db one "select $vfield from $table where $primary_key=:nodeid"]
      return [array get R]
    } else {
      return  [my db one "select $vfield from $table where $primary_key=:nodeid"]
    }
  }

  ###
  # topic: 3cfbd282-1493-c7de-8e61-6052f71bbd20
  ###
  method db_record_save {nodeid record} {
    set table  [my property table]
    set vfield [my property field_value]
    set primary_key [my property primary_key]
    
    set result [my property default_record]
    foreach {var val} [my db one "select $vfield from $table where $primary_key=:nodeid"] {
      dict set result $var $val
    }
    foreach {var val} $record {
      dict set result $var $val
    }
    my db eval "update $table set $vfield=:result where $primary_key=:nodeid"
  }
}

###
# topic: 55b6e10d-3408-f1a2-9a82-d79ea50ef567
# description:
#    Managing records for tables that consist of a primary
#    key a column representing a "field" and another
#    column representing a "value"
###
tao::class moac.sqliteTable.keyvalue {
  ###
  # topic: aafa36af-85fb-90e0-239d-96884eed6ac6
  ###
  method db_record_delete nodeid {
    set table        [my property table]
    set primary_key  [my property primary_key]
    my db one "delete from $table where $primary_key=:nodeid"
  }

  ###
  # topic: 493aba5b-30c4-e186-9d3b-1048ce326bab
  ###
  method db_record_load nodeid {
    set table  [my property table]
    set ffield [my property field_name]
    set vfield [my property field_value]
    set primary_key [my property primary_key]

    set result [my property default_record]
    my db eval "select $ffield as field,$vfield as value from $table where $primary_key=:nodeid" {
      dict set result $field $value
    }
    return $result
  }

  ###
  # topic: 48347592-0761-ebe0-94fe-c24415343a9b
  ###
  method db_record_save {nodeid record} {
    set table  [my property table]
    set ffield [my property field_name]
    set vfield [my property field_value]
    set primary_key [my property primary_key]
    
    set oldrecord [my db_record_load $nodeid]
    foreach {var val} $record {
      if {[dict exists $oldrecord $var]} {
        if {[dict get $oldrecord $var] eq $val } continue
      }
      dict set outrecord $var $val
    }
    if {![llength $outrecord]} return
    
    my db transaction {
      foreach {var val} $outrecord {
        my db change "insert or replace into $table ($primary_key,$ffield,$vfield) VALUES (:nodeid,$var,$val)"
      }
    }
  }
}

