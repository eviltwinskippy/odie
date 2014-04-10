sherpa::module tk {
  package_name tk
  package_version 8.6.1
} {
  superclass sherpa.virtual
  
  method sherpa_vfs_install path {
    set libroot [file join ${::odie(local_repo)} lib]

    file mkdir [file join $path tk8.6]  
    foreach lpath [glob [file join $libroot tk8.6 *]] {
      copy_path $lpath [file join $path tk8.6]
    }
  }
}