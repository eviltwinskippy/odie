toad_module tkhtml {
  compile_after tk
  package_name Tkhtml
  package_version 3.0
  tarball_dir htmlwidget
  tarball_url {http://tkhtml.tcl.tk/tkhtml3-alpha-16.tar.gz}  
} {
  superclass toadkit.distribution.tarball toadkitmodule.tea

  method build_info {} {
    set info [next]
    dict set info static_c_declarations {
extern int Tkhtml_Init(Tcl_Interp *);
extern int Tkhtml_SafeInit(Tcl_Interp *);}
    dict set info static_c_initialization {
  Tcl_StaticPackage(interp, "Tkhtml", Tkhtml_Init, Tkhtml_SafeInit);
}
    return $info
  } 
  method zipdir_populate path {
    copy_path [file join ${::odie(local_repo)} lib Tkhtml3.0] [file join $path lib Tkhtml3.0]
  }  
}