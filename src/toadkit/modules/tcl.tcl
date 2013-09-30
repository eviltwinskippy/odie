###
# Downloads, configures, and compiles Tcl
###
proc ::which_tcl {} {
  switch $::tcl_platform(os) {
    Linux {
      core-8-6-0
    }
    default {
      core-8-6-1
    }
  }
}

toad_module tcl {
  test_file generic/tcl.h
  fossil_url http://core.tcl.tk/tcl
  package_name tcl
  package_version 8.6
  fossil_tag [which_tcl]
} {
  superclass toadkit.distribution.fossil toadkitmodule.gnumake
  
  method build_done {} {
    set info [my build_info]
    set rpath [file normalize [file join ${::odie(local_repo)}]]
    puts [list BUILD DONE $::tcl_platform(platform) $::tcl_platform(os)]
    switch $::tcl_platform(platform) {
      windows {
        if {![file exists [file join [my build_path_local] Makefile]]} {
          return 0
        }
        if {![file exists [file join $rpath lib libtcl86.a]]} {
          puts [list missing [file join $rpath lib libtcl86.a]]
          return 0
        }
        if {![file exists [file join $rpath lib libtclstub86.a]]} {
          puts [list missing [file join $rpath libtcl86.a]]
          return 0
        }
        if {![file exists [file join $rpath bin tclsh86s.exe]]} {
          puts [list missing [file join $rpath bin tclsh86s.exe]]  
          return 0
        }
      }
      default {
        if {![file exists [file join $rpath lib libtcl8.6.a]]} {
          puts [list missing [file join $rpath lib libtcl8.6.a]]
          return 0
        }
        if {![file exists [file join $rpath lib libtclstub8.6.a]]} {
          puts [list missing [file join $rpath libtcl8.6.a]]
          return 0
        }
        if {![file exists [file join $rpath bin tclsh8.6]]} {
          if {![file exists [file join $rpath bin tclsh86s]]} {
            puts [list missing [file join $rpath bin tclsh86s]]  
            return 0
          }
        }
      }
    }
    return 1
  }

  method build {} {
    if {[my build_done]} {
      return
    }
    my step_download_do
    my step_compile_do
  }

  method build_info {} {
    set info [my property build_info_template]
    dict set info linked_statically 1
    switch $::tcl_platform(platform) {
      windows {
        #dict set info static_linked_objects [list \
        #  [file normalize [file join [my build_path_local] libtcl86.a]] \
        #  [file normalize [file join [my build_path_local] libtclstub86.a]] \
        #]
        dict set info static_linked_objects [list \
          [file normalize [file join [my build_path_local] libtcl86.a]]]
      }
      default {
        dict set info static_linked_objects [list \
          [file normalize [file join [my build_path_local] libtcl8.6.a]]]
      }
    }
    #if {[file exists [file join [my build_path_local] tclConfig.sh]]} {
    #  set dat [read_sh_file [file join [my build_path_local] tclConfig.sh]]
    #  if {[dict exists $dat TCL_LIBS]} {
    #    dict set info static_linked_libraries [dict get $dat TCL_LIBS]
    #  }
    #}
    
    return $info
  }

  method zipdir_populate path {
    copy_path ~/odie/lib/tcl8.6 [file join $path tcl8.6]
    copy_path ~/odie/lib/tcl8 [file join $path tcl8]
    set HOST [lindex $::tcl_platform(os) 0]
    #if {$HOST eq "Windows"} {
    #  # Copy embedded extensions
    #  foreach dir {
    #    reg1.3
    #    dde1.4
    #  } {
    #    copy_path ~/odie/lib/$dir [file join $path $dir]
    #  }
    #}
  }

  method build_path_local {} {
    set path [my build_path]
    set HOST [lindex $::tcl_platform(os) 0]
    switch $HOST {
      Linux -
      Darwin {
        return [file join $path unix]
      }
      Windows {
        return [file join $path win]
      }
    }
    return [file join $path unix]
  }

  method step_compile_do {} {
    if {[my build_done]} {
      return
    }
    set hpath [my build_path_local]
    cd $hpath
    my make_env
    if {![file exists [file join $hpath configure]]} {
      doexec autoconf
    }
    if {![file exists [file join $hpath Makefile]]} {
      doexec sh ./configure --prefix=${::odie(local_repo)} --enable-shared=false
    }
    doexec make all
    doexec make install
  }
}

