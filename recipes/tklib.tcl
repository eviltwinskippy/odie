
sherpa::module tklib {
  package_name tklib
  package_version 0.6
  fossil_url {http://fossil.etoyoc.com/fossil/tklib}
} {
  superclass sherpa.distribution.fossil sherpa.module.gnumake
  
  method step_install_do {} {
    next
    set hpath [my build_path_local]
    foreach file [glob -nocomplain [file join $hpath apps *]] {
      set exename [file tail $file]
      set destexe [file join $::odie(local_repo) bin $exename]
      if {[file exists $destexe]} {
        my install_app $file $destexe
      }
    }
  }
  
  method sherpa_vfs_install path {
    copy_path [file join $::odie(local_repo) lib [my property package_name][my property package_version]] [file join $path lib [my property package_name][my property package_version]]
  }
}