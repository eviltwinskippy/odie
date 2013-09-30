
set ::odiepath [file normalize [file join [file dirname [file normalize [info script]]] .. .. ..]]
toad_module odie {} {
  superclass toadkitmodule
  
  # Package is distributed with the kitbuilder
  method step_download_do {} {}
  method make_clean {} {
    foreach dir {odie tao taotk} {
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
  method build {} {
    puts $::odiepath
    foreach dir {odie tao taotk} {
      copy_path [file join $::odiepath lib $dir] [file join ${::odie(local_repo)} lib $dir]
    }
  }
  method zipdir_populate path {
    foreach dir {odie tao taotk} {
      copy_path [file join $::odiepath lib $dir] [file join $path lib $dir]
    }
  } 
}