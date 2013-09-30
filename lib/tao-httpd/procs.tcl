###
# topic: 6fb50373-0f1c-9c2d-331f-6986be815d67
###
proc ::/eventlog {} { 
    return [::tao::node_container events]
}

###
# topic: 562e3392-4e0b-14b3-f12c-683118736fc6
###
proc ::/group gid {
    return [::community /group $gid]
}

###
# topic: ddc9b79c-406d-38ef-8478-60efb9d8796b
###
proc ::/groups {} { 
    return ::community
}

###
# topic: 492361c1-b4cf-bfbe-25c3-4adbf78a01c4
###
proc ::/user uid {
    return [::community /user $uid]
}

###
# topic: 6d1a2898-ca0f-5218-a140-4e7acdc76caf
###
proc ::/users {} {  
    return ::community
}

###
# topic: c49959a0-f35c-fd6f-9f46-1395b7f41efe
###
proc ::ColorScheme {} { 
    set result {}
    set newcolors {
	bgcolor   #669966 barcolor1 #CCFFCC barcolor0 #339966
	rowtitle  #33CC99 rowcolor0 #CCFFCC rowcolor1 #339966
	disabled  #CCFFCC menutext  #000000 maincolor #FFFFFF
    }
    set oldcolors {
	bgcolor   #a0a0c0 barcolor1 #c8c8a0 barcolor0 #c8a0c8
	rowtitle  #006666 rowcolor0 #d8d8d8 rowcolor1 #a0c8a0
	disabled  #a8a8a8 menutext  #000000 maincolor #FFFFFF
    }
    array set colors $oldcolors
    foreach item [array names colors] {
	if {[set val [get ::prefs($item)]] != {} } {
	    set colors($item) $val
	}
    }
    return [array get colors]
}

###
# topic: 8ed43d01-49dc-d7cb-03c4-fadbbaa6797a
###
proc ::csubst buffer {
    if [catch {subst $buffer} err] { 
	return $buffer
    }
    return $err
}

###
# topic: 9d959e5d-a688-a976-55f7-e909c5659fbe
###
proc ::CurrentUser {} { 
    set userid [lindex [array get ::session userid] 1]
    if { $userid == {} } { 
	return nobody
    }
    return $userid
}

###
# topic: a14ae8d3-73c0-d9fa-6209-74132072f5e3
###
proc ::loginPage {{message {}}} {
    ::community loginPage $message
}

###
# topic: ac9bdc00-843d-5243-7d84-cc29354f4fa5
###
proc ::reload {} {
  set result {}
  foreach file [glob [file join $::Config(library) *.tcl]] {
    if { [lsearch pkgIndex.tcl [file tail $file]] < 0 } {
        if [catch {
            source $file
        } err] {
            lappend result [file tail $file] $err
        } else {
            lappend result [file tail $file] ok
        }
    }
  }
}

###
# topic: 6819089e-def9-8099-1ade-f961ccedd584
###
proc ::Template name { 
    return [::html-style::template $name]
}

###
# topic: f9cc2a26-f5a7-37b1-3242-3836846651fd
###
proc ::Uid uid {
    return [::community Uid $uid]
}

###
# topic: aa46c6ab-df14-59e6-020f-9c39c6f22a57
###
proc ::UserFullName uid {
    return [::community UserFullName $uid]
}

###
# topic: 20f547a5-fe92-32b5-eaa9-b1ba796bf107
###
proc ::UserMap {username password} {
    return [::community UserMap $username $password]

}

###
# topic: 20c81bd9-a934-f965-f5a7-efb750e0b5ae
###
proc ::UserName uid {
    return [::community UserName $uid]
}

