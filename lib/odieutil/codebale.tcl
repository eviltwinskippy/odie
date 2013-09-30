package provide codebale 0.1

::namespace eval ::codebale {}

###
# topic: b1e5e6ca-f0bf-9e78-695f-995a35af7c2f
###
proc ::codebale::define {name info} {
  global cmdref
  foreach {var val} $info {
      dict set cmdref($name) $var $val
  }
}

###
# topic: 9cca11ca-4447-43a3-21d3-ad5ac85538b1
###
proc ::codebale::digest_comment {{properties {}}} {
  global block cmdref
  foreach {field value} $properties {
    set block($field) $value
  }

  switch $block(type) {
    class -
    namespace {
      set addr $block(type)/$block(module)
    }
    tclcmd -
    tclmod {
      set addr tclcmd/$block(cmd)      
    }
    tclmethod -
    tclsubcmd {
      set addr tclcmd/$block(module)/$block(cmd)    
    }
    method {
      set addr class/$block(module)/$block(cmd)
      dict set info defined $block(module)
    }
    proc {
      set rawproc $block(cmd)
      set proc [namespace tail $rawproc]
      set ns [proc_nspace $rawproc]
      set addr namespace/$ns/$proc
    }
    default {
      return
    }
  }
  set info [getRefInfo $addr]
  foreach field {title desc arglist type contract} {
    if { [string trim $block($field)] ne {} } {
      dict set info $field $block($field)
    }
  }
  if { [string trim $block(file)] ne {} } {
    if {[dict exist $info file]} {
      set filelist [dict get $info file]
    } else {
      set filelist {}
    }
    ladd filelist $block(file)
    dict set info file $filelist
  }
  set cmdref($addr) $info
}

###
# topic: 504c8f37-6db4-b5e7-b891-21d8c62e11cd
###
proc ::codebale::getRefInfo name {
  global cmdref
  if {![info exist cmdref($name)]} {
    set cmdref($name) [list title {} desc {} arglist {} file {} superclasses {} subclasses {} defined {}]
  }
  return $cmdref($name)
}

###
# topic: 539e5691-68d8-57ea-6229-a131b3aae0e1
###
proc ::codebale::has_comment varname {
  global block
  upvar 1 $varname txt
  
  set txt [string trimright $block(lastcommentblock)]
  set block(lastline) {}
  set block(lastcommentblock) {}
  set block(desc) {}
  
  if { $txt ne {} } {
    return 1
  }
  return 0
}

###
# topic: c0304a04-9be6-f312-06a0-2d15813720ce
###
proc ::codebale::meta_output outfile {
  set fout [open $outfile w]
  puts "SAVING TO $outfile"
  puts $fout "array set filemd5 \x7b"
  foreach {file md5} [lsort -dictionary -stride 2 [array get ::filemd5]] {
    puts $fout "    [list $file $md5]"
  }
  puts $fout "\x7d"
  foreach {tclmod info} [lsort -dictionary -stride 2 [array get ::cmdref]] {
    puts $fout "[list ::codebale::define  $tclmod] \x7b"
    foreach field {title desc type file} {
      if { ![dict exists $::cmdref($tclmod) $field] } {
        dict set ::cmdref($tclmod) $field {}
      }
      puts $fout "   [list $field [dict get $::cmdref($tclmod) $field]]"
    }
    foreach field {arglist superclasses subclasses defined} {
      if { ![dict exists $::cmdref($tclmod) $field] } {
        continue
      } else {
        set value [string trim [dict get $::cmdref($tclmod) $field]]
      }
      if {$value eq {} } continue
      puts $fout "   [list $field $value]"
    }
    puts $fout "\x7d"
  }
  close $fout
}

