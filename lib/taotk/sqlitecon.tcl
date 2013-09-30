set release(sqlitecon.tcl) {$Header: /readi/code/common/sqlitecon.tcl,v 1.6 2006/10/30 20:43:57 drh Exp $}
# A Tk console widget for SQLite.  Invoke sqlitecon::create with a window name,
# a prompt string, and a title to get a new top-level window that allows 
# the user to enter SQL commands.  This is mainly useful for testing and
# debugging.
#

package provide tao::sqlitecon 0.1

::namespace eval ::sqlitecon {}

###
# topic: e1c5ea21-83ab-4f6c-bd81-21d54bc1248d
# description: An in-line editor for SQL
###
proc ::sqlitecon::_edit {origtxt {title {}}} {
  for {set i 0} {[winfo exists .ed$i]} {incr i} continue
  set w .ed$i
  toplevel $w
  wm protocol $w WM_DELETE_WINDOW "$w.b.can invoke"
  wm title $w {Inline SQL Editor}
  frame $w.b
  pack $w.b -side bottom -fill x
  button $w.b.can -text Cancel -width 6 -command [list set ::$w 0]
  button $w.b.ok -text OK -width 6 -command [list set ::$w 1]
  button $w.b.cut -text Cut -width 6 -command [list ::sqlitecon::Cut $w.t]
  button $w.b.copy -text Copy -width 6 -command [list ::sqlitecon::Copy $w.t]
  button $w.b.paste -text Paste -width 6 -command [list ::sqlitecon::Paste $w.t]
  set ::$w {}
  pack $w.b.cut $w.b.copy $w.b.paste $w.b.can $w.b.ok\
     -side left -padx 5 -pady 5 -expand 1
  if {$title!=""} {
    label $w.title -text $title
    pack $w.title -side top -padx 5 -pady 5
  }
  text $w.t -font [::simconfig::get font-console] -bg white -fg black -yscrollcommand [list $w.sb set]
  pack $w.t -side left -fill both -expand 1
  scrollbar $w.sb -orient vertical -command [list $w.t yview]
  pack $w.sb -side left -fill y
  $w.t insert end $origtxt

  vwait ::$w

  if {[set ::$w]} {
    set txt [string trimright [$w.t get 1.0 end]]
  } else {
    set txt $origtxt
  }
  destroy $w
  return $txt
}

###
# topic: 9898237f-f1c3-fd63-a70b-6a14c86c7517
# description:
#    Create a console widget named $w.  The prompt string is $prompt.
#    The title at the top of the window is $title.  The database connection
#    object is $db
###
proc ::sqlitecon::create {w prompt title db} {
  if {[winfo exists $w]} {
    wm deiconify $w
    raise $w
    $w configure -prompt $prompt -title $title -db $db
    return
  } else {
    taotk::sqlconsole $w -prompt $prompt -title $title -db $db
  }
}

###
# topic: cade6d1f-5851-ecfb-b056-c932a3607ce7
# description: Bring up the console for TPE debugging
###
proc ::sqlitecon::start {} {
  if {[winfo exists .sqlitecon]} {
    wm deiconify .sqlitecon
    update
    raise .sqlitecon
  } else {
    set args [list -prompt {sqlite-> } -title {SQLite Console} -db db]
    if {[info exists ::g(font-console)]} {
      lappend args -font $::g(font-console)
    }
    taotk::sqlconsole .sqlitecon {*}$args    
  }
}

