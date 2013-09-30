###
# Downloads, configures, and compiles Tcl
###
toad_module canvas3d {
    fossil_tag v1.2
    compile_after tk
    fossil_url http://3dcanvas.tcl.tk/fossil
    version_name Canvas3d1.2
    package_name Canvas3d
    package_version 1.2
} {
  superclass toadkit.distribution.fossil toadkitmodule.tea
  
  method build_info {} {
    set info [next]
    dict set info static_c_declarations {
extern int Canvas3d_Init(Tcl_Interp*);}
    dict set info static_c_initialization {
  Tcl_StaticPackage(interp,"Canvas3d", Canvas3d_Init, 0);
}
    return $info
  }

  method static_linked_objects {} {
    return [list [file normalize [file join [my build_path] [my static_products]]]]
  }
  
  method zipdir_populate path {
    if {[my property linked_statically]} {
      file copy -force [file join [my build_path] c3dshapes.tcl] [file join $path c3dshapes.tcl]
    } else {
      copy_path [my install_path] [file join $path lib [file tail [my install_path]]]
    }
  }

  method fossil_db {} {
    return [file join [file dirname [my build_path]] [my property module_name].fos]
  }
}