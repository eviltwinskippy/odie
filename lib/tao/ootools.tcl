package require TclOO
package require sqlite3

::namespace eval ::tao {}

::namespace eval ::tao::event {}

::namespace eval ::tao::parser {}

::namespace eval ::tao::signal {}

::namespace eval ::viewobj {}

###
# topic: e710754b-3fe2-f0f1-fd52-58e24bc0e5dc
# title: Closes all floating windows
###
proc ::closeAllWindows {} {
  namespace delete ::viewobj
  namespace eval ::viewobj {}
}

###
# topic: 643efabe-c430-3b20-b66b-760a1ad279bf
###
proc ::tao::args_to_dict args {
  if {[llength $args]==1} {
    return [lindex $args 0]
  }
  return $args
}

###
# topic: b40970b0-d9a2-5259-90b9-105ec8c96d3d
###
proc ::tao::args_to_options args {
  set result {}
  foreach {var val} [args_to_dict {*}$args] {
    lappend result [string trimleft $var -] $val
  }
  return $result
}

###
# topic: da87af14-92df-6d91-3beb-343d9b534d1c
###
proc ::tao::class {name body} {
  set class ::[string trimleft $name :]
  #logicset add ::tao::class_list $class
  if { [::info command $class] == {} } {
    ::tao::metaclass create $class
  }
  ::tao::parser::push $class
  namespace eval ::tao::parser $body
  ::tao::parser::pop
  ::tao::dynamic_methods $class  
  foreach rname [::tao::db eval {select name from class where regen=1}] {
    ::tao::dynamic_methods $rname
  }
}

###
# topic: 87e896b8-994d-ba39-27f2-27685169a939
###
proc ::tao::class_ancestors {class {stackvar {}}} {
  if { $stackvar ne {} } {
    upvar 1 $stackvar stack
  } else {
    set stack {}
  }
  if { $class in $stack } {
    return {}
  }
  stack push stack $class
  if {![catch {::info class superclasses $class} ancestors]} {
    foreach ancestor $ancestors {
      class_ancestors $ancestor stack
    }
  }
  if {![catch {::info class mixins $class} ancestors]} {
    foreach ancestor $ancestors {
      class_ancestors $ancestor stack
    }
  }
  return $stack
}

###
# topic: 19f6ce3e-dca7-d84e-2f7d-82e8a7e9035f
# description: Return a list of IRM classes
###
proc ::tao::class_choices {} {
  ::tao::db eval {select distinct name from class order by name}
}

###
# topic: 8a0deafc-19c1-f360-5a7c-a961ec2ab01f
###
proc ::tao::class_descendents {class {stackvar {}}} {
  if { $stackvar ne {} } {
    upvar 1 $stackvar stack
  } else {
    set stack {}
  }
  if { $class in $stack } {
    return {}
  }
  stack push stack $class
  ::tao::db eval {select class as child from ancestry where parent=:class} {
    class_descendents $child stack
  }
  return $stack
}

###
# topic: 8c73a1eb-e15b-4935-a4ff-657399742257
###
proc ::tao::class_destroy class {
  ::tao::db eval {
delete from class_alias where cname=:class;
delete from ancestry where class=:class;
delete from ancestry where parent=:class;
delete from property where class=:class;
delete from method where class=:class;
delete from typemethod where class=:class;
delete from ensemble where class=:class;
delete from class where name=:class;
  }
}

###
# topic: 4969d897-a83d-91a2-30a1-7f166dbcaede
###
proc ::tao::dynamic_arguments {arglist args} {
  set idx 0
  set len [llength $args]
  if {$len > [llength $arglist]} {
    ###
    # Catch if the user supplies too many arguments
    ###
    set dargs 0
    if {[lindex $arglist end] ni {args dictargs}} {
      set string [dynamic_wrongargs_message $arglist]
      error $string
    }
  }
  foreach argdef $arglist {
    if {$argdef eq "args"} {
      ###
      # Perform args processing in the style of tcl
      ###
      uplevel 1 [list set args [lrange $args $idx end]]
      break
    }
    if {$argdef eq "dictargs"} {
      ###
      # Perform args processing in the style of tcl
      ###
      uplevel 1 [list set args [lrange $args $idx end]]
      ###
      # Perform args processing in the style of tao
      ###
      set dictargs [::tao::args_to_options {*}[lrange $args $idx end]]
      uplevel 1 [list set dictargs $dictargs]
      break
    }
    if {$idx > $len} {
      ###
      # Catch if the user supplies too few arguments
      ###
      if {[llength $argdef]==1} {
        set string [dynamic_wrongargs_message $arglist]
        error $string
      } else {
        uplevel 1 [list set [lindex $argdef 0] [lindex $argdef 1]]
      }
    } else {
      uplevel 1 [list set [lindex $argdef 0] [lindex $args $idx]]
    }
    incr idx
  }
}

