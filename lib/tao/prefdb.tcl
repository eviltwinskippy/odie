###
# A persistant storage system for user preferences
###

###
# Registration system for preferences
###

###
# topic: cbc5b6b6-0f22-9146-5c1e-8036a9822bd2
###
::tao::class tao.prefdb {
  option preffile {default ~/odie/localprefs.sqlite}
  option prefarray {default ::prefs}
  property appname odie
  

  ###
  # topic: 230c61c3-fa7c-66b3-ba9d-335f39354972
  ###
  method _prefs_define {name props} {
    set info {
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
    dict set info command [namespace code {my configure}]
    foreach {var val} $props {
      dict set info $var $val
    }
    if {[dict exists $info appname]} {
      set appname [dict get $info appname]
      dict unset info appname
    } else {
      if {[dict get $info save] eq "family"} {
        set appname [my property appfamily]
      }
    } else {
      set appname  [my property appname]
    }
    foreach {var val} $info {
      my prefdb eval {insert into metadata (appname,field,property,value) VALUES (:appname,:name,:var,:val)}
    }
  }

  ###
  # topic: 9d80464a-d5da-15ad-7995-301092f6159b
  # description: Map a field to a canonical name
  ###
  method _prefs_field_canonical field {
    return $field
  }

  ###
  # topic: 11f166cd-bf03-8463-bbcb-dee4b935b105
  ###
  method _prefs_field_info field {
    # This function should return meta
    # data about the selected field
    return {
      set history 0
      set save {}
    }
  }

  ###
  # topic: 68c576e8-a6e0-1172-25d9-5520bb50a1e3
  ###
  method _prefs_field_remove field {
    my prefdb eval {
      delete from history where field=$field;
    }
  }

  ###
  # topic: a04d9ec4-e84e-2d63-c34b-da361c9e9cfe
  ###
  method _prefs_read {} {
    return [select * from pref_current]
  }

  ###
  # topic: e305f37e-6b88-3d64-add1-6ca12de45944
  ###
  method _prefs_write {field newvalue {mtime -1}} {
    set array [my cget prefarray]
    if {[string range $array 0 1] eq "::"} {
      upvar #0 $array prefarray
    } else {
      upvar #0 [my varname $array] prefarray
    }
    set prefarray($field) $newvalue
    if { $mtime < 0 } {
      set mtime [clock seconds]
    }
    my variable timer
    if {[info exists timer($field)]} {
      after cancel $timer($field)
      unset timer($field)
    }
    set ofield $field
    set field [my _pref_field_canonical $field]
    if { $field eq {} } {
      return
    }
    set info [my _pref_field_info $field]
    
    set history 0
    set save {}
    
    dict with info {}
    ###
    # Do not store volitile field
    ###
    if { $save eq {} } {
      my _prefs_field_remove $field
      return
    }
    
    if { $ofield != $field } {
      my _prefs_field_remove $ofield
    }
    if {$history || $save eq "prefs"} {
      my _prefs_write_history $field $value $mtime
    }
    my _prefs_write_$save $field $value $mtime
  }

  ###
  # topic: 49a3e9ea-0a6b-bd4d-0424-061220878492
  ###
  method _prefs_write_history {field newvalue mtime} {
    my prefdb eval {insert or replace into history(field,value,mtime) VALUES ($field,$newvalue,$mtime)}    
  }

  ###
  # topic: a8a68b48-3fe5-9c35-efbd-cc1652a014c6
  ###
  method _prefs_write_prefs {field newvalue mtime} {
    my prefdb eval {insert or replace into prefs(field,value,mtime) VALUES ($field,$newvalue,$mtime)}    
  }

  ###
  # topic: 1416c526-ba37-b66c-4e6c-2dcf0bb9110b
  ###
  method action::create_preferences {
    foreach {field val} [my property default_prefs] {
      my prefs write $field $val
    }
  }

  ###
  # topic: 4d30f019-2384-8236-7a70-c192abc7d0aa
  ###
  method attach_prefdb {} {
    package require sqlite3
    set preffile [my cget preffile]
    if {![file exists [file dirname [file normalize $preffile]]]} {
      file mkdir [file dirname [file normalize $preffile]]
    }
    set exists [file exists $preffile]
    sqlite3 [self].prefdb $preffile
    my graft [self].prefdb prefdb
    set appname [my property appname]
    set appfamily [my property appfamily]
    
    if {!$exists} {
      my prefdb eval {
create table metadata (
  field string,
  property string,
  value string,
  primary key (field)
);
create table prefs (
  field string,
  value string,
  mtime integer,
  primary key (field)
);
create table history (
  field string,
  value string,
  mtime integer,
  primary key (field,value)
);
create index historyMtime on history (mtime);
}
      my action create_preferences
    }
    my prefdb eval {
create view if not exists history_view
as select histall.* from history histall NATURAL JOIN
( SELECT field,value,max(mtime) as histmax from history where group by field)
mostrecent;

create temporary v
}
    my prefdb timeout 1000
  }

  ###
  # topic: 8a7b7a0a-5094-5c3d-03a2-77d68cf291db
  # description: Ensemble to manage preferences
  ###
  method prefs {method args} {
    return [my _prefs_$method {*}$args]
  }
}

