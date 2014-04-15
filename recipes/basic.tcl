###
# Packages which simply unpack into the sandbox
###
foreach {mod props} {
  tclconfig
} {
  set properties "
    module $mod
    fossil_url [list http://fossil.etoyoc.com/fossil/$mod]
  "
  lappend properties {*}$props
  sherpa::module $mod $properties {
    superclass sherpa.distribution.fossil sherpa.module
  }
}

###
# Really simple modules that are tea based an distributed as fossil clones
###

foreach {mod props} {
  tdbc          {}
  tdbcmysql     {compile_after tdbc}
  tdbcodbc      {compile_after tdbc}
  tdbcpostgres  {compile_after tdbc}
  tdbcsqlite    {compile_after tdbc}
  sampleextension {}
  tkhtml        {}
  canvas3d      {}
  odielib       {}
  bonjour       {}
} {
  set properties "
    module $mod
    fossil_url [list http://fossil.etoyoc.com/fossil/$mod]
  "
  lappend properties {*}$props
  sherpa::module $mod $properties {
    superclass sherpa.distribution.fossil sherpa.module.tea
  }
}
