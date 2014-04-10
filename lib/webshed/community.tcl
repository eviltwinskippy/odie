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
# topic: 2915e0f9-6abd-985c-2ee6-307af4b194b6
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
# topic: 28ad655f-df3c-67ad-2d35-2cb6d80d5dd8
###
proc ::community::aclBaseRights {} {
  return admin
}

###
# topic: 41bf2471-4ce2-01cc-c1df-8774c6485462
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
# topic: da8f27fa-4c15-7ae1-b2f5-195352ac2f0b
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
# topic: a74ce78f-686c-157e-4c51-a6755232a3ae
###
proc ::community::aclCacheSave {aclname userid rights} {
  variable aclSqlObj
  db eval "INSERT OR REPLACE into acl_rights (acl_name,userid,rights) VALUES ('$aclname','$userid','$rights')"
}

###
# topic: dcfdf24c-7ad0-d190-fc78-4cdbe2835414
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
# topic: 98c97d72-5cc4-6eb1-7e40-815058997762
###
proc ::community::aclCreate {aclname parent} {
  variable aclSqlObj
  if { $parent == $aclname } { 
      set parent {}
  }
  db eval "INSERT OR REPLACE into acl (acl_name,parent) VALUES ('$aclname','$parent')"
}

###
# topic: 53808543-9e47-5150-2392-70758dfae05f
###
proc ::community::aclDeleteRule id {
  variable aclSqlObj
  db eval "DELETE from acl_grants where node_id='$id'"
  db eval "DELETE FROM acl_rights"
}

###
# topic: a577835a-4f89-3dce-48fd-371ec9655b4a
###
proc ::community::aclDeny {aclname userid right} {
  variable aclSqlObj
  set userid [UserMap $userid]
  db eval "INSERT OR REPLACE into acl_grants (acl_name,userid,grant,right) VALUES ('$aclname','$userid',0,'$right')"
  db eval "DELETE FROM acl_rights"
}

###
# topic: f692cf5e-1e0e-a08b-1766-e5de04e7df19
###
proc ::community::aclGrant {aclname ruserid right} {
  variable aclSqlObj
  set userid [UserMap $ruserid]
  db eval "INSERT OR REPLACE into acl_grants (acl_name,userid,grant,right) VALUES ('$aclname','$userid',1,'$right')"
  db eval "DELETE FROM acl_rights"
}

###
# topic: 7b9db6ab-e395-3d8b-a999-2915a4606971
###
proc ::community::aclList {} {
  variable aclSqlObj
  return [db eval "select distinct acl_name from acl order by acl_name"]
}

###
# topic: ba23f359-c00c-69de-7035-f421dd8d905f
###
proc ::community::aclLoad filename {
  source $filename
}

###
# topic: 86aa4cba-c2a1-832c-39d4-4d31b603ab07
###
proc ::community::aclNode {aclname node} {
  variable aclSqlObj
  db eval "INSERT OR REPLACE into acl_node (acl_name,node_id) VALUES ('$aclname','$node')"
  db eval "DELETE FROM acl_node_cache"
}

###
# topic: 8001755b-3b8d-22f9-4c9b-87ab22a94d02
###
proc ::community::aclParent aclname {
  variable aclSqlObj
  return [lindex [db eval "select parent from acl where acl_name='$aclname'"] 0]
}