###
# topic: a92cd258-9000-10f6-56f4-c6e7dbffae57
###
proc ::tao::dynamic_methods class {
  set ancestors [::tao::class_ancestors $class]
  ::tao::db eval {delete from ancestry where class=:class}
  set idx -1
  foreach ancestor $ancestors {
    incr idx
    ::tao::db eval {insert into ancestry (class,parent,ancorder) VALUES (:class,:ancestor,:idx);}
  }
  ::tao::dynamic_methods_ensembles $class $ancestors
  ::tao::dynamic_methods_class    $class $ancestors
  ::tao::dynamic_methods_property $class $ancestors
  
  ::tao::db eval {update class set regen=0 where name=:class}
}

###
# topic: b88add19-6bb6-3abc-cc44-639db5e5eae1
###
proc ::tao::dynamic_methods_class {class ancestors} {
  set cmethods {}
  ::tao::db eval {select method,arglist,body from typemethod where class=:class} {
    logicset add cmethods $method
    ::oo::objdefine $class method $method $arglist $body
  }
  foreach anc $ancestors {
    ::tao::db eval {select method,arglist,body from typemethod where class=:anc} {
      if { $method in $cmethods } continue
      ::oo::objdefine $class method $method $arglist $body
    }
  }
}

###
# topic: fb8d74e9-c08d-b81e-e6f1-275dad4d7d6f
###
proc ::tao::dynamic_methods_ensembles {class ancestors} {

  set ensembledict {}
  foreach ancestor $ancestors {
    ::tao::db eval {select method,submethod,arglist,body from ensemble where class=:ancestor} {
      if {![dict exists $ensembledict $method $submethod]} {
        dict set ensembledict $method $submethod [list $arglist $body]
      }
    }
  }

  foreach {ensemble einfo} $ensembledict {
    set eswitch {}
    set default standard
    if {[dict exists $einfo default]} {
      set emethodinfo [dict get $einfo default]
      set arglist     [lindex $emethodinfo 0]
      set realbody    [lindex $emethodinfo 1]
      set body "\n      ::tao::dynamic_arguments [list $arglist] {*}\$args"
      append body "\n      " [string trim $realbody] "      \n"
      set default $body
      dict unset einfo default
    }
    set eswitch \n
    append eswitch "\n    [list <list> [list return [lsort -dictionary [dict keys $einfo]]]]" \n
    foreach {submethod esubmethodinfo} [lsort -stride 2 -dictionary $einfo] {
      set arglist     [lindex $esubmethodinfo 0]
      set realbody    [lindex $esubmethodinfo 1]
      if {[string length [string trim $realbody]] eq {}} {
        append eswitch "    [list $submethod {}]" \n
      } else {
        set body "\n      ::tao::dynamic_arguments [list $arglist] {*}\$args"
        append body "\n      " [string trim $realbody] "      \n"
        append eswitch "    [list $submethod $body]" \n
      }
    }
    if {$default=="standard"} {
      set default "error \"unknown method $ensemble \$method. Valid: [lsort -dictionary [dict keys $eswitch]]\""
    }
    append eswitch [list default $default] \n
    set body {}
    append body \n "set code \[catch {switch -- \$method [list $eswitch]} result opts\]"

    #if { $ensemble == "action" } {
    #  append body \n {  if {$code == 0} { my event generate event $method {*}$dictargs}}
    #}
    append body \n {return -options $opts $result}
    oo::define $class method $ensemble {method args} $body
  }
}

