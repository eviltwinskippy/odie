package provide webshed::community 0.1
if {[info exists webshed_loaded]} {
  error "I'm already loaded"
}
set webshed_loaded 1
puts "Loading Webshed"

::namespace eval ::community {}

###
# topic: cb632ebc-becc-8c25-4162-b82b94ea6e5f
###
proc ::community::/group gid {
  
}

###
# topic: ecd517e1-ab57-accc-19c6-856ee255decc
###
proc ::community::/user uid {
  
}

###
# topic: 04882e39-8837-3259-3668-76b411e167f2
###
proc ::community::accessTypes {} {
  variable aclSqlObj
  set accessTypes {admin edit view}
  foreach type [db eval "select distinct right from acl_grants order by right"] {
      logicset add accessTypes $type
  }     
  return $accessTypes
}

###
# topic: da5e2bb7-bd9f-e334-4df3-4b27bfb478eb
###
proc ::community::aclBaseRights {} {
  return admin
}

###
# topic: bce98182-37ac-10c7-fc27-e5ed33518bc1
###
proc ::community::aclCacheBuild {aclname userid} {
  variable aclSqlObj
  set parentlist {}
  set thisnode $aclname
  while 1 {
        set parentlist [linsert $parentlist 0 $thisnode]
        set parent [lindex [db eval "select parent from acl where acl_name='$thisnode'"] 0]
        if { $parent == {} } { 
            break
        }
        set thisnode $parent
  }

  ###
  #  Build grouplist
  ###
  set grouplist {}
  set rawgrouplist [db eval "select distinct userid from acl_grants"]

  foreach group $rawgrouplist {
      if [UserIsMember $group $userid] {
          logicset add grouplist $group
      }
  }
  logicset add grouplist $userid
  set rights {}
  foreach p $parentlist {
      set stmt "select right,grant from acl_grants where \
acl_name='$p' and \
(userid='[join $grouplist "' OR userid='"]') order by node_id"
      foreach {right grant} [db eval $stmt] {
          if { $grant == "0"} {
              if { $right == "all" } { 
                  set rights {}
              } else {
                  logicset remove rights $right
              }
          } else {
              logicset add rights $right
          }
      }
  }
  return $rights
}

###
# topic: 1aae1d43-c949-31ac-5c54-16fcac0bd35b
###
proc ::community::aclCacheCheck {aclname userid resultvar} {
   upvar 1 $resultvar rights
   variable aclSqlObj
  
   set row [db eval "select rights from acl_rights where acl_name='$aclname' and userid='$userid'"]
   if { $row == {} } { 
        return 1
   }
   set rights [lindex $row 0]
   return 0
}

###
# topic: b35f18b4-4bb6-d972-f79e-eb0d8ecf84ae
###
proc ::community::aclCacheSave {aclname userid rights} {
  variable aclSqlObj
  db eval "INSERT OR REPLACE into acl_rights (acl_name,userid,rights) VALUES ('$aclname','$userid','$rights')"
}

###
# topic: 10eb6d68-0cc3-808b-18a9-472bfcf194e5
###
proc ::community::aclContainerRegister object { 
  variable acl_container_list
  variable aclSqlObj
  
  logicset add acl_container_list $object
  set namelist  [$object aclNameList]
  set grantlist [$object aclGrantList]
  set objname   [$object globalName]
  db eval "BEGIN TRANSACTION"
  foreach {item parent} $namelist {
     db eval "INSERT OR REPLACE into acl (acl_name,parent) VALUES ('$item','$parent')"
  }
  foreach {aclname userid grant right} $grantlist {
     db eval "INSERT OR REPLACE into acl_grants (acl_name,userid,grant,right) VALUES ('$aclname','$userid','$grant','$right')"
  }
  db eval "COMMIT TRANSACTION"
}

###
# topic: ce0ce549-cf20-023b-f470-94eeb49d7470
###
proc ::community::aclCreate {aclname parent} {
  variable aclSqlObj
  if { $parent == $aclname } { 
      set parent {}
  }
  db eval "INSERT OR REPLACE into acl (acl_name,parent) VALUES ('$aclname','$parent')"
}

###
# topic: 04598e75-4d11-f223-013d-0020af927bf8
###
proc ::community::aclDeleteRule id {
  variable aclSqlObj
  db eval "DELETE from acl_grants where node_id='$id'"
  db eval "DELETE FROM acl_rights"
}

