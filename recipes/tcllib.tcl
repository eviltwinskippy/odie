
sherpa::module tcllib {
  package_name tcllib
  package_version 1.16
  fossil_url {http://fossil.etoyoc.com/fossil/tcllib}
} {
  superclass sherpa.distribution.fossil sherpa.module.gnumake
  
  method sherpa_install {} {
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