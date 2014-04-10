sherpa::module sqlite {
  aliases tclsqlite
  package_name sqlite
  package_version 3.8.4.1
  tarball_dir sqlite-autoconf-3080401
  tarball_url {http://sqlite.org/2014/sqlite-autoconf-3080401.tar.gz}
} {
  superclass sherpa.distribution.tarball sherpa.module.gnumake
  
  method build_path_local {} {
    set path [file join [my build_path] tea]
    return $path
  }

  method sherpa_vfs_install path {
    copy_path [file join $::odie(local_repo) lib [my property package_name][my property package_version]] [file join $path lib [my property package_name][my property package_version]]
  } 
}
