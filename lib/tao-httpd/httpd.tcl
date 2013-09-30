###
# Webserver ambassador ensemble
###

::namespace eval ::httpd {}

###
# topic: f1e97be5-b655-c808-e17f-a1ee6acbefe0
###
proc ::httpd::cget args {
  global httpd_config Httpd
  if {[dict exists $httpd_config {*}$args]} {
    return [dict get $httpd_config {*}$args]
  }
  if {[dict exists $httpd_config httpd {*}$args]} {
    return [dict get $httpd_config httpd {*}$args]
  }
  set field [lindex $args 0]
  if {[info exists Httpd($field)]} {
    return $Httpd($field)
  }
  return {}
}

###
# topic: a69720ad-f4dd-9062-1b9f-f4b482e6bfca
###
proc ::httpd::config {field args} {
  variable config
  global Httpd
  if {[llength $args]} {
    cput $field {*}$args
  }
  return [cget $field]
}

###
# topic: 2fe13b13-0965-8467-ca1c-ae65e50493ab
###
proc ::httpd::cput {field args} {
  variable config
  global Httpd

  set Httpd($field) [lindex $args 0]
  dict set config $field {*}$args

}

###
# topic: d53067ba-6d98-b645-d8d2-64de06d84398
###
namespace eval ::httpd {
  variable config
}

###
# topic: d53067ba-6d98-b645-d8d2-64de06d84398
###
namespace eval ::httpd {
  namespace export *
  namespace ensemble create
}

