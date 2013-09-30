toad_module sqlite {
  compile_after tcl
  package_name sqlite
  package_version 3.7.17
  tarball_dir sqlite-autoconf-3071700
  tarball_url {http://www.sqlite.org/2013/sqlite-autoconf-3071700.tar.gz}
} {
  superclass toadkit.distribution.tarball toadkitmodule.tea
  
  method build_path_local {} {
    set path [file join [my build_path] tea]
    return $path
  }
  
  method build_info {} {
    set info {
      linked_statically 0
      static_c_headers {}
      static_c_declarations {}
      static_c_initialization {}
      static_linked_libraries {}
      static_linked_objects {}
      dynamic_libraries {}
      script_libraries {}
    }
    dict set info linked_statically [my property linked_statically]
    dict set info static_linked_objects [list \
      [file normalize [file join [my build_path_local] libsqlite3.7.17.a]]   \
      [file normalize [file join [my build_path_local] tclsqlite3.o]] \
    ]
    if {[file exists [my build_path_local]/Makefile]} {
      set dat [read_sh_file [my build_path_local]/Makefile]
      if {[dict exists $dat LIBS]} {
        dict set info static_linked_libraries [dict get $dat LIBS]
      }
    }
    dict set info static_c_declarations {extern int Sqlite3_Init(Tcl_Interp*);}
    dict set info static_c_initialization {Tcl_StaticPackage(interp,"sqlite3", Sqlite3_Init, 0);}
    return $info
  }


  
}