###
# topic: f241a03c-116c-4a82-fab1-9fab13cc62d5
# description: Routines used for reading meta-data from source files
###
proc ::codebale::parse_comment rawline {
  set line [string trim $rawline]
  set line [string trimleft $line #]
  set line [string trim $line]

  global block

  if {[catch {
    set header [string tolower [lindex $line 0]]
    set field [string trimright $header :]
  } err]} {
    append block(lastcommentblock) $rawline \n
    return 0
  }

  if { $header in "namespace: nspace:"} {
    reset_block
    set block(type) $field
    set block(module) [lindex $line 1]
    if { $block(module) in {/ :: {}} } {
      set block(module) Global
    }
    return 1
  }

  if { $header eq "class:"} {
    reset_block
    set block(type) $field
    set block(module) [lindex $line 1]
    set block(this_class) [lindex $line 1]
    return 1
  }

  if { $header eq "proc:"} {
    reset_block
    set block(type) $field
    set block(module) [proc_nspace [lindex $line 1]]
    set block(cmd) [lindex $line 1]
    set block(arglist) [lrange $line 2 end]
    return 1
  }

  if { $header in {method:}} {
    reset_block
    set block(type) $field
    set block(module) $block(this_class)
    set block(cmd) [lindex $line 1]
    set block(arglist) [lrange $line 2 end]
    return 1
  }

  if { $header in {goal: goalDefine: task: taskdefine:}} {
    reset_block
    set block(type) task
    set block(module) $bloc(this_class)
    set block(cmd) [lindex $line 1]
    set block(arglist) [lrange $line 2 end]
    set block(yields) {}
    return 1
  }

  if { $header in "tclcmd: tclmod:"} {
    reset_block
    set block(type) $field
    set block(module) [lindex $line 1]
    set block(cmd) [lindex $line 1]
    set block(arglist) [lrange $line 2 end]
    return 1
  }
  if { $header in "tclmethod:"} {
    reset_block
    set block(type) $field
    set block(module) [lindex $line 1]
    set block(cmd) [lindex $line 2]
    set block(arglist) [lrange $line 3 end]
    return 1
  }
  if { $header in "tclsubcmd:"} {
    reset_block
    set block(type) $field
    set block(module) [lindex $line 1]
    set block(cmd) [lindex $line 2]
    set block(arglist) [lrange $line 3 end]
    return 1
  }

  if { $header in {title: desc: inherits: arglist: yields: returns: contract:} } {
    set block($field) [lrange $line 1 end]
    set block(appendto) desc
    return 1
  }
  if { $block(appendto) ne {} } {
    append block($block(appendto)) \n $line
    if { $block(type) eq {} } {
      append block(lastcommentblock) $rawline \n
      return 0
    }
    return 1
  }
  if { $header == {} } {
    set block(appendto) {}
    if { $block(lastcomment) eq $line } {
      return 1
    }
    append block(lastcommentblock) $rawline \n
    return 0
  }
  append block(lastcommentblock) $rawline \n
  return 0
}

###
# topic: f9b3ce3a-afc9-72b5-5e33-0ac9b62c31db
###
proc ::codebale::proc_nspace procname {
  set rawproc $procname
  set proc [namespace tail $procname]
  set n [string last $proc $rawproc]
  if { $n == 0 } {
    set nspace {}
  } else {
    set nspace [string range $rawproc 0 [expr {$n - 1}]]
    set nspace [string trimleft $nspace :]
    set nspace [string trimright $nspace :]
  }
  return $nspace
}

###
# topic: 27a7f169-8a00-fb29-4f2c-700a8d8acb7e
###
proc ::codebale::read_csourcefile file {
  global classes base block filename
  reset_block

  set i [string length $base]

  set fname [file rootname [file tail $file]]
  set dir [string trimleft [string range [file dirname $file] $i end] /]
  set fpath $dir/[file tail $file]
  set filename $dir/[file tail $file]
  set fin [open $file r]
  set dat [read $fin]
  close $fin
  set found 0

  set thisline {}
  set thiscomment {}
  set incomment 0
  foreach line [split $dat \n] {
    set line [string trim $line]
    if {[string range $line 0 1] == "/*" } {
        set incomment 1
    }
    if { $incomment } {
      set pline [string trimleft $line "/"]
      set pline [string trimleft $pline "*"]
      set pline [string trimright $pline "/"]
      set pline [string trimright $pline "*"]
      parse_comment $pline
      if {[string range $line end-1 end] eq "*/" } {
        set incomment 0
        digest_comment
        reset_block
      }
    }
  }
  return 1
}

###
# topic: 945f95ae-2fae-b6c6-c3ee-3e8d54248c4b
###
proc ::codebale::read_tclsourcefile file {
  global classes base block filename
  reset_block

  set i [string length $base]

  set fname [file rootname [file tail $file]]
  set dir [string trimleft [string range [file dirname $file] $i end] /]
  set fpath $dir/[file tail $file]
  set filename $dir/[file tail $file]
  set fin [open $file r]
  set dat [read $fin]
  close $fin
  set found 0

  set thisline {}
  set thiscomment {}
  set incomment 0
  foreach line [split $dat \n] {
    set line [string trim $line]
    if { $incomment } {
      if {[string index $line 0] ne "#"} {
        set incomment 0
        digest_comment
        reset_block
      } else {
        set pline [string trimleft $line #]
        parse_comment $pline
      }
    } else {
      if {[string index $line 0] eq "#"} {
        set incomment 1
        set pline [string trimleft $line #]
        parse_comment $pline
      }      
    }
  }
  return 1
}

###
# topic: dd039999-2de5-3488-2c48-f0dfb3f757f4
###
proc ::codebale::reset_block {} {
  global block
  set this_class [lindex [array get block this_class] 1]
  array unset block *
  array set block {
    type {}
    module {}
    contract {}
    cmd {}
    arglist {}
    title {}
    desc {}
    file {}
    appendto desc
    lastcomment {}
    lastline {}
    lastcommentblock {}
  }
  set block(this_class) $this_class
}

###
# topic: d8ef9620-b068-3a82-3761-1725abc83192
###
proc ::codebale::sniffPath {spath stackvar} {
  upvar 1 $stackvar stack    
  set result {}
  if { ![file isdirectory $spath] } return
  if { [string toupper [file tail $spath]] == "CVS" } return
  if {[file extension $spath] eq ".vfs"} return
  if {[file exists [file join $spath pkgIndex.tcl]]} {
    lappend result index [file join $spath pkgIndex.tcl]
  } else {
    foreach f [glob -nocomplain $spath/*.tcl] {
      lappend result source $f
    }
  }
  foreach f [glob -nocomplain $spath/*.tm] {
    lappend result module $f
  }
  foreach f [glob -nocomplain $spath/*.c] {
    lappend result csource $f
  }
  foreach f [glob -nocomplain $spath/*] {
    if [file isdirectory $f] {
      set stack [linsert $stack 0 $f]
    }
  }
  return $result
}