###
# topic: 6b787960-2c20-2398-bd25-f733c0933cf9
###
proc ::tao::dynamic_methods_property {class ancestors} {
  ###
  # Apply properties
  ###  
  set info {}
  dict set info option {}
  set proplist {}
  foreach ancestor $ancestors {
    ::tao::db eval {select property,type,dict from property where class=:ancestor and defined=:ancestor} {
      if {[dict exists $info $type $property]} continue
      if { $type in {eval const subst variable}} {
        # For these values, we want to exclude equivilent calls
        if {[dict exists $info eval $property]} continue
        if {[dict exists $info const $property]} continue
        if {[dict exists $info subst $property]} continue
        lappend proplist $property
        set mdef [split $property _]
        if {[llength $mdef] > 1} {
          set ptype [lindex $mdef 0]
          lappend proptypes($ptype) $property
        }
      }
      dict set info $type $property $dict
    }
  }

  set signaldict {}
  set optiondict {}
  set publicvars {}

  ###
  # Build options
  ###
  set option_classes [dictGet $info option_class]
  # Build option handlers
  foreach {property pdict} [dictGet $info option] {
    set contents {
      default {}
    }
    #append body \n " [list $property "return \[my cget [list $property]\]"]"
    set optionclass [dictGet $pdict class]
    if {[dict exists $option_classes $optionclass]} {
      foreach {f v} [dict get $option_classes $optionclass] {
        dict set contents [string trimleft $f -] $v
      }
    }
    if {[dict exists $info option $optionclass]} {
      foreach {f v} [dict get $info option $optionclass] {
        dict set contents [string trimleft $f -] $v
      }
    }
    foreach {f v} $pdict {
      dict set contents [string trimleft $f -] $v
    }
    dict set info option $property $contents   
  }
  dict set info meta class $class
  dict set info meta ancestors $ancestors
  dict set info meta signal_order [::tao::signal_order [dictGet $info signal]]
  dict set info meta types [lsort -dictionary -unique [array names proptypes]]
  dict set info meta local [get proplist]
  ###
  # Build the body of the property method
  ###
  set commonbody "switch \$field \{"
  append commonbody \n "  [list class [list return $class]]"
  append commonbody \n "  [list ancestors [list return $ancestors]]"
  
  foreach {type typedict} $info {
    set typebody "    switch \[lindex \$args 0\] \{"
    append typebody \n "    [list list [list return [lsort -unique -dictionary [dict keys $typedict]]]]"
    append typebody \n "    [list dict [list return $typedict]]"
    foreach {subprop value} $typedict {
      switch $type {
        variable {
          append typebody \n "    [list $subprop [list return $value]]"          
        }
        default {
          append typebody \n "    [list $subprop [list return $value]]"          
        }
      }
    }
    append typebody "\n    \}" \n
    append commonbody \n "  [list $type $typebody]"
  }
  # Build const property handlers
  foreach {property pdict} [dictGet $info const] {
    append commonbody \n " [list $property [list return $pdict]]"   
  }
  append body $commonbody
  append classbody $commonbody

  # Build eval property handlers
  foreach {property pdict} [dictGet $info eval] {
    if {$property in $proplist} continue
    append body \n " [list $property $pdict]"
  }

  # Build subst property handlers
  foreach {property pdict} [dictGet $info subst] {
    if {$property in $proplist} continue
    append body \n " [list $property [list return [subst $pdict]]]"
  }
  
  # Build option handlers
  foreach {property pdict} [dictGet $info option] {
    dict set publicvars $property $pdict
    append body \n " [list $property "return \[my cget [list $property]\]"]"
  }  
  
  # Build public variable handlers
  foreach {property pdict} [dictGet $info variable] {
    dict set publicvars $property $pdict
    append body \n " [list $property "my variable $property \; return \$property\]"]"
  }

  # End of switch
  append body \n "\}"
  append classbody \n "\}"

  append body \n {return [my get $field]}
  
  oo::define $class method property {field args} $body
  oo::objdefine $class method property {field args} $classbody
}

