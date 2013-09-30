###
# Downloads, configures, and compiles Tcl
###
if {$::tcl_platform(platform) eq "windows"} {
###
# A wrapper around the msys-zip package
###
toad_module zip {
  active 1
} {
  superclass toadkitmodule

  method build_done {} {
    if {![file exists /usr/bin/zip.exe]} {
      return 0
    }
    if 
  }
  
  method build {} {
    if {[my build_done]} {
      return
    }
    doexec mingw-get.exe install msys-zip
    doexec mingw-get install zlib 
    doexec mingw-get install msys-zlib-dev 
  }
}
} else {
toad_module zip {
  active 1
  tarball_url http://downloads.sourceforge.net/infozip/zip30.tar.gz
  tarball_dir zip30
  package_name zip
  package_version 30
  compile_after {}
} {
  superclass toadkit.distribution.tarball toadkitmodule.gnumake

  method build {} {
    if {[my build_done]} {
      return
    }
    my step_download_do
    my step_compile_do
    my step_install_do
  }
  
  method build_done {} {
    if {[file exists /usr/bin/zip]} {
      return 1
    }
    set lpath ${::odie(local_repo)}
    if {[file exists $lpath/bin/zip]} {
      return 1
    }
    if {[file exists $lpath/bin/zip.exe]} {
      return 1
    }
    return 0
  }
  
  method step_compile_do {} {
    set hpath [my build_path_local]
    my make_env

    if {![file exists [file join $hpath unix/Makefile]]} {
      cd $hpath/unix
      doexec sh ./configure --prefix=${::odie(local_repo)}
    }
    cd $hpath    
    doexec make -f unix/Makefile generic_gcc
  }
  
  method step_install_do {} {
    set hpath [my build_path_local]
    cd $hpath
    doexec make -f unix/Makefile install prefix=${::odie(local_repo)}
  }
}
}