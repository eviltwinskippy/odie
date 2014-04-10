###
# topic: 564e9ef0-f212-f1a7-a856-f25df2f6ffeb
# description: Downloads, configures, and compiles Tcl
###
proc ::which_tcl {} {
  switch $::tcl_platform(os) {
    Linux {
      return core-8-6-0
    }
    default {
      return core-8-6-1
    }
  }
}

sherpa::module tcl {
  package_name tcl
  package_version 8.6.1
} {
  superclass sherpa.virtual
  
  method sherpa_vfs_install path {
    set libroot [file join ${::odie(local_repo)} lib]

    file mkdir [file join $path tcl8.6]  
    foreach lpath [glob [file join $libroot tcl8.6 *]] {
      copy_path $lpath [file join $path tcl8.6]
    }
    file mkdir [file join $path tcl8]
    foreach lpath [glob [file join $libroot tcl8 *]] {
      copy_path $lpath [file join $path tcl8]
    }
  }
}