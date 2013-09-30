::namespace eval ::page {}

###
# topic: a00d2b65-962f-eb7f-3c4d-8e20eb91b63f
###
proc ::page {field {newvalue NULL}} {
    if { $newvalue == "NULL" } { 
	return [lindex [array get ::page $field] 1]
    }
    set ::page($field) $newvalue
    return $newvalue
}

###
# topic: 44aca151-91bc-de22-5b2e-3a0e5e1a2788
###
proc ::page::clear {} {
  array set ::page {
      user anonymous
      username anonymous
      userid anonymous
      object ::community
      title {}
      print 0
      redirect {}
      layout   page
      javascript {}
      menuNavigation {}
      menuCommand {}
      menuSearch {}
      menuBackground {}
      error 0
      error_message {}
      errorInfo {}
      content {}
  }
  colors
}

###
# topic: fce8a8fc-5ab0-20e7-0f2f-a1911f145b3e
###
proc ::page::colors {} { 
  array unset ::colors
  array set ::colors [::ColorScheme]
  set ::page(menuBackground) "bgcolor=$::colors(bgcolor)"
  set ::page(background) "bgcolor=$::colors(maincolor)"
}

###
# topic: 216fbad3-0586-60a8-8b2b-0b93ccc3aa68
###
proc ::page::GlobalLinks {} { 
  lappend result  Site /home {Home} Site /home/search {Search}
  #set uobj [[/container users] /node [CurrentUser]]
  set user [CurrentUser]
  set ucon login
  lappend result  Site [$ucon nodeUrl $user] [$ucon nodeSummary $user]
  foreach node [get ::global_nodes] {
      set cobj  [::tao::node_container $node]
      set url   [$cobj nodeUrl $node]
      set label [$cobj nodeSummary $node]
      if { $label == {} } { 
          set label $node
      }
      lappend result Databases $url $label
  }
  foreach {section url label} [community GlobalLinks] { 
      lappend result $section $url $label
  }
}

###
# topic: e654359f-a494-7d54-ad57-5cec170889e0
###
proc ::page::menu {} { 
  return [::wiki::expand [::html-style::template ui/menu]]
}

###
# topic: 148630bd-55d0-1001-f422-25c1cac1fc94
###
proc ::page::menuCommand {container node currentmethod} {
  global colors 
  set bottommenu {}
  set menulist [$container menuMethods $node]
  foreach method $menulist { 
      if { $currentmethod == $method } {
          append bottommenu " <B>$method</b> "
      } else {
          append bottommenu " [::html-style::button $method [$container nodeUrl $node $method]] "
      }
  }
  return $bottommenu
}

###
# topic: b6cd5ebd-6d84-218e-3535-ab4a4ac80114
###
proc ::page::menuNavigation {container object} {
  global colors


  set leftmenu "<TABLE \$menubg width=100%>"
  set row 0

  set sectionlist {}

  set sectiondata(Record) {}
  logicset add sectionlist Site 

  lappend sectiondata(Site) {Home} /home {} 
  lappend sectiondata(Site) {Search} /home/search {} 
  
  foreach {section url label} [GlobalLinks] {
      logicset add sectionlist $section
      lappend sectiondata($section) $label $url  {}
  } 

  if { $object != {} && $object != $container } { 
      ###
      # Build the leftmenu
      ####
      foreach {section url label} [$container menuNavigation $object] {
          logicset add sectionlist $section
          lappend sectiondata($section) $label  $url  {}
      }
  }
  lappend sectiondata(Site) {Test} /home {Test /home {Test /home {}}} {<hr />} {} {} {Log Out} /login/logout {}

  lappend sectiondata(Site) {<hr />} {} {} {Log Out} /login/logout {}

  set url_list {}
  set mresult {}
  foreach sect $sectionlist {
      lappend mresult $sect {} $sectiondata($sect)    
  }
  return [::html-style::dropmenu $mresult]
}

###
# topic: 4f4a3d13-fe8b-67ad-4554-8b9c9cf20735
###
proc ::page::menuSearch {container object} {
  set bottommenu {}
  
  if { $object != {} && $object != $container } {
      set gname [$object NodeId]
      append bottommenu [$container menuSearchForm $gname]
  }
  return $bottommenu
}

###
# topic: e122aea3-8bdb-3468-5550-8935a10c737b
###
proc ::page::render {container node method queryDict} {
  ###
  # Tell atropos to not run garbage collection
  # until we tell her
  # we are ready
  ###
  set ::post_exec {}
  set ::post_exec_force {}

  #::tao::trash_lock
   ::page::clear
   set ::query {}
   set ::query $queryDict
   ::page query $queryDict         

   if [catch {::community urlPrelim} result] {
     return $result
   }
   ::page::colors
   set result {}

   ::page container $container
   ::page object $container
   
  set rmethod [$container httpdMethodAlias $method $node]
  if { $rmethod == {} } {
    return {}
  }
  set errstate [catch {$rmethod $node $queryDict} objresult]

   if { $errstate == 2 } { set errstate 0 }
   if { $errstate } { 
       ::page layout error
       ::page errorInfo $::errorInfo
   }
   #if { [set e [::page error]] != {} } {
   #   ::page content $e
   #} else {
      ::page content $objresult
   #}
   set redirect_url [::page redirect]
   if { $redirect_url != {} } { 
       ::page layout redirect
       ::taourl::redirect $redirect_url
   }
   ::page selectform     {}
   ::page menuNavigation  [menuNavigation $container $node]
   ::page menuCommand     [menuCommand $container $node $method]
   #::page menuSearch      [menuSearch $container $node]

  set result [subst [::html-style::template [::page layout]]]
  ::community urlPostlim
  
  ###
  # Ok atropos... do your thing...
  ###
  #::tao::trash_unlock
  #::tao::trash_collect
  return $result
}