###
# topic: 53ab28ac-5c6e-e601-fe1f-e07b073be88e
###
proc ::tao::dynamic_wrongargs_message arglist {
  set result "Wrong # args: should be:"
  set dargs 0
  foreach argdef $arglist {
    if {$argdef in {args dictargs}} {
      set dargs 1
      break
    }
    if {[llength $argdef]==1} {
      append result " $argdef"
    } else {
      append result " ?[lindex $argdef 0]?"
    }
  }
  if { $dargs } {
    append result " ?option value?..."
  }
  return $result
}

###
# topic: 2097c114-9d50-b67b-94ea-09f0bcad9e5c
###
proc ::tao::event::bind {self event args} {
  if {![llength $args]} {
    return [::tao::db one {select script from object_bind where object=:self and event=:event}]
  }
  set script [lindex $args 0]
  if { $script eq {} } {
    ::tao::db eval {delete from object_bind where object=:self and event=:event}
  } else {
    ::tao::db eval {
insert or ignore into object(name) VALUES (:self);
insert or replace into object_bind (object,event,script) VALUES (:self,:event,:script);
}
  }
}

###
# topic: f2853d38-0a73-2845-610e-40375bcdbe0f
# description: Cancel a scheduled event
###
proc ::tao::event::cancel {self {{task *}}} {
  variable idle_event
  foreach {id event} [array get idle_event $self:$task] {
    ::after cancel $event
    set idle_event($id) {}
  }
}

###
# topic: 8ec32f6b-6ba7-8eaf-9805-24f8dec55b49
###
proc ::tao::event::generate {self event args} {
  set dictargs [::tao::args_to_options {*}$args]
  ###
  # description:
  #    Generate an event
  #    Adds a subscription mechanism for objects
  #    to see who has recieved this event and prevent
  #    spamming or infinite recursion
  ###
  set info $dictargs
  set strict 0
  set sender $self
  dict with dictargs {}

  dict set info id     event#[format %0.8x [incr ::tao::event_count]]
  dict set info origin $self
  dict set info sender $sender
  dict set info rcpt   {}
  
  foreach who [Notification_list $self $event] {
    catch {::tao::event::notify $who $self $event $info}
  }
}

###
# topic: 891289a2-4b8c-c52b-6c22-8f6edb169959
###
proc ::tao::event::nextid {} {
  return "event#[format %0.8x [incr ::tao::event_count]]"
}

###
# topic: 6b802b8f-29d1-8d55-1531-126aaa38e69f
# description:
#    Called recursively to produce a list of
#    who recieves notifications
###
proc ::tao::event::Notification_list {self event {stackvar {}}} {
  if { $stackvar ne {} } {
    upvar 1 $stackvar stack
  } else {
    set stack {}
  }
  if {$self in $stack} {
    return {}
  }
  lappend stack $self

  ::tao::db eval {select receiver from object_subscribers where sender=:self and string_match(event,:event)=1} {
    ::tao::db eval {select name as rcpt from object where string_match(name,:receiver)=1} {
      Notification_list $rcpt $event stack
    }
  }
  return $stack
}

###
# topic: b4b12f6a-ed69-f745-29be-10966afd81da
###
proc ::tao::event::notify {rcpt sender event eventinfo} {
  if {$::tao::trace} {
    puts [list event notify rcpt $rcpt sender $sender event $event info $eventinfo]
  }
  $rcpt notify $event $sender $eventinfo
}

###
# topic: 829c89bd-a736-aed1-c16b-b0c570037088
###
proc ::tao::event::process {self handle script} {
  variable idle_event
  array unset idle_event $self:$handle
  eval $script
}

###
# topic: a6e4eebe-fcd2-cec5-7ee4-f0d8c10c92c0
###
proc ::tao::event::publish {self who event} {
  ::tao::db eval {
insert or ignore into object(name) VALUES (:self);
insert or replace into object_subscribers (sender,receiver,event) VALUES (:self,:who,:event);
}
}

###
# topic: eba686cf-fe18-cd14-1ac9-b4accfc634bb
# description: Schedule an event to occur later
###
proc ::tao::event::schedule {self handle interval script} {
  variable idle_event
  if {$::tao::trace} {
    puts [list $self schedule $event]
  }
  if {[info exists idle_event($self:$handle)]} {
    ::after cancel $idle_event($self:$handle)
  }
  set idle_event($self:$handle) [::after $interval [list ::tao::event::process $self $handle $script]]
}

