###
# Classes used for building
###

namespace eval sherpa {}

###
# Load configuration
###
set here [file dirname [file normalize [info script]]]

source [file join $here .. local.tcl.in]

if {[file exists [file join $here .. local.tcl]]} {
  source [file join $here .. local.tcl]
} elseif {[file exists ~/odie/etc/local.rc]} {
  source ~/odie/etc/local.rc
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
      if {[file isdirectory $file]} {
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
# topic: 4263063e-d13c-afe3-8029-13ee73c732eb
###
proc ::sherpa::module {name properties definition} {
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

proc ::sherpa::metapath {} [list return [file join ${::odie(local_repo)} var sherpa]]

if {[catch {package require sqlite3} err]} {
###
# Version of meta tools to run with no working sqlite
###
proc ::sherpa::meta_get {package args} {
  variable metadata
  if {![dict exists $metadata $package]} {
    return {}
  }
  if {[llength $args] eq 0} {
    return [dict get $metadata $package]
  }
  set result {}
  foreach field $args {
    if {[dict exists $metadata $package $field]} {
      lappend result [dict get $metadata $package $field]
    } else {
      lappend result {}
    }
  }
  return $result
}

proc ::sherpa::meta_clear {package} {
  variable metadata
  dict set metadata $package {}
  meta_signal $package
}

proc ::sherpa::meta_put {package field value} {
  variable metadata
  dict set metadata $package $field $value
  meta_signal $package
}

proc ::sherpa::meta_signal {package} {
  variable nextevent
  after cancel $nextevent
  set nextevent [after idle ::sherpa::meta_backup]
  variable package_updates
  lappend package_updates $package
}

proc ::sherpa::meta_backup {} {
  variable package_updates
  variable metadata
  set path [metapath]
  file mkdir $path
  foreach package $package_updates {
    set fout [open $path/$package.txt w]
    puts $fout "# Manifest of data for package $package"
    foreach {field value} [dict get $metadata $package] {
      puts $fout [list $field $value]
    }
    close $fout
  }
  set package_updates {}
}

proc ::sherpa::read_manifest {} {
  variable metadata
  set path [metapath]
  foreach file [glob -nocomplain $path/*.txt] {
    set fin [open $file r]
    set package [file rootname [file tail $file]]
    while {[gets $fin line] >= 0} {
      if {[string index [string trim $line] 0] eq "#"} continue
      set field [lindex $line 0]
      set value [lindex $line 1]
      dict set metadata $package $field $value
    }
    close $fin
  }
}

} else {
  
proc ::sherpa::meta_clear {package} {
  metadb eval {delete from module_info where package=:package}
  meta_signal $package
}
  
proc ::sherpa::meta_get {package args} {
  if {[llength $args] eq 0} {
    return [metadb eval {select field,value from module_info where package=:package}]
  }
  set result {}
  foreach field $args {
    lappend result [metadb one {select value from module_info where package=:package and field=:field}]
  }
  return $result
}

proc ::sherpa::meta_put {package field value} {
  metadb eval {insert or replace into module_info
(package,field,value) VALUES (:package,:field,:value)}
  meta_signal $package
}

proc ::sherpa::meta_signal {package} {
  variable nextevent
  after cancel $nextevent
  set nextevent [after idle ::sherpa::meta_backup]
  variable package_updates
  lappend package_updates $package
}

proc ::sherpa::meta_backup {} {
  variable package_updates
  set path [metapath]
  file mkdir $path
  foreach package $package_updates {
    set fout [open $path/$package.txt w]
    puts $fout "# Manifest of data for package $package"
    metadb eval {select field,value from module_info where package=:package order by field} {
      puts $fout [list $field $value]
    }
    close $fout
  }
  set package_updates {}
}

proc ::sherpa::read_manifest {} {
  set path [metapath]
  if {![file exists $path]} {
    file mkdir $path
  }
  set idxfile [file join $path sherpa.sqlite]
  if {![file exists $idxfile]} {
    sqlite3 metadb $idxfile
    metadb eval {
create table module_info (
  package string,
  field   string,
  value   string,
  primary key (package,field) on conflict replace
);
insert into module_info (package,field,value) VALUES
('sherpa','schema','0.1');
    }
    foreach file [glob -nocomplain [file join $path *.txt]] {
      set fin [open $file r]
      set package [file rootname [file tail $file]]
      while {[gets $fin line] >= 0} {
        if {[string index [string trim $line] 0] eq "#"} continue
        set field [lindex $line 0]
        set value [lindex $line 1]
        metadb eval {
insert into module_info (package,field,value) VALUES (:package,:field,:value);
        }
      }
      close $fin
    }
  } else {
    sqlite3 metadb $idxfile
  }
}

}

set ::sherpa::nextevent {}
set ::sherpa::metadata {}

###
# topic: 97da9869-4404-8eb3-dfa5-85e37b3a9cab
###
oo::class create sherpa.tools {
  constructor {} {
    my init_properties
  }
  

  ###
  # topic: b704e789-03ac-c3d8-bfcb-be92f7af180a
  ###
  method build_info {} {
    return {}
  }

  ###
  # topic: 9a533dac-a306-5172-14fc-9ac9be931d31
  ###
  method build_path {} {
    return [file normalize [file join $::odie(sandbox) [my property module_name]]]
  }

  ###
  # topic: ebc13ed1-0891-e114-8f0d-07b64f463c18
  ###
  method do_clean {} {
    #file delete -force [my build_path]
  }

  ###
  # topic: d265185c-117f-a4d0-6be6-fe37afbe78f7
  ###
  method do_mkdir {} {
    set build_path [my build_path]
    file mkdir $build_paths
  }

  ###
  # topic: 036758a1-7cb4-7188-08ff-fbba3db8b484
  ###
  method init_properties {} {
    my variable property build_info
    set property {
      compile_after {}
      module_name generic
      active 1
    }
  }

  ###
  # topic: 00897982-75d5-3652-20ce-b54831f074f5
  ###
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

  method sherpa_skip {} { return 0 }
}

###
# topic: 6463c62b-cd01-0acd-4cea-bf9034aa7559
###
oo::class create sherpa.module {
  
  superclass sherpa.tools

  method sherpa_skip {} {
    return 0
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

  method sherpa_platform {} {
    set HOST [lindex $::tcl_platform(os) 0]
    switch $HOST {
      Linux {
        return unix
      }
      Darwin {
        return macosx
      }
    }
    return $::tcl_platform(platform)
  }

  ###
  # topic: a1999f61-4e96-b25f-947f-f18d1594b5b0
  ###
  method build_info {} {
    return [my property build_info_template]
  }

  ###
  # topic: cbba4dc0-4912-e60d-749d-291a7fc88ce5
  ###
  method build_path {} {
    return [file normalize [file join $::odie(sandbox) [my property module_name]]]
  }

  method install_app {src dest} {
    set fin [open $src r]
    set fout [open $dest w]
    gets $fin line
    if {[string trim $line] eq {#! /usr/bin/env tclsh}} {
      puts $fout "#! [list $::odie(tcl_shell)]"
    } elseif {[string trim $line] eq {#! /usr/bin/env wish}} {
      puts $fout "#! [list $::odie(wish_shell)]"
    } else {
      while {[gets $fin line] >= 0} {
        if {[string index $line 0] != "#" } break
        puts $fout $line
      }
      if {[string range $line 0 10] eq "exec tclsh "} {
        puts $fout "exec [list $::odie(tcl_shell)] \"\$0\" \$\{1+\"\$@\"\}"
      } elseif {[string range $line 0 9] eq "exec wish "} {
        puts $fout "exec [list $::odie(wish_shell)] \"\$0\" \$\{1+\"\$@\"\}"
      } else {
        puts $fout $line
      }
    }
    puts $fout [read $fin]
    close $fin
    close $fout
    exec chmod a+x $dest
  }

  method install_forward {src dest} {
    set fin [open $src r]
    set fout [open $dest w]
    gets $fin line
    if {[string trim $line] eq {#! /usr/bin/env tclsh}} {
      puts $fout "#! [list $::odie(tcl_shell)]"
    } elseif {[string trim $line] eq {#! /usr/bin/env wish}} {
      puts $fout "#! [list $::odie(wish_shell)]"
    } else {
      while {[gets $fin line] >= 0} {
        if {[string index $line 0] != "#" } break
        puts $fout $line
      }
      if {[string range $line 0 10] eq "exec tclsh "} {
        puts $fout "exec [list $::odie(tcl_shell)] \"\$0\" \$\{1+\"\$@\"\}"
      } elseif {[string range $line 0 9] eq "exec wish "} {
        puts $fout "exec [list $::odie(wish_shell)] \"\$0\" \$\{1+\"\$@\"\}"
      } else {
        puts $fout $line
      }
    }
    puts $fout [list source $src]
    close $fin
    close $fout
    exec chmod a+x $dest
  }

  method install_capp {src dest} {
    global cc exe
    file delete $dest
    set ofile [file rootname $dest].o
    doexec $cc {*}$::env(CFLAGS)  -o $ofile -c $src
    doexec $cc {*}$::env(CFLAGS) $ofile -o $dest
    file delete $ofile
    exec chmod a+x $dest
  }
  
  ###
  # topic: 936f89f1-33ab-38a3-aa3b-f4cd4d4a26ad
  ###
  method init_properties {} {
    my variable property build_info
    set property {
      compile_after {}
      module_name generic
      active 1
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

  ###
  # topic: e373546a-c6a3-ca68-e80a-c809bfb0ab8c
  ###
  method property_dict {} {
    my variable property
    return $property
  }

  method sherpa_present {} {
    return [string is true -strict [::sherpa::meta_get [my property module_name] installed]]
  }
  method sherpa_download {} {}
  method sherpa_clean {} {}
  method sherpa_install {} {
    # Fill this in with all the code to download,
    # compile, and install this module
    my sherpa_register
  }
  method sherpa_register {} {
    ::sherpa::meta_put [my property module_name] installed 1
  }
  method sherpa_uninstall {} {
    my sherpa_clean
    my sherpa_unregister
  }
  method sherpa_unregister {} {
    ::sherpa::meta_put [my property module_name] installed 0
  }
  method sherpa_upgrade {} {}
  ###
  # description:
  # Detect properties that are only known after download
  ###
  method sherpa_detect_properties {} {}

  ###
  # topic: 2737d134-8143-b96e-1a0d-6ea26a52273d
  ###
  method sherpa_vfs_install path {}

  ###
  # topic: aa2c749e-63a2-0f44-3433-ae4c6d48aa24
  ###
  method test {} {}
}

oo::class create sherpa.virtual {
  superclass sherpa.module
  method sherpa_present {} {
    return 1
  }
}

oo::class create sherpa.module.odie {
  superclass sherpa.module

  method build_path_local {} {
    return [file normalize [file join $::odie(sandbox) odie]]
  }
  
  # Package is distributed with the kitbuilder
  method sherpa_download {} {}

  method sherpa_clean {} {
    foreach app [my property module_packages] {
      set appfile [file join ${::odie(local_repo)} bin $app]
      if {[file exists $appfile]} {
        file delete $appfile
      }
    }
    foreach dir [my property module_packages] {
      set path [file join  ${::odie(local_repo)} lib $dir]
      if {[file exists $path]} {
        file delete -force $path
      }
      set path [file join  ${::odie(local_repo)} zipdir $dir]
      if {[file exists $path]} {
        file delete -force $path
      }      
    }
  }
  
  method sherpa_install {} {
    foreach app [my property module_apps] {
      set srcfile [file join [my build_path_local] apps $app]
      set appfile [file join ${::odie(local_repo)} bin $app]
      my install_app $srcfile $appfile
    }
    foreach dir [my property module_packages] {
      set srcpath [file join [my build_path_local] lib $dir]
      set dpath [file join ${::odie(local_repo)} lib $dir]
      if {[file exists $dpath]} {
        file delete -force $dpath
      }
      copy_path $srcpath $dpath
      ::codebale::pkg_mkIndex $dpath
    }
    my sherpa_register
  }

  method sherpa_vfs_install path {
    foreach dir [my property module_packages] {
      set dest [file join $path lib $dir]
      puts [list [my property module] INSTALL [file join $::odiepath lib $dir] $dest ]
      copy_path [file join $::odiepath lib $dir] $dest
    }
  }
}

oo::class create sherpa.module.library {
  superclass sherpa.module

  method sherpa_install {} {
    my sherpa_download
    set srcpath [my build_path]
    set dpath [file join $::odie(local_repo) lib [my property package_name][my property package_version]]
    file delete -force $dpath

    foreach modpath [glob -nocomplain [file join $srcpath modules *]] {
      set mdpath [file join $dpath [file tail $modpath]]
      copy_path $modpath $mdpath
      if {[file exists [file join $mdpath pkgIndex.tcl]]} {
        file delete [file join $mdpath pkgIndex.tcl]
      }
    }
    foreach file [glob -nocomplain [file join $srcpath apps *]] {
      set exename [file tail $file]
      set destexe [file join $::odie(local_repo) bin $exename]
      if {[file exists $destexe]} {
        my install_app $file $destexe
      }
    }
    ::codebale::pkg_mkIndex $dpath
    my sherpa_register
  }
  
  method sherpa_vfs_install path {
    set srcpath [my build_path]
    set dpath [file join $path lib [my property package_name][my property package_version]]
    file delete -force $dpath
    foreach modpath [glob -nocomplain [file join $srcpath modules *]] {
      copy_path $modpath [file join $dpath [file tail $modpath]]
    }
  }
}

###
# topic: 9dd69d38-637a-0cc2-6582-6cc591b44da7
###
oo::class create sherpa.module.gnumake {
  superclass sherpa.module

  ###
  # topic: 46a31b6f-441c-00c6-60db-3fbbbf13587f
  ###
  method sherpa_install {} {
    my step_compile_do
    my step_install_do
    my sherpa_register
  }

  ###
  # topic: 2feb690d-9a73-8de0-8555-469f424f39d9
  ###
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
  # topic: c81457b0-84e6-6755-29da-1570ba624492
  ###
  method init_properties {} {
    next
    my variable property
    dict set property test_file {}
    dict set property linked_statically 0
  }

  ###
  # topic: 2d4cf424-4730-4c30-7e23-80fae2cd4bb5
  ###
  method sherpa_clean {} {
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
    return
  }

  method step_compile_static {} {
    set hpath [my build_path_local]
    cd $hpath
    my make_env
    if {![file exists [file join $hpath configure]]} {
      doexec autoconf
    }
    if {![file exists [file join $hpath Makefile]]} {
      doexec sh ./configure --prefix=${::odie(local_repo)} --enable-shared=false --with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib --libdir=${::odie(local_repo)}/lib
    }
    doexec make all
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
    if {![file exists [file join $hpath Makefile]]} {
      doexec sh ./configure --prefix=${::odie(local_repo)} --bindir=${::odie(local_repo)}/bin --libdir=${::odie(local_repo)}/lib
      #--with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib
    }
    doexec make all
  }

  ###
  # topic: 2623418b-4baf-4d59-e2a8-7df01b8ddd0f
  ###
  method step_install_do {} {
    set hpath [my build_path_local]
    cd $hpath
    doexec make install
  }
}

###
# topic: 4d3287f3-982d-eaa0-f086-2ad80a0e6177
###
oo::class create sherpa.module.tea {
  superclass sherpa.module.gnumake

  ###
  # topic: e19734aa-4ea0-34c4-7cec-bb9c89accc73
  ###
  method sherpa_install {} {
    my sherpa_download
    my sherpa_detect_properties
    if {[my build_done]} {
      return
    }
    my step_compile_do
    my step_install_do
    my sherpa_register
  }

  ###
  # topic: 81ed8a39-9f8d-7a10-282e-c40ae50d9ca7
  ###
  method build_done {} {
    return [file exists [my install_path]]
  }

  ###
  # topic: 9ee6b1ed-f625-5e3c-33d9-fbbf848b8dd1
  ###
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
  # description:
  # Detect properties that are only known after download
  ###
  method sherpa_detect_properties {} {
    my variable property
    if {[dict get $property package_version] ne {}} {
      if {[dict get $property package_name] ne {}} {
        return
      }
    }
    ###
    # Detect package name and/or version
    ###
    set sandbox [my build_path_local]
    if {![file exists $sandbox/tclconfig]} {
      # Link to tclconfig
      exec ln -s $::odie(sandbox)/tclconfig tclconfig
    }
    set version_detected {}
    if {[file exists $sandbox/configure.in]} {
      set fin [open $sandbox/configure.in]
      while {[gets $fin line] >= 0} {
        set line [string trim $line]
        if {[string range $line 0 6] ne "AC_INIT"} continue
        set line [string range $line 8 end]
        set line [string trimright $line "\)"]
        set line [split $line ,]
        set name [string trimleft [string trimright [string trim [lindex $line 0]] "\]"] "\["]
        set vers [string trimleft [string trimright [string trim [lindex $line 1]] "\]"] "\["]
        dict set property package_name $name
        dict set property package_version $vers
        dict set property install_path [file join ${::odie(local_repo)} lib $name$vers]
        break
      }
      close $fin
    }
  }

  ###
  # topic: 2a16e61c-dd3f-595d-d273-11310e1e750a
  ###
  method init_properties {} {
    next
    
    my variable property
    dict set property linked_statically 0
    dict set property package_version {}
    dict set property package_name {}
  }

  ###
  # topic: c3651334-f227-75fc-2a40-19fe149c72ad
  ###
  method install_path {} {
    return [my property install_path]
  }

  ###
  # topic: 5ab8ae45-3e3b-5bb3-face-9dee03910832
  ###
  method sherpa_clean {} {
    set hpath [my build_path_local]
    set libpath [my property install_path]
    if {[file exists $hpath/Makefile]} {
      cd $hpath
      catch {doexec make clean} err
    }
    if {$libpath eq {} } return
    if {[file exists $libpath]} {
      file delete -force $libpath
    }
  }

  ###
  # topic: dcc47592-0f8c-44f0-c073-6be389a830fd
  ###
  method sherpa_vfs_install path {
    my sherpa_detect_properties
    copy_path [file join $::odie(local_repo) lib [my property package_name][my property package_version]] [file join $path lib [my property package_name][my property package_version]]
  }
}

###
# topic: ad9bc131-ca77-6bc8-7439-886220029f3a
###
oo::class create sherpa.distribution {
  superclass sherpa.tools

  ###
  # topic: 81c4fe70-ebd1-720b-631c-8dfeb66316fb
  ###
  method init_properties {} {
    next
    my variable property
    dict set property version_name {}
  }

  ###
  # topic: 125e58b1-0ba7-0bda-69a4-0e347427a208
  ###
  method sherpa_download {} {
    error "Not implemented"
  }
}

###
# topic: 4f84f19b-46b4-2292-403f-43e283429131
###
oo::class create sherpa.distribution.tarball {
  superclass sherpa.distribution
  
  #method build_path {} {
  #  return [file normalize [file join $::odie(sandbox) [my property tarball_dir]]]
  #}

  ###
  # topic: f6368b7b-0804-8400-8c3d-4c4cdda1e97b
  ###
  method init_properties {} {
    next
    my variable property
    dict set property  tarball_dir {}
    dict set property tarball_url {}
  }

  ###
  # topic: 5d108612-850c-e344-7917-d8c71c6f6d25
  ###
  method sherpa_download {} {
    if {[file exists [my build_path_local]/configure.in]} {
      return
    }
    
    set tarfile [my tarball_file]
    if {![file exists $tarfile]} {
      package require http
      set tmpchan [open $tarfile w]
      fconfigure $tmpchan -translation binary
      puts [list  GETTING [file tail $tarfile] from [my property tarball_url]]
      set token [::http::geturl [my property tarball_url] -channel $tmpchan -binary yes]
      http::cleanup $token
      close $tmpchan
    }
    cd $::odie(sandbox)
    file mkdir unpack
    cd unpack
    puts "UNPACKING [file tail [my tarball_file]] to [file tail [my build_path]] in $::odie(sandbox)"
    file copy -force $::odie(download)/[file tail [my tarball_file]] [file tail [my tarball_file]]
    catch {doexec tar xfz [file tail [my tarball_file]]}
    if {[file tail [my property tarball_dir]] ne [file tail [my build_path]]} {
      puts "RENAMING [my property tarball_dir] to [my build_path]"
      file rename [my property tarball_dir]  [my build_path]
    }
  }

  ###
  # topic: 144b2156-f1de-b1c1-78f3-71de78cadbab
  ###
  method tarball_file {} {
    return [file join $::odie(download) [my property package_name][my property package_version].tar.gz]
  }
}

oo::class create sherpa.module.binary {
  superclass sherpa.module sherpa.distribution

  method sherpa_skip {} {
    set platforms [my property platforms]
    if {[my sherpa_platform] ni $platforms } {
      # Fake like it's there
      return 1
    }
    return 0
  }

  method sherpa_present {} {
    if {[my sherpa_skip]} {
      return 1
    }
    return [string is true -strict [::sherpa::meta_get [my property module_name] installed]]
  }

  method sherpa_download {} {
    if {[my sherpa_skip]} {
      return
    }
    set tarfile [my zip_file]
    if {![file exists $tarfile]} {
      package require http
      set tmpchan [open $tarfile w]
      fconfigure $tmpchan -translation binary
      puts [list  GETTING [file tail $tarfile] from [my property remote_url]]
      set token [::http::geturl [my property remote_url] -channel $tmpchan -binary yes]
      http::cleanup $token
      close $tmpchan
    }
    puts "UNPACK"
    cd $::odie(sandbox)
    catch {doexec upzip $tarfile}
  }

  method sherpa_install {} {
    if {[my sherpa_skip]} {
      return
    }
    copy_path [file join $::odie(sandbox) [my property package_name]] [file join $::odie(local_repo) lib [my property package_name][my property package_version]]
    my sherpa_register
  } 
  

  method sherpa_vfs_install path {
    if {[my sherpa_skip]} {
      return
    }
    copy_path [file join $::odie(sandbox) [my property package_name]] [file join $path lib [my property package_name][my property package_version]]
  } 
  

  method zip_file {} {
    return [file join $::odie(download) [my property package_name].zip]
  }
}

###
# topic: 604e75c8-e06a-4bfe-4aaa-badf67bf29a3
###
oo::class create sherpa.distribution.fossil {
  superclass sherpa.distribution
  
  ###
  # topic: 9e651a76-7d0b-8f3e-e670-925c2da98cf6
  ###
  method fossil_db {} {
    foreach ext {.fossil .fos} {
      set fname  [file join $::odie(download) [my property module_name]$ext]
      if {[file exists $fname]} {
        return $fname
      }
    }
    return $fname
  }

  ###
  # topic: d146502f-0bcd-8d12-9bdf-4718026a7e5c
  ###
  method init_properties {} {
    next
    my variable property
    dict set property fossil_url {}
    dict set property fossil_tag trunk
  }

  ###
  # topic: b0ceb78b-fe72-a635-efee-25d8e5e81714
  ###
  method sherpa_download {} {
    set build_path [my build_path]
    if {[file exists $build_path]} return
    if {![file exists $::odie(sandbox)]} {
      file mkdir $::odie(sandbox)
    }
    if {![file exists $::odie(download)]} {
      file mkdir $::odie(download)
    }
    if {![file exists [my fossil_db]]} {     
      cd $::odie(download)
      doexec fossil clone [my property fossil_url] [my fossil_db]
    }
    if {![file exists [my build_path]]} {
      file mkdir $build_path
      cd $build_path
      if {![file exists [file join $build_path _FOSSIL_]] && ![file exists [file join $build_path .fslckout]]} {
        doexec fossil open [my fossil_db] [my property fossil_tag]
      }
    }
  }
  
  method fossil_info {} {
    set result {}
    cd [my build_path]
    dict set result url [my property fossil_url]
    set dat [exec fossil status]
    foreach line [split $dat \n] {
      if {[lindex $line 0] eq "tags:"} {
        dict set result tags [string trim [lrange $line 1 end]]
        break
      }
      if {[lindex $line 0] eq "checkout:"} {
        set hash [lindex $line end-3]
        set maxdate [lrange $line end-2 end-1]
        dict set result checkout $hash
        dict set result datestamp $maxdate
      }
      if {[lindex $line 0] eq "comment:"} {
        break
      }
    }
    return $result
  }
  
  method sherpa_register {} {
    set mod [my property module_name]
    ::sherpa::meta_clear $mod
    foreach {field value} [my fossil_info] {
      ::sherpa::meta_put $mod $field $value
    }
    ::sherpa::meta_put $mod installed 1
  }
  
  method fossil_sync_and_update {} {
    set mod [my property module_name]
    set dat [::sherpa::meta_get $mod]
    puts "SHERPA SYNC + UPDATE $mod"
    set reregister 0
    cd [my build_path]
    if {![dict exists $dat url] || [dict get $dat url] != [my property fossil_url]} {
      puts "FOSSIL REPOSITORY HAS MOVED. PULLING FROM NEW LOCATION"
      catch {doexec fossil pull [my property fossil_url]}
    }
    catch {doexec fossil update [my property fossil_tag]}
    set info [my fossil_info]
    if {[dict exists $dat checkout]} {
      if {[dict get $info checkout] == [dict get $dat checkout]} {
        if {$reregister} {
          my sherpa_register
        }
        return 0
      }
    }
    return 1
  }
  
  method sherpa_upgrade {} {
    if {![my sherpa_present]} {
      return 0
    }
    if {![my fossil_sync_and_update]} {
      return 0
    }
    puts "New version of [my property module_name] available. Recompiling..."
    my sherpa_clean
    my sherpa_install
    return 1
  }
}

###
# topic: 4f84f19b-46b4-2292-403f-43e283429131
# description: Grab extensions from the teapot
# NOTE:
# Using ActiveState binaries for your own purposes is kosher,
# but redistributing them requires a license agreement.
###
oo::class create sherpa.module.teapot {
  superclass sherpa.tools


  
  method sherpa_download {} {
    
  }
  
  method tarball_file {} {
    return [file join $::odie(download) [my property package_name][my property package_version].tar.gz]
  }

}

###
# topic: feb6d273-2bdb-ce01-cf6d-b996b96133a0
###
oo::class create sherpa.module.embedded {
  superclass sherpa.module
}

oo::class create sherpa.module.program {
  superclass sherpa.module

  ###
  # topic: 583fd121-49ab-74f3-d07c-0042e995c1ae
  ###
  method build_done {} {
    if {[file exists [my executable]]} {
      return 1
    }
    return 0
  }


  ###
  # topic: 8a91c733-f4a1-7979-9024-646b64032c6d
  ###
  method executable {} {
    return [file normalize [file join ${::odie(local_repo)} bin [my property executable]]]
  }

  ###
  # topic: 98f0562f-cfa8-f562-bc0d-89bf9cf2b1d2
  ###
  method sherpa_clean {} {
    file delete [my executable]
  }
  
  ###
  # topic: 0c78a27d-9e71-3c3e-1bcd-93390c60cb6f
  ###
  method sherpa_download {} {}

  method sherpa_upgrade {} {
    return 0
  }
}

###
# topic: e9d29909-c4cc-8950-18b9-f03a85ca0160
###
oo::class create sherpa.module.script {
  superclass sherpa.module.program

  ###
  # topic: 7a53a290-8022-9478-708c-719412d9b0c3
  ###
  method sherpa_install {} {
    set fout [open [my executable] w]
    puts $fout [my script]
    close $fout
    doexec chmod a+x [my executable]
    my sherpa_register
  }

  ###
  # topic: d7b63296-34af-7f91-43b1-acb91b938550
  ###
  method script {} {
    set tclsh [my property tcl_shell]
    return [string map [list %tclsh% $tclsh] {#!%tclsh%
    
puts "Hello World"
  }]
  }
}

oo::class create sherpa.module.cexecutable {
  superclass sherpa.module.program

  ###
  # topic: 7a53a290-8022-9478-708c-719412d9b0c3
  ###
  method sherpa_install {} {
    catch {doexec $cc {*}$::env(CFLAGS)  -o zzipsetupstub.o -c $::odie(sandbox)/odie/src/apps/zzipsetupstub.c} err

    set fout [open [my executable] w]
    puts $fout [my script]
    close $fout
    doexec chmod a+x [my executable]
    my sherpa_register
  }
  
}

###
# Begin the execution here
###

if {$tcl_platform(platform) == "windows"} {
  set exe .exe
} else {
  set exe {}
}

###
# Detect our build environment from tclConfig.sh and tkConfig.sh
###
set stripexe strip
if {![info exists ::env(LDFLAGS)]} {
  set ::env(LDFLAGS) {}
}
if {![info exists ::env(CFLAGS)]} {
  set ::env(CFLAGS) {}
}

set dat [read_sh_file ${odie(local_repo)}/lib/tclConfig.sh]
set cc [dict get $dat TCL_CC]
set defs [dict get $dat TCL_DEFS]
if {[dict exists $dat TCL_LD_FLAGS]} {
  set ::env(LDFLAGS) [dict get $dat TCL_LD_FLAGS]
}
if {[dict exists $dat TCL_EXTRA_CFLAGS]} {
  set ::env(CFLAGS) [dict get $dat TCL_EXTRA_CFLAGS]
}

foreach file [glob [file dirname [info script]]/*.tcl] {
  if {[file tail $file] eq "index.tcl"} continue
  source $file
}

if {[file exists ~/odie/etc/sherpa.rc]} {
  source ~/odie/etc/sherpa.rc
}

set order {}
set sorted {}
set allmod [lsort -dictionary [array names modules]]
while 1 {
  set done 1
  foreach {mod object} [lsort -stride 2 [array get modules]] {
    if { $mod in $order } continue
    set after [$object property compile_after]
    if {$after eq {}} {
      lappend order $mod
    } else {
      set idx [lsearch $allmod $after]
      if { $idx < 0} {
        error "$mod requested to be after $after, which wasn't registered in $allmod"
      }
      set idx [lsearch $order $after]
      if { $idx < 0 } {
        set done 0
      } else {
        set order [linsert $order [expr {$idx+1}] $mod]
      }
    }
  }
  if {$done} break
}

proc ::toadkit_order {} [list return $order]

::sherpa::read_manifest
