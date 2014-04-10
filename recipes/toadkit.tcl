###
# Common code for producing self-extracting-executables
###
oo::class create sherpa.sae {
  superclass sherpa.module

  method build_path {} {
    return [file normalize [file join $::odie(sandbox) toadkit-build]]
  }

  method build_path_local {} {
    return [file normalize [file join $::odie(sandbox) toadkit-build]]
  }
  
  method build_depends {} {
    global odie tcl_platform cc exe
    cd [file join $odie(sandbox) odie]
    doexec make tcltk-static
    set buildpath [my build_path_local]

    if {[file exists $buildpath]} {
      foreach ext {.c .o .a .dylib .dll .so .exe toadkit_bare} {
        foreach file [glob -nocomplain [file join $buildpath/*$ext]] {
          file delete $file
        }
      }
    }
    file mkdir $buildpath
    cd $buildpath
    # Create the zzipsetupstup binary
    #catch {doexec $cc {*}$::env(CFLAGS)  -o zzipsetupstub.o -c $::odie(sandbox)/odie/src/toadkit/zzipsetupstub.c} err
    #catch {doexec $cc {*}$::env(CFLAGS) zzipsetupstub.o -o zzipsetupstub$exe} err
    #file copy -force zzipsetupstub$exe ${odie(local_repo)}/bin

    ###
    # Insert odie into the environment path
    ###
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
  
  method sherpa_install {} {
    my sherpa_download
    my sherpa_detect_properties
    if {[my build_done]} {
      return
    }
    my step_compile_do
    my sherpa_register
  }


  method build_done {} {
    if {![file exists $::odie(local_repo)/bin/default.tcl]} {
      return 0
    }
    if {[file exists $::odie(local_repo)/bin/[my property exe_name]]} {
      return 1
    }
    if {[file exists $::odie(local_repo)/bin/[my property exe_name].exe]} {
      return 1
    }
    return 0
  }
  
  method build_path {} {
    return [file normalize [file join $::odie(sandbox) toadkit-build]]

  }
  
  method static_compile_packages {} {
    
    if {$::tcl_platform(platform) eq "windows"} {
      set tclsrcpath [file join $buildpath tcl win]
      set tksrcpath [file join $buildpath tk win]
      file copy -force [file join $::odie(sandbox) odie src toadkit wish.main.win.c] $buildpath/main_wish.c
    } else {
      set tclsrcpath [file join $buildpath tcl unix]
      set tksrcpath [file join $buildpath tk unix]
      
      file copy -force [file join $::odie(sandbox) odie src toadkit wish.main.unix.c] $buildpath/main_wish.c
    }  
  }
  
  method sherpa_clean {} {
    set hpath [my build_path]    
    #doexec make clean
    #file delete $hpath
    #foreach file [glob -nocomplain [file join $::odie(local_repo) bin toadkit_bare*]] {
    #  file delete $file
    #}
  }

}

sherpa::module tclkit {
  package_name tclkit
  package_version 0.1
  exe_name tclkit_bare
} {
  superclass sherpa.sae

  method step_compile_do {} {
    global odie tcl_platform cc exe
    
    my build_depends
    set buildpath [my build_path_local]

    cd $buildpath
    set HOST [lindex $::tcl_platform(os) 0]
    
    if {$::tcl_platform(platform) eq "windows"} {
      set tclsrcpath [file join $odie(sandbox) tcl-static win]
      file copy -force [file join $::odie(sandbox) odie src toadkit tclsh.main.win.c] $buildpath/main_tclsh.c
    } else {
      set tclsrcpath [file join $odie(sandbox) tcl-static unix]
      file copy -force [file join $::odie(sandbox) odie src toadkit tclsh.main.unix.c] $buildpath/main_tclsh.c
    }
    file copy -force $::odie(sandbox)/odie/src/toadkit/zvfs.c $buildpath/zvfs.c
    if {![file exists $::odie(sandbox)/odie/src/toadkit/packages.c]} {
      file copy -force $::odie(sandbox)/odie/src/toadkit/packages.c.in $buildpath/packages.c
    } else {
      file copy -force $::odie(sandbox)/odie/src/toadkit/packages.c $buildpath/packages.c
    }
    set sources {main_tclsh.c zvfs.c packages.c}
    
    ###
    # Detect our build environment from tclConfig.sh and tkConfig.sh
    ###
    set stripexe strip
    set static_c_headers [list -I $odie(local_repo)/include -I $tclsrcpath]
    set static_linked_objects {}
    set static_linked_libraries {}
    
    ###
    # Build our static Tcl shell
    ###
    set objs {}
    set dat [read_sh_file [file join $tclsrcpath tclConfig.sh]]
    
    if {[dict exists $dat TCL_LIBS]} {
      set static_linked_libraries [dict get $dat TCL_LIBS]
    }
    if {[dict exists $dat TCL_LD_FLAGS]} {
      set ::env(LDFLAGS) [dict get $dat TCL_LD_FLAGS]
    }
    if {[dict exists $dat TCL_EXTRA_CFLAGS]} {
      set ::env(CFLAGS) [dict get $dat TCL_EXTRA_CFLAGS]
    }
    lappend defs {*}[dict get $dat TCL_DEFS]
    
    switch $tcl_platform(platform) {
      "windows" {
        ###
        # When building a TK executable in windows, we need to provide
        # resource objects
        ###
        lappend static_linked_objects \
          [file normalize [file join $tclsrcpath libtcl86.a]] \
          [file normalize [file join $tclsrcpath libtclstub86.a]]
        lappend objs [file join $tksrcpath tcl.res.o]
        lappend objs [file join $tksrcpath tclsh.res.o]
      }
      default {
        lappend static_linked_objects \
          [file normalize [file join $tclsrcpath libtcl8.6.a]]
      }
    }
    
    # Take care of obj files in tksrcpath
    foreach obj $objs {
      doexec make -C $tksrcpath [file tail $obj]
    }
    
    foreach cfile $sources {
      set ofile [file rootname $cfile].o
      catch {doexec $cc -DTCL_USE_STATIC_PACKAGES -DSTATIC_BUILD=1 {*}$static_c_headers {*}$::env(CFLAGS) -o $ofile -c $cfile}
      lappend objs $ofile
    }
    
    # Strangeness to get around a quirk in mingw
    if {[catch {set ldflags $::env(LDFLAGS)}]} {
      set ldflags {}
    }
    
    set buildargs [list $cc {*}$objs {*}$static_linked_objects {*}$static_linked_libraries {*}$ldflags]
    doexec {*}$buildargs -o [my property exe_name]$exe
    #doexec $stripexe toadkit_bare$exe
    
    file copy -force [my property exe_name]$exe ${odie(local_repo)}/bin  
    #file copy -force zzipsetupstub$exe ${odie(local_repo)}/bin
    if {![file exists [file join $odie(local_repo) bin default_tclsh.tcl]]} {
       file copy [file join $::odie(sandbox) odie src toadkit default_tclsh.tcl] [file join $odie(local_repo) bin default_tclsh.tcl]
    }
  }
}


sherpa::module toadkit {
  package_name toadkit
  package_version 0.1
  exe_name toadkit_bare
} {
  superclass sherpa.sae

  method gather_sources {} {
    my variable tclsrcpath tksrcpath objfiles csources
    set buildpath [my build_path_local]

  }


  method step_compile_do {} {
    global odie tcl_platform cc exe
    
    my build_depends
    set buildpath [my build_path_local]
    
    cd $buildpath
    set HOST [lindex $::tcl_platform(os) 0]

    if {$::tcl_platform(platform) eq "windows"} {
      set tclsrcpath [file join $odie(sandbox) tcl-static win]
      set tksrcpath  [file join $odie(sandbox) tk-static win]
      file copy -force [file join $::odie(sandbox) odie src toadkit wish.main.win.c] $buildpath/main_wish.c
    } else {
      set tclsrcpath [file join $odie(sandbox) tcl-static unix]
      set tksrcpath  [file join $odie(sandbox) tk-static unix]
      file copy -force [file join $::odie(sandbox) odie src toadkit wish.main.unix.c] $buildpath/main_wish.c
    }
    file copy -force $::odie(sandbox)/odie/src/toadkit/zvfs.c $buildpath/zvfs.c
    if {![file exists $::odie(sandbox)/odie/src/toadkit/packages.c]} {
      file copy -force $::odie(sandbox)/odie/src/toadkit/packages.c.in $buildpath/packages.c
    } else {
      file copy -force $::odie(sandbox)/odie/src/toadkit/packages.c $buildpath/packages.c
    }
    set sources {main_wish.c zvfs.c packages.c}
    
    ###
    # Detect our build environment from tclConfig.sh and tkConfig.sh
    ###
    set stripexe strip
    set static_c_headers [list -I $odie(local_repo)/include -I $tclsrcpath -I $tksrcpath]
    set static_linked_objects {}
    set static_linked_libraries {}
    
    ###
    # Build our static Wish shell
    ###
    set objs {}
    # Integrated Tk
    set dat [read_sh_file [file join $tksrcpath tkConfig.sh]]
    
    if {[dict exists $dat TK_LIBS]} {
      set static_linked_libraries [dict get $dat TK_LIBS]
    }
    if {[dict exists $dat TK_LD_FLAGS]} {
      set ::env(LDFLAGS) [dict get $dat TK_LD_FLAGS]
    }
    if {[dict exists $dat TK_EXTRA_CFLAGS]} {
      set ::env(CFLAGS) [dict get $dat TK_EXTRA_CFLAGS]
    }
    lappend defs {*}[dict get $dat TK_DEFS]
    
    switch $tcl_platform(platform) {
      "windows" {
        ###
        # When building a TK executable in windows, we need to provide
        # resource objects
        ###
        lappend static_linked_objects \
          [file normalize [file join $tclsrcpath libtcl86.a]] \
          [file normalize [file join $tclsrcpath libtclstub86.a]] \
          [file normalize [file join $tksrcpath libtk86.a]] \
          [file normalize [file join $tksrcpath libtkstub86.a]]
        lappend objs [file join $tksrcpath tk.res.o]
        lappend objs [file join $tksrcpath wish.res.o]
      }
      default {
        lappend static_linked_objects \
          [file normalize [file join $tclsrcpath libtcl8.6.a]] \
          [file normalize [file join $tksrcpath libtk8.6.a]]
      }
    }
    
    # Take care of obj files in tksrcpath
    foreach obj $objs {
      doexec make -C $tksrcpath [file tail $obj]
    }
    
    foreach cfile $sources {
      set ofile [file rootname $cfile].o
      catch {doexec $cc -DTCL_USE_STATIC_PACKAGES -DSTATIC_BUILD=1 {*}$static_c_headers {*}$::env(CFLAGS) -o $ofile -c $cfile}
      lappend objs $ofile
    }
    
    # Strangeness to get around a quirk in mingw
    if {[catch {set ldflags $::env(LDFLAGS)}]} {
      set ldflags {}
    }
    
    set buildargs [list $cc {*}$objs {*}$static_linked_objects {*}$static_linked_libraries {*}$ldflags]
    doexec {*}$buildargs -o [my property exe_name]$exe
    #doexec $stripexe toadkit_bare$exe
    
    file copy -force [my property exe_name]$exe ${odie(local_repo)}/bin  
    #file copy -force zzipsetupstub$exe ${odie(local_repo)}/bin
    if {![file exists [file join $odie(local_repo) bin default.tcl]]} {
       file copy [file join $::odie(sandbox) odie src toadkit default.tcl] [file join $odie(local_repo) bin default.tcl]
    }
  }
}


sherpa::module sampletoadkit {
  package_name sampletoadkit
  package_version 0.1
  fossil_url {http://fossil.etoyoc.com/fossil/sampletoadkit}
} {
  superclass sherpa.distribution.fossil sherpa.module

  method build_path {} {
    return [file normalize [file join $::odie(sandbox) [my property package_name]]]
  }

  method sherpa_clean {} {
    file delete -force [my build_path]
  }
  
  method sherpa_install {} {
    my sherpa_download
    my sherpa_register
  }
}