###
# topic: 63d680db-51c1-a3a0-4c2a-038b8f9747d0
###
proc ::tao::event::signal {self event} {
  
}

###
# topic: e64cff02-4027-ee93-403e-dddd5dd9fdde
###
proc ::tao::event::subscribe {self who event} {
  ::tao::db eval {
insert or ignore into object(name) VALUES (:self);
insert or replace into object_subscribers (receiver,sender,event) VALUES (:self,:who,:event);
}
}

###
# topic: 177acc5c-440c-6154-37dd-02cba0ab778c
###
proc ::tao::event::unpublish {self args} {
  switch {[llength $args]} {
    0 {
      ::tao::db eval {delete from object_subscribers where sender=:self}
    }
    1 {
      set event [lindex $args 0]
      ::tao::db eval {delete from object_subscribers where sender=:self and string_match(event,:event)=1}
    }
  }
}

###
# topic: 5f74cfd0-1735-fb1a-9070-5a5f74f6cd8f
###
proc ::tao::event::unsubscribe {self args} {
  switch {[llength $args]} {
    0 {
      ::tao::db eval {delete from object_subscribers where receiver=:self}
    }
    1 {
      set event [lindex $args 0]
      ::tao::db eval {delete from object_subscribers where receiver=:self and string_match(event,:event)=1}
    }
  }
}

###
# topic: cd54fcd0-eef2-9965-5f36-c9d1e1454d53
###
proc ::tao::macro {name arglist body} {
  proc ::tao::parser::$name $arglist $body
}

###
# topic: cf50771b-b066-4678-ec38-57b360c25aab
# title: Go nowhere, do nothing
###
proc ::tao::noop args {}

###
# topic: d42790a7-31ce-9e3f-f186-6e71f9c42f17
# description: Unregister an object from the odie event manager
###
proc ::tao::object_destroy object {
  ::tao::event::generate $object destroy {}
  variable trace
  if { $trace } {
    puts [list ::tao::object_destroy $object]
  }
  set names [list $object {*}[::tao::db eval {select alias from object_alias where cname=:object}]]
  foreach name $names {
    ::tao::db eval {
delete from object where name=:name;
delete from object_bind where object=:name;
delete from object_subscribers where sender=:name;
delete from object_subscribers where receiver=:name;
delete from object_alias where cname=:name or alias=:name;
    }
  }
}

###
# topic: d9ebb42d-d1ce-3ecd-e390-5b57f96109ab
###
proc ::tao::object_rename {object newname} {
  variable trace
  if { $trace } {
    puts [list ::tao::object_rename $object -> $newname]
  }
  rename $object ::[string trimleft $newname]
  ::tao::db eval {
update object_alias set cname=:newname where cname=:object;
update object set name=:newname where name=:object;
update object_bind set object=:newname where object=:object;
update object_subscribers set sender=:newname where sender=:object;
update object_subscribers set receiver=:newname where receiver=:object;

insert or replace into object_alias(cname,alias) VALUES (:newname,:object);
}
}

###
# topic: 7a5c7e04-9897-04ee-f117-ff3c9dd88823
###
proc ::tao::parser::class_method {name arglist body} {
  set class [peek]
  method $name $arglist $body
  ::tao::db eval {insert or replace into typemethod (class,defined,method,arglist,body) VALUES (:class,:class,:name,:arglist,:body);}
}

###
# topic: 710a9316-8e4b-a7a9-71d3-dbb8a3e7bcbc
###
proc ::tao::parser::component args {
  
}

###
# topic: 688435d2-ae23-cc1b-1657-3910305f370d
###
proc ::tao::parser::delegate {keyword object args} {
  switch $keyword {
    method {}
    option {}
    typemethod -
    class_method {} 
  }
}

###
# topic: 4cb3696b-f06d-1e37-2107-795de7fe1545
###
proc ::tao::parser::destructor rawbody {
  set body {
::tao::object_destroy [self]
  }
  append body $rawbody
  ::oo::define [peek] destructor $body
}

