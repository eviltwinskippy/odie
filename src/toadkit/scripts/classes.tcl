###
# Classes used for building
###
set here [file dirname [file normalize [info script]]]
source [file join $here ../local.tcl]

if {$tcl_platform(platform) == "windows"} {
  set exe .exe
} else {
  set exe {}
}

###
# topic: 88bb89fe-88b6-cfaf-ccbd-970d3025c8be
###
proc ::copy_path {src dest} {
  set stack {}
  set result {}
  set src [file normalize $src]
  set dest [file normalize $dest]
  set srcpathidx [string length $src]
  if {[file isdirectory $src]} {
    lappend stack $src
  } else {
    lappend result $src
  }
  while {[llength $stack]} {
    set path [lindex $stack 0]
    set stack [lrange $stack 1 end]
    foreach file [glob -nocomplain $path/*] {
      if [file isdirectory $file] {
        set stack [linsert $stack 0 $file]
      } else {
        lappend result $file
      }
    }
  }
  foreach file $result {
    set newpath $dest[string range $file $srcpathidx end]
    if {![file exists [file dirname $newpath]]} {
      file mkdir [file dirname $newpath]
    }
    file copy -force $file $newpath
  }
}

###
# topic: 5b6897b1-d604-5033-2ff9-f389b5ca952d
###
proc ::doexec args {
  puts "DOEXEC $args"
  exec {*}$args >&@ stdout
}

###
# topic: c78d05ee-03f2-7eed-73a5-5a0624052348
###
proc ::read_sh_file filename {
  puts "READING $filename"
  set result {}
  set fin [open $filename r]
  set thisline {}
  while {[gets $fin line]>=0} {
    append thisline $line
    if {![info complete $thisline]} {
      append thisline \n
      continue
    }
    set parseline [string trim $thisline]
    set thisline {}
    if {[string index [string trim $parseline] 0] eq "#"} continue
    if {[string trim $parseline] eq {}} continue
    if {[set idx [string first = $parseline]] < 0} continue
    set field [string trim [string range $parseline 0 [expr {$idx-1}]]]
    set value [string trim [string range $parseline [expr {$idx+1}] end]]
    set value [string trim $value \']
    dict set result $field $value
  }
  return $result
}

###
# topic: 912fce73-60ed-6a4c-54ec-efb2b6a9ce48
###
proc ::toad_module {name properties definition} {
  oo::class create ::odiemod.$name.class $definition
  
  ###
  # Define the init_properties method
  ###
  
  set script {
  next
  my variable property
  }
  foreach {var val} $properties {
    append script \n "  " [list dict set property $var [subst $val]]
  }
  append script \n "   " [list dict set property module_name $name]
  append script \n
  oo::define ::odiemod.$name.class method init_properties {} $script
  # Create an instance of this class
  ::odiemod.$name.class create ::odiemod.$name
  set ::modules($name) ::odiemod.$name
}


oo::class create  toadkit.tools {

  constructor {} {
    my init_properties
  }
  
  method init_properties {} {
    my variable property build_info
    set property {
      compile_after {}
      module_name generic
      active 1
      all_steps {}
    }
  }

  ###
  # topic: cbba4dc0-4912-e60d-749d-291a7fc88ce5
  ###
  method build_path {} {
    return [file normalize [file join [my property sandbox] [my property module_name]]]
  }

  ###
  # topic: 09be3e2e-9a59-0bb6-ec6d-d75d3dc05a59
  ###
  method do_clean {} {
    #file delete -force [my build_path]
  }

  ###
  # topic: a98d4ec0-e5df-e7df-8984-5eabd9f03bec
  ###
  method do_mkdir {} {
    set build_path [my build_path]
    file mkdir $build_paths
  }

  method build_info {} {
    return {}
  }

  method property field {
    if { $field eq "build_info_template" } {
      my variable build_info
      return $build_info
    }
    my variable property
    if {[dict exists $property $field]} {
      return [dict get $property $field]
    }
    if {[info exists ::odie($field)]} {
      return $::odie($field)
    }
    return {}
  }
  

  ###
  # topic: 0c75a2b5-c7b6-8197-80e1-59976311c3b7
  ###
  method zipdir_populate path {
    
  }
}

###
# topic: 6463c62b-cd01-0acd-4cea-bf9034aa7559
###
oo::class create  toadkitmodule {
  
  superclass toadkit.tools
  
  method init_properties {} {
    my variable property build_info
    set property {
      compile_after {}
      module_name generic
      active 1
      all_steps {}
    }
    set build_info {
      linked_statically 0
      static_c_headers {}
      static_c_declarations {}
      static_c_initialization {}
      static_linked_libraries {}
      static_linked_objects {}
      dynamic_libraries {}
      script_libraries {}
    }
  }
  
  method property_dict {} {
    my variable property
    return $property
  }
  
  ###
  # topic: 10d4c70d-b87c-2fbb-3cf0-56b546f33eeb
  ###
  method build {} {
    # Fill this in with all the code to download,
    # compile, and install this module
  }

  ###
  # topic: 223b9d91-1e2e-cd9a-bef2-eef8ad2549c9
  ###
  method build_host {} {
    set HOST [lindex $::tcl_platform(os) 0]
    switch $HOST {
      Linux {
        return unix
      }
      Darwin {
        return macosx
      }
      Windows {
        return win
      }
    }
    return $::tcl_platform(platform)
  }

  method build_info {} {
    return [my property build_info_template]
  }

  ###
  # topic: f76a3f0a-7ebd-c017-7fd1-64d663f48b4a
  ###
  method build_path {} {
    return [file normalize [file join [my property sandbox] [my property module_name]]]
  }
  
  ###
  # topic: aa2c749e-63a2-0f44-3433-ae4c6d48aa24
  ###
  method test {} {}

}

###
# topic: 9dd69d38-637a-0cc2-6582-6cc591b44da7
###
oo::class create  toadkitmodule.gnumake {
  superclass toadkitmodule

  method init_properties {} {
    next
    my variable property
    dict set property test_file {}
    dict set property linked_statically 0
  }


  method build {} {
    my step_compile_do
    my step_install_do
  }

  ###
  # topic: 1f354b6f-a5ad-4d0d-91c9-a2b4aac63ad1
  ###
  method build_path_local {} {
    set path [my build_path]
    return $path
  }

  ###
  # topic: bb83df45-615e-f71f-449e-c9dab643fe91
  ###
  method do_clean {} {
    #file delete -force [my build_path]
  }

  ###
  # topic: 2d4cf424-4730-4c30-7e23-80fae2cd4bb5
  ###
  method make_clean {} {
    set hpath [my build_path_local]
    if {[file exists $hpath/Makefile]} {
      cd $hpath
      catch {doexec make clean} err
    }
  }

  ###
  # topic: 29b467bc-c871-f1dd-4b60-f4a60a01d298
  ###
  method make_distclean {} {
    set hpath [my build_path_local]
    cd $hpath
    doexec make distclean
  }

  ###
  # topic: a4f41d70-3c65-1b3c-a5a5-be60f3fbb453
  ###
  method make_env {} {
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
  }

  method build_info {} {
    set info [my property build_info_template]
    set linked_statically [my property linked_statically]
    dict set info linked_statically $linked_statically
    if {[my property linked_statically]} {
      if {[file exists [file join [my build_path_local] Makefile]]} {
        set dat [read_sh_file [file join [my build_path_local] Makefile]]
        if {[dict exists $dat LIBS]} {
          dict set info static_linked_libraries [dict get $dat LIBS]
        }
        if {[dict exists $dat PKG_LIB_FILE]} {
          set result {}
          foreach item [dict get $dat PKG_LIB_FILE] {
            lappend result [file normalize [file join [my build_path_local] $item]]
          }
          dict set info static_linked_objects $result
        }
      }
    } else {
      if {[file exists [file join [my build_path_local] Makefile]]} {
        set dat [read_sh_file [file join [my build_path_local] Makefile]]
        if {[dict exists $dat PKG_LIB_FILE]} {
          set result {}
          foreach item [dict get $dat PKG_LIB_FILE] {
            lappend result [file normalize [file join [my build_path_local] $item]]
          }
          dict set info dynamic_libraries $result
        }
      }
    }
    return $info
  }

  ###
  # topic: 9a9f210d-c3a9-eb43-be5b-95b96bcb88c0
  ###
  method step_compile_do {} {
    set hpath [my build_path_local]
    cd $hpath
    my make_env
    if {![file exists [file join $hpath configure]]} {
      doexec autoconf
    }
    if {[my property linked_statically]} {
      if {![file exists [file join $hpath Makefile]]} {
        doexec sh ./configure --prefix=${::odie(local_repo)} --enable-shared=false --with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib
      }
    } else {
      if {![file exists [file join $hpath Makefile]]} {
        doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib
      }
    }
    doexec make all

  }
  
  method step_install_do {} {
    puts [list [self] step_install_do]
    set hpath [my build_path_local]
    cd $hpath
    doexec make install
  }
}

oo::class create  toadkitmodule.tea {
  superclass toadkitmodule.gnumake

  method init_properties {} {
    next
    my variable property
    dict set property linked_statically 0
    dict set property package_version 0.1
    dict set property package_name generic
  }


  method build {} {
    if {[my build_done]} {
      return
    }
    my step_download_do
    my step_compile_do
    my step_install_do
  }
  
  method build_info {} {
    set info [my property build_info_template]
    set linked_statically [my property linked_statically]
    dict set info linked_statically $linked_statically
    if {[my property linked_statically]} {
      if {[file exists [file join [my build_path_local] Makefile]]} {
        set dat [read_sh_file [file join [my build_path_local] Makefile]]
        if {[dict exists $dat LIBS]} {
          dict set info static_linked_libraries [dict get $dat LIBS]
        }
        if {[dict exists $dat PKG_LIB_FILE]} {
          set result {}
          foreach item [dict get $dat PKG_LIB_FILE] {
            lappend result [file normalize [file join [my build_path_local] $item]]
          }
          dict set info static_linked_objects $result
        }
      }
      dict set info static_c_declarations "extern int [my property package_name]_Init(Tcl_Interp*);"
      dict set info static_c_initialization "Tcl_StaticPackage(interp,\"[my property package_name\]\", [my property package_name]_Init, 0)\;"
    } else {
      if {[file exists [file join [my build_path_local] Makefile]]} {
        set dat [read_sh_file [file join [my build_path_local] Makefile]]
        if {[dict exists $dat PKG_LIB_FILE]} {
          set result {}
          foreach item [dict get $dat PKG_LIB_FILE] {
            lappend result [file normalize [file join [my build_path_local] $item]]
          }
          dict set info dynamic_libraries $result
        }
      }
    }
    return $info
  }

  ###
  # topic: 2d4cf424-4730-4c30-7e23-80fae2cd4bb5
  ###
  method make_clean {} {
    set hpath [my build_path_local]
    if {[file exists $hpath/Makefile]} {
      cd $hpath
      catch {doexec make clean} err
    }
    if {[file exists [my install_path]]} {
      file delete -force [my install_path]
    }
  }

  method install_path {} {
    return [file join ${::odie(local_repo)} lib  [my property package_name][my property package_version]]
  }
  
  method build_done {} {
    puts [list [self] build_done [my install_path]]
    return [file exists [my install_path]]
  }

  method zipdir_populate path {
    copy_path [my install_path] [file join $path lib [file tail [my install_path]]]
  } 
}

oo::class create  toadkit.distribution {
  superclass toadkit.tools

  method init_properties {} {
    next
    my variable property
    dict set property version_name {}
  }

  method step_download_do {} {
    error "Not implemented"
  }
}

###
# topic: c41787e2-3851-a3d4-a8c2-5be4411f0f09
###
oo::class create toadkit.distribution.tarball {
  superclass toadkit.distribution
  
  method init_properties {} {
    next
    my variable property
    dict set property  tarball_dir {}
    dict set property tarball_url {}
  }
  
  #method build_path {} {
  #  return [file normalize [file join [my property sandbox] [my property tarball_dir]]]
  #}

  ###
  # topic: 71a7904b-f1fa-bde4-4681-9f8dac88defd
  ###
  method step_download_do {} {
    if {[file exists [my build_path_local]/configure.in]} {
      return
    }
    
    set tarfile [my tarball_file]
    if {![file exists $tarfile]} {
      package require http
      set tmpchan [open $tarfile w]
      fconfigure $tmpchan -translation binary
      puts [list  GETTING [file tail $tarfile] from [my property tarball_url]]
      set token [::http::geturl [my property tarball_url] -channel $tmpchan]
      http::cleanup $token
      close $tmpchan
    }
    cd [my property sandbox]
    file mkdir unpack
    cd unpack
    puts "UNPACKING [file tail [my tarball_file]] to [file tail [my build_path]] in [my property sandbox]"
    catch {doexec tar xfz ../[file tail [my tarball_file]]}
    if {[file tail [my property tarball_dir]] ne [file tail [my build_path]]} {
      puts "RENAMING [my property tarball_dir] to [my build_path]"
      file rename [my property tarball_dir]  [my build_path]
    }
  }

  ###
  # topic: edc7fa99-0a79-f64c-ba7f-404b2c68202b
  ###
  method tarball_file {} {
    return [file join [my property sandbox] [my property package_name][my property package_version].tar.gz]
  }
}

###
# topic: b717b3d4-e18e-a9f1-b72d-5543a28d01d3
###
oo::class create  toadkit.distribution.fossil {
  superclass toadkit.distribution
  
  
  method init_properties {} {
    next
    my variable property
    dict set property fossil_url {}
    dict set property fossil_tag trunk
    dict set property all_steps {
      step_download_do
      step_configure_do
      step_compile_do
      step_install_do
    }
  }
  
  ###
  # topic: fce24db8-63ba-4ad5-6cef-250e97055807
  ###
  method fossil_db {} {
    if {[file exists ~/Developer/[my property module_name].fos]} {
      return [file normalize ~/Developer/[my property module_name].fos]
    }
    if {[file exists ~/Developer/[my property package_name].fos]} {
      return [file normalize ~/Developer/[my property package_name].fos]
    }
    return [file join [my property sandbox] [my property package_name].fos]
  }

  ###
  # topic: d5a2cb0e-641b-cdeb-5e5b-c4003761a1ff
  ###
  method step_download_do {} {
    set build_path [my build_path]
    if {[file exists $build_path]} return
    if {![file exists [my property sandbox]]} {
      file mkdir [my property sandbox]
    }
    if {![file exists [my fossil_db]]} {     
      cd [my property sandbox]
      puts [list GETTING [my fossil_db] from [my property fossil_url]]
      doexec fossil clone [my property fossil_url] [my fossil_db]
    }
    if {![file exists [my build_path]]} {
      puts [list UNPACKING to [my build_path]]
      file mkdir $build_path
      cd $build_path
      if {![file exists [file join $build_path _FOSSIL_]] && ![file exists [file join $build_path .fslckout]]} {
        doexec fossil open [my fossil_db] [my property fossil_tag]
      }
    }
  }
}

oo::class create toadkitmodule.embedded {
  superclass toadkit.tools

}

oo::class create toadkitmodule.script {
  superclass toadkit.tools

  method step_download_do {} {}
  method make_clean {} {
    file delete [my executable]
  }
  method build_done {} {
    if {[file exists [my executable]]} {
      return 1
    }
    return 0
  }
  method executable {} {
    return [file normalize [file join ${::odie(local_repo)} bin [my property executable]]]
  }
  method build {} {
    set fout [open [my executable] w]
    puts $fout [my script]
    close $fout
    doexec chmod a+x [my executable]
  }
  method script {} {
    set tclsh [my property tcl_shell]
    return [string map [list %tclsh% $tclsh] {#!%tclsh%
    
puts "Hello World"
  }]
  }
}