###
# topic: aa3f1f26-7541-c87e-10ed-1970c1160a56
###
tao::class taotk::meta::sqlconsole {
  superclass taotk::meta::console
  option db {class organ}
  option prompt {default {sqlite-> }}
  option title  {default {SQLite Console}}

  ###
  # topic: aa9e99f9-3b7a-cee1-b836-e15f561f1d54
  # description:
  #    Execute a single SQL command.  Pay special attention to control
  #    directives that begin with "."
  #    
  #    The return value is the text output from the command, properly
  #    formatted.
  ###
  method DoCommand cmd {
    my variable v
    set mode $v(mode)
    set header $v(header)
    if {[regexp {^(\.[a-z]+)} $cmd all word]} {
      if {$word==".mode"} {
        regexp {^.[a-z]+ +([a-z]+)} $cmd all v(mode)
        return {}
      } elseif {$word==".exit"} {
        my destroy
        return {}
      } elseif {$word==".header"} {
        regexp {^.[a-z]+ +([a-z]+)} $cmd all v(header)
        return {}
      } elseif {$word==".tables"} {
        set mode multicolumn
        set cmd {SELECT name FROM sqlite_master WHERE type='table'
                 UNION ALL
                 SELECT name FROM sqlite_temp_master WHERE type='table'}
        my <db> eval {PRAGMA database_list} {
           if {$name!="temp" && $name!="main"} {
              append cmd "UNION ALL SELECT name FROM $name.sqlite_master\
                          WHERE type='table'"
           }
        }
        append cmd  { ORDER BY 1}
      } elseif {$word==".fullschema"} {
        set pattern %
        regexp {^.[a-z]+ +([^ ]+)} $cmd all pattern
        set mode list
        set header 0
        set cmd "SELECT sql FROM sqlite_master WHERE tbl_name LIKE '$pattern'
                 AND sql NOT NULL UNION ALL SELECT sql FROM sqlite_temp_master
                 WHERE tbl_name LIKE '$pattern' AND sql NOT NULL"
        my <db> eval {PRAGMA database_list} {
           if {$name!="temp" && $name!="main"} {
              append cmd " UNION ALL SELECT sql FROM $name.sqlite_master\
                          WHERE tbl_name LIKE '$pattern' AND sql NOT NULL"
           }
        }
      } elseif {$word==".schema"} {
        set pattern %
        regexp {^.[a-z]+ +([^ ]+)} $cmd all pattern
        set mode list
        set header 0
        set cmd "SELECT sql FROM sqlite_master WHERE name LIKE '$pattern'
                 AND sql NOT NULL UNION ALL SELECT sql FROM sqlite_temp_master
                 WHERE name LIKE '$pattern' AND sql NOT NULL"
        my <db> eval {PRAGMA database_list} {
           if {$name!="temp" && $name!="main"} {
              append cmd " UNION ALL SELECT sql FROM $name.sqlite_master\
                          WHERE name LIKE '$pattern' AND sql NOT NULL"
           }
        }
      } else {
        return \
          ".exit\n.mode line|list|column|csv\n.schema ?TABLENAME?\n.tables"
      }
    }
    set res {}
    if {$mode=="list"} {
      my <db> eval $cmd x {
        set sep {}
        foreach col $x(*) {
          append res $sep$x($col)
          set sep |
        }
        append res \n
      }
      if {[info exists x(*)] && $header} {
        set sep {}
        set hdr {}
        foreach col $x(*) {
          append hdr $sep$col
          set sep |
        }
        set res $hdr\n$res
      }
    } elseif {[string range $mode 0 2]=="col"} {
      set y {}
      my <db> eval $cmd x {
        foreach col $x(*) {
          if {![info exists cw($col)] || $cw($col)<[string length $x($col)]} {
             set cw($col) [string length $x($col)]
          }
          lappend y $x($col)
        }
      }
      if {[info exists x(*)] && $header} {
        set hdr {}
        set ln {}
        set dash ---------------------------------------------------------------
        append dash ------------------------------------------------------------
        foreach col $x(*) {
          if {![info exists cw($col)] || $cw($col)<[string length $col]} {
             set cw($col) [string length $col]
          }
          lappend hdr $col
          lappend ln [string range $dash 1 $cw($col)]
        }
        set y [concat $hdr $ln $y]
      }
      if {[info exists x(*)]} {
        set format {}
        set arglist {}
        set arglist2 {}
        set i 0
        foreach col $x(*) {
          lappend arglist x$i
          append arglist2 " \$x$i"
          incr i
          append format "  %-$cw($col)s"
        }
        set format [string trimleft $format]\n
        if {[llength $arglist]>0} {
          foreach $arglist $y "append res \[format [list $format] $arglist2\]"
        }
      }
    } elseif {$mode=="multicolumn"} {
      set y [my <db> eval $cmd]
      set max 0
      foreach e $y {
        if {$max<[string length $e]} {set max [string length $e]}
      }
      set ncol [expr {int(80/($max+2))}]
      if {$ncol<1} {set ncol 1}
      set nelem [llength $y]
      set nrow [expr {($nelem+$ncol-1)/$ncol}]
      set format "%-${max}s"
      for {set i 0} {$i<$nrow} {incr i} {
        set j $i
        while 1 {
          append res [format $format [lindex $y $j]]
          incr j $nrow
          if {$j>=$nelem} break
          append res {  }
        }
        append res \n
      }
    } elseif {$mode=="csv"} {
      my <db> eval $cmd x {
        set sep {}
        foreach col $x(*) {
          set val $x($col)
          if {$val=="" || [regexp {[\s",]} $val]} {
             set val \"[string map [list \" \"\"] $val]\"
          }
          append res $sep$val
          set sep ,
        }
        append res \n
      }
    } else {
      my <db> eval $cmd x {
        foreach col $x(*) {append res "$col = $x($col)\n"}
        append res \n
      }
    }
    return [string trimright $res]
  }

  ###
  # topic: 48ce19b2-dadd-0831-ddd6-afe1ec9603e7
  ###
  method Enter {} {
    my variable v
    set w [my organ text]
    scan [my text index insert] %d.%d row col
    set start $row.$v(plength)
    set line [my text get $start "$start lineend"]
    my text insert end \n
    my text mark set out end
    if {$v(prior)==""} {
      set cmd $line
    } else {
      set cmd $v(prior)\n$line
    }
    if {[string index $cmd 0]=="." || [my <db> complete $cmd]} {
      regsub -all {\n} [string trim $cmd] { } cmd2
      my addHistory $cmd2
      set rc [catch {my DoCommand $cmd} res]
      if {![winfo exists $w]} return
      if {$rc} {
        my text insert end $res\n err
      } elseif {[string length $res]>0} {
        my text insert end $res\n ok
      }
      set v(prior) {}
      my text insert end $v(prompt)
    } else {
      set v(prior) $cmd
      regsub -all {[^ ]} $v(prompt) . x
      my text insert end $x
    }
    my text mark set insert end
    my text mark set out {insert linestart}
    my text yview insert
  }

  ###
  # topic: 26862d40-efe9-b9ea-75d3-1e3c15c10db3
  ###
  method initialize {} {
    my variable v
    array set v {
      mode column
      header on
    }
  }
}

###
# topic: fb6ad926-3b57-2896-052a-c4c3bb6520d6
###
tao::class taotk::sqlconsole {
  superclass taotk::meta::sqlconsole taotk::toplevel

  ###
  # topic: 50eb2aca-4dbd-2ae7-3ed2-0c752038dd40
  ###
  method build_widget window {
    set w $window
    set prompt [my cget prompt]
    set title  [my cget title]
    upvar #0 $w.t v
    if {[winfo exists $w]} {destroy $w}
    if {[info exists v]} {unset v}
    toplevel $w
    wm title $w $title
    wm iconname $w $title
    my graft topframe $w

    my build_buttons    
    my build_console
    my bind_widget $window
  }
}

###
# topic: cceceb5d-a991-e07b-6eeb-21375178fa46
# description: Modify sqlite containers to display a console
###
tao::class moac.sqliteDb {
  ###
  # topic: 71d828ce-c096-1916-b45b-c12a4dff5e1d
  ###
  method console {} {
    set self [self object]

    set tkpath [string map {:: _ . _ { } _} $self]
    set tkpath .sqlitecon#[string trimleft [string map {__ _} $tkpath] _]
    if {[winfo exists $tkpath]} {
      wm deiconify $tkpath
      wm raise $tkpath
      return
    }
    taotk::sqlconsole $tkpath db $self
  }
}

###
# topic: 76f4cb1d-454b-9d70-c2fc-6b0dad0d6374
# description:
#    sqlitecon is an interactive console for accessing an
#    sqlite database
###
namespace eval ::sqlitecon {
# do nothing
}

# Start the console
#
# sqlitecon::create {.sqlitecon} {% } {SQLite Console} db