###
# topic: 744b10c6-558e-c3d8-cd0e-51f4f14c5722
# title: Define an ensemble method for this agent
###
::proc ::tao::parser::ensemble {ensemble ebody} {
  set class [peek]
  if {[::tao::db exists {select method from method where class=:class and method=:ensemble}]} {
    ::tao::db eval {
delete from method where class=:class and method=:method;
}
    
  }
  foreach {method arglist body} $ebody {
    ::tao::db eval {
insert or replace into ensemble (class,defined,method,submethod,arglist,body) VALUES (:class,:class,:ensemble,:method,:arglist,:body);
}
  }
}

###
# topic: 1c5df374-e798-791a-cb06-e74050c38dfa
# title: Define an ensemble method for this agent
###
::proc ::tao::parser::ensemble_method {ensemble method arglist body} {
    ::tao::db eval {
insert or replace into ensemble (class,defined,method,submethod,arglist,body) VALUES (:class,:class,:ensemble,:method,:arglist,:body);
}
}

###
# topic: ec9ca249-b75e-2667-ad5b-cb2f7cd8c568
# title: Define an ensemble method for this agent
###
::proc ::tao::parser::method {rawmethod args} {
  set class [peek]
  set mlist [split $rawmethod "::"]
  if {[llength $mlist]==1} {
    set method $rawmethod
    set arglist [lindex $args 0]
    set body [lindex $args 1]
    ::tao::db eval {insert or replace into method (class,defined,method,arglist,body) VALUES (:class,:class,:method,:arglist,:body);}
    ::oo::define $class method $rawmethod {*}$args
    return
  }
  set ensemble [lindex $mlist 0]
  set method [join [lrange $mlist 2 end] "::"]
  switch [llength $args] {
    1 {
      set arglist dictargs
      set body [lindex $args 0]
      ::tao::db eval {insert or replace into ensemble (class,defined,method,submethod,arglist,body) VALUES (:class,:class,:ensemble,:method,:arglist,:body);}
    }
    2 {
      set arglist [lindex $args 0]
      set body [lindex $args 1]
      ::tao::db eval {insert or replace into ensemble (class,defined,method,submethod,arglist,body) VALUES (:class,:class,:ensemble,:method,:arglist,:body);}
    }
  }
}

###
# topic: 68aa4460-0523-5a06-32a1-0e2a441c0777
###
proc ::tao::parser::option {name args} {
  set class [peek]
  set dictargs {default {}}
  foreach {var val} [::tao::args_to_dict {*}$args] {
    dict set dictargs [string trimleft $var -] $val
  }
  property [string trimleft $name -] option $dictargs
}

###
# topic: 827a3a33-1a2e-212a-6e30-1f59c1eead59
###
proc ::tao::parser::option_class {name args} {
  set class [peek]
  set dictargs {default {}}
  foreach {var val} [::tao::args_to_dict {*}$args] {
    dict set dictargs [string trimleft $var -] $val
  }
  property [string trimleft $name -] option_class $dictargs
}

###
# topic: baeb5170-936f-985e-0e97-be63018bc130
###
proc ::tao::parser::peek args {
  if {[llength $args] == 2} {
    upvar 1 [lindex $args 0] class [lindex $args 1] docnode 
  }
  ::variable classStack
  set class   [lindex $classStack end]
  return ${class}
}

###
# topic: 1c598e92-d29b-a031-1212-b3fdf2334b34
###
proc ::tao::parser::pop {} {
  ::variable classStack
  set class      [lindex $classStack end]
  set classStack [lrange $classStack 0 end-1]

  # Signal for all decendents to regenerate
  foreach d [::tao::class_descendents $class] {
    tao::db eval {update class set regen=1 where name=:d}
  }
  return $class
}

###
# topic: 83160a2a-ba9d-fa45-5d82-b46cdd2e4127
# title: Define the properties for this agent
###
proc ::tao::parser::properties info {
  set class [peek]
  foreach {var val} $info {
    ::tao::db eval {insert or replace into property (class,defined,property,type,dict) VALUES (:class,:class,:var,'const',:val);}
  }
}

