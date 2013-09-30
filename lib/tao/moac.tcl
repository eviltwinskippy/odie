#oo::define oo::class {
#  destructor {
#    ::tao::class_destroy [self]
#  }
#}
if {[info command ::tao::metaclass] eq {}} {
  oo::class create ::tao::metaclass {
    superclass ::oo::class
    
    method property args {
      set self [self]
      set l [llength $args]
      if {$l==0} {
        return [::tao::db eval {select property,dict from property where class=:self and type='const'}] 
      }
      if {$l==1} {
        set field [lindex $args 0]
        return [::tao::db one {select dict from property where class=:self and type='const' and property=:field}]
      }
      set result {}
      foreach field $args {
        lappend result $field
        lappend result [::tao::db one {select dict from property where class=:self and type='const' and property=:field}]
      }
    }
    
    destructor {
      ::tao::class_destroy [self]
    }
  }
}

###
# topic: 5539066c-3e90-2cbd-b008-77a2eb4e7acd
# title: Mother of all Classes
# description:
#    Base class used to define a global
#    template of expected behaviors
###
tao::class moac {
  
  variable signals_pending {}
  variable signals_processed {}
  variable organs {}
  variable ActiveLocks configure
  option trace {
    widget boolean
    default 0
  }
  option_class variable {
    widget entry
    set-command {my Variable_set %field% %value%}
    get-command {my Variable_get %field%}
  }
  option_class organ {
    widget label
    set-command {my Option_graft %field% %value%}
    get-command {my organ %field%}
  }
  option_class property {
    widget label
    default-command {my property %field%}
  }

  property options_strict 0

  constructor args {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my initialize
  }

  destructor {}

  ###
  # topic: 314734df-a363-2ac2-5678-f97786b6ae0a
  # description: Indicate to the user that the program is processing
  ###
  method action::busy {
  }

  ###
  # topic: 745b09e9-08d5-5b6d-f6a1-a3c6093e374e
  # description: Commands to run when the system releases the gui
  ###
  method action::idle {}

  ###
  # topic: c5faad4a-7324-ab35-accc-ca2c00d6ac84
  ###
  method action::pipeline_busy {} {}

  ###
  # topic: aa0aa225-1e49-b9e7-7673-446cf7b68e4e
  # description: Commands to run when the system releases the locks
  ###
  method action::pipeline_idle {} {}

  ###
  # topic: 326e7af2-0603-acca-3a51-6ba1f703e405
  ###
  method cget {field {default {}}} {
    my variable config
    set field [string trimleft $field -]
    set dat [my property option dict]
    if {![dict exists $dat $field]} {
      error "Invalid option -$field. Valid: [dict keys $dat]"
    }
    set info [dict get $dat $field]
    if {$default eq "default"} {
      set getcmd [dictGet $info default-command]
      if {$getcmd ne {}} {
        return [{*}[string map [list %field% $field %self% [self]] $getcmd]]
      } else {
        return [dictGet $info default]
      }
    }
    set getcmd [dictGet $info get-command]
    if {$getcmd ne {}} {
      return [{*}[string map [list %field% $field %self% [self]] $getcmd]]
    }
    if {![dict exists $config $field]} {
      set getcmd [dictGet $info default-command]
      if {$getcmd ne {}} {
        dict set config $field [{*}[string map [list %field% $field %self% [self]] $getcmd]]
      } else {
        dict set config $field [dictGet $info default]
      }
    }
    if {$default eq "varname"} {
      set varname [my varname visconfig]
      set ${varname}($field) [dict get $config $field]
      return "${varname}($field)"
    }
    return [dict get $config $field]
  }

  ###
  # topic: 6065ce3e-0a2f-0a4c-ed5f-9984b579cd05
  ###
  method code {} {
    return [namespace code {self}]
  }

  ###
  # topic: 14356671-973b-9bac-e8ca-0de32b8edd86
  ###
  method configure args {
    set dictargs [::tao::args_to_options {*}$args]
    if {[llength $dictargs] == 1} {
      return [my cget [lindex $dictargs 0]]
    }
    my configurelist $dictargs
    my configurelist_triggers $dictargs
  }

  ###
  # topic: 8619ccc4-4f6d-d35e-b20c-31491eb7c83d
  ###
  method configurelist dictargs {
    my variable config

    set dat [my property option dict]
    if {[my property options_strict]} {
      foreach {field val} $dictargs {
        if {![dict exists $dat $field]} {
          error "Invalid option $field. Valid: [dict keys $dat]"
        }
      }
    }
    ###
    # Validate all inputs
    ###
    foreach {field val} $dictargs {
      set script [dictGet $dat $field validate-command]
      if {$script ne {}} {
        {*}[string map [list %field% [list $field] %value% [list $val] %self% [self]] $script]
      }
    }
    ###
    # Apply all inputs with special rules
    ###
    foreach {field val} $dictargs {
      set script [dictGet $dat $field set-command]
      if {$script ne {}} {
        {*}[string map [list %field% [list $field] %value% [list $val] %self% [self]] $script]
      } else {
        dict set config $field $val
      }
    }
  }

  ###
  # topic: 5e0413cb-1ecd-efc1-746b-f7c82cc33a5d
  ###
  method configurelist_triggers dictargs {
    set dat [my property option dict]
    ###
    # Apply normal inputs
    ###
    foreach {field val} $dictargs {
      my Option_set $field $val
    }
  }

  ###
  # topic: 3c54cd52-e671-de60-2102-ebf9d5562a2d
  ###
  method debugOut string {}

  ###
  # topic: 52dd304d-6df8-aadc-4a60-eb3f2e5b6b03
  ###
  method event {submethod args} {
    ::tao::event::$submethod [self] {*}$args
  }

  ###
  # topic: e04b7ac7-2d11-853d-e591-28469a01f1b8
  ###
  method forward {method args} {
    oo::objdefine [self] forward $method {*}$args
  }

  ###
  # topic: 92971042-7138-47f7-88b0-7704312df200
  ###
  method get {{field {}}} {
    if { $field == {} } {
      set result {}
      foreach f [::info object vars [self]] {
        my variable $f
        if {[array exists $f]} {
          dict set result @$f [::array get $f]
        } else {
          dict set result $f [set $f]
        }
      }
      return $result
    }
    my variable $field
    if {[array exists $field]} {
      return [::array get $field]
    }
    if {[info exists $field]} {
      return [set $field]
    }
    return {}
  }

  ###
  # topic: 7be7adbd-32da-8c19-909a-eab4d140fce4
  ###
  method getVarname field {
    return [my varname $field]
  }

  ###
  # topic: e1c1cccb-5201-997d-e0c5-4e04394b61e2
  ###
  method graft args {
    my variable organs
    if {[llength $args] == 1} {
      error "Need two arguments"
    }
    set object {}
    foreach {stub object} $args {
      set stub [string trimleft $stub /]
      dict set organs $stub $object
      # Create a public reference
      my forward ${stub} $object
      # Create a private reference for style
      my forward <${stub}> $object
      #my forward <${stub} $object
      #my forward ${stub}> $object
    }
    return $object
  }

  ###
  # topic: cc411e96-8d4d-634e-e3c4-c3ab15f4a935
  # description:
  #    Called during the constructor to
  #    set up all local variables and data
  #    structures. It is a seperate method
  #    to ensure inheritence chains predictably
  #    and also to keep us from having to pass
  #    along the constructor's arguments
  ###
  method initialize {} {}

  ###
  # topic: a60f53f5-b738-9a1d-2dc9-2f1d7ecb2eff
  # description:
  #    Provide a default value for all options and
  #    publically declared variables, and locks the
  #    pipeline mutex to prevent signal processing
  #    while the contructor is still running.
  #    Note, by default an odie object will ignore
  #    signals until a later call to <i>my lock remove pipeline</i>
  ###
  method InitializePublic {} {
    my variable config
    if {![info exists config]} {
      set config {}
    }
    set dat [my property option dict]
    foreach {var info} $dat {
      if {[dict exists $info set-command]} {
        if {[catch {my cget $var} value]} {
          dict set config $var [my cget $var default]
        } else {
          if { $value eq {} } {
            dict set config $var [my cget $var default]
          }
        }
      }
      if {![dict exists $config $var]} {
        dict set config $var [my cget $var default]
      }
    }
    set vardict [my property variable dict]
    foreach {var default} $vardict {
      if { $var eq "config" } continue
      my variable $var
      if {![info exists $var]} {
        set $var $default
      }
    }
  }

  ###
  # topic: 4d020d2b-1dc4-b997-b50d-12a5c5324ee9
  ###
  method lock::active {} {
    my variable ActiveLocks
    return $ActiveLocks
  }

  ###
  # topic: d4aa2ecc-e73c-8f78-38f0-d7f6aec1017d
  ###
  method lock::create args {
    my variable ActiveLocks
    set result 0
    foreach lock $args {
      if { $lock in $ActiveLocks } {
        set result 1
      } else {
        lappend ActiveLocks $lock
      }
    }
    return $result
  }

  ###
  # topic: 066243d9-4bde-2e4f-ea3c-532519aa8d52
  ###
  method lock::peek args {
    my variable ActiveLocks
    set result 0
    foreach lock $args {
      if { $lock in $ActiveLocks } {
        set result 1
      }
    }
    return $result
  }

  ###
  # topic: b76ea7d5-b9c7-8561-897e-8926aaf5b7d3
  ###
  method lock::remove args {
    my variable ActiveLocks
    if {![llength $ActiveLocks]} {
      return 0
    }
    logicset remove ActiveLocks {*}$args
    if {![llength $ActiveLocks]} {
      my lock remove_all
      return 1
    }
    return 0
  }

  ###
  # topic: 71d752aa-320b-c13b-c027-f89ecc59c4d6
  # description: Force-Removes all locks
  ###
  method lock::remove_all {} {
    my variable ActiveLocks
    set ActiveLocks {}
    my Signal_pipeline
  }

  ###
  # topic: df00845e-dcbf-6f93-65b9-ee824513102a
  ###
  method morph newclass {
    my lock create morph
    set class [string trimleft [info object class [self]]]
    set newclass [string trimleft $newclass :]
    if {[info command ::$newclass] eq {}} {
      error "Class $newclass does not exist"
    }
    if { $class ne $newclass } {
      oo::objdefine [self] class ::${newclass}
      my variable config
      set savestate $config
      my InitializePublic
      my configurelist $savestate
    }
    my lock remove morph
  }

  ###
  # topic: 097b4bc9-cb41-a640-dc1b-2e3c7bb540f7
  ###
  method mutex::down flag {
    my variable mutex
    if {![info exists mutex($flag)]} {
      set mutex($flag) 0
    }
    set value $mutex($flag)
    set mutex($flag) 0
    return $value
  }

  ###
  # topic: f6ca9969-19c5-a68f-efc4-6498141f69c5
  ###
  method mutex::peek flag {
    my variable mutex
    if {![info exists mutex($flag)]} {
      set mutex($flag) 0
    }
    return $mutex($flag)
  }

  ###
  # topic: 9411686e-a278-c11b-f564-b4bad642e85a
  ###
  method mutex::up flag {
    my variable mutex
    if {![info exists mutex($flag)]} {
      set mutex($flag) 0
    }
    if {[set mutex($flag)] > 0} {
      return 1
    }
    set mutex($flag) 1
    return 0
  }

  ###
  # topic: 822295ec-6348-6b83-b551-0d84e310b57f
  # description: Provide a quiet null handler for events
  ###
  method notify::default {event sender eventinfo} {}

  ###
  # topic: b0a19f1e-37d8-9986-1766-0bf6d73d1d5a
  ###
  method Option_get::default {} {
    my variable $method
    if {[info exists $method]} {
      return [set $method]
    }
    return {}
  }

  ###
  # topic: 063d313d-838c-cae5-82d6-202a0dabc67d
  ###
  method Option_graft {organ pointer} {
    my variable config
    if { $pointer ne {} } {
      dict set config $organ $pointer
      my graft $organ $pointer
    }
  }

  ###
  # topic: be2032a1-a895-c4bb-71bb-9510ad767b59
  ###
  method Option_noop args {
  }

  ###
  # topic: 87183fa8-5f70-d09e-9dae-2f66e2ffb2da
  # description: Default handler for options
  ###
  method Option_set::default newvalue {
    my variable $method
    if {[info exists $method]} {
      set $method $newvalue
    }
  }

  ###
  # topic: 3f0b7f48-ed3b-d2d9-bf96-f7c8ca506146
  ###
  method organ {{stub all}} {
    my variable organs
    if {![info exists organs]} {
      return {}
    }
    if { $stub eq "all" } {
      return $organs
    }
    return [dictGet $organs $stub]
  }

  ###
  # topic: d8319395-fecc-61c1-41df-eb9eec220461
  ###
  method private {method args} {
    return [my $method {*}$args]
  }

  ###
  # topic: 32e39448-14cb-a506-7507-4fee4eb130d4
  ###
  method proxy who {
    return [$who code]
  }

  ###
  # topic: 886b734b-f9a9-8aa7-82e8-f77b9a42c344
  ###
  method put args {
    if { [llength $args] == 1 } {
      set args [lindex $args 0]
    }
    foreach {key val} [::tao::args_to_dict {*}$args] {
      string trimleft $key -
      my variable $key
      set $key $val
    }
  }

  ###
  # topic: 5b9a51d5-e327-84f0-8cb7-973e8f4115f0
  ###
  method sensai object {
    foreach {stub obj} [$object organ all] {
      my graft $stub $obj
    }
  }

  ###
  # topic: 8d766b04-68b7-850a-fd91-ab0e2cad3473
  # description: Does nothing
  ###
  method signal args {
    set rawlist [::tao::args_to_dict {*}$args]
    my variable signals_pending signals_processed
        
    set sigdat [my property signal dict]
    ###
    # Process incoming signals
    ###
    set signalmap $signals_pending
    foreach rawsignal $rawlist {
      ::tao::signal_expand $rawsignal $sigdat signalmap
    }

    set newsignals {}
    foreach signal $signalmap {
      if {$signal in $signals_processed} continue
      if {$signal in $signals_pending} continue
      set action [dict get $sigdat $signal action]
      if {[string length $action]} {
        lappend newsignals $signal
        lappend signals_pending $signal
      }
      set apply_action [dict get $sigdat $signal apply_action]
      if {[string length $apply_action]} {
        eval $apply_action
      }
    }
    if {[llength [my lock active]]} {
      return
    }

    if {("idle" in $rawlist && [llength $signals_pending]) || [llength $newsignals] } {
      set event [my event schedule signal idle [namespace code {my Signal_pipeline}]]
    } else {
      set event {}
    }
    return [list $event $signals_pending]
  }

  ###
  # topic: 29052202-645e-e414-a695-33fa7d918cc5
  ###
  method Signal_pipeline {} {
    if {[my mutex up pipeline]} {
      ###
      # Prevent the pipeline from being entered twice
      ###
      return
    }
    set trace [my cget trace]
    my action pipeline_busy
    set sigdat [my property signal dict]
    my variable signals_pending signals_processed
    set order [my property meta signal_order]
    set pass 0
    if {$trace} {
      puts [list [self] [self method] $signals_pending]
    }
    if [catch {
    while {[llength [set signals $signals_pending]]} {
      ###
      # Copy our pending signals and clear out the list
      ###
      set signals_pending {}
      # Ignore mutually exclusive tasks
      set ignored {}
      foreach signal $order {
        if { $signal in $signals && $signal ni $ignored } {
          foreach item [dict get $sigdat $signal excludes] {
            logicset add ignored $item
          }
        }
      }      
      ###
      # Fire off signals in the order calculated
      ###
      foreach signal $order {
        if { $signal in $signals && $signal ni $ignored } {
          set action [dict get $sigdat $signal action]
        }
      }
      foreach signal $order {
        if { $signal in $signals && $signal ni $ignored } {
          lappend signals_processed $signal
          if {$trace} {
            puts [list $signal [dict get $sigdat $signal action]]
          }
          eval [dict get $sigdat $signal action]
        }
      }
      update idletasks
    }
    } err] {
      my message error $err $::errorInfo
    }
    my action pipeline_idle
    my mutex down pipeline
    ###
    # If this sequence triggered more sequences
    # schedule our next call
    ###
    set signals_processed {}
  }

  ###
  # topic: be2f01f4-706f-a64f-80e5-72137e109e36
  # title: Generate a path to a subordinate object
  ###
  method SubObject::default {} {
    return [namespace current]::SubObject_generic_$method
  }

  ###
  # topic: bda8baec-9227-ee0f-745c-7d3253d94b9c
  ###
  method trace {{onoff {}}} {
    my variable trace
    if { $onoff == {} } {
      return $trace
    }
    set trace $onoff
    if { $trace } {
      oo::objdefine [self] method debugOut string {puts [list [my simTime] [self] $string]}
    } else {
      oo::objdefine [self] method debugOut string {}
    }
  }

  ###
  # topic: a4927f78-b394-395d-b322-b698e4b03027
  ###
  method Variable_get::default {} {
    my variable $method
    return [get $method]
  }

  ###
  # topic: f41203d7-83da-c403-1e26-5073ffaa3aff
  ###
  method Variable_set::default newvalue {
    my variable $method
    set $method $newvalue
  }
}

