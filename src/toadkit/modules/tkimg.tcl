toad_module tkimg {
  compile_after dtplite
  package_name tkimg
  package_version 1.4
  tarball_path tkimg
  tarball_url {http://downloads.sourceforge.net/project/tkimg/tkimg/1.4/tkimg1.4.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Ftkimg%2F&ts=1379431225&use_mirror=softlayer-dal}
  tarball_dir tkimg
} {
  superclass toadkit.distribution.tarball toadkitmodule.tea
  
  method step_compile_do {} {
    set hpath [my build_path_local]
    cd $hpath
    my make_env
    catch {doexec make distclean}
    if {![file exists [file join $hpath configure]]} {
      doexec autoconf
    }
    doexec sh ./configure --prefix=${::odie(local_repo)} --with-tcl=${::odie(local_repo)}/lib --with-tk=${::odie(local_repo)}/lib    
    doexec make all
  }
  
  method zipdir_populate path {
    copy_path [file join $::odie(local_repo) lib Img1.4] [file join $path lib [file tail [my install_path]]]
  } 
}