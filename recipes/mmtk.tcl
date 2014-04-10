###
# Downloads, configures, and compiles Tcl
###
sherpa::module mmtk {
    fossil_tag trunk
    fossil_url http://fossil.etoyoc.com/fossil/mmtk
    package_name MMTk
    package_version 0.1
} {
  superclass sherpa.distribution.fossil sherpa.module.tea
  
  method build_info {} {
    set info [next]
    dict set info static_c_declarations {
extern int Canvas3d_Init(Tcl_Interp*);}
    dict set info static_c_initialization {
  Tcl_StaticPackage(interp,"MMTk", MMTk_Init, 0);
}
    return $info
  }

  method static_linked_objects {} {
    return [list [file normalize [file join [my build_path] [my static_products]]]]
  }
  
  method sherpa_vfs_install path {
    if {[my property linked_statically]} {
      file copy -force [file join [my build_path] c3dshapes.tcl] [file join $path c3dshapes.tcl]
    } else {
      copy_path [file join $::odie(local_repo) lib [my property package_name][my property package_version]] [file join $path lib [my property package_name][my property package_version]]
    }
  }
}