###
# topic: 709b71e1-0365-e576-653d-00f185ca9efd
# title: Define the properties for this agent
###
proc ::tao::parser::property {property args} {
  set class [peek]
  switch [llength $args] {
    1 {
      set type const
      set value [lindex $args 0]
    }
    2 {
      set type [lindex $args 0]
      set value [lindex $args 1]
    }
    default {
      error "Usage:
property name typet valuedict
OR property name value"
    }
  }
  if { $type eq {} } {
    set type eval
  }
    ::tao::db eval {
insert or replace into property (class,defined,property,type,dict) VALUES (:class,:class,:property,:type,:value);
  }
}

###
# topic: bd23198e-f193-8428-fb15-32dd96de2c12
# description: Push a class onto the stack
###
proc ::tao::parser::push type {
  ::variable classStack
  lappend classStack $type
  if {![::tao::db exists {select name from class where name=:type}]} {
    ::tao::db eval {insert into class (name,regen) VALUES (:type,1);}
  } else {
    ::tao::db eval {update class set regen=1 where name=:type}
  }
}

###
# topic: 4d12b6ca-2823-d960-a81e-6f15fd9962e6
###
proc ::tao::parser::signal {name infodict} {
  set result {
    apply_action {}
    action       {}
    aliases      {}
    comment      {}
    excludes     {}
    preceeds     {}
    follows      {}
    triggers     {}
  }
  dict set result name $name
  foreach {f v} $infodict {
    dict set result $f $v
  }
  property $name signal $result
}

###
# topic: 615b7c43-b863-b0d8-d1f9-107a8d126b21
###
proc ::tao::parser::variable {name {default {}}} {
  property $name variable $default
}

###
# topic: 2b83713f-cee7-dc7c-a173-29351befcec6
###
proc ::tao::Signal_compare {i j sigdat {trace 0}} {
  if {$i == $j} {
    return 0
  }

  set j_preceeds_i [Signal_matches $j [dict get $sigdat $i preceeds]]
  set i_preceeds_j [Signal_matches $i [dict get $sigdat $j preceeds]]
  set j_follows_i [Signal_matches $j [dict get $sigdat $i follows]]
  set i_follows_j [Signal_matches $i [dict get $sigdat $j follows]]

  if {$i_preceeds_j && !$j_preceeds_i && !$i_follows_j} {
    return -1
  }
  if {$j_preceeds_i && !$i_preceeds_j && !$j_follows_i} {
    return 1
  }
  if {$j_follows_i && !$i_follows_j} {
    return 1
  }
  if {$i_follows_j && !$j_follows_i} {
    return -1
  }
  set j_triggers_i [Signal_matches $j [dict get $sigdat $j triggers]]
  set i_triggers_j [Signal_matches $i [dict get $sigdat $i triggers]]
  return 0
}

###
# topic: 1f4128fa-725b-7af7-7fc6-458fe653a651
###
proc ::tao::signal_expand {rawsignal sigdat {signalvar {}}} {
  if {$signalvar ne {}} {
    upvar 1 $signalvar result
  } else {
    set result {}
  }
  if {$rawsignal in $result} {
    return {}
  }
  if {[dict exists $sigdat $rawsignal]} {
    lappend result $rawsignal
    # Map triggers
    foreach s [dict get $sigdat $rawsignal triggers] {
      signal_expand $s $sigdat result
    }
  } else {
    # Map aliases
    foreach {s info} $sigdat {
      if {$rawsignal in [dict get $info aliases]} {
        signal_expand $s $sigdat result
      }
    }
  }
  return $result
}

###
# topic: e4f50e1a-5f57-57fd-e0d4-306a50ca3a43
###
proc ::tao::Signal_matches {signal fieldinfo} {
  foreach value $fieldinfo {
    if {[string match $value $signal]} {
      return 1
    }
  }
  return 0
}

