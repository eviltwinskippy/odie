#! /bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh $0 ${1+"$@"}

###
# For debugging:
# (Re)build a single module
###
if { $argv eq {} } {
  puts "Usage: make_module.tcl COMMAND MODULENAME ?MODULENAME...?"
  exit 1
}
proc sherpa_load_recipies {} {
  set ::sherpa_script [file normalize [info script]]
  set here [file dirname $::sherpa_script]
  uplevel #0 source [file join $here .. lib odie index.tcl]
  if {[file exists [file join $here .. recipes index.tcl]]} {
    set ::sandbox_dir    [file dirname $here]
    uplevel #0 source ${::sandbox_dir}/recipes/index.tcl  
  } elseif {[file tail $here] eq "bin"} {
    set ::sandbox_dir    [file normalize [file join $here .. sandbox odie]]
    uplevel #0 source ${::sandbox_dir}/recipes/index.tcl  
  } else {
    error "Script run from unknown location"
  }
  
  set bindir [file normalize [file join ${::odie(local_repo)} bin]]
  switch $::tcl_platform(platform) {
    unix {
      if {[info exists ::env(PATH)]} {
        set path [split $::env(PATH) :]
        if {$bindir ni $path} {
          set path [linsert $path 0 $bindir]
          set ::env(PATH) [join $path :]
        } 
      }
    }
    windows {
      foreach var {path PATH} {
        if {[info exists ::env($var)]} {
          set path [split $::env($var) \;]
          if {$bindir ni $path} {
            set path [linsert $path 0 $bindir]
            set ::env($var) [join $path \;]
          } 
        }        
      }
    }
  }
}

sherpa_load_recipies


set HOST [lindex $::tcl_platform(os) 0]
switch $HOST {
  Linux {
# Special environmental settings
  }
  Darwin {
# Special environmental settings
    array set ::env {
LDFLAGS {-headerpad_max_install_names -Wl,-search_paths_first}
CFLAGS  {-O2 -DALLOW_EMPTY_EXPAND -arch x86_64 -arch i386 -pipe -fvisibility=hidden   -isysroot /Developer/SDKs/MacOSX10.6.sdk -mmacosx-version-min=10.5}
}
  }
  Windows {
# Special environmental settings

  }
}

switch [lindex $argv 0] {
  pkg_mkIndex {
    set base [lindex $argv 1]
    if { $base eq {} } {
      set base [pwd]
    }
    if {[file exists $base/pkgIndex.tcl]} {
      file delete $base/pkgIndex.tcl
    }
    ::codebale::pkg_mkIndex $base
  }
  reinstall {
    foreach mod [lrange $argv 1 end] {
      if {$mod in {tcl tk sqlite}} continue
      $modules($mod) sherpa_uninstall
    }
    foreach mod [lrange $argv 1 end] {
      if {[$modules($mod) sherpa_present]} continue
      if {[$modules($mod) sherpa_skip]} continue

      if {$mod ni {tcl tk}} {
        set path [$modules($mod) build_path]
        $modules($mod) sherpa_download
        $modules($mod) sherpa_detect_properties
        $modules($mod) sherpa_clean
        $modules($mod) sherpa_install
        update
      }
      $modules($mod) sherpa_vfs_install $odie(zipdir)
    }    
  }
  get-source {
    foreach mod [lrange $argv 1 end] {
      if {[$modules($mod) sherpa_present]} continue
      if {[$modules($mod) sherpa_skip]} continue
      if {$mod ni {tcl tk}} {
        set path [$modules($mod) build_path]
        $modules($mod) sherpa_download
        $modules($mod) sherpa_detect_properties
        update
      }
    }    
  }
  install {
    foreach mod [lrange $argv 1 end] {
      if {[$modules($mod) sherpa_present]} continue
      if {[$modules($mod) sherpa_skip]} continue
      if {$mod ni {tcl tk}} {
        set path [$modules($mod) build_path]
        $modules($mod) sherpa_download
        $modules($mod) sherpa_detect_properties
        $modules($mod) sherpa_clean
        $modules($mod) sherpa_install
        update
      }
      $modules($mod) sherpa_vfs_install $odie(zipdir)
    }    
  }
  uninstall {
    foreach mod [lrange $argv 1 end] {
      if {$mod in {tcl tk sqlite}} continue
      $modules($mod) sherpa_uninstall
    }    
  }
  self-upgrade -
  upgrade-self {
    puts "UPDATING ODIE"
    $modules(odie) fossil_sync_and_update
    $modules(odie) sherpa_register
    # Flush packages and reload
    puts "RELOADING PACKAGES"
    sherpa.tools destroy
    sherpa_load_recipies
    #foreach module {
    #  sherpa
    #} {
    #  $::modules($module) sherpa_clean
    #  $::modules($module) sherpa_install
    #}
    $modules(odie) sherpa_install
  }
  upgrade -
  update {
    if {[lindex $argv 1] eq "all"} {
      set modulelist [array names modules]
    } else {
      set modulelist [lrange $argv 1 end] 
    }
    foreach mod $modulelist {
      if {[$modules($mod) sherpa_skip]} continue
      $modules($mod) sherpa_upgrade
    }
  }
  list {
    set result {}
    foreach mod [array names modules] {
      if {[$modules($mod) sherpa_skip]} continue
      lappend result $mod
    }
    puts [lsort $result]
  }
  vfs_mkIndex {
    set base [lindex $argv 1]
    set tclCompiler [lindex $argv 2]
    set stack {}
    set idxfile [file join $base packages.tcl]
    if {[file exists $idxfile]} {
      file delete $idxfile
    }
    
    set stack {}
    set buffer {
    set ::SRCDIR [file dirname [file normalize [info script]]]
    namespace eval ::starkit {
      variable topdir
      set topdir $::SRCDIR
    }
    }
    append buffer [::codebale::pkgindex_path $base] 
    set fout [open $idxfile w]
    puts $fout {# Tcl package index file, version 1.1
# This file is generated by the "sherpa" command
# and sourced either when an application starts up.
# It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $SRCDIR is derived from
# the present location of the script.
# This system defers to any existing pkgIndex.tcl scripts
# that exist in the path, as they may contain addition setup
# logic.
    }
    puts $fout $buffer
    close $fout
    exit 0 
  }
  vfs_install -
  zipdir {
    set zippath [lindex $argv 1]
    if { $zippath eq {} } {
      set zippath  $odie(zipdir)
    }
    if {[llength [lindex $argv 2]] > 0 } {
      set pkglist [lindex $argv 2]
    } else {
      set pkglist [lrange $argv 2 end]
    }
    foreach mod $pkglist {
      if {[$modules($mod) sherpa_skip]} continue
      $modules($mod) sherpa_vfs_install $zippath
    }
  }
  default {
    if {[llength [lindex $argv 1]] > 0 } {
      set pkglist [lindex $argv 1]
    } else {
      set pkglist [lrange $argv 1 end]
    }
    foreach mod $pkglist {
      set result [$modules($mod) [lindex $argv 0]]
      puts $result
    }
  }
}
update

