
set ::odiepath [file normalize [file join [file dirname [file normalize [info script]]] .. .. ..]]

sherpa::module odie {
    fossil_tag trunk
    fossil_url http://fossil.etoyoc.com/fossil/odie
    package_name odie
    package_version 0.1
} {
  superclass sherpa.distribution.fossil sherpa.module.tea
  
  method sherpa_clean {} {
  }
  
  method sherpa_install {} {
    ###
    # Build the mini-applications that the rest of the build uses
    ###
    global exe
    
    my sherpa_register
    foreach cfile {
      mkhdr.c
      zzipsetupstub.c
    } {
      my install_capp ${::odie(local_repo)}/sandbox/odie/apps/$cfile ${::odie(local_repo)}/bin/[file rootname $cfile]$exe
    }
    
    foreach tclfile {
      mktclopts.tcl
    } {
      my install_app ${::odie(local_repo)}/sandbox/odie/apps/$tclfile ${::odie(local_repo)}/bin/[file rootname $tclfile]$exe
    }
    foreach tclfile {
      sherpa.tcl
    } {
      my install_forward ${::odie(local_repo)}/sandbox/odie/apps/$tclfile ${::odie(local_repo)}/bin/[file rootname $tclfile]$exe
    }
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

  method sherpa_upgrade {} {
    my fossil_sync_and_update
    my sherpa_register
  }
  
  method sherpa_vfs_install args {}
}

#sherpa::module sherpa {
#  module_apps {sherpa}
#  module_packages {odie odieutil calendar}
#} {
#  superclass sherpa.module.odie
#}

sherpa::module taohttpd {
  module_apps {httpd.tcl}
  module_packages {llama ohai tclhttpd webshed tao-httpd}
} {
  superclass sherpa.module.odie
}
