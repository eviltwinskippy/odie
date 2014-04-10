package require httpd::md5hex

::namespace eval ::login {}

###
# topic: bdf23e76-a7d9-65dc-98c0-c3b0f2ae0e40
###
proc ::login::html queryDict { 
  return [::community loginPage {Please Log In}]
}

###
# topic: 5c3408d4-4400-42bb-335f-a97af4a78582
###
proc ::login::html/authenticate {username plaintext password remember} {
  if { $username == {} } { 
      return [::community loginPage {Invalid Form: No Username}]
  }
  if { $plaintext == {} } {
    set plaintext $password
  }
  if { $plaintext == {} } { 
      return [::community loginPage {Invalid Form: No Pass}]
  }
  set uname [::community UserMap $username $plaintext]
  if { $uname != {} }  {
          set username $uname
  }
  if {[::community Authenticate $username $plaintext]} {
    return [login_page $username [string is true $remember]]
  }
  return [::community loginPage {Invalid Form: Login Failed}]
}

###
# topic: cd084dac-ccc6-5d29-1705-351206171dae
###
proc ::login::html/direct uid {
  set userid [::community::direct_authenticate $uid]
  if { $userid <= 0} {
    return [::community loginPage {Please Log In}]
  }
  return [login_page $userid 0]
}

###
# topic: cff773ef-0b74-f9dd-a144-e455b4b1ed11
###
proc ::login::html/login queryDict {
  
  return [::community loginPage  {Please Log In}]
}

###
# topic: 1532939d-420f-4e62-149e-45601a0ddf7e
###
proc ::login::html/logout queryDict {
  ::community SessionLoad
  set sesid [::community session_peek]
  ::community CookiesDestroy
  
  ::community session_pop
  ::community session_push anonymous
  ::community session_invalidate $sesid
  
  return [::community loginPage {You have been logged out}]
}

###
# topic: 660ee7b2-aa91-6312-31e4-6c65e01ab0b3
###
proc ::login::html/session queryDict {
  community prelim
  ::community SessionLoad

  append result "<HTML><HEAD><TITLE>Session Data</TITLE></HEAD><BODY>\n"
  append result "<H2>Session</H2>"
  append result "domains: - [httpd virtual_alias] [httpd cget siteRoot]<p>"
  append result "<TABLE>\n"
  foreach {var val} [array get ::session] { 
      append result "<TR><TH>$var</TH><TD>$val</TD></TR>\n"
  }
  append result "</TABLE>\n"
  append result "<H2>User Prefs</H2>"
  append result "<TABLE>\n"
  foreach {var val} [array get ::userprefs] { 
      append result "<TR><TH>$var</TH><TD>$val</TD></TR>\n"
  }
  append result "</TABLE>\n"
  append result "<H2>Env</H2>"
  append result "<TABLE>\n"
  foreach {var val} [array get ::env] { 
      append result "<TR><TH>$var</TH><TD>$val</TD></TR>\n"
  }
  append result "</TABLE>\n"
  return $result
}

###
# topic: 46a4f951-de04-87ee-9b77-9a4b51fa0f31
###
proc ::login::html/su queryDict {
  prelim
  variable session_build_proc

  append result {
<HTML>
<HEAD><TITLE>Switch Users</TITLE></HEAD>
<BODY>
  }
#	append result "<P>[get session(rights)]</P>"
  if {[lsearch [get session(rights)] admin] < 0 } {
      append result {
<H1>This Function is for Administrators Only</H1>
      }
  } else {
      append result "
      <FORM action=$home/su_do method=post>
Switch User:  <input name=USER size=15> <input type=submit name=function value=su>
</FORM>
"
  }
  if {[set realuser [lutil peek session(realuser)]] != {}} {
      append result "
<P>
You appear as $session(username), but are really $realuser
<FORM action=$home/su_undo method=post>
Un-Switch User: <input type=submit name=function value=undosu></FROM>
"
  }
  append result {
</BODY>
</HTML>
  }
  urlPostlim
  return $result
}

###
# topic: 36438e94-f321-d496-9fd6-0c0ca04a0233
###
proc ::login::html/su_do queryDict {
  prelim
  variable session_build_proc
  set USER [dict get $quertDict USER]

  if {[lsearch [get session(rights)] admin] < 0 } {
      ::taourl::redirect $home/su
  }

  set realusers [get session(realuser)]
  lutil push realusers $session(username)

  set ::session(username)  $USER
  set ::session(realuser) $realusers

  [SessionBuild $USER]
  urlPostlim
  return [my html/session]

}

###
# topic: 458f84bd-194c-6a51-3983-9aaf232f07a9
###
proc ::login::html/su_undo queryDict {
  prelim
  variable session_build_proc

  set realusers [get session(realuser)]
  lutil pop realusers username
  set session_id $session(session_id) 
  if { $username != {} } { 
      [SessionBuild $username]
  } 
  urlPostlim
  return [my html/session]
}

###
# topic: 03f21d57-5a50-408f-8764-b2c00864fc79
###
proc ::login::login_page {username remember} {
  set now [clock seconds]      
  set uid [::community Uid $username]
  set session_id [md5hex ${uid}-${now}]
  ###
  # If we have a session, redirect to home
  ###
  set url  [::community cget homeUrl]
  if { $url eq {} } {
    set url /home
  }
  
  ::community session_create $session_id $username
  ::community session_push $session_id
  ::community CookiesCreate $remember
  
  ::community SessionBuild $username
  
  ::community session_pop
  
  set result {<HTML><HEAD><TITLE>Logging In...</TITLE>}
  
  append result "
<META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">
<META HTTP-EQUIV=\"Refresh\" Content=\"0; url=$url\">
<HEAD><BODY>
"
    
  append result "
[::html-style::template site-logo]
<P>You are now logged in<P>
Stand by while your home page is loaded
    
If your browser does not load the page after several seconds
<A HREF=$url>Click here for your Home Page</A>
</BODY>
</HTML>
"
  return [subst $result]
}

###
# topic: 5287cbe2-5309-7e92-f7fc-80b8bc64ebfd
###
proc ::login::menuMethods args {}

###
# topic: 180aaa57-93b5-e08d-8cb9-d7f907eec94c
###
proc ::login::menuNavigation args {}

###
# topic: ed782d44-380a-016d-f663-f6472a9ce702
###
proc ::login::nodeSummary user {
  return [db eval {select name from users where uid=$user}]
}

###
# topic: 541441d2-a8f5-2e7e-ce12-6c95b6b13a20
###
proc ::login::nodeUrl user {
  return /login/user/$user
}

###
# topic: ed1d3091-a9cb-be82-92af-450d8db44299
###
namespace eval ::login {
namespace export *
  namespace ensemble create
}

Direct_Url /login ::login::html

