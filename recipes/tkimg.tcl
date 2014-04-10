sherpa::module tkimg {
  compile_after tcllib
  package_name Img
  package_version 1.4.2
  fossil_tag trunk
  fossil_url http://fossil.etoyoc.com/fossil/tkimg
} {
  superclass sherpa.distribution.fossil sherpa.module.tea
  
  method step_compile_do {} {
    set hpath [my build_path_local]
    cd $hpath
    my make_env
    catch {doexec make distclean}
    if {![file exists [file join $hpath configure]]} {
      doexec autoconf
    }
    doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib --libdir=${::odie(local_repo)}/lib 
    doexec make all
  }
  
  method sherpa_vfs_install path {
    copy_path [file join $::odie(local_repo) lib [my property package_name][my property package_version]] [file join $path lib [my property package_name][my property package_version]]
  } 
}