###
# topic: e091bb77-b690-dcfa-25a4-875d3822922c
###
proc ::community::aclDeny {aclname userid right} {
  variable aclSqlObj
  set userid [UserMap $userid]
  db eval "INSERT OR REPLACE into acl_grants (acl_name,userid,grant,right) VALUES ('$aclname','$userid',0,'$right')"
  db eval "DELETE FROM acl_rights"
}

###
# topic: 42ff5cff-5107-db9c-3215-6c2e26720e92
###
proc ::community::aclGrant {aclname ruserid right} {
  variable aclSqlObj
  set userid [UserMap $ruserid]
  db eval "INSERT OR REPLACE into acl_grants (acl_name,userid,grant,right) VALUES ('$aclname','$userid',1,'$right')"
  db eval "DELETE FROM acl_rights"
}

###
# topic: 72f71e49-cc88-992d-3ed9-ce393d0dd34c
###
proc ::community::aclList {} {
  variable aclSqlObj
  return [db eval "select distinct acl_name from acl order by acl_name"]
}

###
# topic: 69e5fb2a-0f61-c3cc-8f43-5279e6f212bf
###
proc ::community::aclLoad filename {
  source $filename
}

###
# topic: ad00c790-b8c5-b2d2-1127-ae8aac60b857
###
proc ::community::aclNode {aclname node} {
  variable aclSqlObj
  db eval "INSERT OR REPLACE into acl_node (acl_name,node_id) VALUES ('$aclname','$node')"
  db eval "DELETE FROM acl_node_cache"
}

###
# topic: d48d621f-bfdd-d658-c808-a70268924103
###
proc ::community::aclParent aclname {
  variable aclSqlObj
  return [lindex [db eval "select parent from acl where acl_name='$aclname'"] 0]
}

###
# topic: ba11bf22-5b2e-b424-2cc8-4db989434ec3
###
proc ::community::aclRevoke {aclname userid right} {
  variable aclSqlObj
  set userid [UserMap $userid]
  if { $right == "all" } { 
     db eval "DELETE from acl_grants where acl_name=$aclname and userid=$userid"
  } else {
     db eval "DELETE from acl_grants where acl_name='$aclname' and userid='$userid' and right='$right'"
  }
  db eval "DELETE FROM acl_rights" 
  db eval "DELETE FROM acl_node_cache"
}

###
# topic: 78e27e97-86e6-b48f-5887-ca422971a5c8
###
proc ::community::aclRights {aclname userid {right {}}} {
  ### The way it outta work
  set userid [UserMap $userid]
  if [aclCacheCheck $aclname $userid rightslist] {
      set rightslist [aclCacheBuild $aclname $userid]
      aclCacheSave $aclname $userid $rightslist 
  }

  if { [lsearch $rightslist admin] >= 0 } {
     if { $right == {} } { 
         return admin
     }
     return 1 
  }
  if { $right == {} } { 
     return $rightslist
  }
  if { [lsearch $rightslist $right] >= 0 } {
     return 1
  }
  return 0
}

