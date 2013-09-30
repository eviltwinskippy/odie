###
# Downloads, configures, and compiles Tk
###
toad_module tk {
  compile_after tcl
  test_file generic/tk.h
  fossil_url http://core.tcl.tk/tk
  package_name tk
  package_version 8.6
  fossil_tag [which_tcl]
} {
  superclass toadkit.distribution.fossil toadkitmodule.gnumake
  
  method build_done {} {
    set info [my build_info]
    set rpath [file normalize ${::odie(local_repo)}]
    if {![file exists [file join $rpath lib libtk8.6.a]]} {
      return 0
    }
    if {![file exists [file join $rpath lib libtkstub8.6.a]]} {
      return 0
    }
    if {![file exists [file join $rpath bin wish8.6]]} {
      if {![file exists [file join $rpath bin wish86.exe]]} {
        return 0
      }
    }
    return 1
  }
  
  method build_done {} {
    set info [my build_info]
    set rpath [file normalize [file join ${::odie(local_repo)}]]

    switch $::tcl_platform(platform) {
      windows {
        if {![file exists [file join [my build_path_local] Makefile]]} {
          return 0
        }
        if {![file exists [file join $rpath lib libtk86.a]]} {
          puts [list missing [file join $rpath lib libtk86.a]]
          return 0
        }
        if {![file exists [file join $rpath lib libtkstub86.a]]} {
          puts [list missing [file join $rpath libtjk6.a]]
          return 0
        }
        if {![file exists [file join $rpath bin wish86s.exe]]} {
          puts [list missing [file join $rpath bin wish86s.exe]]  
          return 0
        }
      }
      default {
        if {![file exists [file join $rpath lib libtk8.6.a]]} {
          puts [list missing [file join $rpath lib libtk8.6.a]]
          return 0
        }
        if {![file exists [file join $rpath lib libtkstub8.6.a]]} {
          return 0
        }
        if {![file exists [file join $rpath bin wish8.6s]]} {
          if {![file exists [file join $rpath bin wish8.6]]} {
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
  
  method kit_info {} {
    
  }
  
  method build_info {} {
    set info [my property build_info_template]
    dict set info linked_statically 1
    switch $::tcl_platform(platform) {
      windows {
        dict set info static_linked_objects [list \
          [file normalize [file join ${::odie(local_repo)} lib libtk86.a]]]
        ]
      }
      default {
        dict set info static_linked_objects [list \
          [file normalize [file join ${::odie(local_repo)} lib libtk8.6.a]]]
      }
    }
    if {[file exists [file join [my build_path_local] tkConfig.sh]]} {
      set dat [read_sh_file [file join [my build_path_local] tkConfig.sh]]
      if {[dict exists $dat TK_LIBS]} {
        dict set info static_linked_libraries [dict get $dat TK_LIBS]
      }
    }
    return $info
  }

  method zipdir_populate path {
    copy_path [file join ${::odie(local_repo)} lib tk8.6] [file join $path tk8.6]
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
    switch [my build_host] {
      unix {
        doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --enable-shared=false
      }
      macosx {
        doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --enable-shared=false --enable-aqua=yes
      }
      win {
        doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --enable-shared=false
      }
    }    
    doexec make all
    doexec make install
  }
}