###
# topic: 4d3bb3b5-ac7b-5166-edc1-1d707ed87839
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
# topic: 0c1df040-7f2b-d109-a502-5d8920e6d40e
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
# topic: 6058b2df-a6a7-85d4-26ac-f8c92e0d2060
###
proc ::community::aclRules aclname {
  variable aclSqlObj
  return [db eval "select node_id,userid,right,grant from
acl_grants where acl_name='$aclname' order by node_id"]
}

###
# topic: a708fcd3-0c75-0c4b-aaf1-144e999cce9e
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
# topic: 5504fea3-e813-e8e1-0bad-a6cd81c035bd
###
proc ::community::aclSetParent {aclname newparent} {
  variable aclSqlObj
  set newparent [string trim [lindex $newparent 0]]
  db eval "update acl set parent='$newparent' where acl_name='$aclname'"
}

###
# topic: 46a0e9f1-b92a-8578-2d9f-388f041b1ad1
###
proc ::community::aclWheelMode {} {
  return 1
}

###
# topic: fe01c519-6627-4ce6-f453-5e7e8a784639
###
proc ::community::Anonymous {} {
  if { [CurrentUser] in {anonymous nobody {} 99} } {
      return 1
  }
  return 0
}

###
# topic: de2ace7e-6173-bf58-f878-f47501c4dc70
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
# topic: 129b0307-5931-ba31-f2d3-797ef22e89d1
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
# topic: 7af1ae3d-8420-e01e-730d-0e9e750aa24e
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
# topic: fe64e676-9fd2-48e5-ab5d-4df1594c29fc
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
# topic: 9a48c2f9-fb2c-4523-2ad7-371994ddeac0
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
# topic: 7d40853a-024b-0daf-076b-c84040944203
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
# topic: 5845b96b-5e4a-e1fb-c90d-efecc7a620dd
###
proc ::community::homeUrl {} {
  return /home
}

###
# topic: ba57c2fe-e317-2166-568d-1426e809b6d1
###
proc ::community::LocalHost {} { 
  if { [lindex [split [::taourl::request_get host] :] 0] == "localhost" } {
      return 1
  }
  return 0
}

###
# topic: 9b6bd662-283e-cb20-79ef-6e5f50b11c9e
###
proc ::community::loginPage {{message {}}} {
  ::page title "Please Log In"
  ::page message $message
  ::page layout login
  return [subst [::html-style::template login]]
}

###
# topic: 75b6e239-d9f8-0593-99e5-da0abee8a1dc
###
proc ::community::menuMethods args {}

###
# topic: 04d953ac-5a03-7839-688c-64b72dc4c273
###
proc ::community::menuNavigation args {}

###
# topic: 66301c91-1a2e-b02c-8e65-5c58800348e1
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
# topic: 6cb8347a-9741-cc27-799f-cebbc87be23d
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
# topic: 663e9c98-8db2-e0aa-1977-c6cfed7da54e
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
# topic: fdbe3629-ab32-be24-8ab4-9b4ba3187d07
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
# topic: 183b00ce-f25b-c213-fd82-1a171f9f0d4b
###
proc ::community::Uid username {
  set user [lindex [split $username -] end]
  set uid [db one {select uid from users where uid=$user or username=$user or email=$user limit 1}]
  return $uid   
}

###
# topic: 8b283f31-04e3-bab8-b185-69782b7b287c
###
proc ::community::urlPostlim {} {
   set ::errorFlag([get ::session(userid)]) 0
  session_pop
}

###
# topic: 57204247-8833-81ce-9356-be7fd79f36ba
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
# topic: 355481a3-4b17-0673-effa-876e43e81586
###
proc ::community::UserFullName user {
  set user [lindex [split $username -] end]
  set uid [db one {select name from users where uid=$user or username=$user or email=$user limit 1}]
}

###
# topic: af281d55-2f32-da73-2382-dcabd915cf76
###
proc ::community::UserIsMember {group userid} {
  if { $userid == "anonymous" } { return 0 }
  if { $userid == "nobody" } { return 0 }
  if { $userid == "" } { return 0 } 
  if { $userid == "99" } { return 0 }
  return 1
}

###
# topic: c87deda7-1c87-7ef4-7f83-05b70475a6b2
###
proc ::community::UserMap {username {altstring {}}} {
  set username [db one {select username from users where uid=$username OR username=$username or email=$username limit 1}]            
  return $username
}

###
# topic: a9058f79-9077-9766-e47d-a3c7e1f5d6d3
###
proc ::community::UserName user {
  set user [lindex [split $username -] end]
  set uid [db one {select username from users where uid=$user or username=$user or email=$user limit 1}]
 
}

###
# topic: 6e74a813-c5ff-9655-7fb0-6d76f409184e
###
proc ::community::UserType username {
  set username [db eval {select type from users where uid=$username OR username=$username or email=$username limit 1}]
  return $username
}

###
# topic: c6af2982-f14d-a23e-84f6-b3e7afc92985
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