###
# topic: 639ddb42-e3d4-082f-c13c-2171a7cef5ea
###
proc ::community::aclRules aclname {
  variable aclSqlObj
  return [db eval "select node_id,userid,right,grant from
acl_grants where acl_name='$aclname' order by node_id"]
}

###
# topic: 2673aa3f-023b-9b2a-9d8d-cf4d1f7c1176
###
proc ::community::aclSave filename {
  variable aclSqlObj
 set fout [open $filename.new w]
 puts $fout "### ACL SAVED [clock second]"
 foreach {acl_name parent} [db eval "select acl_name,parent from acl
order by parent,acl_name"] {
     puts $fout [list [self] aclCreate $acl_name $parent]
 }
 foreach {grant aclname userid right} [db eval "select grant,acl_name,userid,right from acl_grants order by acl_name,node_id"] {
    if { $grant < 1 } { 
        puts $fout [list [self] aclDeny $aclname $userid $right]
    } else {
        puts $fout [list [self] aclGrant $aclname $userid $right]
    }
 }
 foreach {acl_name node_id} [db eval "select acl_name,node_id from acl_node order by acl_name,node_id"] {
     puts $fout [list [self] aclNode $acl_name $node_id]
 }
 close $fout

 if [file exists $filename] {
    file rename -force $filename ${filename}.bak
 }
 file rename -force $filename.new $filename
 
}

###
# topic: 1d45eac1-3acd-f309-1fae-78ca7e1059ce
###
proc ::community::aclSetParent {aclname newparent} {
  variable aclSqlObj
  set newparent [string trim [lindex $newparent 0]]
  db eval "update acl set parent='$newparent' where acl_name='$aclname'"
}

###
# topic: ad4306ca-aa4f-7cee-9159-9bf652c20dcc
###
proc ::community::aclWheelMode {} {
  return 1
}

###
# topic: 7510caf9-4f02-bfb8-f89f-b42c53700593
###
proc ::community::Anonymous {} {
  if { [CurrentUser] in {anonymous nobody {} 99} } {
      return 1
  }
  return 0
}

###
# topic: bab8e0f0-866a-2ce1-64d6-4a4a9a4f0295
###
proc ::community::AnonymousUser {{prohibit_anon 0}} {
  set sesid [get ::session(sesid)]
  if {$sesid in {{} nobody anonymous 99}} {
      set sesid anonymous
  }

  if { $prohibit_anon && $sesid == "anonymous" } {
      CookiesDestroy
      ::page error 1
      error [loginPage]
  }
  return {}
}

###
# topic: 7f75e21b-71cf-e040-6baf-ecd8a28dc405
###
proc ::community::Authenticate {username password} {
  set cleartext [db one {select password from users where username=$username limit 1}]
  if { $cleartext == {} } {
      return 0
  }
  if { $password == $cleartext } {
      return 1
  }
  return 0
}

###
# topic: 9f9af7ac-fdb4-e5ab-4076-b6e6a25dfaec
###
proc ::community::cget field {
  if {[info command ::community::$field] != {} } {
    return [::community::$field]
  }
  variable settings
  if {[dict exists [get settings] $field]} {
    return [dict get $settings $field]
  }
  global Config
  if {[info exists Config($field)]} {
    return $Config($field)
  }
  return {}
}

###
# topic: cd7d763b-25d5-edb2-1080-082a20636eaf
###
proc ::community::CookiesCreate {{remember 0}} {
  variable expire
  set session_id [session_peek]

  if [LocalHost] {
      set local_session $session_id
  }
  ###
  # Ensure that whatever name the user type in is included
  # in the list of cookie domains
  ###
  set host [lindex [split [::taourl::request_get host] :] 0]

  if [string is true -strict $remember] {
    set ::session(remember) 1
    Cookie_Set  -name session \
      -value $session_id \
      -domain $host \
      -path / \
      -expires [clock format [expr [clock seconds] + [set expire]] -format "%Y-%m-%d"]
    set ::session(remember) 1
    Cookie_Set  -name session-login \
      -value $session_id \
      -domain $host \
      -path / \
      -expires [clock format [expr [clock seconds] + [set expire]] -format "%Y-%m-%d"]
  } else {
    set ::session(remember) 0
    Cookie_Set  -name session \
      -value $session_id \
      -domain $host \
      -path /
    set ::session(remember) 0
    Cookie_Set  -name session-login \
      -value $session_id \
      -domain $host \
      -path /
  }
  
}

###
# topic: 808ff4a2-402c-1f17-9434-b9f8e8954871
###
proc ::community::CookiesDestroy {} { 
  global env

  if [LocalHost] {
    set local_session {}
  } else {
    Cookie_Unset session
  }
}

###
# topic: f734a993-cb7b-64d0-01dd-ec25573827a7
# description:
#    Returns a session ID number from a cookie
#    
#    If no cookie could be retrieved, returns
#    "anonymous"
###
proc ::community::CookiesRetrieve {} {
  global env page
  set authinfo {}

  set result {}
  set authinfo [Cookie_Get session]
  foreach item $authinfo {
    if {[string length $item]} {
      lappend result $item
    }
  }

  # An Ugly Hack for testing
  # Browsers do not seem to store cookies originating
  # from localhost
  if { $result == {} } {
      if [LocalHost] {
          set result $local_session
      }
  }

  if { $result == {} } {
      set result anonymous
  }

  return $result
}

###
# topic: d2074ca5-5aea-522b-fecb-13daca81cc22
###
proc ::community::get_sesid keyval {
  foreach key $keyval {
    if {[db exists {select sesid from session where node_id=:key or sesid=:key}]} {
      return [db one {select sesid from session where node_id=:key or sesid=:key}]
    }
  }
  if { [llength $keyval] == 2 } { 
      set keyval [lindex $keyval 1]
  }
  if ![string is integer $keyval] {
      return $keyval
  }
  return [db one {select sesid from session where node_id=:keyval}]
}

###
# topic: 51b7f83e-9dbe-5213-12ea-aa2546dce2be
###
proc ::community::GlobalLinks {} {
  
}

###
# topic: 1e99bb08-c615-2fae-7a6d-5cc58a4f62fc
###
proc ::community::homepage {} {
  return [::wiki::html/node 2]
}

###
# topic: 730ef67f-6a55-62c9-397d-7e9867336228
###
proc ::community::homeUrl {} {
  return /home
}

###
# topic: 616868c7-2474-8cc1-59d3-268e2d6e4d66
###
proc ::community::LocalHost {} { 
  if { [lindex [split [::taourl::request_get host] :] 0] == "localhost" } {
      return 1
  }
  return 0
}

###
# topic: ddc9d7b4-c01c-58ee-7556-ec4e368a08f7
###
proc ::community::loginPage {{message {}}} {
  ::page title "Please Log In"
  ::page message $message
  ::page layout login
  return [subst [::html-style::template login]]
}

###
# topic: ea285341-42b1-d3f3-f0d8-a6ad5bfe4098
###
proc ::community::menuMethods args {}

###
# topic: 7490f13f-7837-e3ea-7147-577bf00225b7
###
proc ::community::menuNavigation args {}

###
# topic: 6e5d21e6-b0de-28cd-d65b-7542357186f1
###
proc ::community::nodeAcl node {
  if { [set aclnode [db one {select acl_name from acl_node_cache where node_id=$node}] != {} } {
      return $aclnode
  }
  set aclnode [db one select {acl_name from acl_node where node_id=$node}]
  if { $aclnode == {} } { 
    if { [lsearch [aclList] $node] >= 0 } {
      set aclnode $node
    }
  }
  if { $aclnode == {} } {
    if {[set cobj [lindex [split $node -] 0]] != $node } { 
      set aclnode [nodeAcl $cobj]
    }
  }
  if { $aclnode == {} } { 
    set aclnode default
  }
  db eval {INSERT OR REPLACE INTO acl_node_cache (acl_name,node_id) VALUES ($aclnode,$node)}
  return $aclnode
}

###
# topic: 57af05bd-9369-3a86-217b-a6340f1d5496
###
proc ::community::poke args {
  variable settings
  if {[llength $args]==1} {
    foreach {var val} [lindex $args 0] {
      dict set settings $var $val
    }
  } else {
    dict set settings {*}$args 
  }
}

###
# topic: 68a3e6c4-baca-1ec1-99ed-7cf7868e0104
###
proc ::community::prefsLoad args { 
  ::page::colors
  upvar 1 user user
  set user [::CurrentUser]
  ::page user $user
  return {}
}

###
# topic: bbdfdbc0-e11d-a575-2e81-c8a27de46b0f
###
proc ::community::prelim {} {
  uplevel 1 {
      global page session prefs env userprefs
      ::community::urlPrelim
      variable home
  }
}

###
# topic: 9064e9d0-9f58-de41-697d-f9260d7015d4
###
proc ::community::prohibit_anon {} {
  return 0
}

###
# topic: 86073f8e-c7d9-e499-9ba6-c63e54c300bb
# description: Create a new session ID
###
proc ::community::session_create {sesid userid {info {}}} {
  variable expire
  variable aclSqlObj
  set sesid  [get_sesid $sesid]

  set ::lastauth foo
  ###
  # Sessions automatically expire 48 hours after issue
  ###
  # Can overrid by specifiying expires in the info
  ###
  set expires [expr [clock seconds] + $expire]
  set created [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  
  array set foo $info
  array set foo [list sesid $sesid userid $userid expires $expires]
  set dat [array get foo]
  db eval {INSERT OR REPLACE into session (sesid,expires,data) VALUES ($sesid,$expires,$dat)}
}

###
# topic: 619d332d-f5bd-452d-d40b-12c82dd34c9e
# description:
#    Dump the contents of the session in [list var val var val ...]
#    format
###
proc ::community::session_dump {} {
  return [array get ::session]
}

###
# topic: c1101f0e-f7ca-9f10-adea-d73165b0910b
# description: Return a field from the session.
###
proc ::community::session_infoget {{fields {}}} {
  return [array get ::session $fields]
}

###
# topic: cde626e4-feca-ed28-3318-808c03290724
# description: Set a field inside a session
###
proc ::community::session_infoset values {
  return [array set ::session $values]
}

###
# topic: 72df6c94-7bde-32d4-d6bc-af724ba3a334
# description:
#    Marks a session as being invailid
#    
#    Also performs garbage collection on any other dead or expired sessions.
###
proc ::community::session_invalidate sesid {
  variable aclSqlObj
  set sesid  [get_sesid $sesid]
  db eval {delete from session where sesid=$sesid}
  ###
  # Cleanup all dead sessions
  ###
  set now [clock seconds]
  db eval {delete from session where expires < $now}
}

###
# topic: 7303bf64-23f1-4893-a01c-8fa19911a1aa
###
proc ::community::session_peek {} { 
  variable session_stack
  set sesid [lutil pop session_stack]
}

###
# topic: 7030850c-e6b0-d662-a5b4-86ffb430e347
# description:
#    "log out" the current session, save changes, and re-push the previous
#    session into the foreground (if any)
#    
#    If no session is available, the "anonymous" session is loaded
###
proc ::community::session_pop {} {
  variable session_stack
  session_save
  set sesid [lutil pop session_stack]
  array unset ::session
}

###
# topic: 80eed6f7-4149-4144-cd8d-0eb711aff335
# description:
#    Push a session ID into the authentication stack
#    
#    I use a stack to keep track of what level we are operating at. Some
#    tasks need privilage escalation, which is implemented by pushing a
#    new session, and popping when out of the critical section.
#    
#    At this point the system does NOT check who is actually entitled to
#    push session information. Feel free to override this proc ::community::with
#    code that DOES.
#    
#    After a session push, the contents of the session are loaded into
#    a global array ::session and user preferences are loaded into a
#    global array ::userprefs
###
proc ::community::session_push sesid {
  variable session_stack
  set sesid  [get_sesid $sesid]

  array unset ::session
  array unset ::userprefs
  if ![session_validate $sesid ::session] {
      error "Invalid Session"
  }
  lutil push session_stack $sesid

  if { $sesid == "anonymous" } {
      array set ::session {
          username nobody
          userid   99
          groups   nobody
          group    99
          rights   {}
      }         
  } 
  array set ::userprefs [array get ::session]
  set ::session(sesid) $sesid
}

###
# topic: c5225846-6474-75fa-c3cf-22b3e5f885ec
###
proc ::community::session_save {} { 
  variable expire
  variable aclSqlObj
  set sesid [session_peek]
  if { $sesid == {} } {  
      set sesid [get ::session(sesid)]
  }
  set expires [expr [clock seconds] + $expire]
  set dat [array get ::session]
  db eval {
    UPDATE session set expires=$expires,data=$dat where sesid=$sesid
  }
}

###
# topic: b63bc9a2-d9a8-7aff-9453-51be052777e8
###
proc ::community::session_su newuserid {
  lutil push ::session(usersstack) $::session(userid)
  set ::session(userid)  $newuserid
}

###
# topic: 66ef9888-3365-d8af-ee7b-892b0f1642ab
###
proc ::community::session_su_undo {} { 

  lutil pop ::session(userstack) userid
  set ::session(userid)  $userid

}

###
# topic: f02b987b-250b-bae9-3420-a55ba5fdab8b
# description: Returns 1 if session is valid, 0 otherwise
###
proc ::community::session_validate {sesid {varname {}}} {
  variable aclSqlObj
  if { $varname != {} } { 
      upvar 1 $varname info
  }
  set sesid  [get_sesid $sesid]
  set row [db eval {select expires,data from session where sesid=$sesid}]

  set expires [lindex $row 0]
  array set info [lindex $row 1]

  set ::lastauth {}
  # A session for anonymous always exists
  if { $sesid == "anonymous" } {
      lappend ::lastauth anon
      return 1
  }
  if { $expires != {} } { 
      if { $expires < [clock seconds] } {
         lappend ::lastauth "expired"
         session_invalidate $sesid
         return 0
      }
  }
  lappend ::lastauth [list Loaded $sesid [array get info]]
  if { [array get info userid] == {} } {
      lappend ::lastauth "No Session"
      session_invalidate $sesid
      return 0
  }
  return 1
}

###
# topic: 9c6a73a5-eb12-f745-86a0-4601d6c1157e
###
proc ::community::SessionBuild {{username {}}} { 
  global session
  global prefs

  if { $username == {} } {
      set username $session(username)
  }
  
  set session(uid)      [Uid $username]
  set session(username) [UserMap $username {}]
  set session(USER)     $::session(username)
  set session(usertype)    [UserType $username]
  set session(timestamp) [clock seconds]
}

###
# topic: 04438e14-adf6-9169-42b3-64c6cde8a21d
###
proc ::community::SessionLoad {} {
  set session_id {}
  foreach session_id [CookiesRetrieve] {
    if ![catch {session_push $session_id} valid] {
      return $session_id
    }
  }
  #if { $session_id != {} } {
  #  CookiesDestroy
  #  session_invalidate $session_id
  #}
  ###
  # Invalid session
  # nuke the cookes and 
  # revert to anonymous
  ###
  #CookiesDestroy
  return anonymous
}

###
# topic: a2cabf5c-493c-24c5-ee25-dc1e6bad27a2
###
proc ::community::Uid username {
  set user [lindex [split $username -] end]
  set uid [db one {select uid from users where uid=$user or username=$user or email=$user limit 1}]
  return $uid   
}

###
# topic: 7decfdcd-6bf3-3b3a-5fd7-deff5fa79000
###
proc ::community::urlPostlim {} {
   set ::errorFlag([get ::session(userid)]) 0
  session_pop
}

###
# topic: 728e8d3a-2444-17ac-ac23-a2b4bf166f7a
###
proc ::community::urlPrelim {{object {}} {aclcheck {}}} {
  ###
  #  Run through the postexec script
  ###
  ::page::clear

  if { $::post_exec != {} } { 
      foreach script $::post_exec {
          if [catch {eval $script} err] {
              puts [list error script $err]
          }
      } 
  }

  if { $::post_exec_force != {} } { 
      foreach script $::post_exec_force {
          if [catch {eval $script} err] {
              puts [list error $script $err]
          }
      } 
  }

  set ::post_exec {}
  set ::post_exec_force {}
  SessionLoad

  AnonymousUser [prohibit_anon]

  ###
  # Load Session
  ###
  prefsLoad
  ::page title {}

  if { $aclcheck != {} } { 
      if ![aclRights $aclcheck [CurrentUser] access] {
          error [::html-style::template access-denied]
      }
  }
}

###
# topic: 73501c8b-62c1-c40c-59b3-cf622a8bdcb8
###
proc ::community::UserFullName user {
  set user [lindex [split $username -] end]
  set uid [db one {select name from users where uid=$user or username=$user or email=$user limit 1}]
}

###
# topic: fd2d1f5f-8b70-76ba-6815-04c4a6290474
###
proc ::community::UserIsMember {group userid} {
  if { $userid == "anonymous" } { return 0 }
  if { $userid == "nobody" } { return 0 }
  if { $userid == "" } { return 0 } 
  if { $userid == "99" } { return 0 }
  return 1
}

###
# topic: a941faf9-0261-9b3f-9948-6e14bb566457
###
proc ::community::UserMap {username {altstring {}}} {
  set username [db one {select username from users where uid=$username OR username=$username or email=$username limit 1}]            
  return $username
}

###
# topic: b50f1e78-2378-c9cc-a602-56649be09e14
###
proc ::community::UserName user {
  set user [lindex [split $username -] end]
  set uid [db one {select username from users where uid=$user or username=$user or email=$user limit 1}]
 
}

###
# topic: 616804ee-5d4d-899d-c41c-060ae4df4055
###
proc ::community::UserType username {
  set username [db eval {select type from users where uid=$username OR username=$username or email=$username limit 1}]
  return $username
}

###
# topic: c8f2a75e-5cbd-9912-ee94-39d371488b0c
###
proc ::community::wrapPage objresult {
  set page [::html-style::template [::page layout]]
  set result [subst $page]
  urlPostlim
  return $result
}

###
# topic: 30485880-67cb-83d6-9eaf-4b0aa64dde6f
###
namespace eval ::community {
variable expire  172800
  namespace export *
  namespace ensemble create
  set ::post_exec {}
  set ::post_exec_force {}
}

###
# Session Management
###

###
#    Session manager object
#
#    Designed to be loaded by the system as a generic monikor (usually
#    session), this system validates and invalidates access credentials
#    stored in an SQL (or sql-like) database. (See build_tables Method)
###

