toad_module dtplite {
  compile_after tcllib
  executable dtplite  
} {
  superclass toadkitmodule.script

  method script {} {
    set tclsh [my property tcl_shell]
    set local_repo ${::odie(local_repo)}
    return [string map [list %tclsh% $tclsh %local_repo% $local_repo] {#!%tclsh%
    
#
# DTPLITE
# Wrapper to produce a DTP lite binary
#

if [catch {package require dtplite}] {
  source [file join %local_repo% lib tcllib1.15 dtplite dtplite.tcl]
}

::dtplite::ProcessCmdline $argv
  }]
  }
}