###
# topic: 9cfad45c-db25-7837-b138-44261768286e
###
proc ::tao::signal_order sigdat {
  set allsig [lsort -dictionary [dict keys $sigdat]]
  
  foreach i $allsig {
    set follows($i) {}
    set preceeds($i) {}
  }
  foreach i $allsig {
    foreach j $allsig {
      if { $i eq $j } continue
      set cmp [Signal_compare $i $j $sigdat]
      if { $cmp < 0 } {
        logicset add follows($i) $j
      }
    }
  }
  # Resolve mutual dependencies
  foreach i $allsig {
    foreach j $follows($i) {
      foreach k $follows($j) {
        if {[Signal_compare $i $k $sigdat] < 0} {
          logicset add follows($i) $k
        }
      }
    }
  }
  foreach i $allsig {
    foreach j $follows($i) {
      logicset add preceeds($j) $i
    }
  }
  # Start with sorted order
  set order $allsig
  set pass 0
  set changed 1
  while {$changed} {
    set changed 0
    foreach i $allsig {
      set iidx [lsearch $order $i]
      set max $iidx
      foreach j $preceeds($i) {
        set jidx [lsearch $order $j]
        if {$jidx > $max } {
          set after $j
          set max $jidx
        }
      }
      if { $max > $iidx } {
        set changed 1
        set order [lreplace $order $iidx $iidx]
        set order [linsert $order [expr {$max + 1}] $i]
      }
    }
    if {[incr pass]>10} break
  }
  return $order
}

###
# topic: de8ee09c-5a76-e553-6426-4b1e7a4b8003
###
proc ::tao::singleton {name body} {
  set class ::[string trimleft $name :].class
  #logicset add ::tao::class_list $class
  if { [::info command $class] == {} } {
    ::tao::metaclass create $class
  }
  ::tao::parser::push $class
  namespace eval ::tao::parser $body
  ::tao::parser::pop

  foreach rname [::tao::db eval {select name from class where regen=1}] {
    ::tao::dynamic_methods $rname
  }
  $class create $name
}

###
# topic: 37e7bd0b-e3ca-7297-996d-a2abdf5a85c7
###
namespace eval ::tao::event {
  variable nextevent {}
  variable nexteventtime 0
}

###
# topic: c5f7c9ad-a6fe-1605-2192-73b957283d70
# description: Work space for the IRM class parser
###
namespace eval ::tao::parser {
foreach keyword {
    constructor deletemethod export filter forward  renamemethod
    self superclass unexport unknown
  } {
    proc $keyword args "::oo::define \[peek\] $keyword {*}\$args"
  }
  namespace export *
}

###
# topic: b14c5055-3727-4904-5783-40ec1bc12af1
###
namespace eval ::tao {
  namespace export *

  ###
  # Cache the bits of the UUID seed that aren't likely to change
  # once the software is loaded, but which can be expensive to
  # generate
  ###
  variable ::tao::UUID_Seed [list [info hostname] [get env(USER)] [get env(user)]]
}

if {[info command ::tao::db] eq {}} {
  package require sqlite3
  sqlite3 ::tao::db :memory:
  # Build the schema
  ::tao::db function string_match {string match}
 
  ::tao::db eval {
create table class (
  name string primary key,
  package string,
  regen integer default 0
);
create table class_alias (
  cname string references class,
  alias string references class
);

create table object (
  name string primary key,
  package string,
  regen integer default 0
);
create table object_alias (
  cname string references object,
  alias string references object
);

create table object_bind (
  object string references object,
  event  string,
  script blob,
  primary key (object,event) on conflict replace
);

create table object_schedule (
  object string references object,
  event  string,
  time   integer,
  eventorder  integer default 0,
  script string,
  primary key (object,event) on conflict replace
);

create table object_subscribers (
  sender   string references object,
  receiver string references object,
  event string,
  primary key (sender,receiver,event) on conflict ignore
);

create table ancestry (
  class string references class,
  ancorder integer,
  parent string references class,
  primary key (class,ancorder)
);
create table property (
  class string references class,
  property string,
  defined string references class,
  type string,
  dict keyvaluelist,
  primary key (class,property,type) on conflict replace
);
create table method (
  class string references class,
  method string,
  arglist string,
  body text,
  defined string references class,
  primary key (class,method) on conflict replace
);
create table typemethod (
  class string references class,
  method string,
  arglist string,
  body text,
  defined string references class,
  primary key (class,method) on conflict replace
);
create table ensemble (
  class string references class,
  method string,
  submethod string,
  arglist string,
  defined string references class,
  body text,
  primary key (class,method,submethod) on conflict replace
);
  }
}

###
# topic: b14c5055-3727-4904-5783-40ec1bc12af1
###
namespace eval ::tao {
  variable trace 0
}

